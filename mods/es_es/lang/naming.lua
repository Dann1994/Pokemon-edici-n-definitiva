-- The naming screen's letter grid. Returns an empty table -> keeps the
-- English alphabet.
--
-- A Spanish grid (Ñ, accented vowels, ¿ ¡) is drafted but the scaffold's
-- `mod.hooks:on("ui.naming.grid", ...)` call in main.lua is not a real
-- API on this engine build -- wiring it needs the right hook name first.
-- See BACKLOG 7b.5.
return {}
