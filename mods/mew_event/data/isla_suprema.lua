-- ISLA_SUPREMA -- the remote island of the Mew quest (Stages 4-5).
--
-- One small OVERWORLD map: a wooden dock on the south coast (the sailor
-- waits there to take the player back to Vermilion), a short linear
-- forest path north, the weathered "F." sign beside the path, and a
-- clearing at the top with the ancient statue.
--
-- 8 x 13 blocks (16 x 26 cells).  Block ids, confirmed against the
-- vanilla OVERWORLD tileset by rendering the atlas:
--   15 tree wall (solid)   1 open ground (walkable, this is the path too)
--   10 tall grass (deco, no encounters registered)   84 dock planks
--   67 sea (border)   8 route sign post (post = the block's SE cell, 5,17)
-- The layout is deliberately plain -- geometry and collision are right,
-- the texturing is a first pass to refine in Tiled
-- (scripts/tiled_export_mew_event.py).
local T, G, g, D, W, S = 15, 1, 10, 84, 67, 8

return {
  id = "ISLA_SUPREMA",
  label = "IslaSuprema",
  index = 1000,
  tileset = "OVERWORLD",
  palette = "VIRIDIAN",   -- forest greens (beats the vanilla cascade)
  width = 8,
  height = 13,
  borderBlock = W,
  blocks = {
    T, T, T, T, T, T, T, T,   -- 0  north tree wall
    T, G, G, G, G, G, G, T,   -- 1  clearing (statue at cell 6,3)
    T, G, g, G, G, g, G, T,   -- 2
    T, G, G, G, G, G, G, T,   -- 3
    T, T, G, G, G, T, T, T,   -- 4  forest narrows
    T, g, G, G, G, g, G, T,   -- 5  forest
    T, G, G, G, G, G, g, T,   -- 6
    T, G, g, G, G, G, G, T,   -- 7
    T, T, S, G, G, T, T, T,   -- 8  forest entrance -- route sign post at (5,17)
    T, G, G, G, G, G, G, T,   -- 9  coast clearing
    T, G, G, G, G, G, G, T,   -- 10
    T, G, G, G, G, G, G, T,   -- 11
    W, W, D, D, D, W, W, W,   -- 12 the dock
  },
  connections = {},
  warps = {},   -- travel both ways is scripted (Commands.warp), no doors
  objects = {
    { index = 1, name = "ISLA_SUPREMA_SAILOR", sprite = "SPRITE_SAILOR",
      movement = "STAY", range = "NONE", x = 7, y = 24,
      text = "TEXT_ISLA_SUPREMA_SAILOR" },
    -- pokered-plus: the same stone-boulder sprite Viridian Gym's puzzle
    -- uses (SPRITE_BOULDER, static/single-frame, walker=false -- data/
    -- generated/sprites.lua) rather than the Cinnabar Lab fossil-tank
    -- sprite this started with, so the ancient statue actually reads as
    -- a gym-style stone monument (playtest request)
    { index = 2, name = "ISLA_SUPREMA_STATUE", sprite = "SPRITE_BOULDER",
      movement = "STAY", range = "NONE", x = 6, y = 3,
      text = "TEXT_ISLA_SUPREMA_STATUE" },
  },
  signs = {
    { text = "TEXT_ISLA_SUPREMA_SIGN", x = 5, y = 17 },
  },
}
