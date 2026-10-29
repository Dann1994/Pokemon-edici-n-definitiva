-- Visual check for BACKLOG.md §7b.5: the es_ES naming grid (Ñ after N,
-- accented vowels on row 4) on both pages, plus a typed name using them.
--   SHOT_DIR=<dir> POKEPORT_DRIVER=tests/drivers/naming_grid_es_shot.lua \
--     "love" . --game=red
local U = require("tests.drivers.util")
local DIR = os.getenv("SHOT_DIR") or "."

return function(game)
  U.wait(5)
  local Pokemon = require("src.pokemon.Pokemon")
  local NamingScreen = require("src.ui.NamingScreen")
  U.teleport(game, "PALLET_TOWN", 5, 6, "down")
  U.wait(10)
  local mon = Pokemon.new(game.data, "PIKACHU", 5)
  local ns = NamingScreen.new(game, { title = "¿MOTE?", maxLen = 10, mon = mon })
  game.stack:push(ns)
  U.wait(20)
  -- "ÑANDÚ": type through the grid cells themselves, as A would
  local function pick(r, c)
    ns.row, ns.col = r, c
    U.wait(2)
    U.tap(game, "a")
    U.wait(4)
  end
  pick(2, 6) -- Ñ
  pick(1, 1) -- A
  pick(2, 5) -- N
  pick(1, 4) -- D
  pick(4, 6) -- Ú
  ns.row, ns.col = 2, 6
  U.wait(10)
  U.shot(game, DIR .. "/1_naming_upper.png")
  ns.lower = true
  U.wait(10)
  U.shot(game, DIR .. "/2_naming_lower.png")
  U.log("typed", table.concat(ns.glyphs))
  U.log("NAMING_GRID_ES_SHOT_DONE")
  love.event.quit()
end
