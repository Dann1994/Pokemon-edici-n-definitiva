-- ISLA_SUPREMA -- the remote island of the Mew quest (Stages 4-5).
--
-- One small OVERWORLD map: a wooden dock on the south coast (the sailor
-- waits there to take the player back to Vermilion), a short linear
-- forest path north, the weathered "F." sign beside the path, and a
-- clearing at the top with the ancient statue.
--
-- 8 x 13 blocks (16 x 26 cells).  Block ids, confirmed against the
-- vanilla OVERWORLD tileset / PALLET_TOWN / VERMILION_CITY:
--   15 tree wall (solid)   1 open ground        10 dirt path
--   11 tall grass (deco)   84 dock planks       67 sea (border)
local T, G, P, g, D, W = 15, 1, 10, 11, 84, 67

return {
  id = "ISLA_SUPREMA",
  label = "IslaSuprema",
  index = 1000,
  tileset = "OVERWORLD",
  width = 8,
  height = 13,
  borderBlock = W,
  blocks = {
    T, T, T, T, T, T, T, T,   -- 0  north tree wall
    T, G, G, G, G, G, G, T,   -- 1  clearing (statue at cell 6,3)
    T, G, G, P, G, G, G, T,   -- 2
    T, G, G, P, G, G, G, T,   -- 3
    T, T, G, P, G, T, T, T,   -- 4  forest narrows
    T, g, G, P, G, g, G, T,   -- 5  forest
    T, G, G, P, G, G, g, T,   -- 6
    T, G, G, P, G, G, G, T,   -- 7
    T, T, G, P, G, T, T, T,   -- 8  forest entrance (the "F." sign is at 5,18)
    T, G, G, P, G, G, G, T,   -- 9  coast clearing
    T, G, G, P, G, G, G, T,   -- 10
    T, G, G, P, G, G, G, T,   -- 11
    W, W, D, D, D, W, W, W,   -- 12 the dock
  },
  connections = {},
  warps = {},   -- travel both ways is scripted (Commands.warp), no doors
  objects = {
    { index = 1, name = "ISLA_SUPREMA_SAILOR", sprite = "SPRITE_SAILOR",
      movement = "STAY", range = "NONE", x = 7, y = 24,
      text = "TEXT_ISLA_SUPREMA_SAILOR" },
    { index = 2, name = "ISLA_SUPREMA_STATUE", sprite = "SPRITE_FOSSIL",
      movement = "STAY", range = "NONE", x = 6, y = 3,
      text = "TEXT_ISLA_SUPREMA_STATUE" },
  },
  signs = {
    { text = "TEXT_ISLA_SUPREMA_SIGN", x = 5, y = 18 },
  },
}
