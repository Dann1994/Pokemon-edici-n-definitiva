-- BACKLOG §6.1: "probar el modo LAN con 2 instancias" -- a real host-side
-- run against a real guest process (tests/drivers/lan_live_guest.lua) over
-- actual UDP loopback (127.0.0.1), not the in-process Net.loopbackPair()
-- the automated suite (tests/run_link_tests.lua) uses.  Walks the exact UI
-- path a player takes from src/link/LinkState.lua: HOST A GAME -> wait for
-- the guest -> pick BATTLE -> LEVELS: ANY -> fight it out.
--
--   SHOT_DIR=<dir> POKEPORT_IDENTITY=lantest_host POKEPORT_DRIVER=tests/drivers/lan_live_host.lua lovec.exe .
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local DIR = os.getenv("SHOT_DIR") or "/tmp/shots"
  local Pokemon = require("src.pokemon.Pokemon")
  local LinkState = require("src.link.LinkState")

  game.save.party = { Pokemon.new(game.data, "CHARIZARD", 40) }
  game.save.player.name = "RED"

  do -- diagnostic: dump the link fingerprint surface for a host/guest diff
    local Handshake = require("src.link.Handshake")
    local Fingerprint = require("src.link.Fingerprint")
    local mods = Handshake.mods(game)
    local gen = Handshake.generation(game)
    local fp = Fingerprint.compute(game.data, mods, gen)
    local surf = Fingerprint.surface(game.data, mods, gen)
    os.execute('mkdir -p "' .. DIR .. '" 2>/dev/null')
    local f = io.open(DIR .. "/fingerprint.txt", "w")
    if f then f:write("fp=" .. fp .. "\n" .. surf); f:close() end
    U.log("HOST FINGERPRINT: " .. fp .. " (surface " .. #surf .. " bytes)")
  end

  U.teleport(game, "PALLET_TOWN", 5, 6, "down")
  local ow = game.stack:top()
  U.wait(10)

  local link = LinkState.new(game)
  game.stack:push(link)
  U.wait(5)
  U.log("HOST: menu up, index=" .. tostring(link.index))

  -- index 1 = HOST A GAME
  U.tap(game, "a")
  U.wait(5)
  if link.stage ~= "hosting" then
    U.log("HOST FAIL: expected stage=hosting, got " .. tostring(link.stage)
          .. " (net error: " .. tostring(link.net and link.net.error) .. ")")
    return
  end
  U.log("HOST: hosting at " .. tostring(link.net.address))
  U.shot(game, DIR .. "/host_1_hosting.png")

  local waited = 0
  while link.stage == "hosting" and waited < 1800 do
    U.wait(1); waited = waited + 1
  end
  if link.stage ~= "modeSelect" then
    U.log("HOST FAIL: guest never paired (stage=" .. tostring(link.stage) .. ")")
    return
  end
  U.log("HOST: guest paired after " .. waited .. " frames, peer=" .. tostring(link.peerName))
  U.shot(game, DIR .. "/host_2_connected.png")

  -- modeSelect: index 1=TRADE, 2=BATTLE -- move down once, confirm
  U.tap(game, "down")
  U.wait(2)
  U.tap(game, "a")
  U.wait(5)

  waited = 0
  while link.stage ~= "battleOptions" and link.stage ~= "notice" and waited < 600 do
    U.wait(1); waited = waited + 1
  end
  if link.stage == "notice" then
    U.log("HOST FAIL: compat notice instead of battleOptions: "
          .. table.concat(link.noticeLines or {}, " | "))
    return
  end
  if link.stage ~= "battleOptions" then
    U.log("HOST FAIL: never reached battleOptions (stage=" .. tostring(link.stage) .. ")")
    return
  end
  U.log("HOST: battleOptions reached, LEVELS=" .. tostring(link.levelChoice))
  U.shot(game, DIR .. "/host_3_battle_options.png")

  -- leave LEVELS on ANY, confirm
  U.tap(game, "a")
  U.wait(5)

  waited = 0
  while link.stage == "battleWait" and waited < 600 do
    U.wait(1); waited = waited + 1
  end
  if link.stage ~= "battleRunning" then
    U.log("HOST FAIL: link battle never started (stage=" .. tostring(link.stage) .. ")")
    return
  end
  U.log("HOST: link battle running")
  U.wait(30)
  U.shot(game, DIR .. "/host_4_battle_scene.png")

  -- mash A until the battle resolves and LinkState unwinds back to the
  -- overworld (exitWith pops both the battle and LinkState itself)
  waited = 0
  while game.stack:top() ~= ow and waited < 10800 do
    U.tap(game, "a")
    waited = waited + 1
  end
  if game.stack:top() ~= ow then
    U.log("HOST FAIL: link battle never finished after " .. waited .. " frames")
    return
  end
  U.log("HOST: link battle finished and returned to the overworld after "
        .. waited .. " frames")
  U.wait(10)
  U.shot(game, DIR .. "/host_5_back_in_overworld.png")
  U.log("LAN_LIVE_HOST_DONE")
end
