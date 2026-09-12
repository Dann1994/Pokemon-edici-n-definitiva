-- pokered-plus: HOLD B TO RUN (save.options.holdBToRun, on by default).
-- Holding B on foot halves step frames -- reusing the bike's own
-- bikeStepFrames, the same count a mod asking through movement.speed would
-- get -- AND doubles the walk-cycle clock's own rate to match, unlike the
-- bike (which only halves the former: see Player.lua's own comment on why
-- that split exists). Off on the bike, surfing, or mid-ledge-hop (the bike
-- already excludes hops for the same reason -- a hop is a fixed cosmetic
-- arc, not a regular step); off when the option is OFF.
--   luajit tests/engine/hold_b_to_run.lua

package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local Data = require("src.core.Data")
if not (Data.maps and Data.maps.PALLET_TOWN) then Data:load() end

local Game = require("src.core.Game")
local Player = require("src.world.Player")
local T = require("tests.modkit")

local function makeGame(opts)
  opts = opts or {}
  Game.save = {
    options = { holdBToRun = opts.holdBToRun },
    onBike = opts.onBike or false,
  }
  Game.input = { isDown = function(_, b) return b == "b" and opts.bHeld or false end }
end

local function newPlayer()
  local p = Player.new(Data, 5, 5, "down")
  p.stepFrames, p.bikeStepFrames = 16, 8
  return p
end

-- ------------------------------------------------------------ isRunning

makeGame{ bHeld = true }
local p = newPlayer()
T.eq(p:isRunning(), true, "holding B on foot: running (option defaults on)")

makeGame{ bHeld = false }
T.eq(p:isRunning(), false, "B not held: not running")

makeGame{ bHeld = true, holdBToRun = false }
T.eq(p:isRunning(), false, "OPTIONS -> HOLD B TO RUN = OFF: never running")

makeGame{ bHeld = true, onBike = true }
T.eq(p:isRunning(), false, "on the bike: already faster, B does not also run")

makeGame{ bHeld = true }
p = newPlayer()
p.surfing = true
T.eq(p:isRunning(), false, "surfing: nothing to run with")

p.surfing = false
p.ledgeHop = true
T.eq(p:isRunning(), false,
  "mid-ledge-hop: excluded the same way bike speedup already is")

-- --------------------------------------------------------------- stepLength

makeGame{ bHeld = true }
p = newPlayer()
local frames, running = p:stepLength("down")
T.eq(frames, 8, "running halves step frames, reusing bikeStepFrames")
T.eq(running, true, "and reports it ran, for update()'s animClock rate")

makeGame{ bHeld = false }
frames, running = p:stepLength("down")
T.eq(frames, 16, "not running: the normal walk step length")
T.eq(running, false, nil)

makeGame{ bHeld = true, onBike = true }
frames, running = p:stepLength("down")
T.eq(frames, 8, "on the bike, still halved (bike's own speedup, not running)")
T.eq(running, false, "but stepLength does not report it as a RUN")

-- tryMove locks stepFramesCur/runningCur in for the whole step (mirrors
-- onBike's own "decided once, at the start of the step" contract)
makeGame{ bHeld = true }
p = newPlayer()
local Map = require("src.world.Map")
local MapLoader = require("src.world.MapLoader")
local pallet = MapLoader.load(Data, "PALLET_TOWN")
local result = p:tryMove("down", pallet, {})
T.eq(result, "moved", "a real step starts (Pallet (5,6) facing down is open)")
T.eq(p.stepFramesCur, 8, "tryMove captured the running-halved length")
T.eq(p.runningCur, true, "and latched runningCur for update() to read")

-- ------------------------------------------------------- update(): animClock

-- running: the clock ticks twice a frame, so one walk-cycle (16 ticks)
-- still lands on exactly one (now half-length, 8-frame) step -- same ratio
-- normal walking keeps, just twice as fast in real time
p = newPlayer()
p.moving, p.progress, p.stepFramesCur, p.runningCur = true, 0, 8, true
p.targetX, p.targetY = p.cellX, p.cellY + 1
for _ = 1, 8 do p:update() end
T.eq(p.animClock, 16, "8 running frames advance animClock by 16 (2/frame)")

-- a normal (non-running) step over the same 8 real frames only reaches half
p = newPlayer()
p.moving, p.progress, p.stepFramesCur, p.runningCur = true, 0, 16, false
p.targetX, p.targetY = p.cellX, p.cellY + 1
for _ = 1, 8 do p:update() end
T.eq(p.animClock, 8, "8 walking frames advance animClock by 8 (1/frame)")

-- wall-bonk in place: running still pumps animClock at 2/frame (isRunning()
-- read live here, since a bonk has no "locked in at step start" moment)
makeGame{ bHeld = true }
p = newPlayer()
p.bumpFrames = 4
for _ = 1, 4 do p:update() end
T.eq(p.animClock, 8, "running into a wall still animates at 2/frame")

makeGame{ bHeld = false }
p = newPlayer()
p.bumpFrames = 4
for _ = 1, 4 do p:update() end
T.eq(p.animClock, 4, "walking into a wall animates at the normal 1/frame")

T.finish("hold b to run")
