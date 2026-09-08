-- Build a post-game test save so the mew_event / oak_event quests can be
-- played without finishing the whole game.
--
--   "%ProgramFiles%\LOVE\love.exe" . --game=red POKEPORT_DRIVER=scripts/make_test_save.lua
-- or set the env var first:
--   set POKEPORT_DRIVER=scripts\make_test_save.lua
--   "%ProgramFiles%\LOVE\love.exe" . --game=red
--
-- Writes the active Red save slot and quits.  Launch the game normally
-- afterwards and pick CONTINUE.  You spawn in Pueblo Paleta with:
--   * the League beaten, 150 Pokemon registered, 8 badges, all story
--     events done (so the world is in its post-game state)
--   * a party led by MEWTWO L70 (the Fuji gate needs it) + a strong team
--     that can win the Oak battle, with FLY / SURF / CUT / STRENGTH
--   * POKE FLUTE, S.S.TICKET, BICYCLE, every HM, Ultra Balls, a Master
--     Ball, Full Restores, Rare Candies, ~1,000,000 money
--   * neither quest started (no MOD_MEW_* / MOD_OAK_*, no EVENT_BEAT_PROF_OAK)
--
-- To test:
--   Mew  -> Pokemon Mansion 3F (Cinnabar) : the scientist event
--           then Mr. Fuji (Lavender), the Vermilion sailor, the island
--   Oak  -> Oak's lab (Pallet) : the rival, then Bill / Cinnabar lab /
--           Lance at the Indigo Plateau / Prof. Oak on Route 1

return function(Game)
  -- let the boot sequence settle
  for _ = 1, 20 do coroutine.yield() end

  local Data = require("src.core.Data")
  if not Data.pokemon then Data:load() end
  local SaveData = require("src.core.SaveData")
  local Pokemon = require("src.pokemon.Pokemon")

  local function mk(species, level, moves)
    local mon = Pokemon.new(Data, species, level)
    if moves then
      mon.moves = {}
      for _, id in ipairs(moves) do
        local def = Data.moves[id]
        mon.moves[#mon.moves + 1] = { id = id, pp = def and def.pp or 15 }
      end
    end
    if mon.stats then
      mon.hp = mon.stats.hp
      mon.status = nil
    end
    return mon
  end

  local save = SaveData.newGame({
    startMap = "PALLET_TOWN", startX = 5, startY = 6, startFacing = "down",
    playerName = "RED", rivalName = "BLUE",
  })
  save.player.map = "PALLET_TOWN"
  save.player.x, save.player.y, save.player.facing = 5, 6, "down"
  save.money = 999999
  save.lastHeal = { map = "PALLET_TOWN", x = 5, y = 6 }
  save.lastOutdoor = { id = "PALLET_TOWN", x = 5, y = 6 }

  -- ---- every story EVENT_ flag scraped from data/scripts (post-game world)
  local blocked = {
    EVENT_BEAT_PROF_OAK = true,              -- keep the Oak event available
  }
  local seen, count = {}, 0
  local function eat(text)
    for name in text:gmatch("EVENT_[A-Z0-9_]+") do
      if not seen[name] and not blocked[name]
         and not name:find("_THIS_RUN$") and not name:find("_TEMP$") then
        seen[name] = true
        save.flags[name] = true
        count = count + 1
      end
    end
  end
  for _, path in ipairs(love.filesystem.getDirectoryItems("data/scripts")) do
    if path:sub(-4) == ".lua" then
      local body = love.filesystem.read("data/scripts/" .. path)
      if body then eat(body) end
    end
  end
  local hdr = love.filesystem.read("data/generated/trainer_headers.lua")
  if hdr then eat(hdr) end
  -- a couple the scrape can miss but the gates read explicitly
  for _, f in ipairs({ "EVENT_BEAT_CHAMPION_RIVAL", "EVENT_GOT_STARTER",
      "EVENT_CHOSE_SQUIRTLE", "EVENT_GOT_POKEDEX", "EVENT_GOT_POKE_FLUTE",
      "EVENT_RESCUED_MR_FUJI", "EVENT_RESCUED_MR_FUJI_2", "EVENT_GOT_SS_TICKET",
      "EVENT_GOT_BIKE_VOUCHER", "EVENT_BOUGHT_BICYCLE", "EVENT_BEAT_MEWTWO" }) do
    save.flags[f] = true
  end

  -- ---- Pokedex: 150 owned (everything but MEW), all 151 seen
  for id in pairs(Data.pokemon) do
    save.pokedex.seen[id] = true
    if id ~= "MEW" then save.pokedex.owned[id] = true end
  end

  -- ---- bag
  save.inventory = {
    BOULDERBADGE = 1, CASCADEBADGE = 1, THUNDERBADGE = 1, RAINBOWBADGE = 1,
    SOULBADGE = 1, MARSHBADGE = 1, VOLCANOBADGE = 1, EARTHBADGE = 1,
    POKE_FLUTE = 1, S_S_TICKET = 1, BICYCLE = 1,
    HM_CUT = 1, HM_FLY = 1, HM_SURF = 1, HM_STRENGTH = 1, HM_FLASH = 1,
    MASTER_BALL = 1, ULTRA_BALL = 30, GREAT_BALL = 20,
    FULL_RESTORE = 12, HYPER_POTION = 20, MAX_REPEL = 10,
    RARE_CANDY = 20, REVIVE = 10,
  }

  -- ---- party: MEWTWO + a team that covers HMs and can win the Oak fight
  save.party = {
    mk("MEWTWO",   70, { "PSYCHIC_M", "RECOVER", "ICE_BEAM", "THUNDERBOLT" }),
    mk("CHARIZARD", 74, { "FLY", "FLAMETHROWER", "SLASH", "EARTHQUAKE" }),
    mk("BLASTOISE", 74, { "SURF", "ICE_BEAM", "BLIZZARD", "BODY_SLAM" }),
    mk("VENUSAUR",  74, { "RAZOR_LEAF", "SLEEP_POWDER", "BODY_SLAM", "CUT" }),
    mk("SNORLAX",   72, { "STRENGTH", "BODY_SLAM", "EARTHQUAKE", "REST" }),
    mk("ALAKAZAM",  72, { "PSYCHIC_M", "RECOVER", "THUNDER_WAVE", "FLASH" }),
  }

  save.meta = SaveData.buildMeta(nil, save.meta)
  local ok = SaveData.save(save)
  print("========================================================")
  print(ok and "TEST SAVE WRITTEN" or "SAVE FAILED")
  print(("  %d story flags set, 150 dex, party of %d (lead %s L%d)")
    :format(count, #save.party, save.party[1].species, save.party[1].level))
  print("  spawn: PALLET_TOWN (5,6) -- launch normally and pick CONTINUE")
  print("========================================================")
  love.timer = love.timer or {}
  love.event.quit()
end
