-- Visual check: UI LAYOUT = WIDE stretches the overworld dialogue box (and
-- the YES/NO over it) flush across the window bottom, text at native size.
--   SHOT_DIR=<dir> POKEPORT_DRIVER=tests/drivers/wide_dialogue_shot.lua \
--     "love" . --game=red
local U = require("tests.drivers.util")
local DIR = os.getenv("SHOT_DIR") or "."

return function(game)
  U.wait(5)
  game.save.options.uiLayout = "wide"
  U.teleport(game, "PALLET_TOWN", 5, 6, "down")
  U.wait(8)

  local TextBox = require("src.render.TextBox")
  local text = "Hola {PLAYER}. Este es el nuevo cuadro de "
    .. "diálogo ancho:\11ocupa todo el ancho de la ventana y el "
    .. "texto se\11repagina para llenar las líneas.{PROMPT}"
  game.stack:push(TextBox.new(game, text, function() end))
  U.wait(60)
  U.shot(game, DIR .. "/wide_dialogue_1_textbox.png")

  -- a YES/NO over the wide box
  game.stack:push(TextBox.new(game, "¿YES/NO?{PROMPT}", function() end, {
      choice = function() end,
    }))
  U.wait(150)
  U.shot(game, DIR .. "/wide_dialogue_2_choice.png")

  U.log("WIDE_DIALOGUE_SHOT_DONE")
  love.event.quit()
end
