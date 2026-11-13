-- pfUI-ConsumeManager
-- A pfUI third-party module (modelled on pfUI-TotemBar / pfUI-PaladinBar) that keeps your raid
-- consumables on one bar:
--   * exclusive consumables (one flask, one food, one weapon oil...) get ONE button per group;
--     hover it to open the list of every item of that group, with how many you carry:
--       left-click  -> use it
--       right-click -> make it the group's default (the one the bar button uses)
--   * buff-bar buttons glow while their buff is not on you
--   * stackable consumables (elixirs, protection potions...) get one button each
--   * a button is lit (coloured border, timer) while its buff is on you and dimmed while it is missing
--   * "use next missing" (key binding / macro) uses the first persistent buff you are missing
--   * potions & utility (used reactively) live on their own bar, which stays up in combat
--
-- Buff detection uses nampower when it is there (item spell ids -> aura spell ids), the buff names
-- otherwise. Buffs that can't be guessed are learned the first time you use the item from the bar.

pfConsumeManager = pfConsumeManager or {}

BINDING_HEADER_PFCONSUMEMANAGER = "pfUI Consume Manager"
BINDING_NAME_PFCONSUMEMANAGER_NEXT = "Use next missing consumable"

pfUI:RegisterModule("consumemanager", "vanilla", function()
  -- [[ data ]] --
  -- excl  = only one of the category can be up: one dropdown / one bar button with a hover list
  -- auto  = a buff you keep up: counted by "use next missing" and by "hide while active"
  -- weapon = inventory slot the item is applied on
  -- anybuff = buff names that count for every item of the category (all foods give "Well Fed")
  local CATS = {
    { key = "flask",       label = "Flask",                                 excl = true, auto = true },
    { key = "food",        label = "Food",                                  excl = true, auto = true, anybuff = { "well fed" } },
    { key = "drink",       label = "Alcohol",                               excl = true, auto = true },
    { key = "zanza",       label = "Zanza",                                 excl = true, auto = true },
    { key = "strength",    label = "Strength (Giants / Juju Power)",        excl = true, auto = true },
    { key = "attackpower", label = "Attack Power (Firewater / Juju Might)", excl = true, auto = true },
    { key = "mainhand",    label = "Main Hand",                             excl = true, auto = true, weapon = 16, items = "weapon" },
    { key = "offhand",     label = "Off Hand",                              excl = true, auto = true, weapon = 17, items = "weapon" },
    { key = "elixir",      label = "Elixirs",                               auto = true },
    { key = "blasted",     label = "Blasted Lands",                         excl = true, auto = true },
    { key = "concoction",  label = "Concoctions",                           auto = true },
    { key = "tea",         label = "Tea",                                   excl = true },
    { key = "protection",  label = "Protection Potions" },
    { key = "potion",      label = "Potions & Utility" },
  }

  -- name = English item name (matched exactly, or as the start of the item name),
  -- id = item id when known (Turtle WoW customs are found by name and their id is remembered),
  -- buff = buff names when they differ from the item name, nobuff = nothing to track
  local ITEMS = {
    -- flasks
    { key = "titans",      cat = "flask", name = "Flask of the Titans", id = 13510 },
    { key = "wisdom",      cat = "flask", name = "Flask of Distilled Wisdom", id = 13511, buff = { "distilled wisdom" } },
    { key = "supreme",     cat = "flask", name = "Flask of Supreme Power", id = 13512, buff = { "supreme power" } },
    { key = "chromatic",   cat = "flask", name = "Flask of Chromatic Resistance", id = 13513, buff = { "chromatic resistance" } },
    -- food
    { key = "lefishe",     cat = "food", name = "Le Fishe Au Chocolat" },
    { key = "chimaerok",   cat = "food", name = "Dirge's Kickin' Chimaerok Chops", id = 21023 },
    { key = "herbalsalad", cat = "food", name = "Empowering Herbal Salad" },
    { key = "nightfin",    cat = "food", name = "Nightfin Soup", id = 13931, buff = { "mana regeneration" } },
    { key = "berries",     cat = "food", name = "Sour Mountain Berries" },
    { key = "squideel",    cat = "food", name = "Squid Eel Skewer" },
    { key = "grilledsquid",cat = "food", name = "Grilled Squid", id = 13928 },
    { key = "mushroom",    cat = "food", name = "Power Mushroom" },
    { key = "hardmushroom",cat = "food", name = "Hardened Mushroom", id = 51717 },
    { key = "dumplings",   cat = "food", name = "Smoked Desert Dumplings", id = 20452 },
    { key = "mightfish",   cat = "food", name = "Mightfish Steak" },
    { key = "delight",     cat = "food", name = "Danonzo's Tel'Abim Delight" },
    { key = "surprise",    cat = "food", name = "Danonzo's Tel'Abim Surprise" },
    { key = "runntum",     cat = "food", name = "Runn Tum Tuber Surprise", id = 18254 },
    -- alcohol
    { key = "rumsey",      cat = "drink", name = "Rumsey Rum Black Label", id = 21151 },
    { key = "merlot",      cat = "drink", name = "Medivh's Merlot" },
    { key = "merlotblue",  cat = "drink", name = "Medivh's Merlot Blue" },
    -- zanza
    { key = "spiritzanza", cat = "zanza", name = "Spirit of Zanza", id = 20079 },
    { key = "swiftzanza",  cat = "zanza", name = "Swiftness of Zanza", id = 20081 },
    { key = "sheenzanza",  cat = "zanza", name = "Sheen of Zanza", id = 20080 },
    -- strength
    { key = "giants",      cat = "strength", name = "Elixir of Giants", id = 9206, buff = { "elixir of the giants" } },
    { key = "jujupower",   cat = "strength", name = "Juju Power", id = 12451 },
    -- attack power
    { key = "firewater",   cat = "attackpower", name = "Winterfall Firewater", id = 12820 },
    { key = "jujumight",   cat = "attackpower", name = "Juju Might", id = 12460 },
    -- weapon (main hand / off hand share this list)
    { key = "wizardoil",   cat = "weapon", name = "Brilliant Wizard Oil", id = 20749 },
    { key = "manaoil",     cat = "weapon", name = "Brilliant Mana Oil", id = 20748 },
    { key = "elemstone",   cat = "weapon", name = "Elemental Sharpening Stone", id = 18262 },
    { key = "consstone",   cat = "weapon", name = "Consecrated Sharpening Stone", id = 23122 },
    { key = "blessedoil",  cat = "weapon", name = "Blessed Wizard Oil", id = 23123 },
    { key = "frostoil",    cat = "weapon", name = "Frost Oil", id = 3829 },
    { key = "shadowoil",   cat = "weapon", name = "Shadow Oil", id = 3824 },
    { key = "densestone",  cat = "weapon", name = "Dense Sharpening Stone", id = 12404 },
    { key = "denseweight", cat = "weapon", name = "Dense Weightstone", id = 12643 },
    -- elixirs
    { key = "mongoose",    cat = "elixir", name = "Elixir of the Mongoose", id = 13452 },
    { key = "gae",         cat = "elixir", name = "Greater Arcane Elixir", id = 13454 },
    { key = "superdef",    cat = "elixir", name = "Elixir of Superior Defense", id = 13445, buff = { "greater armor" } },
    { key = "mageblood",   cat = "elixir", name = "Mageblood Potion", id = 20007, buff = { "mana regeneration" } },
    { key = "dreamshard",  cat = "elixir", name = "Dreamshard Elixir" },
    { key = "dreamtonic",  cat = "elixir", name = "Dreamtonic" },
    { key = "firepower",   cat = "elixir", name = "Elixir of Greater Firepower", id = 21546, buff = { "greater firepower" } },
    { key = "naturepower", cat = "elixir", name = "Elixir of Greater Nature Power" },
    { key = "shadowpower", cat = "elixir", name = "Elixir of Shadow Power", id = 9264, buff = { "shadow power" } },
    { key = "frostpower",  cat = "elixir", name = "Elixir of Frost Power", id = 17708, buff = { "frost power" } },
    { key = "fortitude",   cat = "elixir", name = "Elixir of Fortitude", id = 3825, buff = { "health ii" } },
    { key = "trollsblood", cat = "elixir", name = "Major Troll's Blood Potion", id = 20004, buff = { "regeneration" } },
    { key = "demonslaying",cat = "elixir", name = "Elixir of Demonslaying", id = 9224 },
    -- blasted lands
    { key = "scorpok",     cat = "blasted", name = "Ground Scorpok Assay", id = 8412, buff = { "strike of the scorpok" } },
    { key = "roids",       cat = "blasted", name = "R.O.I.D.S.", id = 8410, buff = { "rage of ages" } },
    { key = "cortex",      cat = "blasted", name = "Cerebral Cortex Compound", id = 8423, buff = { "infallible mind" } },
    { key = "lungjuice",   cat = "blasted", name = "Lung Juice Cocktail", id = 8411, buff = { "spirit of boar" } },
    { key = "gizzard",     cat = "blasted", name = "Gizzard Gum", id = 8424, buff = { "spiritual domination" } },
    -- concoctions (Turtle WoW, each one is two elixirs in one)
    { key = "emeraldmongoose", cat = "concoction", name = "Concoction of the Emerald Mongoose" },
    { key = "dreamwater",  cat = "concoction", name = "Concoction of the Dreamwater" },
    { key = "arcanegiant", cat = "concoction", name = "Concoction of the Arcane Giant" },
    -- tea (instant, one or the other)
    { key = "nordanaar",   cat = "tea", name = "Nordanaar Herbal Tea", nobuff = true },
    { key = "sugartea",    cat = "tea", name = "Tea With Sugar", nobuff = true },
    -- protection potions
    { key = "gfpp",        cat = "protection", name = "Greater Fire Protection Potion", id = 13457, buff = { "fire protection" } },
    { key = "gfrpp",       cat = "protection", name = "Greater Frost Protection Potion", id = 13456, buff = { "frost protection" } },
    { key = "gnpp",        cat = "protection", name = "Greater Nature Protection Potion", id = 13458, buff = { "nature protection" } },
    { key = "gspp",        cat = "protection", name = "Greater Shadow Protection Potion", id = 13459, buff = { "shadow protection" } },
    { key = "gapp",        cat = "protection", name = "Greater Arcane Protection Potion", id = 13461, buff = { "arcane protection" } },
    { key = "ghpp",        cat = "protection", name = "Greater Holy Protection Potion", id = 13460, buff = { "holy protection" } },
    { key = "magicres",    cat = "protection", name = "Magic Resistance Potion", id = 9036, buff = { "resistance" } },
    -- potions & utility
    { key = "stoneshield", cat = "potion", name = "Greater Stoneshield Potion", id = 13455, buff = { "greater stoneshield" } },
    { key = "freeaction",  cat = "potion", name = "Free Action Potion", id = 5634, buff = { "free action" } },
    { key = "lip",         cat = "potion", name = "Limited Invulnerability Potion", id = 3387, buff = { "invulnerability" } },
    { key = "quickness",   cat = "potion", name = "Potion of Quickness" },
    { key = "restorative", cat = "potion", name = "Restorative Potion", id = 9030, buff = { "restoration" } },
    { key = "majorheal",   cat = "potion", name = "Major Healing Potion", id = 13446, nobuff = true },
    { key = "majormana",   cat = "potion", name = "Major Mana Potion", id = 13444, nobuff = true },
    { key = "rejuv",       cat = "potion", name = "Major Rejuvenation Potion", id = 18253, nobuff = true },
    { key = "demonicrune", cat = "potion", name = "Demonic Rune", id = 12662, nobuff = true },
    { key = "darkrune",    cat = "potion", name = "Dark Rune", id = 20520, nobuff = true },
    { key = "swiftness",   cat = "potion", name = "Swiftness Potion", id = 2459, nobuff = true },
    { key = "antivenom",   cat = "potion", name = "Powerful Anti-Venom", id = 19440, nobuff = true },
    { key = "jungleremedy",cat = "potion", name = "Jungle Remedy", id = 2633, nobuff = true },
    { key = "holywater",   cat = "potion", name = "Stratholme Holy Water", id = 13180, nobuff = true },
    { key = "bandage",     cat = "potion", name = "Heavy Runecloth Bandage", id = 14530, nobuff = true },
    { key = "frozenrune",  cat = "potion", name = "Frozen Rune", id = 22682, nobuff = true },
  }

  local NONE = "none"
  local NONE_ICON = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"   -- red cross
  local NONE_TEXT = "|T" .. NONE_ICON .. "|t |cffff5555" .. T["None"] .. "|r"   -- no ":" (dropdown splits on it)
  local UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
  local PREFIX = "|cff33ffccpf|rConsumeManager: "
  local COLOR_UP = { .2, 1, .4 }
  local COLOR_LOW = { 1, .75, .1 }

  local catByKey, itemByKey, itemsOf = {}, {}, {}
  for _, cat in ipairs(CATS) do catByKey[cat.key] = cat end
  for _, item in ipairs(ITEMS) do
    itemByKey[item.key] = item
    itemsOf[item.cat] = itemsOf[item.cat] or {}
    table.insert(itemsOf[item.cat], item)
  end
  local function CatItems(cat) return itemsOf[cat.items or cat.key] or {} end

  -- [[ default configuration ]] --
  local defaults = {
    enable    = "1",
    hidecombat = "1",         -- hide the buff bar in combat
    showwhen  = "always",     -- always / group / raid / instance
    -- potion bar (Potions & Utility)
    pot_enable    = "1",
    pot_showwhen  = "always", -- always / combat
    pot_size      = "30",
    pot_spacing   = "2",
    pot_perrow    = "12",
    pot_rows      = "0",
    pot_direction = "HORIZONTAL",
    pot_flyout    = "TOP",
    pot_showbg    = "1",
    hideup    = "0",          -- hide buttons whose buff is up (persistent buffs only)
    hidemissing = "0",        -- hide buttons of consumables you don't carry
    glow      = "1",          -- buff-bar buttons glow while their buff is missing
    refresh   = "2",          -- minutes: a buff with less left counts as missing (0 = only when gone)
    count     = "1",
    timer     = "1",
    size      = "30",
    spacing   = "2",
    perrow    = "12",         -- buttons per line
    rows      = "0",          -- number of lines (0 = use buttons per line)
    direction = "HORIZONTAL",
    flyout    = "TOP",
    hover     = "1",
    showbg    = "1",
  }
  for _, cat in ipairs(CATS) do
    if cat.excl then
      defaults["sel_" .. cat.key] = NONE
      defaults["show_" .. cat.key] = (cat.key == "offhand" or cat.key == "tea") and "0" or "1"
    else
      for _, item in ipairs(CatItems(cat)) do defaults["use_" .. item.key] = "0" end
    end
  end
  for key, value in pairs(defaults) do
    pfUI:UpdateConfig("consumemanager", nil, key, value)
  end

  local cfg = C.consumemanager

  -- learned data (all characters): item ids found by name, buffs learned on use
  pfConsumeManagerDB = pfConsumeManagerDB or {}
  local function DB()
    pfConsumeManagerDB.ids = pfConsumeManagerDB.ids or {}
    pfConsumeManagerDB.learned = pfConsumeManagerDB.learned or {}
    return pfConsumeManagerDB
  end

  -- 1.4.1: the potion bar is shown out of combat too (1.4.0 saved "combat" as its default)
  if not DB().potalways then
    DB().potalways = true
    cfg.pot_showwhen = "always"
  end

  local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
  end

  local HAS_NAMPOWER = GetPlayerAuraDuration and GetSpellRecField and GetItemStatsField and true

  local function Norm(s)
    local n = string.gsub(string.lower(s or ""), "[^%w]", "")
    return n
  end
  local normOf = {}
  for _, item in ipairs(ITEMS) do normOf[item] = Norm(item.name) end

  local function ItemId(item)
    return item.id or DB().ids[item.key]
  end

  -- [[ bag scan ]] --
  -- item -> { count, bag, slot, icon }
  local bags = {}
  local matchCache = {}   -- item id -> item def or false

  local function MatchItem(id, name)
    if id and matchCache[id] ~= nil then return matchCache[id] end
    local found
    for _, item in ipairs(ITEMS) do
      if item.id and item.id == id then found = item break end
    end
    if not found and name then
      local n, best, bestlen = Norm(name), nil, 0
      for _, item in ipairs(ITEMS) do
        local d = normOf[item]
        if d == n then best = item break end
        local len = string.len(d)
        if not item.id and len > bestlen and string.sub(n, 1, len) == d then best, bestlen = item, len end
      end
      found = best
    end
    if id then matchCache[id] = found or false end
    return found
  end

  local function ScanBags()
    bags = {}
    for bag = 0, 4 do
      for slot = 1, GetContainerNumSlots(bag) or 0 do
        local link = GetContainerItemLink(bag, slot)
        if link then
          local _, _, id = string.find(link, "item:(%d+)")
          local _, _, name = string.find(link, "%[(.+)%]")
          id = tonumber(id)
          local item = MatchItem(id, name)
          if item then
            local icon, count = GetContainerItemInfo(bag, slot)
            local b = bags[item]
            if not b then
              b = { count = 0, bag = bag, slot = slot, icon = icon }
              bags[item] = b
            end
            b.count = b.count + (count or 1)
            if id and not item.id then DB().ids[item.key] = id end
          end
        end
      end
    end
  end

  local function FindSlot(item)
    for bag = 0, 4 do
      for slot = 1, GetContainerNumSlots(bag) or 0 do
        local link = GetContainerItemLink(bag, slot)
        if link then
          local _, _, id = string.find(link, "item:(%d+)")
          local _, _, name = string.find(link, "%[(.+)%]")
          if MatchItem(tonumber(id), name) == item then return bag, slot end
        end
      end
    end
  end

  local iconCache = {}
  local function Icon(item)
    if bags[item] and bags[item].icon then return bags[item].icon end
    if iconCache[item] then return iconCache[item] end
    local id = ItemId(item)
    if id then
      local tex = ({ GetItemInfo(id) })[9]
      if not tex and GetItemStatsField and GetItemIconTexture then
        local ok, display = pcall(GetItemStatsField, id, "displayInfoID")
        if ok and display then tex = GetItemIconTexture(display) end
      end
      if tex then iconCache[item] = tex return tex end
    end
    return UNKNOWN_ICON
  end

  local function Count(item)
    return bags[item] and bags[item].count or 0
  end

  -- [[ buffs ]] --
  -- spell ids of an item's use effect and of the spells those trigger (nampower)
  local spellCache = {}
  local function ItemSpells(item)
    if spellCache[item] then return spellCache[item] end
    local list = {}
    local id = ItemId(item)
    if HAS_NAMPOWER and id then
      local ok, spells = pcall(GetItemStatsField, id, "spellID")
      if ok and type(spells) == "table" then
        for _, sid in pairs(spells) do
          if type(sid) == "number" and sid > 0 then
            list[sid] = true
            local okT, trig = pcall(GetSpellRecField, sid, "effectTriggerSpell")
            if okT and type(trig) == "table" then
              for _, t in pairs(trig) do
                if type(t) == "number" and t > 0 then list[t] = true end
              end
            end
          end
        end
      elseif not ok or spells == nil then
        return list   -- item not loaded yet: don't cache
      end
    end
    spellCache[item] = list
    return list
  end

  local scan = CreateFrame("GameTooltip", "pfConsumeManagerScan", nil, "GameTooltipTemplate")
  scan:SetOwner(WorldFrame, "ANCHOR_NONE")

  local spellNames = {}
  local function SpellName(sid)
    if spellNames[sid] == nil then
      local ok, name = pcall(GetSpellRecField, sid, "name")
      spellNames[sid] = (ok and name and string.lower(name)) or false
    end
    return spellNames[sid]
  end

  -- buffs = { ids = { [spellId] = expiry }, names = { [name] = expiry }, keys = { [key] = true } }
  -- expiry = GetTime() at which it runs out, 0 = no duration
  local buffs = { ids = {}, names = {}, keys = {} }
  local buffsDirty = true

  local function ReadBuffs()
    local now = GetTime()
    local b = { ids = {}, names = {}, keys = {} }
    if HAS_NAMPOWER then
      for slot = 0, 31 do
        local sid, remain = GetPlayerAuraDuration(slot)
        if sid and sid > 0 then
          local exp = (remain and remain > 0) and (now + remain / 1000) or 0
          b.ids[sid] = exp
          b.keys["id:" .. sid] = true
          local name = SpellName(sid)
          if name then b.names[name] = exp end
        end
      end
    else
      for i = 0, 31 do
        local idx = GetPlayerBuff(i, "HELPFUL")
        if not idx or idx < 0 then break end
        local left = GetPlayerBuffTimeLeft(idx) or 0
        local exp = left > 0 and (now + left) or 0
        scan:ClearLines()
        scan:SetPlayerBuff(idx)
        local name = pfConsumeManagerScanTextLeft1 and pfConsumeManagerScanTextLeft1:GetText()
        if name then
          name = string.lower(name)
          b.names[name] = exp
          b.keys["n:" .. name] = true
        end
      end
    end
    return b
  end

  -- [[ learning: the first new buff after using an item from the bar ]] --
  local pending

  local function StartLearning(item)
    if item.nobuff or item.cat == "weapon" then return end
    pending = { item = item, snap = buffs.keys, deadline = GetTime() + (item.cat == "food" and 30 or 10) }
  end

  local function CheckLearning()
    if not pending then return end
    if GetTime() > pending.deadline then pending = nil return end
    local item, own, new = pending.item, ItemSpells(pending.item), nil
    for key in pairs(buffs.keys) do
      if not pending.snap[key] then
        local _, _, sid = string.find(key, "^id:(%d+)$")
        if sid and own[tonumber(sid)] and item.cat ~= "food" then
          pending = nil   -- already detected through the item's own spell
          return
        end
        if not (sid and own[tonumber(sid)]) then new = key end
      end
    end
    if new then
      DB().learned[item.key] = new
      pending = nil
    end
  end

  local function UpdateBuffs(force)
    if not buffsDirty and not force then return end
    buffsDirty = false
    buffs = ReadBuffs()
    CheckLearning()
  end

  local function Expiry(exp, now)
    if exp == 0 then return 0 end
    return math.max(exp - now, .01)
  end

  -- returns nil (no buff to track), false (missing) or the seconds left (0 = no duration)
  local function BuffLeft(item, cat)
    local now = GetTime()
    if cat and cat.weapon then
      local hasMH, mhExp, _, hasOH, ohExp = GetWeaponEnchantInfo()
      if cat.weapon == 16 then
        return hasMH and ((mhExp or 0) / 1000) or false
      end
      return hasOH and ((ohExp or 0) / 1000) or false
    end
    if item.nobuff then return nil end
    UpdateBuffs()

    local spells = ItemSpells(item)
    for sid in pairs(spells) do
      if buffs.ids[sid] then return Expiry(buffs.ids[sid], now) end
    end
    local learned = DB().learned[item.key]
    if learned then
      local _, _, sid = string.find(learned, "^id:(%d+)$")
      local _, _, name = string.find(learned, "^n:(.+)$")
      if sid and buffs.ids[tonumber(sid)] then return Expiry(buffs.ids[tonumber(sid)], now) end
      if name and buffs.names[name] then return Expiry(buffs.names[name], now) end
    end
    -- names: only when the item's spells are unknown (no nampower / Turtle item not loaded),
    -- since two items can share a buff name (Mageblood and Nightfin Soup: "Mana Regeneration")
    if not next(spells) then
      if item.buff then
        for _, name in pairs(item.buff) do
          if buffs.names[name] then return Expiry(buffs.names[name], now) end
        end
      end
      local own = string.lower(item.name)
      if buffs.names[own] then return Expiry(buffs.names[own], now) end
    end
    if cat and cat.anybuff then
      for _, name in pairs(cat.anybuff) do
        if buffs.names[name] then return Expiry(buffs.names[name], now) end
      end
    end
    return false
  end

  -- true when the buff is up and not about to run out
  local function IsFresh(left)
    if not left then return false end
    if left == 0 then return true end
    local refresh = (tonumber(cfg.refresh) or 0) * 60
    return left > refresh
  end

  -- [[ using items ]] --
  local function Use(item, cat)
    if not item then return false end
    local bag, slot = FindSlot(item)
    if not bag then
      Print("no " .. item.name .. " in your bags.")
      return false
    end
    local start, duration = GetContainerItemCooldown(bag, slot)
    if start and start > 0 and duration and duration > 1.5 then return false end
    if CursorHasItem and CursorHasItem() then return false end

    if item.cat == "weapon" then
      local target = (cat and cat.weapon) or 16
      if not GetInventoryItemLink("player", target) then
        Print("no weapon in that slot.")
        return false
      end
      UseContainerItem(bag, slot)
      if SpellIsTargeting() then
        PickupInventoryItem(target)
        -- confirm replacing the current temporary enchant
        if StaticPopup_Visible and StaticPopup_Visible("REPLACE_ENCHANT") then
          ReplaceEnchant()
          StaticPopup_Hide("REPLACE_ENCHANT")
        end
        if SpellIsTargeting() then SpellStopTargeting() end
      end
    else
      UpdateBuffs(true)
      StartLearning(item)
      UseContainerItem(bag, slot)
    end
    return true
  end

  -- [[ selection ]] --
  local function Selected(cat)
    local key = cfg["sel_" .. cat.key]
    if not key or key == NONE then return nil end
    local item = itemByKey[key]
    if item and item.cat == (cat.items or cat.key) then return item end
  end

  local function Enabled(item)
    return cfg["use_" .. item.key] == "1"
  end

  -- the potion bar holds this category, the buff bar everything else
  local POTION_CAT = "potion"

  -- every button a bar should have, in order: { cat, item }
  -- potion = true: potion bar, false: buff bar, nil: both
  local function Wanted(potion)
    local list = {}
    for _, cat in ipairs(CATS) do
      if potion ~= nil and (cat.key == POTION_CAT) ~= potion then
        -- other bar
      elseif cat.excl then
        -- a group button is there even without a default: its list is where you pick one
        if cfg["show_" .. cat.key] == "1" then
          table.insert(list, { cat = cat, item = Selected(cat), group = true })
        end
      else
        for _, item in ipairs(CatItems(cat)) do
          if Enabled(item) then table.insert(list, { cat = cat, item = item }) end
        end
      end
    end
    return list
  end

  -- how many items of the group you carry
  local function GroupCount(cat)
    local n = 0
    for _, item in ipairs(CatItems(cat)) do n = n + Count(item) end
    return n
  end

  -- group buttons are never hidden by "hide while up": their list is the way to change the default
  local function Hidden(entry)
    if entry.group then
      -- no default and none carried: nothing to show (pick one in the config dropdown)
      if not entry.item and GroupCount(entry.cat) == 0 then return true end
      return cfg.hidemissing == "1" and GroupCount(entry.cat) == 0
    end
    if cfg.hidemissing == "1" and Count(entry.item) == 0 then return true end
    if cfg.hideup == "1" and entry.cat.auto and IsFresh(BuffLeft(entry.item, entry.cat)) then return true end
    return false
  end

  -- bar button icon: the default, or (no default) the first item of the group you carry
  local function EntryIcon(entry)
    if entry.item then return Icon(entry.item) end
    for _, item in ipairs(CatItems(entry.cat)) do
      if Count(item) > 0 then return Icon(item) end
    end
    return UNKNOWN_ICON
  end

  local function UseNextMissing()
    for _, entry in ipairs(Wanted(false)) do
      local item, cat = entry.item, entry.cat
      if item and cat.auto and Count(item) > 0 then
        local left = BuffLeft(item, cat)
        if left ~= nil and not IsFresh(left) then
          if Use(item, cat) then return true, item.name end
        end
      end
    end
    return false
  end

  local function InCombat()
    return UnitAffectingCombat("player") and true or false
  end

  -- pfUI unlock mode: keep every bar visible so it can be moved
  local function Unlocked()
    return pfUI.unlock and pfUI.unlock:IsShown() and true or false
  end

  local function ShouldShow(self)
    if Unlocked() then return true end
    if self and self.potion then
      if cfg.pot_enable ~= "1" then return false end
      return cfg.pot_showwhen == "always" or InCombat()
    end
    if cfg.enable ~= "1" then return false end
    if cfg.hidecombat == "1" and InCombat() then return false end
    local when = cfg.showwhen
    if when == "raid" then return GetNumRaidMembers() > 0 end
    if when == "group" then return (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) end
    if when == "instance" then
      if IsInInstance then
        local inside = IsInInstance()
        return inside and true or false
      end
      return GetNumRaidMembers() > 0
    end
    return true
  end

  -- [[ the bars ]] --
  -- prefix: config key prefix of the bar's layout options
  local bars = {}
  local function NewBar(name, potion, prefix)
    local f = CreateFrame("Frame", name, UIParent)
    f.buttons, f.potion, f.prefix = {}, potion, prefix
    table.insert(bars, f)
    return f
  end
  local bar = NewBar("pfConsumeManager", false, "")
  local potbar = NewBar("pfConsumeManagerPotions", true, "pot_")

  local function RefreshAll()
    for _, f in ipairs(bars) do f:UpdateConfig() end
  end

  local function Opt(self, key)
    return cfg[self.prefix .. key]
  end

  local function DefaultBorder(button)
    button:SetBackdropBorderColor(GetStringColor(pfUI_config.appearance.border.color))
  end

  local function FormatTime(remain)
    if remain >= 3600 then return math.floor(remain / 3600 + .5) .. "h" end
    if remain >= 60 then return math.ceil(remain / 60) .. "m" end
    return math.floor(remain + .5)
  end

  local function ShowTooltip(button, item, cat, main)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if not item and main then
      GameTooltip:SetText(cat.label, 1, .82, 0)
      GameTooltip:AddLine("No default chosen.", 1, 1, 1)
      GameTooltip:AddLine("Hover the button and right-click one in the list.", .7, .7, .7)
      GameTooltip:AddDoubleLine("Left / right-click", "Pin the list", 1, 1, 1, .2, 1, .8)
      GameTooltip:Show()
      return
    end
    if not item then
      GameTooltip:SetText(T["None"], 1, .33, .33)
      GameTooltip:AddLine("Right-click: hide the " .. cat.label .. " button", 1, 1, 1)
      GameTooltip:Show()
      return
    end
    local b = bags[item]
    if b then
      GameTooltip:SetBagItem(b.bag, b.slot)
    elseif ItemId(item) then
      GameTooltip:SetHyperlink("item:" .. ItemId(item) .. ":0:0:0")
    else
      GameTooltip:SetText(item.name, 1, 1, 1)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("In bags", Count(item), 1, 1, 1, 1, 1, 1)
    local left = BuffLeft(item, cat)
    if left == false then
      GameTooltip:AddDoubleLine("Buff", "missing", 1, 1, 1, 1, .3, .3)
    elseif left then
      GameTooltip:AddDoubleLine("Buff", left > 0 and ("up, " .. FormatTime(left) .. " left") or "up", 1, 1, 1, .2, 1, .4)
    end
    if main and cat.excl then
      GameTooltip:AddDoubleLine("Left-click", "Use", 1, 1, 1, .2, 1, .8)
      GameTooltip:AddDoubleLine("Right-click", "Pin the " .. cat.label .. " list", 1, 1, 1, .2, 1, .8)
    elseif main then
      GameTooltip:AddDoubleLine("Left-click", "Use", 1, 1, 1, .2, 1, .8)
    else
      GameTooltip:AddDoubleLine("Left-click", "Use", 1, 1, 1, .2, 1, .8)
      GameTooltip:AddDoubleLine("Right-click", "Set as default " .. cat.label, 1, 1, 1, .2, 1, .8)
    end
    GameTooltip:Show()
  end

  local function CreateButton(name, parent)
    local b = CreateFrame("Button", name, parent)
    b:SetWidth(30)
    b:SetHeight(30)
    CreateBackdrop(b, nil, true)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetTexCoord(.08, .92, .08, .92)
    SetAllPointsOffset(b.icon, b, 2)

    b.hl = b:CreateTexture(nil, "OVERLAY")
    b.hl:SetAllPoints(b.icon)
    b.hl:SetTexture(1, 1, 1, .2)
    b.hl:Hide()

    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    return b
  end

  local function SetSelected(cat, key)
    cfg["sel_" .. cat.key] = key
    RefreshAll()
  end

  -- flyout buttons
  local function FlyOnClick()
    local cat = this.cat
    if this.none then
      if arg1 == "RightButton" then SetSelected(cat, NONE) end
      return
    end
    if arg1 == "RightButton" then
      SetSelected(cat, this.item.key)
      if this:IsVisible() then ShowTooltip(this, this.item, cat) end
    else
      Use(this.item, cat)
    end
  end

  local function FlyOnEnter()
    this.hl:Show()
    ShowTooltip(this, (not this.none) and this.item or nil, this.cat)
  end

  local function FlyOnLeave()
    this.hl:Hide()
    GameTooltip:Hide()
  end

  local function FlyoutOnUpdate()
    if this.pinned then return end
    if MouseIsOver(this) or MouseIsOver(this.owner) then
      this.leave = nil
    else
      this.leave = this.leave or GetTime()
      if GetTime() - this.leave > .3 then this:Hide() end
    end
  end

  -- bar buttons
  local function MainOnClick()
    local entry = this.entry
    if not entry then return end
    if arg1 == "RightButton" or (entry.group and not entry.item) then
      if entry.group then
        local fly = this.fly
        if fly:IsShown() and fly.pinned then
          fly.pinned = nil
          fly:Hide()
        else
          this:GetParent():BuildFlyout(this)
          fly.pinned = true
          fly.leave = nil
          fly:Show()
        end
      end
    else
      Use(entry.item, entry.cat)
    end
  end

  local function MainOnEnter()
    this.hl:Show()
    local entry = this.entry
    if not entry then return end
    if entry.group and cfg.hover == "1" then
      this:GetParent():BuildFlyout(this)
      this.fly.leave = nil
      this.fly:Show()
    end
    ShowTooltip(this, entry.item, entry.cat, true)
  end

  local function MainOnLeave()
    this.hl:Hide()
    GameTooltip:Hide()
  end

  local function GetBarButton(owner, i)
    local b = owner.buttons[i]
    if b then return b end
    local name = owner:GetName() .. "Button" .. i
    b = CreateButton(name, owner)

    b.cdbg = CreateFrame("Frame", nil, b)
    b.cdbg:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.cd = CreateFrame(COOLDOWN_FRAME_TYPE or "Model", name .. "Cooldown", b.cdbg, "CooldownFrameTemplate")
    b.cd.pfCooldownType = "ALL"

    b.textframe = CreateFrame("Frame", nil, b)
    b.textframe:SetAllPoints(b)
    b.textframe:SetFrameLevel(b:GetFrameLevel() + 4)
    b.timer = b.textframe:CreateFontString(nil, "OVERLAY")
    b.timer:SetFont(pfUI.font_default, C.global.font_size, "OUTLINE")
    b.timer:SetPoint("TOP", b, "TOP", 0, -3)
    b.count = b.textframe:CreateFontString(nil, "OVERLAY")
    b.count:SetFont(pfUI.font_default, C.global.font_size, "OUTLINE")
    b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 3)
    b.count:SetJustifyH("RIGHT")

    -- pulsing glow (group buttons whose default buff is missing)
    b.glow = CreateFrame("Frame", nil, b)
    b.glow:SetFrameLevel(b:GetFrameLevel() + 6)
    b.glow:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.glow.tex = b.glow:CreateTexture(nil, "OVERLAY")
    b.glow.tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    b.glow.tex:SetBlendMode("ADD")
    b.glow.tex:SetVertexColor(1, .82, .1)
    b.glow.tex:SetAllPoints(b.glow)
    b.glow:SetScript("OnUpdate", function()
      this.tex:SetAlpha(.55 + .45 * math.sin(GetTime() * 6))
    end)
    b.glow:Hide()

    b:SetScript("OnClick", MainOnClick)
    b:SetScript("OnEnter", MainOnEnter)
    b:SetScript("OnLeave", MainOnLeave)

    b.fly = CreateFrame("Frame", nil, b)
    b.fly.owner = b
    b.fly.buttons = {}
    b.fly:SetFrameStrata("DIALOG")
    b.fly:SetScript("OnUpdate", FlyoutOnUpdate)
    b.fly:Hide()

    owner.buttons[i] = b
    return b
  end

  local function BuildFlyout(self, b)
    local cat = b.entry.cat
    local fly = b.fly
    local chosen = Selected(cat)
    local list = {}
    -- items you carry first, then the others
    for _, item in ipairs(CatItems(cat)) do if Count(item) > 0 then table.insert(list, item) end end
    for _, item in ipairs(CatItems(cat)) do if Count(item) == 0 then table.insert(list, item) end end
    table.insert(list, NONE)

    local size, spacing, dir = self.size, self.spacing, Opt(self, "flyout")
    local count = table.getn(list)
    local step = size + spacing

    for i = 1, count do
      local f = fly.buttons[i]
      if not f then
        f = CreateButton(nil, fly)
        f:SetScript("OnClick", FlyOnClick)
        f:SetScript("OnEnter", FlyOnEnter)
        f:SetScript("OnLeave", FlyOnLeave)
        f.count = f:CreateFontString(nil, "OVERLAY")
        f.count:SetFont(pfUI.font_default, C.global.font_size, "OUTLINE")
        f.count:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 3)
        fly.buttons[i] = f
      end

      local isNone = list[i] == NONE
      f.cat = cat
      f.item = (not isNone) and list[i] or nil
      f.none = isNone
      f:SetWidth(size)
      f:SetHeight(size)
      f:ClearAllPoints()
      if dir == "BOTTOM" then
        f:SetPoint("TOP", fly, "TOP", 0, -(i - 1) * step)
      elseif dir == "LEFT" then
        f:SetPoint("RIGHT", fly, "RIGHT", -(i - 1) * step, 0)
      elseif dir == "RIGHT" then
        f:SetPoint("LEFT", fly, "LEFT", (i - 1) * step, 0)
      else
        f:SetPoint("BOTTOM", fly, "BOTTOM", 0, (i - 1) * step)
      end

      if isNone then
        f.icon:SetTexture(NONE_ICON)
        f.icon:SetVertexColor(1, 1, 1)
        f.count:SetText("")
      else
        local n = Count(list[i])
        f.icon:SetTexture(Icon(list[i]))
        if n > 0 then f.icon:SetVertexColor(1, 1, 1) else f.icon:SetVertexColor(.35, .35, .35) end
        f.count:SetText(n > 0 and n or "|cffff33330")
      end
      if (not isNone and list[i] == chosen) then
        f:SetBackdropBorderColor(COLOR_UP[1], COLOR_UP[2], COLOR_UP[3], 1)
      else
        DefaultBorder(f)
      end
      f:Show()
    end

    for i = count + 1, table.getn(fly.buttons) do
      fly.buttons[i]:Hide()
    end

    local length = math.max(count * size + (count - 1) * spacing, 1)
    fly:ClearAllPoints()
    if dir == "BOTTOM" then
      fly:SetPoint("TOP", b, "BOTTOM", 0, -spacing)
      fly:SetWidth(size) fly:SetHeight(length)
    elseif dir == "LEFT" then
      fly:SetPoint("RIGHT", b, "LEFT", -spacing, 0)
      fly:SetWidth(length) fly:SetHeight(size)
    elseif dir == "RIGHT" then
      fly:SetPoint("LEFT", b, "RIGHT", spacing, 0)
      fly:SetWidth(length) fly:SetHeight(size)
    else
      fly:SetPoint("BOTTOM", b, "TOP", 0, spacing)
      fly:SetWidth(size) fly:SetHeight(length)
    end
  end

  -- which buttons are visible: rebuilt only when this changes
  local function LayoutSig(self, list)
    local sig = ShouldShow(self) and "1" or "0"
    for _, entry in ipairs(list) do
      if not Hidden(entry) then sig = sig .. entry.cat.key .. ":" .. (entry.item and entry.item.key or NONE) .. "," end
    end
    return sig
  end

  local function UpdateConfig(self)
    local list = Wanted(self.potion)
    local visible = ShouldShow(self)
    self.sig = LayoutSig(self, list)

    local size = tonumber(Opt(self, "size")) or 30
    local spacing = tonumber(Opt(self, "spacing")) or 2
    local horizontal = Opt(self, "direction") ~= "VERTICAL"
    self.size, self.spacing = size, spacing

    -- buttons per line: from "Rows" when set, else "Buttons Per Row"
    local total = 0
    if visible then
      for _, entry in ipairs(list) do
        if not Hidden(entry) then total = total + 1 end
      end
    end
    local perrow = math.max(tonumber(Opt(self, "perrow")) or 12, 1)
    local rows = tonumber(Opt(self, "rows")) or 0
    if rows > 0 then perrow = math.max(math.ceil(total / math.floor(rows)), 1) end

    local shown = 0
    if visible then
      for _, entry in ipairs(list) do
        if not Hidden(entry) then
          shown = shown + 1
          local b = GetBarButton(self, shown)
          b.entry = entry
          b:SetWidth(size)
          b:SetHeight(size)
          b.cdbg:SetWidth(size - 3)
          b.cdbg:SetHeight(size - 3)
          b.icon:SetTexture(EntryIcon(entry))
          b.glow:SetWidth(size * 1.9)
          b.glow:SetHeight(size * 1.9)
          b.tvalue, b.cvalue, b.state, b.lastcount = nil, nil, nil, nil   -- force a redraw on the next tick
          local idx = shown - 1
          local line, col = math.floor(idx / perrow), idx - math.floor(idx / perrow) * perrow
          local x = spacing + (horizontal and col or line) * (size + spacing)
          local y = spacing + (horizontal and line or col) * (size + spacing)
          b:ClearAllPoints()
          b:SetPoint("TOPLEFT", self, "TOPLEFT", x, -y)
          b:Show()
          if b.fly:IsShown() then self:BuildFlyout(b) end
        end
      end
    end
    for i = shown + 1, table.getn(self.buttons) do
      local b = self.buttons[i]
      b.entry = nil
      b.glow:Hide()
      b.fly.pinned = nil
      b.fly:Hide()
      b:Hide()
    end

    if shown == 0 then
      self:SetWidth(size + spacing * 2)
      self:SetHeight(size + spacing * 2)
      if Unlocked() then
        self:SetAlpha(1)   -- empty bar: still shown so it can be moved
        return
      end
      if self.backdrop then self.backdrop:Hide() end
      self:SetAlpha(0)   -- not Hide(): its OnUpdate keeps watching for changes
      return
    end
    self:SetAlpha(1)

    local cols = math.min(shown, perrow)
    local lines = math.ceil(shown / perrow)
    local w = spacing + cols * (size + spacing)
    local h = spacing + lines * (size + spacing)
    self:SetWidth(horizontal and w or h)
    self:SetHeight(horizontal and h or w)

    if Opt(self, "showbg") == "1" then
      CreateBackdrop(self)
      self.backdrop:Show()
    elseif self.backdrop then
      self.backdrop:Hide()
    end
  end

  -- [[ per-button state ]] --
  local function SetText(fs, b, field, text)
    if b[field] ~= text then
      b[field] = text
      fs:SetText(text or "")
    end
  end

  local function UpdateButton(b)
    local entry = b.entry
    local item, cat = entry.item, entry.cat

    if not item then
      -- group without a default: total of the group, greyed out
      local n = GroupCount(cat)
      SetText(b.count, b, "cvalue", (cfg.count == "1" and (n > 0 and tostring(n) or "|cffff33330")) or nil)
      SetText(b.timer, b, "tvalue", nil)
      if b.state ~= "nodefault" then
        b.state = "nodefault"
        DefaultBorder(b)
        b.icon:SetVertexColor(.4, .4, .4)
        b.glow:Hide()
        CooldownFrame_SetTimer(b.cd, 0, 0, 0)
        b.cdstart, b.cdduration = 0, 0
      end
      return
    end

    local n = Count(item)
    local left = BuffLeft(item, cat)

    -- count
    SetText(b.count, b, "cvalue", (cfg.count == "1" and (n > 0 and tostring(n) or "|cffff33330")) or nil)

    -- state: up / low / missing / none (no buff tracked)
    local state
    if left == nil then state = "none"
    elseif left == false then state = "missing"
    elseif IsFresh(left) then state = "up"
    else state = "low" end

    if b.state ~= state or b.lastcount ~= n then
      b.state, b.lastcount = state, n
      -- glow: buff-bar buttons of buffs you keep up (not the potion bar, not protection potions)
      if cfg.glow == "1" and cat.auto and not b:GetParent().potion
        and (state == "missing" or state == "low") then
        b.glow:Show()
      else
        b.glow:Hide()
      end
      if state == "up" then
        b:SetBackdropBorderColor(COLOR_UP[1], COLOR_UP[2], COLOR_UP[3], 1)
        b.icon:SetVertexColor(1, 1, 1)
      elseif state == "low" then
        b:SetBackdropBorderColor(COLOR_LOW[1], COLOR_LOW[2], COLOR_LOW[3], 1)
        b.icon:SetVertexColor(1, 1, 1)
      else
        DefaultBorder(b)
        if n == 0 then
          b.icon:SetVertexColor(.8, .25, .25)
        elseif state == "missing" then
          b.icon:SetVertexColor(.5, .5, .5)
        else
          b.icon:SetVertexColor(1, 1, 1)
        end
      end
    end

    -- timer
    local t
    if cfg.timer == "1" and left and left > 0 then
      t = (state == "low" and "|cffffbb22" or "|cffffffff") .. FormatTime(left) .. "|r"
    end
    SetText(b.timer, b, "tvalue", t)

    -- cooldown wheel
    local bb = bags[item]
    local start, duration, enable = 0, 0, 0
    if bb then start, duration, enable = GetContainerItemCooldown(bb.bag, bb.slot) end
    if b.cdstart ~= start or b.cdduration ~= duration then
      b.cdstart, b.cdduration = start, duration
      CooldownFrame_SetTimer(b.cd, start or 0, duration or 0, enable or 0)
    end
  end

  local function BarOnUpdate()
    local now = GetTime()
    if (this.tick or 0) > now then return end
    this.tick = now + .2

    if (this.full or 0) <= now then
      this.full = now + 5
      buffsDirty = true   -- safety net for missed aura events
    end
    UpdateBuffs()

    local list = Wanted(this.potion)
    if LayoutSig(this, list) ~= this.sig then
      this:UpdateConfig()
    end
    for _, b in ipairs(this.buttons) do
      if b.entry and b:IsShown() then UpdateButton(b) end
    end
  end

  for _, f in ipairs(bars) do
    f.BuildFlyout = BuildFlyout
    f.UpdateConfig = UpdateConfig
    f:SetScript("OnUpdate", BarOnUpdate)
  end

  -- [[ events ]] --
  local events = CreateFrame("Frame")
  events:RegisterEvent("PLAYER_ENTERING_WORLD")
  events:RegisterEvent("BAG_UPDATE")
  events:RegisterEvent("PLAYER_AURAS_CHANGED")
  events:RegisterEvent("UNIT_INVENTORY_CHANGED")
  events:RegisterEvent("PARTY_MEMBERS_CHANGED")
  events:RegisterEvent("RAID_ROSTER_UPDATE")
  events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  events:RegisterEvent("PLAYER_REGEN_DISABLED")
  events:RegisterEvent("PLAYER_REGEN_ENABLED")
  events:SetScript("OnEvent", function()
    if event == "PLAYER_AURAS_CHANGED" then
      buffsDirty = true
    elseif event == "UNIT_INVENTORY_CHANGED" then
      if arg1 == "player" then buffsDirty = true end
    elseif event == "BAG_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
      this.bagdirty = true
    else
      this.layoutdirty = true
    end
  end)
  events:SetScript("OnUpdate", function()
    if this.bagdirty then
      -- bag events come in bursts: scan once per frame
      this.bagdirty = nil
      ScanBags()
      for _, f in ipairs(bars) do
        for _, b in ipairs(f.buttons) do
          if b.entry and b:IsShown() then
            b.icon:SetTexture(EntryIcon(b.entry))
            b.state = nil
            if b.fly:IsShown() then f:BuildFlyout(b) end
          end
        end
        f.sig = nil
      end
    end
    if this.layoutdirty then
      -- combat / group changes: rebuild right away (the bars' own check runs every 0.2s)
      this.layoutdirty = nil
      for _, f in ipairs(bars) do f:UpdateConfig() end
    end
  end)

  bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 240)
  potbar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 280)
  UpdateMovable(bar, true)
  UpdateMovable(potbar, true)
  ScanBags()
  RefreshAll()

  -- [[ public API ]] --
  local function FindItem(query)
    query = Norm(query)
    if query == "" then return end
    for _, item in ipairs(ITEMS) do
      if item.key == query or normOf[item] == query then return item end
    end
    for _, item in ipairs(ITEMS) do
      if string.find(normOf[item], query, 1, true) then return item end
    end
  end

  local function FindCat(query)
    query = string.lower(query or "")
    if catByKey[query] then return catByKey[query] end
    for _, cat in ipairs(CATS) do
      if string.find(string.lower(cat.label), query, 1, true) then return cat end
    end
  end

  -- group: category key or label, name: item name / key or "none"
  local function SelectInGroup(group, name)
    local cat = FindCat(group)
    if not cat or not cat.excl then return false end
    if string.lower(name or "") == NONE then SetSelected(cat, NONE) return true, cat end
    local item = FindItem(name)
    if not item or item.cat ~= (cat.items or cat.key) then return false end
    SetSelected(cat, item.key)
    return true, cat, item
  end

  _G.pfConsumeManager.UseNext = UseNextMissing
  _G.pfConsumeManager.Use = function(name)
    local item = FindItem(name or "")
    if not item then return false end
    local cat = catByKey[item.cat]
    if item.cat == "weapon" then cat = catByKey.mainhand end
    return Use(item, cat)
  end
  _G.pfConsumeManager.Select = SelectInGroup
  _G.pfConsumeManager.Refresh = RefreshAll

  _G.SLASH_PFCONSUMEMANAGER1 = "/consumemanager"
  _G.SLASH_PFCONSUMEMANAGER2 = "/cm"
  _G.SLASH_PFCONSUMEMANAGER3 = "/consumes"
  _G.SlashCmdList["PFCONSUMEMANAGER"] = function(msg)
    local _, _, cmd, rest = string.find(msg or "", "^%s*(%S*)%s*(.-)%s*$")
    cmd = string.lower(cmd or "")

    if cmd == "next" then
      local ok, name = UseNextMissing()
      if not ok then Print("nothing missing.") end
    elseif cmd == "use" then
      if not _G.pfConsumeManager.Use(rest) then Print("can't use '" .. rest .. "'.") end
    elseif cmd == "set" then
      local _, _, group, name = string.find(rest, "^(%S+)%s+(.+)$")
      local ok, cat, item = SelectInGroup(group, name)
      if ok then
        Print(cat.label .. ": " .. (item and item.name or T["None"]))
      else
        Print("unknown group or item. Example: /cm set flask titans, /cm set mainhand none")
      end
    elseif cmd == "missing" or cmd == "list" then
      local any
      for _, entry in ipairs(Wanted()) do
        local left = entry.item and BuffLeft(entry.item, entry.cat)
        if not entry.item then
          if cmd == "list" then any = true Print(entry.cat.label .. ": no default") end
        elseif cmd == "list" or (entry.cat.auto and left ~= nil and not IsFresh(left)) then
          any = true
          local state = (left == nil and "") or (left == false and " |cffff5555missing")
            or (left > 0 and (" |cff33ff66" .. FormatTime(left))) or " |cff33ff66up"
          Print(entry.cat.label .. ": " .. entry.item.name .. " (" .. Count(entry.item) .. ")" .. state)
        end
      end
      if not any then Print(cmd == "list" and "nothing selected. /pfui -> Thirdparty -> Consume Manager" or "nothing missing.") end
    elseif cmd == "forget" then
      local item = FindItem(rest)
      if item then
        DB().learned[item.key] = nil
        Print("forgot the buff learned for " .. item.name .. ".")
      else
        pfConsumeManagerDB.learned = {}
        Print("forgot every learned buff.")
      end
    elseif cmd == "scan" then
      matchCache, spellCache, iconCache = {}, {}, {}
      ScanBags()
      RefreshAll()
      Print("bags rescanned.")
    else
      Print("commands:")
      DEFAULT_CHAT_FRAME:AddMessage("  /cm next |cffaaaaaa- use the first persistent buff you are missing")
      DEFAULT_CHAT_FRAME:AddMessage("  /cm use <item> |cffaaaaaa- e.g. /cm use mongoose")
      DEFAULT_CHAT_FRAME:AddMessage("  /cm set <group> <item|none> |cffaaaaaa- e.g. /cm set flask titans, /cm set food none")
      DEFAULT_CHAT_FRAME:AddMessage("  /cm missing |cffaaaaaa- list missing buffs")
      DEFAULT_CHAT_FRAME:AddMessage("  /cm list |cffaaaaaa- list the selection")
      DEFAULT_CHAT_FRAME:AddMessage("  /cm forget [item] |cffaaaaaa- forget learned buffs")
      DEFAULT_CHAT_FRAME:AddMessage("  /cm scan |cffaaaaaa- rescan your bags")
      DEFAULT_CHAT_FRAME:AddMessage("  config: /pfui -> Thirdparty -> Consume Manager")
    end
  end

  -- [[ pfUI config GUI ]] --
  if pfUI.gui and pfUI.gui.CreateGUIEntry then
    local positions = {
      "TOP:" .. T["Top"],
      "BOTTOM:" .. T["Bottom"],
      "LEFT:" .. T["Left"],
      "RIGHT:" .. T["Right"],
    }
    local showwhen = {
      "always:Always",
      "group:In A Group",
      "raid:In A Raid",
      "instance:In An Instance",
    }

    local function Values(cat)
      return function()
        local values = {}
        for _, item in ipairs(CatItems(cat)) do
          table.insert(values, item.key .. ":" .. item.name)
        end
        table.insert(values, NONE .. ":" .. NONE_TEXT)
        return values
      end
    end

    local potwhen = {
      "always:Always",
      "combat:In Combat Only",
    }

    local update = function() RefreshAll() end

    pfUI.gui.CreateGUIEntry(T["Thirdparty"], "Consume Manager", function()
      local CreateConfig = pfUI.gui.CreateConfig

      CreateConfig(update, "Enable Consume Manager (Buff Bar)", cfg, "enable", "checkbox")
      CreateConfig(update, "Hide In Combat", cfg, "hidecombat", "checkbox")
      CreateConfig(update, "Show The Bar", cfg, "showwhen", "dropdown", showwhen)

      -- one line per group: name, default dropdown, then a "Show" checkbox after the dropdown
      local header = CreateConfig(nil, "Exclusive (Only One At A Time)", nil, nil, "header")
      if header then
        header.showcap = header:CreateFontString(nil, "OVERLAY", "GameFontWhite")
        header.showcap:SetFont(pfUI.font_default, C.global.font_size)
        header.showcap:SetTextColor(.2, 1, .8, 1)
        header.showcap:SetPoint("BOTTOM", header, "BOTTOMRIGHT", -12, 0)
        header.showcap:SetText("Show")
      end
      for _, cat in ipairs(CATS) do
        if cat.excl then
          local row = CreateConfig(update, cat.label, cfg, "sel_" .. cat.key, "dropdown", Values(cat))
          if row and row.input then
            local showkey = "show_" .. cat.key
            row.input:ClearAllPoints()
            row.input:SetPoint("RIGHT", row, "RIGHT", -26, 0)

            local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            cb:SetNormalTexture("")
            cb:SetPushedTexture("")
            cb:SetHighlightTexture("")
            CreateBackdrop(cb, nil, true)
            cb:SetWidth(14)
            cb:SetHeight(14)
            cb:SetPoint("RIGHT", row, "RIGHT", -5, 1)
            if cfg[showkey] == "1" then cb:SetChecked(1) else cb:SetChecked(nil) end
            cb:SetScript("OnClick", function()
              cfg[showkey] = this:GetChecked() and "1" or "0"
              update()
            end)
            if cb.backdrop_shadow then cb.backdrop_shadow:Hide() end
            row.showbox = cb
          end
        end
      end

      for _, cat in ipairs(CATS) do
        if not cat.excl and cat.key ~= POTION_CAT then
          CreateConfig(nil, cat.label, nil, nil, "header")
          for _, item in ipairs(CatItems(cat)) do
            CreateConfig(update, item.name, cfg, "use_" .. item.key, "checkbox")
          end
        end
      end

      CreateConfig(nil, "Behaviour", nil, nil, "header")
      CreateConfig(update, "Refresh When Less Than X Minutes Left (0 = only when gone)", cfg, "refresh")
      CreateConfig(update, "Glow Buttons When Their Buff Is Missing", cfg, "glow", "checkbox")
      CreateConfig(update, "Hide Stackable Buttons While Their Buff Is Up", cfg, "hideup", "checkbox")
      CreateConfig(update, "Hide Consumables You Don't Carry", cfg, "hidemissing", "checkbox")

      CreateConfig(nil, T["Layout"], nil, nil, "header")
      CreateConfig(update, T["Button Size"], cfg, "size")
      CreateConfig(update, T["Spacing"], cfg, "spacing", "dropdown", pfUI.gui.dropdowns.spacing)
      CreateConfig(update, "Buttons Per Row (Columns)", cfg, "perrow")
      CreateConfig(update, "Rows (0 = use Buttons Per Row)", cfg, "rows")
      CreateConfig(update, T["Bar Direction"], cfg, "direction", "dropdown", pfUI.gui.dropdowns.orientation)
      CreateConfig(update, "List Direction", cfg, "flyout", "dropdown", positions)
      CreateConfig(update, "Open List On Mouseover", cfg, "hover", "checkbox")
      CreateConfig(update, "Show Buff Timer", cfg, "timer", "checkbox")
      CreateConfig(update, "Show Item Count", cfg, "count", "checkbox")
      CreateConfig(update, T["Show Background"], cfg, "showbg", "checkbox")

      -- potion bar: used reactively during fights
      CreateConfig(nil, "Potion Bar (" .. catByKey[POTION_CAT].label .. ")", nil, nil, "header")
      CreateConfig(update, "Enable Potion Bar", cfg, "pot_enable", "checkbox")
      CreateConfig(update, "Show The Potion Bar", cfg, "pot_showwhen", "dropdown", potwhen)
      for _, item in ipairs(CatItems(catByKey[POTION_CAT])) do
        CreateConfig(update, item.name, cfg, "use_" .. item.key, "checkbox")
      end

      CreateConfig(nil, "Potion Bar Layout", nil, nil, "header")
      CreateConfig(update, T["Button Size"], cfg, "pot_size")
      CreateConfig(update, T["Spacing"], cfg, "pot_spacing", "dropdown", pfUI.gui.dropdowns.spacing)
      CreateConfig(update, "Buttons Per Row (Columns)", cfg, "pot_perrow")
      CreateConfig(update, "Rows (0 = use Buttons Per Row)", cfg, "pot_rows")
      CreateConfig(update, T["Bar Direction"], cfg, "pot_direction", "dropdown", pfUI.gui.dropdowns.orientation)
      CreateConfig(update, T["Show Background"], cfg, "pot_showbg", "checkbox")
    end)
  end
end)
