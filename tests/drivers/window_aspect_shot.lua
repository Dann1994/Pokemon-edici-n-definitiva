-- Verify WindowAspect: with the lock on, a 4:3 window renders the game
-- letterboxed to 16:9 (and the window itself snaps to 16:9).
local U = require("tests.drivers.util")
local OUT = os.getenv("SHOT_DIR") or "."

return function(game)
  local WindowAspect = require("src.core.WindowAspect")

  love.window.setMode(1200, 900, { resizable = true }) -- 4:3
  U.wait(3)
  WindowAspect.enable()
  U.wait(3)
  local w, h = love.window.getMode()
  U.log(("after enable: window is %dx%d  (ratio %.3f)"):format(w, h, w / h))

  U.teleport(game, "PALLET_TOWN", 5, 6, "down")
  U.wait(10)
  game.stack:push(require("src.render.TextBox").new(game,
    "Comprobando el bloqueo 16:9 de la ventana.{PROMPT}", function() end))
  U.wait(40)
  U.shot(game, OUT .. "/aspect_1_windowed.png")

  -- now emulate a wide desktop / fullscreen: a much wider window
  love.window.setMode(2560, 1080, { resizable = true })
  U.wait(3)
  WindowAspect.onResize()
  U.wait(3)
  w, h = love.window.getMode()
  U.log(("after 2560x1080 + snap: %dx%d  (ratio %.3f)"):format(w, h, w / h))
  U.shot(game, OUT .. "/aspect_2_ultrawide.png")

  U.log("WINDOW_ASPECT_SHOT_DONE")
  love.event.quit(0)
end
