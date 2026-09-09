-- Snapshot the dynamic wide battle: surface matches the window aspect so
-- FILL leaves no bars, the message strip is flush on the window bottom and
-- the player mon's feet sit on it.
local U = require("tests.drivers.util")
local OUT = os.getenv("SHOT_DIR") or "."

return function(game)
  local BattleState = require("src.battle.BattleState")
  local Pokemon = require("src.pokemon.Pokemon")
  local WindowAspect = require("src.core.WindowAspect")

  love.window.setMode(1920, 1080, { resizable = true })
  WindowAspect.enable()
  U.wait(3)

  local o = game.save.options
  o.battleLayout, o.battleFit, o.battleHud, o.battleBg =
    "wide", "fill", "standard", "white"

  game.save.party = { Pokemon.new(game.data, "CHARMANDER", 14) }
  U.teleport(game, "ROUTE_1", 5, 5, "down")
  U.wait(30)

  local battle = BattleState.newWild(game, "PIDGEY", 9,
    { onFinish = function() end })
  game.overworld:pushBattle(battle)
  U.wait(600)
  battle.introSlide = 0
  battle.introBalls = nil
  battle.showEnemyTrainer = false
  battle.showPlayerBack = false
  battle.enemySendingOut = false
  battle.sendingOut = false
  battle.phase = "menu"; battle.menuIndex = 1
  U.wait(20)
  U.shot(game, OUT .. "/wbd_menu.png")

  battle.phase = "moveSelect"; battle.moveIndex = 1; U.wait(5)
  U.shot(game, OUT .. "/wbd_moves.png")

  battle.phase = "messages"
  battle.shown = { { }, { } }
  local txt = "PIDGEY usó ATAQUE ARENA."
  battle.shown[1] = {}
  for i = 1, #txt do battle.shown[1][i] = txt:byte(i) end
  U.wait(5)
  U.shot(game, OUT .. "/wbd_msg.png")

  U.log("WBD_SHOT_DONE")
  love.event.quit(0)
end
