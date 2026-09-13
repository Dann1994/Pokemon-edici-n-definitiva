-- pokered-plus: Alt+Enter toggles OPTIONS -> VIDEO -> VIDEO MODE
-- (WINDOWED <-> BORDERLESS), the conventional desktop fullscreen shortcut,
-- reached straight from Game:keypressed rather than the menu. Mirrors that
-- row's own step function exactly: cycle the saved option, push it live
-- (VideoMode.apply), persist it (writeOptions).
--   luajit tests/engine/alt_enter_fullscreen_toggle.lua

package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.harness")
local check, eq = T.check, T.eq

local Game = require("src.core.Game")
local Input = require("src.core.Input")
local VideoMode = require("src.core.VideoMode")

-- Game:keypressed's own final fallback (no branch claimed the key) forwards
-- to Input:keypressed, which needs its bindings table built first
Input:init()

local realIsDown = love.keyboard.isDown
local altHeld = false
love.keyboard.isDown = function(k)
  if k == "lalt" or k == "ralt" then return altHeld end
  return false
end

local wroteOptions = 0
local origWrite = Game.writeOptions
Game.writeOptions = function(self) wroteOptions = wroteOptions + 1 end

local function freshGame()
  wroteOptions = 0
  -- a bare top()-returns-nil stub: enough for the onKeyPressed
  -- short-circuit at the top of Game:keypressed, and for a
  -- non-toggle key to fall all the way through to Pipelines.hotkey's
  -- own self.stack:top() call at the very end without a real stack
  Game.stack = { top = function() return nil end }
  Game.save = { options = { videoMode = "windowed" } }
end

-- --------------------------------------------------------------- the gate

freshGame()
altHeld = false
Game:keypressed("return")
eq(Game.save.options.videoMode, "windowed",
  "plain Enter (no Alt held): does not toggle")
eq(wroteOptions, 0, "...and never persists")

freshGame()
altHeld = true
Game:keypressed("a") -- Alt held, but not Enter
eq(Game.save.options.videoMode, "windowed",
  "Alt + a non-Enter key: does not toggle")

-- ------------------------------------------------------------- the toggle

freshGame()
altHeld = true
Game:keypressed("return")
eq(Game.save.options.videoMode, "borderless",
  "Alt+Enter: WINDOWED -> BORDERLESS")
eq(wroteOptions, 1, "...and persists the change")
eq(VideoMode.modeLabel(Game.save.options.videoMode), "BORDERLESS",
  "...matching what OPTIONS -> VIDEO -> VIDEO MODE would show")

Game:keypressed("return") -- still held, a second press
eq(Game.save.options.videoMode, "windowed",
  "a second Alt+Enter toggles back: BORDERLESS -> WINDOWED")
eq(wroteOptions, 2, "...and persists that too")

love.keyboard.isDown = realIsDown
Game.writeOptions = origWrite

T.finish("alt+enter fullscreen toggle")
