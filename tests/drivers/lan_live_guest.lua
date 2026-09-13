-- BACKLOG §6.1: "probar el modo LAN con 2 instancias" -- the guest half of
-- tests/drivers/lan_live_host.lua.  Run this as a second, separate LOVE
-- process (own POKEPORT_IDENTITY so the two saves never collide) at the
-- same time as the host driver; they pair over real UDP on 127.0.0.1.
--
--   SHOT_DIR=<dir> POKEPORT_IDENTITY=lantest_guest POKEPORT_DRIVER=tests/drivers/lan_live_guest.lua lovec.exe .
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local DIR = os.getenv("SHOT_DIR") or "/tmp/shots"
  local Pokemon = require("src.pokemon.Pokemon")
  local LinkState = require("src.link.LinkState")

  game.save.party = { Pokemon.new(game.data, "BLASTOISE", 40) }
  game.save.player.name = "BLUE"

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
    U.log("GUEST FINGERPRINT: " .. fp .. " (surface " .. #surf .. " bytes)")
  end

  U.teleport(game, "PALLET_TOWN", 5, 6, "down")
  local ow = game.stack:top()
  U.wait(10)

  local link = LinkState.new(game)
  game.stack:push(link)
  U.wait(5)

  -- give the host a head start so its UDP socket is listening before we dial
  U.wait(60)

  -- index 2 = JOIN A GAME
  U.tap(game, "down")
  U.wait(2)
  U.tap(game, "a")
  U.wait(5)
  if link.stage ~= "addrEntry" then
    U.log("GUEST FAIL: expected stage=addrEntry, got " .. tostring(link.stage))
    return
  end
  link.addr = LinkState.addrEntry("127.0.0.1")
  U.shot(game, DIR .. "/guest_1_addr_entry.png")

  U.tap(game, "a") -- connect
  U.wait(1)
  -- pairing over loopback can be near-instant, so "joining" may already have
  -- advanced to "waitMode" by the time we check
  if link.stage ~= "joining" and link.stage ~= "waitMode" then
    U.log("GUEST FAIL: expected stage=joining/waitMode, got " .. tostring(link.stage)
          .. " status=" .. tostring(link.status))
    return
  end
  U.log("GUEST: dialing " .. tostring(link.net and (link.net.target or link.net.address)))
  U.shot(game, DIR .. "/guest_2_joining.png")

  local waited = 0
  while (link.stage == "joining" or link.stage == "waitMode") and waited < 1800 do
    U.wait(1); waited = waited + 1
  end
  if link.stage == "notice" then
    U.log("GUEST FAIL: compat notice instead of a battle: "
          .. table.concat(link.noticeLines or {}, " | "))
    return
  end
  if link.stage ~= "battleWait" and link.stage ~= "battleRunning" then
    U.log("GUEST FAIL: never reached battleWait (stage=" .. tostring(link.stage) .. ")")
    return
  end
  U.log("GUEST: paired and battle mode agreed after " .. waited .. " frames, peer="
        .. tostring(link.peerName))
  U.shot(game, DIR .. "/guest_3_connected.png")

  waited = 0
  while link.stage == "battleWait" and waited < 600 do
    U.wait(1); waited = waited + 1
  end
  if link.stage ~= "battleRunning" then
    U.log("GUEST FAIL: link battle never started (stage=" .. tostring(link.stage) .. ")")
    return
  end
  U.log("GUEST: link battle running")
  U.wait(30)
  U.shot(game, DIR .. "/guest_4_battle_scene.png")

  waited = 0
  while game.stack:top() ~= ow and waited < 10800 do
    U.tap(game, "a")
    waited = waited + 1
  end
  if game.stack:top() ~= ow then
    U.log("GUEST FAIL: link battle never finished after " .. waited .. " frames")
    return
  end
  U.log("GUEST: link battle finished and returned to the overworld after "
        .. waited .. " frames")
  U.wait(10)
  U.shot(game, DIR .. "/guest_5_back_in_overworld.png")
  U.log("LAN_LIVE_GUEST_DONE")
end
