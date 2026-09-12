-- Visual check for this session's additions:
--   (1) the field-move A-press prompt (SURF), OPTIONS -> EXTRAS -> FIELD
--       MOVE PROMPT (src/world/OverworldController.lua:tryFieldMovePrompt)
--   (2) the UI LAYOUT = WIDE party-menu side panel
--       (src/ui/PartyMenu.lua:drawPanel)
--   (3) the UI LAYOUT = WIDE bag/shop/PC item box, phase 2 of §1.9
--       (src/ui/ListMenu.lua:drawItemBox, the BUY list's owned-count column)
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

  -- ------------------------------------------------- (3) wide shop item box
  -- Viridian Mart's actual stock (data/scripts): a mix of long and short
  -- names, one already partly owned (POTION) and one not (PARLYZ_HEAL, so
  -- a row with no owned column proves the wide box doesn't fake one).
  game.save.money = 3000
  game.save.inventory = { POTION = 5, POKE_BALL = 12 }
  local ShopMenu = require("src.ui.ShopMenu")
  while game.stack:top() do game.stack:pop() end
  local mart = ShopMenu.new(game, {
    "POKE_BALL", "POTION", "ANTIDOTE", "PARLYZ_HEAL", "BURN_HEAL",
  }, function() end)
  game.stack:push(mart)
  U.wait(5)
  U.tap(game, "a") -- BUY (index 1 by default)
  U.wait(20)
  U.shot(game, DIR .. "/5_shop_wide_item_box.png")

  -- same scene, UI LAYOUT = CENTERED: sanity check that the sliver of
  -- BUY/SELL/QUIT peeking on the left of the item box (tx=4's classic
  -- inset) is pre-existing and not something the wide pass introduced
  game.save.options.uiLayout = "centered"
  while game.stack:top() do game.stack:pop() end
  local mart2 = ShopMenu.new(game, {
    "POKE_BALL", "POTION", "ANTIDOTE", "PARLYZ_HEAL", "BURN_HEAL",
  }, function() end)
  game.stack:push(mart2)
  U.wait(5)
  U.tap(game, "a")
  U.wait(20)
  U.shot(game, DIR .. "/6_shop_classic_item_box.png")
  game.save.options.uiLayout = "wide"

  U.log("SESSION_RECAP_SHOT_DONE")
  love.event.quit()
end
