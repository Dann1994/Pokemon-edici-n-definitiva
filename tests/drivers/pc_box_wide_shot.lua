-- Visual check for BACKLOG.md §1.9 phase 4: the UI LAYOUT = WIDE preview
-- in Bill's PC mon lists (src/ui/ListMenu.lua:drawMonPreview, opts.monPreview
-- from src/ui/BoxMenu.lua), the same list under CENTERED for contrast, and
-- the shop BUY list sharing the wide box.
--   SHOT_DIR=<dir> POKEPORT_DRIVER=tests/drivers/pc_box_wide_shot.lua \
--     "love" . --game=red
local U = require("tests.drivers.util")
local DIR = os.getenv("SHOT_DIR") or "."

return function(game)
  -- a driver boots into a 4:3 window; the real game locks 16:9 on entry
  -- (src/core/WindowAspect.lua), the shape the wide box is sized for
  love.window.setMode(1280, 720, { resizable = true })
  -- setMode alone fires no resize event; the renderer sizes its frame off it
  if love.resize then love.resize(1280, 720) end
  U.wait(5)
  local Pokemon = require("src.pokemon.Pokemon")
  local Boxes = require("src.pokemon.Boxes")
  local BoxMenu = require("src.ui.BoxMenu")

  game.save.party = { Pokemon.new(game.data, "BULBASAUR", 34) }
  Boxes.ensure(game.save)
  local box = Boxes.active(game.save)
  for i = #box, 1, -1 do box[i] = nil end
  for _, sp in ipairs({ "CHARIZARD", "PIKACHU", "GYARADOS", "MAGNEMITE",
                        "CLEFAIRY" }) do
    box[#box + 1] = Pokemon.new(game.data, sp, 30)
  end
  U.teleport(game, "PALLET_TOWN", 5, 6, "down")
  U.wait(10)

  local function openWithdraw()
    while game.stack:top() and game.stack:top() ~= game.overworld do
      game.stack:pop()
    end
    game.stack:push(BoxMenu.new(game))
    U.wait(5)
    U.tap(game, "a") -- WITHDRAW
    U.wait(20)
    return game.stack:top()
  end

  game.save.options.uiLayout = "wide"
  local list = openWithdraw()
  U.shot(game, DIR .. "/1_pc_withdraw_wide_charizard.png")
  list.index = 2
  U.wait(10)
  U.shot(game, DIR .. "/2_pc_withdraw_wide_pikachu.png")
  list.index = 3
  U.wait(10)
  U.shot(game, DIR .. "/3_pc_withdraw_wide_gyarados.png")
  list.index = 4
  U.wait(10)
  U.shot(game, DIR .. "/4_pc_withdraw_wide_magnemite.png")

  game.save.options.uiLayout = "centered"
  openWithdraw()
  U.shot(game, DIR .. "/5_pc_withdraw_classic.png")

  -- the shop BUY list rides the same wide item box (phase 2): checks the
  -- palette-zone widening and the anchor height fix there too
  game.save.options.uiLayout = "wide"
  game.save.money = 3000
  game.save.inventory = { POTION = 5 }
  while game.stack:top() and game.stack:top() ~= game.overworld do
    game.stack:pop()
  end
  game.stack:push(require("src.ui.ShopMenu").new(game,
    { "POKE_BALL", "POTION", "ANTIDOTE", "PARLYZ_HEAL" }, function() end))
  U.wait(5)
  U.tap(game, "a") -- BUY
  U.wait(20)
  U.shot(game, DIR .. "/6_shop_buy_wide.png")

  U.log("PC_BOX_WIDE_SHOT_DONE")
  love.event.quit()
end
