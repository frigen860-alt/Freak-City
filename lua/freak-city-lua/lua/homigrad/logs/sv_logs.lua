if CLIENT then return end

util.AddNetworkString("zlogs_open")
util.AddNetworkString("zlogs_request")
util.AddNetworkString("zlogs_send")

ZLOGS = ZLOGS or {}

sql.Query([[
CREATE TABLE IF NOT EXISTS zcity_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    time TEXT,
    category TEXT,
    action TEXT,
    nick TEXT,
    steamid TEXT,
    steamid64 TEXT,
    ip TEXT,
    details TEXT
)
]])

-- Авто-миграция старой таблицы, если раньше не было колонки ip
do
    local info = sql.Query("PRAGMA table_info(zcity_logs)") or {}
    local hasIP = false

    for _, row in ipairs(info) do
        if row.name == "ip" then
            hasIP = true
            break
        end
    end

    if not hasIP then
        sql.Query("ALTER TABLE zcity_logs ADD COLUMN ip TEXT")
        print("[ZLOGS] Added missing ip column")
    end
end

local function esc(s)
    return sql.SQLStr(tostring(s or ""))
end

local function pname(ply)
    if not IsValid(ply) then return "CONSOLE" end
    return ply:Nick() or "unknown"
end

local function sid(ply)
    if not IsValid(ply) then return "CONSOLE" end
    return ply:SteamID() or "UNKNOWN"
end

local function sid64(ply)
    if not IsValid(ply) then return "0" end
    return ply:SteamID64() or "0"
end

local function getIP(ply)
    if not IsValid(ply) then return "CONSOLE" end
    if ply:IsBot() then return "BOT" end

    if isstring(ply.ZLogsCachedIP) and ply.ZLogsCachedIP ~= "" then
        return ply.ZLogsCachedIP
    end

    local ip = "0.0.0.0"

    local ok, res = pcall(function()
        return ply:IPAddress()
    end)

    if ok and isstring(res) and res ~= "" then
        ip = res
    end

    -- IPv4 с портом: 185.97.255.43:27005 -> 185.97.255.43
    ip = string.match(ip, "^(%d+%.%d+%.%d+%.%d+)") or ip

    if ip == "loopback" then
        ip = "127.0.0.1"
    end

    ply.ZLogsCachedIP = ip
    return ip
end

local function targetName(ent)
    if not IsValid(ent) then return "unknown" end
    if ent:IsPlayer() then 
        return ent:Nick() .. " [" .. ent:SteamID() .. "]"
    end
    return ent:GetClass() .. " #" .. ent:EntIndex()
end

function ZLOGS.Add(ply, category, action, details)
    sql.Query(string.format(
        "INSERT INTO zcity_logs(time, category, action, nick, steamid, steamid64, ip, details) VALUES(%s,%s,%s,%s,%s,%s,%s,%s)",
        esc(os.date("%Y-%m-%d %H:%M:%S")),
        esc(category),
        esc(action),
        esc(pname(ply)),
        esc(sid(ply)),
        esc(sid64(ply)),
        esc(getIP(ply)),
        esc(details)
    ))

    print("[ZLOGS] [" .. tostring(category) .. "] " .. pname(ply) .. " [" .. getIP(ply) .. "] | " .. tostring(action) .. " | " .. tostring(details))
end

concommand.Add("zlogs", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    net.Start("zlogs_open")
    net.Send(ply)
end)

net.Receive("zlogs_request", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    if len > 2048 then return end

    local category = net.ReadString()
    local search = net.ReadString()

    local where = "1=1"

    if category ~= "All Logs" then
        where = where .. " AND category = " .. esc(category)
    end

    if search ~= "" then
        local like = esc("%" .. search .. "%")
        where = where .. " AND (nick LIKE " .. like .. " OR steamid LIKE " .. like .. " OR steamid64 LIKE " .. like .. " OR ip LIKE " .. like .. " OR details LIKE " .. like .. " OR action LIKE " .. like .. ")"
    end

    local rows = sql.Query("SELECT * FROM zcity_logs WHERE " .. where .. " ORDER BY id DESC LIMIT 300") or {}

    net.Start("zlogs_send")
    net.WriteTable(rows)
    net.Send(ply)
end)

--=========================================================
-- BASIC LOGS
--=========================================================

hook.Add("PlayerInitialSpawn", "zlogs_join", function(ply)
    timer.Simple(0, function()
        if IsValid(ply) then
            getIP(ply)
        end
    end)

    timer.Simple(1, function()
        if IsValid(ply) then
            ZLOGS.Add(ply, "Connect", "Join", "Player joined from IP=" .. getIP(ply))
        end
    end)
end)

hook.Add("PlayerDisconnected", "zlogs_leave", function(ply)
    ZLOGS.Add(ply, "Disconnect", "Leave", "Player left from IP=" .. getIP(ply))
end)

hook.Add("PlayerSay", "zlogs_chat", function(ply, text)
    ZLOGS.Add(ply, "Chat", "Say", text)
end)

hook.Add("PlayerDeath", "zlogs_death", function(victim, inflictor, attacker)
    local details = "victim=" .. targetName(victim)

    if IsValid(attacker) then
        details = details .. " | attacker=" .. targetName(attacker)
    end

    if IsValid(inflictor) then
        details = details .. " | inflictor=" .. inflictor:GetClass()
    end

    ZLOGS.Add(victim, "Damage", "Death", details)
end)

--=========================================================
-- Q MENU / SANDBOX
--=========================================================

hook.Add("PlayerSpawnedProp", "zlogs_prop", function(ply, model, ent)
    ZLOGS.Add(ply, "Sandbox", "SpawnProp", "model=" .. tostring(model))
end)

hook.Add("PlayerSpawnedNPC", "zlogs_npc", function(ply, ent)
    ZLOGS.Add(ply, "Sandbox", "SpawnNPC", "class=" .. tostring(IsValid(ent) and ent:GetClass() or "unknown"))
end)

hook.Add("PlayerSpawnedSENT", "zlogs_sent", function(ply, ent)
    ZLOGS.Add(ply, "Sandbox", "SpawnEntity", "class=" .. tostring(IsValid(ent) and ent:GetClass() or "unknown"))
end)

hook.Add("PlayerSpawnedVehicle", "zlogs_vehicle", function(ply, ent)
    ZLOGS.Add(ply, "Sandbox", "SpawnVehicle", "class=" .. tostring(IsValid(ent) and ent:GetClass() or "unknown"))
end)

hook.Add("PlayerSpawnedRagdoll", "zlogs_ragdoll", function(ply, model, ent)
    ZLOGS.Add(ply, "Sandbox", "SpawnRagdoll", "model=" .. tostring(model))
end)

hook.Add("PlayerSpawnedEffect", "zlogs_effect", function(ply, model, ent)
    ZLOGS.Add(ply, "Sandbox", "SpawnEffect", "model=" .. tostring(model))
end)

hook.Add("PlayerGiveSWEP", "zlogs_giveswep", function(ply, class)
    ZLOGS.Add(ply, "Spawn", "GiveSWEP", "class=" .. tostring(class))
end)

hook.Add("PlayerSpawnSWEP", "zlogs_spawnswep", function(ply, class)
    ZLOGS.Add(ply, "Spawn", "SpawnSWEP", "class=" .. tostring(class))
end)

--=========================================================
-- ULX
--=========================================================

timer.Simple(2, function()
    if not ulx or not ulx.fancyLogAdmin or ulx.ZLogsOld then return end

    ulx.ZLogsOld = ulx.fancyLogAdmin

    ulx.fancyLogAdmin = function(ply, format, ...)
        local msg = tostring(format or "")
        local args = {...}

        for k, v in ipairs(args) do
            local rep

            if IsValid(v) and v:IsPlayer() then
                rep = v:Nick() .. " [" .. v:SteamID() .. "]"
            else
                rep = tostring(v)
            end

            msg = string.gsub(msg, "#" .. k, rep)
        end

        ZLOGS.Add(ply, "ULX", "ULX Action", msg)

        return ulx.ZLogsOld(ply, format, ...)
    end

    print("[ZLOGS] ULX hooked")
end)

--=========================================================
-- ZCITY ADMINTOOLS LOGGING
--=========================================================

ZLOGS.AdminCtx = ZLOGS.AdminCtx or nil

local adminToolNames = {
    notify = "Notify",
    givegun = "Give",
    strip = "Strip",
    fullstrip = "Full Strip",
    reset_org = "Reset organism",
    freeze = "Freeze / Unfreeze",
    snatch = "Snatch",
    ragdollize = "Stun / Get up",
    vomit = "Make vomit",
    lobotomize = "Lobotomize",
    killsilent = "Kill Silent",
    removeply = "Remove",
    setplayerclass = "Set player class",
    break_limb = "Break Limb",
    amputate_limb = "Amputate Limb",
    door_toggle = "Toggle Door",
    door_lock = "Lock Door",
    door_unlock = "Unlock Door",
    respawn_ply_in_rag = "Respawn Player",
    respawn_lply_in_rag = "Spawn Self",
    respawn_ragply_in_rag = "Spawn RagOwner"
}

local function ctx()
    return ZLOGS.AdminCtx
end

local function logCtx(action, target, extra)
    local c = ctx()
    if not c or not IsValid(c.admin) then return end

    local details = "target=" .. targetName(target)

    if extra and extra ~= "" then
        details = details .. " | " .. tostring(extra)
    end

    ZLOGS.Add(c.admin, "Command", "[AdminTools] " .. action, details)
end

local function wrapProperties()
    if not properties or properties.ZLogsWrapped then return end
    properties.ZLogsWrapped = true

    local oldAdd = properties.Add

    properties.Add = function(name, tbl)
        if istable(tbl) and isfunction(tbl.Receive) and adminToolNames[name] and not tbl.ZLogsReceiveWrapped then
            local oldReceive = tbl.Receive
            tbl.ZLogsReceiveWrapped = true

            tbl.Receive = function(self, length, ply)
                ZLOGS.AdminCtx = {
                    admin = ply,
                    prop = name,
                    label = adminToolNames[name]
                }

                ZLOGS.Add(ply, "Command", "[AdminTools] Click", "action=" .. adminToolNames[name])

                local ok, err = pcall(oldReceive, self, length, ply)

                ZLOGS.AdminCtx = nil

                if not ok then
                    ErrorNoHalt("[ZLOGS] AdminTools receive error: " .. tostring(err) .. "\n")
                    return
                end
            end
        end

        return oldAdd(name, tbl)
    end

    if properties.List then
        for name, tbl in pairs(properties.List) do
            if istable(tbl) and isfunction(tbl.Receive) and adminToolNames[name] and not tbl.ZLogsReceiveWrapped then
                local oldReceive = tbl.Receive
                tbl.ZLogsReceiveWrapped = true

                tbl.Receive = function(self, length, ply)
                    ZLOGS.AdminCtx = {
                        admin = ply,
                        prop = name,
                        label = adminToolNames[name]
                    }

                    ZLOGS.Add(ply, "Command", "[AdminTools] Click", "action=" .. adminToolNames[name])

                    local ok, err = pcall(oldReceive, self, length, ply)

                    ZLOGS.AdminCtx = nil

                    if not ok then
                        ErrorNoHalt("[ZLOGS] AdminTools receive error: " .. tostring(err) .. "\n")
                        return
                    end
                end
            end
        end
    end

    print("[ZLOGS] AdminTools properties hooked")
end

local function wrapFunctionTable(tbl, key, newFunc)
    if not tbl then return end
    if not isfunction(tbl[key]) then return end
    if tbl["ZLogsOld_" .. key] then return end

    tbl["ZLogsOld_" .. key] = tbl[key]
    tbl[key] = newFunc
end

local function wrapAdminFunctions()
    if ZLOGS.AdminFunctionsWrapped then return end
    ZLOGS.AdminFunctionsWrapped = true

    local plyMeta = FindMetaTable("Player")
    local entMeta = FindMetaTable("Entity")

    if plyMeta then
        wrapFunctionTable(plyMeta, "SetPlayerClass", function(self, class, ...)
            logCtx("Set player class", self, "class=" .. tostring(class))
            return plyMeta.ZLogsOld_SetPlayerClass(self, class, ...)
        end)

        wrapFunctionTable(plyMeta, "StripWeapons", function(self, ...)
            logCtx("Strip weapons", self, "")
            return plyMeta.ZLogsOld_StripWeapons(self, ...)
        end)

        wrapFunctionTable(plyMeta, "Give", function(self, class, ...)
            logCtx("Give weapon/entity", self, "class=" .. tostring(class))
            return plyMeta.ZLogsOld_Give(self, class, ...)
        end)

        wrapFunctionTable(plyMeta, "Kill", function(self, ...)
            logCtx("Kill", self, "")
            return plyMeta.ZLogsOld_Kill(self, ...)
        end)

        wrapFunctionTable(plyMeta, "KillSilent", function(self, ...)
            logCtx("KillSilent / Remove", self, "")
            return plyMeta.ZLogsOld_KillSilent(self, ...)
        end)
    end

    if entMeta then
        wrapFunctionTable(entMeta, "Freeze", function(self, state, ...)
            logCtx(state and "Freeze" or "Unfreeze", self, "")
            return entMeta.ZLogsOld_Freeze(self, state, ...)
        end)

        wrapFunctionTable(entMeta, "Remove", function(self, ...)
            logCtx("Remove", self, "")
            return entMeta.ZLogsOld_Remove(self, ...)
        end)

        wrapFunctionTable(entMeta, "Fire", function(self, input, ...)
            local c = ctx()
            if c and (c.prop == "door_toggle" or c.prop == "door_lock" or c.prop == "door_unlock") then
                logCtx(adminToolNames[c.prop] or "Door action", self, "input=" .. tostring(input))
            end

            return entMeta.ZLogsOld_Fire(self, input, ...)
        end)
    end

    timer.Simple(1, function()
        if hg then
            if isfunction(hg.LightStunPlayer) and not hg.ZLogsOld_LightStunPlayer then
                hg.ZLogsOld_LightStunPlayer = hg.LightStunPlayer
                hg.LightStunPlayer = function(target, ...)
                    logCtx("Stun", target, "")
                    return hg.ZLogsOld_LightStunPlayer(target, ...)
                end
            end

            if isfunction(hg.FakeUp) and not hg.ZLogsOld_FakeUp then
                hg.ZLogsOld_FakeUp = hg.FakeUp
                hg.FakeUp = function(target, ...)
                    logCtx("Get up", target, "")
                    return hg.ZLogsOld_FakeUp(target, ...)
                end
            end

            if isfunction(hg.BreakNeck) and not hg.ZLogsOld_BreakNeck then
                hg.ZLogsOld_BreakNeck = hg.BreakNeck
                hg.BreakNeck = function(target, ...)
                    logCtx("Break Limb", target, "limb=Neck")
                    return hg.ZLogsOld_BreakNeck(target, ...)
                end
            end

            if isfunction(hg.ExplodeHead) and not hg.ZLogsOld_ExplodeHead then
                hg.ZLogsOld_ExplodeHead = hg.ExplodeHead
                hg.ExplodeHead = function(target, ...)
                    logCtx("Amputate Limb", target, "limb=Head")
                    return hg.ZLogsOld_ExplodeHead(target, ...)
                end
            end
        end

        if hg and hg.organism then
            if isfunction(hg.organism.Clear) and not hg.organism.ZLogsOld_Clear then
                hg.organism.ZLogsOld_Clear = hg.organism.Clear
                hg.organism.Clear = function(org, ...)
                    logCtx("Reset organism", org and org.owner, "")
                    return hg.organism.ZLogsOld_Clear(org, ...)
                end
            end

            if isfunction(hg.organism.Vomit) and not hg.organism.ZLogsOld_Vomit then
                hg.organism.ZLogsOld_Vomit = hg.organism.Vomit
                hg.organism.Vomit = function(target, ...)
                    logCtx("Make vomit", target, "")
                    return hg.organism.ZLogsOld_Vomit(target, ...)
                end
            end

            if isfunction(hg.organism.AmputateLimb) and not hg.organism.ZLogsOld_AmputateLimb then
                hg.organism.ZLogsOld_AmputateLimb = hg.organism.AmputateLimb
                hg.organism.AmputateLimb = function(org, limb, ...)
                    logCtx("Amputate Limb", org and org.owner, "limb=" .. tostring(limb))
                    return hg.organism.ZLogsOld_AmputateLimb(org, limb, ...)
                end
            end

            if istable(hg.organism.input_list) and not hg.organism.ZLogsInputListWrapped then
                hg.organism.ZLogsInputListWrapped = true

                local limbNames = {
                    larmup = "Left Arm",
                    rarmup = "Right Arm",
                    llegup = "Left Leg",
                    rlegup = "Right Leg",
                    spine1 = "Spine 1",
                    spine2 = "Spine 2",
                    spine3 = "Spine 3"
                }

                for fn, limbName in pairs(limbNames) do
                    if isfunction(hg.organism.input_list[fn]) and not hg.organism.input_list["ZLogsOld_" .. fn] then
                        hg.organism.input_list["ZLogsOld_" .. fn] = hg.organism.input_list[fn]

                        hg.organism.input_list[fn] = function(org, ...)
                            logCtx("Break Limb", org and org.owner, "limb=" .. limbName)
                            return hg.organism.input_list["ZLogsOld_" .. fn](org, ...)
                        end
                    end
                end
            end
        end
    end)

    print("[ZLOGS] AdminTools function hooks loaded")
end

timer.Simple(0, wrapProperties)
timer.Simple(1, wrapProperties)
timer.Simple(3, wrapProperties)
timer.Simple(6, wrapProperties)

timer.Simple(0, wrapAdminFunctions)
timer.Simple(2, wrapAdminFunctions)
timer.Simple(6, wrapAdminFunctions)

--=========================================================
-- COMMAND SEARCH
--=========================================================

concommand.Add("zlogs_search", function(ply, cmd, args, argStr)
    if IsValid(ply) and not ply:IsAdmin() then return end

    local q = tostring(argStr or "")
    if q == "" then return end

    local like = esc("%" .. q .. "%")

    local rows = sql.Query(string.format([[
        SELECT * FROM zcity_logs
        WHERE nick LIKE %s
           OR steamid LIKE %s
           OR steamid64 LIKE %s
           OR ip LIKE %s
           OR action LIKE %s
           OR category LIKE %s
           OR details LIKE %s
        ORDER BY id DESC
        LIMIT 300
    ]], like, like, like, like, like, like, like)) or {}

    for _, r in ipairs(rows) do
        print("#" .. r.id .. " [" .. r.time .. "] [" .. r.category .. "] " .. r.nick .. " [" .. (r.ip or "0.0.0.0") .. "] " .. r.steamid .. " | " .. r.action .. " | " .. r.details)
    end
end)


concommand.Add("zlogs_ips", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end

    for _, v in ipairs(player.GetAll()) do
        print("[ZLOGS IP] " .. v:Nick() .. " | " .. v:SteamID() .. " | " .. getIP(v))
    end
end)

print("[ZLOGS] Full ZCity log system loaded (fixed with IP logging)")
