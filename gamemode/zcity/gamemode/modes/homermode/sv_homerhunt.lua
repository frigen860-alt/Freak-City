local MODE = MODE

MODE.name = "homerhunt"
MODE.PrintName = "Homer Hunt"
MODE.LootSpawn = false
MODE.GuiltDisabled = true
MODE.randomSpawns = true
MODE.noBoxes = true
MODE.ForBigMaps = false
MODE.Chance = 0.04

-- ============================================================
-- HOMER HUNT CONFIG
-- Один игрок = Гомер, остальные = Барты.
-- Барты должны убить Гомера.
-- Гомер получает способности Superfighters.
-- ============================================================

MODE.HomerModel = "models/player/norrland/homer.mdl" -- сюда поставишь модель Гомера
MODE.BartModel = "models/hellinspector/the_simpsons_game/bart.mdl" -- сюда поставишь модель Барта

-- Если хочешь несколько моделей Бартов:
MODE.BartModels = {
	"models/hellinspector/the_simpsons_game/bart.mdl",
	"models/hellinspector/the_simpsons_game/bart.mdl",
	"models/hellinspector/the_simpsons_game/bart.mdl",
}

-- Оружие Гомера. Можно оставить только руки.
MODE.HomerWeapons = {
	"weapon_hands_sh",
	"weapon_walkie_talkie",
}

-- Оружие Бартов. Тут сам ставишь нужные SWEP class.
MODE.BartWeapons = {
	"weapon_hands_sh",

	-- примеры:
	-- "weapon_hg_crowbar",
	-- "weapon_hk_usp",
}

-- Что добавить в Inventory игрока.
MODE.HomerInventoryWeapons = {
	"hg_sling",
}

MODE.BartInventoryWeapons = {
	-- "hg_sling",
}

-- ============================================================
-- DM-STYLE LOADOUT CONFIG
-- Тут настраивай что выдавать.
-- armor пишется как в DM: "vest10", "helmet8", без ent_armor_
-- primary/secondary/melee/medicine/grenades пишутся классами оружия.
-- ============================================================

MODE.HomerLoadout = {
	primary = nil,
	secondary = nil,
	melee = "weapon_hands_sh",
	armor = {},
	ammo = 3,
	ammo2 = 2,
	medicine = {},
	grenades = {},
	inventory = {"hg_sling"},
	attachments = "",
}

MODE.BartLoadout = {
	primary = "weapon_hg_kukri",
	secondary = nil,
	melee = "weapon_hands_sh",
	armor = {"ent_armor_helmet8", "ent_armor_vest10"},
	ammo = 3,
	ammo2 = 2,
	medicine = {"weapon_bandage_sh", "weapon_tourniquet"},
	grenades = {},
	inventory = {},
	attachments = "",
}


MODE.HomerHealth = 150
MODE.BartHealth = 100

MODE.HomerRoleName = "Гомер"
MODE.BartRoleName = "Барт"

MODE.HomerRoleColor = Color(255, 190, 45)
MODE.BartRoleColor = Color(255, 220, 65)

util.AddNetworkString("homerhunt_start")
util.AddNetworkString("homerhunt_end")

local function HH_GetAlivePlayers()
	local alive = {}

	for _, ply in player.Iterator() do
		if not IsValid(ply) then continue end
		if ply:Team() == TEAM_SPECTATOR then continue end
		if not ply:Alive() then continue end
		if ply.organism and ply.organism.incapacitated then continue end

		alive[#alive + 1] = ply
	end

	return alive
end

local function HH_SafeSetModel(ply, mdl)
	if not IsValid(ply) then return end
	if not mdl or mdl == "" then return end

	if util.IsValidModel(mdl) then
		ply:SetModel(mdl)
	end
end

local function HH_ClearWeapons(ply)
	if not IsValid(ply) then return end

	ply:StripWeapons()
	ply:StripAmmo()
end

local function HH_GiveWeapons(ply, weapons)
	if not IsValid(ply) then return end
	if not istable(weapons) then return end

	for _, wep in ipairs(weapons) do
		if isstring(wep) and wep ~= "" then
			ply:Give(wep)
		end
	end

end

local function HH_GiveInventoryWeapons(ply, weapons)
	if not IsValid(ply) then return end
	if not istable(weapons) then return end

	local inv = ply:GetNetVar("Inventory") or {}
	inv["Weapons"] = inv["Weapons"] or {}

	for _, wep in ipairs(weapons) do
		if isstring(wep) and wep ~= "" then
			inv["Weapons"][wep] = true
		end
	end

	ply:SetNetVar("Inventory", inv)
end


local function HH_SafeInventory(ply)
	local inv = ply:GetNetVar("Inventory") or {}
	inv["Weapons"] = inv["Weapons"] or {}
	ply:SetNetVar("Inventory", inv)
	return inv
end

local function HH_GiveAmmoForWeapon(ply, wep, ammoMul)
	if not IsValid(ply) or not IsValid(wep) then return end

	ammoMul = ammoMul or 3

	local ammoType = wep:GetPrimaryAmmoType()
	local maxClip = wep:GetMaxClip1()

	if ammoType and ammoType >= 0 and maxClip and maxClip > 0 then
		ply:GiveAmmo(maxClip * ammoMul, ammoType, true)
	end
end

local function HH_GiveWeaponWithAmmo(ply, class, ammoMul, attachments)
	if not IsValid(ply) then return end
	if not isstring(class) or class == "" then return end

	local wep = ply:Give(class)

	if IsValid(wep) then
		HH_GiveAmmoForWeapon(ply, wep, ammoMul)

		if attachments and attachments ~= "" and hg and hg.AddAttachmentForce then
			hg.AddAttachmentForce(ply, wep, istable(attachments) and table.Random(attachments) or attachments)
		end
	end

	return wep
end

local function HH_GiveListWeapons(ply, list)
	if not IsValid(ply) or not istable(list) then return end

	for _, class in ipairs(list) do
		HH_GiveWeaponWithAmmo(ply, class, 1)
	end
end

local function HH_ApplyArmor(ply, armorList)
	if not IsValid(ply) then return end
	if not istable(armorList) or #armorList <= 0 then return end

	-- Правильный способ из DM.
	-- Пример: {"helmet8", "vest10"}
	if hg and hg.AddArmor then
		hg.AddArmor(ply, armorList)
		return
	end

	-- Запасной способ, если hg.AddArmor отсутствует.
	for _, armor in ipairs(armorList) do
		if not isstring(armor) or armor == "" then continue end

		local class = armor
		if not string.StartWith(class, "ent_armor_") then
			class = "ent_armor_" .. class
		end

		local ent = ents.Create(class)
		if IsValid(ent) then
			ent:SetPos(ply:GetPos())
			ent:Spawn()

			if ent.Use then
				ent:Use(ply, ply, USE_ON, 1)
			elseif ent.Touch then
				ent:Touch(ply)
			end

			timer.Simple(0, function()
				if IsValid(ent) then ent:Remove() end
			end)
		end
	end
end

local function HH_ApplyLoadout(ply, loadout)
	if not IsValid(ply) then return end
	loadout = loadout or {}

	HH_SafeInventory(ply)

	if loadout.melee then
		HH_GiveWeaponWithAmmo(ply, loadout.melee, 1)
	end

	if loadout.primary then
		HH_GiveWeaponWithAmmo(ply, loadout.primary, loadout.ammo or 3, loadout.attachments)
	end

	if loadout.secondary then
		HH_GiveWeaponWithAmmo(ply, loadout.secondary, loadout.ammo2 or 2)
	end

	HH_GiveListWeapons(ply, loadout.grenades)
	HH_GiveListWeapons(ply, loadout.medicine)

	if loadout.inventory then
		HH_GiveInventoryWeapons(ply, loadout.inventory)
	end

	HH_ApplyArmor(ply, loadout.armor)

	ply:Give("weapon_walkie_talkie")

	timer.Simple(0, function()
		if not IsValid(ply) then return end

		if loadout.primary and ply:HasWeapon(loadout.primary) then
			ply:SelectWeapon(loadout.primary)
		elseif loadout.secondary and ply:HasWeapon(loadout.secondary) then
			ply:SelectWeapon(loadout.secondary)
		elseif loadout.melee and ply:HasWeapon(loadout.melee) then
			ply:SelectWeapon(loadout.melee)
		elseif ply:HasWeapon("weapon_hands_sh") then
			ply:SelectWeapon("weapon_hands_sh")
		end
	end)
end


local function HH_SetRole(ply, role)
	if not IsValid(ply) then return end

	ply.HomerHuntRole = role
	ply:SetNWString("HomerHuntRole", role)

	if role == "homer" then
		ply:SetNWBool("HomerHuntHomer", true)
		ply:SetNWBool("HomerHuntBart", false)
	else
		ply:SetNWBool("HomerHuntHomer", false)
		ply:SetNWBool("HomerHuntBart", true)
	end
end

function MODE:CanLaunch()
	return true
end

function MODE:Intermission()
	game.CleanUpMap()

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then
			continue
		end

		ApplyAppearance(ply)
		ply:SetupTeam(0)
	end

	local rndpoints = zb.GetMapPoints("RandomSpawns")
	zonepoint = table.Random(rndpoints or {})

	net.Start("homerhunt_start")
		net.WriteVector(zonepoint and zonepoint.pos or vector_origin)
		net.WriteEntity(NULL)
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	return HH_GetAlivePlayers()
end

function MODE:GetHomer()
	for _, ply in player.Iterator() do
		if IsValid(ply) and ply.HomerHuntRole == "homer" then
			return ply
		end
	end

	return NULL
end

function MODE:GetAliveBarts()
	local barts = {}

	for _, ply in player.Iterator() do
		if not IsValid(ply) then continue end
		if ply.HomerHuntRole ~= "bart" then continue end
		if not ply:Alive() then continue end
		if ply.organism and ply.organism.incapacitated then continue end

		barts[#barts + 1] = ply
	end

	return barts
end

function MODE:ShouldRoundEnd()
	local homer = self:GetHomer()
	local homerAlive = IsValid(homer) and homer:Alive() and not (homer.organism and homer.organism.incapacitated)
	local aliveBarts = self:GetAliveBarts()

	if not homerAlive then
		self.HomerHuntWinner = "barts"
		return true
	end

	if #aliveBarts <= 0 then
		self.HomerHuntWinner = "homer"
		return true
	end

	return false
end

function MODE:RoundStart()
	self.HomerHuntWinner = nil

	local alive = HH_GetAlivePlayers()
	local homer = table.Random(alive or {})

	if not IsValid(homer) and alive[1] then
		homer = alive[1]
	end

	for _, ply in ipairs(alive) do
		ply:SetSuppressPickupNotices(true)
		ply.noSound = true

		HH_ClearWeapons(ply)

		if ply == homer then
			HH_SetRole(ply, "homer")

			HH_SafeSetModel(ply, self.HomerModel)
			ply:SetHealth(self.HomerHealth)
			ply:SetMaxHealth(self.HomerHealth)

			-- Выдача как в DM: оружие, патроны, броня, медицина.
			HH_ApplyLoadout(ply, self.HomerLoadout)

			-- Старые списки оставлены как доп. выдача, если ты ими пользуешься.
			HH_GiveWeapons(ply, self.HomerWeapons)
			HH_GiveInventoryWeapons(ply, self.HomerInventoryWeapons)

			timer.Simple(0.05, function()
				if IsValid(ply) and ply.HomerHuntRole == "homer" then
					local lw = self.HomerLoadout or {}
					if lw.primary and ply:HasWeapon(lw.primary) then
						ply:SelectWeapon(lw.primary)
					elseif lw.melee and ply:HasWeapon(lw.melee) then
						ply:SelectWeapon(lw.melee)
					end
				end
			end)

			if ply.organism then
				ply.organism.recoilmul = 0.25
				ply.organism.superfighter = true
				ply.organism.adrenaline = math.max(ply.organism.adrenaline or 0, 0.25)
			end

			zb.GiveRole(ply, self.HomerRoleName, self.HomerRoleColor)
		else
			HH_SetRole(ply, "bart")

			local bartModel = table.Random(self.BartModels or {}) or self.BartModel
			HH_SafeSetModel(ply, bartModel)

			ply:SetHealth(self.BartHealth)
			ply:SetMaxHealth(self.BartHealth)

			-- Выдача как в DM: оружие берётся в руки, патроны и броня надеваются.
			HH_ApplyLoadout(ply, self.BartLoadout)

			-- Старые списки оставлены как доп. выдача, если ты ими пользуешься.
			HH_GiveWeapons(ply, self.BartWeapons)
			HH_GiveInventoryWeapons(ply, self.BartInventoryWeapons)

			if ply.organism then
				ply.organism.recoilmul = 1
				ply.organism.superfighter = false
			end

			zb.GiveRole(ply, self.BartRoleName, self.BartRoleColor)
		end

		timer.Simple(0.1, function()
			if IsValid(ply) then
				ply.noSound = false
			end
		end)

		ply:SetSuppressPickupNotices(false)
	end

	net.Start("homerhunt_start")
		net.WriteVector((zonepoint and zonepoint.pos) or vector_origin)
		net.WriteEntity(IsValid(homer) and homer or NULL)
	net.Broadcast()
end

function MODE:GiveWeapons()
end

function MODE:GiveEquipment()
end

function MODE:RoundThink()
end

function MODE:PlayerDeath(ply)
	if IsValid(ply) and ply.HomerHuntRole == "homer" then
		self.HomerHuntWinner = "barts"
	end
end

function MODE:CanSpawn()
end

function MODE:EndRound()
	timer.Simple(2, function()
		local homer = self:GetHomer()

		net.Start("homerhunt_end")
			net.WriteString(self.HomerHuntWinner or "unknown")
			net.WriteEntity(IsValid(homer) and homer or NULL)
		net.Broadcast()
	end)
end
