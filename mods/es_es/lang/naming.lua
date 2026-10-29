-- The naming screen's letter grid (src/ui/NamingScreen.lua), rows 1-4 of
-- each page. Rows 5 (- ? ! ♂ ♀ / . , ED) and 6 (the case switch) are kept
-- from whatever grid the engine -- or a mod below this one -- hands over,
-- so confirm/case-flip keep working (see main.lua's ui.naming.grid wrap).
--
-- Gen 1's grid is exactly 5 rows of 9 inside its box, no room for a 6th,
-- but the Spanish alphabet is 27 letters: 3 rows of 9 with the Ñ after N.
-- The space moves to row 4, which trades ( ) : ; [ ] (next to useless in
-- a name) for the accented vowels. Every glyph here is on the accents page
-- main.lua registers (or a ROM tile: é) -- no Ü: that page only has the
-- lower-case ü, and a blank cell would type an invisible character.
-- Return {} to keep the English grid.
return {
  upper = {
    { "A", "B", "C", "D", "E", "F", "G", "H", "I" },
    { "J", "K", "L", "M", "N", "Ñ", "O", "P", "Q" },
    { "R", "S", "T", "U", "V", "W", "X", "Y", "Z" },
    { " ", "Á", "É", "Í", "Ó", "Ú", "×", "<PK>", "<MN>" },
  },
  lower = {
    { "a", "b", "c", "d", "e", "f", "g", "h", "i" },
    { "j", "k", "l", "m", "n", "ñ", "o", "p", "q" },
    { "r", "s", "t", "u", "v", "w", "x", "y", "z" },
    { " ", "á", "é", "í", "ó", "ú", "×", "<PK>", "<MN>" },
  },
}
