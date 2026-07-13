if SERVER then
    util.AddNetworkString("get_karma")
end

local function ulx_setkarma(calling_ply, target_ply, amount)
    if not IsValid(target_ply) then return end

    amount = tonumber(amount) or 0

    target_ply.Karma = amount

    if target_ply.SetNetVar then
        target_ply:SetNetVar("Karma", amount)
    end

    ulx.fancyLogAdmin(
        calling_ply,
        "#A set #T karma to #i",
        target_ply,
        amount
    )
end

local setkarma = ulx.command("ZCity", "ulx setkarma", ulx_setkarma, "!setkarma")
setkarma:addParam{type = ULib.cmds.PlayerArg}
setkarma:addParam{type = ULib.cmds.NumArg, min = -1000, max = 1000, default = 0, hint = "karma"}
setkarma:defaultAccess(ULib.ACCESS_ADMIN)
setkarma:help("Set player's ZCity karma.")