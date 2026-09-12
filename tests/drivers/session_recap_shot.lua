-- Visual check for this session's two additions:
--   (1) the field-move A-press prompt (SURF), OPTIONS -> EXTRAS -> FIELD
--       MOVE PROMPT (src/world/OverworldController.lua:tryFieldMovePrompt)
--   (2) the UI LAYOUT = WIDE party-menu side panel
--       (src/ui/PartyMenu.lua:drawPanel)
--   SHOT_DIR=<dir> POKEPORT_DRIVER=tests/drivers/session_recap_shot.lua \
--     "love" . --game=red
local U = require("tests.drivers.util")
local DIR = os.getenv("SHOT_DIR") or "."

return function(game)
  U.wait(5)

  -- ------------------------------------------------- (1) field move prompt
  -- Pallet Town (4,13) facing down: the known-good south-shore water tile
  -- also used by tests/engine/field_move_prompt.lua.
  local Pokemon = require("src.pokemon.Pokemon")
  game.save.options.fieldMovePrompt = true
  game.save.party = { Pokemon.new(game.data, "SQUIRTLE", 20) }
  -- give the lead SURF and the Soul Badge so the water tile is mountable
  game.save.party[1].moves = { { id = "SURF", pp = 20 } }
  game.save.inventory = game.save.inventory or {}
  game.save.inventory.SOULBADGE = true
  U.teleport(game, "PALLET_TOWN", 4, 13, "down")
  U.wait(10)
  U.tap(game, "a")
  U.wait(60)
  U.shot(game, DIR .. "/1_field_move_prompt_surf.png")
  -- close the prompt without mounting, back to a clean map
  U.tap(game, "b")
  U.wait(10)

  -- --------------------------------------------- (2) wide party menu panel
  game.save.options.uiLayout = "wide"
  game.save.party = {
    Pokemon.new(game.data, "BULBASAUR", 34),
    Pokemon.new(game.data, "CHARIZARD", 42),  -- dual-typed: TYPE1 + TYPE2
    Pokemon.new(game.data, "GYARADOS", 30),   -- oversized sprite: scale-down
    Pokemon.new(game.data, "PIKACHU", 18),
    Pokemon.new(game.data, "ALAKAZAM", 38),
    Pokemon.new(game.data, "ONIX", 24),
  }
  local Screens = require("src.ui.Screens")
  local pm = Screens.push(game, "PartyMenu", {})
  pm.index = 2 -- CHARIZARD: shows the dual-type column
  U.wait(20)
  U.shot(game, DIR .. "/2_party_wide_panel_charizard.png")
  pm.index = 3 -- GYARADOS: shows the >64px sprite scale-down clamp
  U.wait(10)
  U.shot(game, DIR .. "/3_party_wide_panel_gyarados.png")
  pm.index = 4 -- PIKACHU: ELÉCTRICO is the longest Spanish type name (9)
  U.wait(10)
  U.shot(game, DIR .. "/4_party_wide_panel_pikachu.png")

  U.log("SESSION_RECAP_SHOT_DONE")
  love.event.quit()
end
