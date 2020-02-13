if not gadgetHandler:IsSyncedCode() then return false end

function gadget:GetInfo()
    return {
        name = "Zero Wars",
        desc = "zero wars",
        author = "petturtle",
        date = "2020",
        license = "GNU GPL, v2 or later",
        layer = 1,
        enabled = true,
        handler = true
    }
end

local Platform = VFS.Include("LuaRules/Gadgets/ZeroWData/Platform.lua")
local IdleUnit = VFS.Include("LuaRules/Gadgets/ZeroWData/IdleUnit.lua")
local Side = VFS.Include("LuaRules/Gadgets/ZeroWData/Side.lua")

local dataSet = false

local leftTeam
local rightTeam
local leftSide
local rightSide

local updateTime = 60
local idleUnits = {}

----- Initalizing Game -----

-- Create team, holds all team related data for each side
function CreateTeam(nullAI)
    local allyTeam = select(6, Spring.GetTeamInfo(nullAI, false))
    local playerList = Spring.GetTeamList(allyTeam)

    -- remove nullAI from player list
    for i = 1, #playerList do
        if (playerList[i] == nullAI) then
            table.remove(playerList, i)
        end
    end

	local team = {
		nullAI = nullAI,
		allyTeam = allyTeam,
		playerList = playerList
    }
	return team
end

-- Sets left side data on initialize
local function InitializeLeftSide()

    -- Set platform data
    local platformTop    = Platform.new(0, 1280, 1144)
    local platformCenter = Platform.new(1152, 1280, 0)
    local platformBottom = Platform.new(2304, 1280, -1144)
    local plats = {platformTop, platformCenter, platformBottom}
    
    for i = 1, #leftTeam.playerList do
        table.insert(plats[(i%3)+1].players, leftTeam.playerList[i])
    end

    -- Remove unused platforms
    for i = #plats, 1, -1 do
        if #plats[i].players == 0 then
            table.remove(plats, i)
        end
    end

    leftSide = Side.new(leftTeam, plats, 5888)
end

-- Sets right side data on initialize
local function InitializeRightSide()

    -- Set platform data
    local platformTop    = Platform.new(0, -1280,  1144)
    local platformCenter = Platform.new(1152, -1280,  0)
    local platformBottom = Platform.new(2304, -1280, -1144)
    local plats = {platformTop, platformCenter, platformBottom}

    for i = 1, #rightTeam.playerList do
        table.insert(plats[(i%3)+1].players, rightTeam.playerList[i])
    end

    -- Remove unused platforms
    for i = #plats, 1, -1 do
        if #plats[i].players == 0 then
            table.remove(plats, i)
        end
    end

    rightSide = Side.new(rightTeam, plats, 2303)
end

-- Sets left side data on first frame
local function CreateLeftSide()
    leftSide.baseId = Spring.CreateUnit("baseturret", 2303, 10000, 1530, "e", leftTeam.nullAI)
    leftSide.turretId= Spring.CreateUnit("centerturret", 3264, 10000, 1530, "e", leftTeam.nullAI)
    Spring.SetUnitBlocking(leftSide.baseId, false)
    Spring.SetUnitBlocking(leftSide.turretId, false)

    for i = 1, #leftSide.plats do
        for t = 1, #leftSide.plats[i].players do
            Spring.CreateUnit("basiccon", leftSide.plats[i].rect.x1, 10000, leftSide.plats[i].rect.y1 + 350, "e", leftSide.plats[i].players[t])
            local units = Spring.GetTeamUnits(leftSide.plats[i].players[t])
            Spring.SetUnitPosition(units[1], 1855, 1537)
            local aa = Spring.CreateUnit("superaaturret", leftSide.plats[i].rect.x1 + 364, 10000, leftSide.plats[i].rect.y1 + 380, "e", leftTeam.nullAI)
        end
    end

    Spring.CreateUnit("staticrearm", 1480, 10000, 1226, "e", leftTeam.nullAI)
    Spring.CreateUnit("staticrearm", 1480, 10000, 1386, "e", leftTeam.nullAI)
    Spring.CreateUnit("staticrearm", 1480, 10000, 1529, "e", leftTeam.nullAI)
    Spring.CreateUnit("staticrearm", 1480, 10000, 1703, "e", leftTeam.nullAI)
    Spring.CreateUnit("staticrearm", 1480, 10000, 1848, "e", leftTeam.nullAI)

    Spring.SetTeamResource(leftTeam.nullAI, "metal", 0)
    for i = 1, #leftTeam.playerList do
        Spring.SetTeamResource(leftTeam.playerList[i], "metal", 0)
    end

    Spring.CreateUnit("staticstorage", 0, 10000, 0, "n", leftTeam.nullAI)
    local nullAICom = Spring.GetUnitsInRectangle(3968, 1152, 4224, 1920, leftTeam.nullAI)
    Spring.DestroyUnit(nullAICom[1], false, true)
end

-- Sets right side data on first frame
local function CreateRightSide()
    rightSide.baseId = Spring.CreateUnit("baseturret", 5888, 10000, 1530, "w", rightTeam.nullAI)
    rightSide.turretId = Spring.CreateUnit("centerturret", 4930, 10000, 1530, "w", rightTeam.nullAI)
    Spring.SetUnitBlocking(rightSide.baseId, false)
    Spring.SetUnitBlocking(rightSide.turretId, false)

    Spring.CreateUnit("staticrearm", 6711, 10000, 1226, "w", rightTeam.nullAI)
    Spring.CreateUnit("staticrearm", 6711, 10000, 1386, "w", rightTeam.nullAI)
    Spring.CreateUnit("staticrearm", 6711, 10000, 1529, "w", rightTeam.nullAI)
    Spring.CreateUnit("staticrearm", 6711, 10000, 1703, "w", rightTeam.nullAI)
    Spring.CreateUnit("staticrearm", 6711, 10000, 1848, "w", rightTeam.nullAI)

    for i = 1, #rightSide.plats do
        for t = 1, #rightSide.plats[i].players do
            Spring.CreateUnit("basiccon", rightSide.plats[i].rect.x2, 10000, rightSide.plats[i].rect.y2 - 350, "e", rightSide.plats[i].players[t])
            local units = Spring.GetTeamUnits(rightSide.plats[i].players[t])
            Spring.SetUnitPosition(units[1], 6336, 1537)
            local aa = Spring.CreateUnit("superaaturret", rightSide.plats[i].rect.x2 - 364, 10000, rightSide.plats[i].rect.y1 + 370, "w", rightTeam.nullAI)
        end
    end

    Spring.SetTeamResource(rightTeam.nullAI, "metal", 0)
    for i = 1, #rightTeam.playerList do
        Spring.SetTeamResource(rightTeam.playerList[i], "metal", 0)
    end

    Spring.CreateUnit("staticstorage", 8192, 10000, 0, "n", rightTeam.nullAI)
    local nullAICom = Spring.GetUnitsInRectangle(3968, 1152, 4224, 1920, rightTeam.nullAI)
    Spring.DestroyUnit(nullAICom[1], false, true)
end

function gadget:Initialize()
    if Game.modShortName ~= "ZK" then
        gadgetHandler:RemoveGadget()
        return
    end

    -- Set teams
    local teams = Spring.GetTeamList()
    local nullAI = {}
    for i = 1, #teams do
        local luaAI = Spring.GetTeamLuaAI(teams[i])
        if luaAI and string.find(string.lower(luaAI), "ai") then
            table.insert(nullAI, teams[i])
        end
    end

    if (#nullAI == 2) then
        leftTeam = CreateTeam(nullAI[1])
        rightTeam = CreateTeam(nullAI[2])
    else
        gadgetHandler:RemoveGadget()
        return
    end

    InitializeLeftSide()
    InitializeRightSide()
    GG.leftSide = leftSide
    GG.rightSide = rightSide
end

function gadget:GameFrame(f)
    if f == 1 then
        Spring.CreateUnit("superaaturret", 2940, 10000, 4, "s", Spring.GetGaiaTeamID())
        Spring.CreateUnit("superaaturret", 4092, 10000, 4, "s", Spring.GetGaiaTeamID())
        Spring.CreateUnit("superaaturret", 5244, 10000, 4, "s", Spring.GetGaiaTeamID())
        Spring.CreateUnit("superaaturret", 2940, 10000, 3056, "n", Spring.GetGaiaTeamID())
        Spring.CreateUnit("superaaturret", 4092, 10000, 3056, "n", Spring.GetGaiaTeamID())
        Spring.CreateUnit("superaaturret", 5244, 10000, 3056, "n", Spring.GetGaiaTeamID())

        CreateLeftSide()
        CreateRightSide()
        dataSet = true
    end

    if f > 0 and f % updateTime == 0 then
        -- add attack order to idle units
        for i = #idleUnits, 1, -1 do
            if not Spring.GetUnitIsDead(idleUnits[i].unit) then
                local cQueue = Spring.GetCommandQueue(idleUnits[i].unit, 1)
                if cQueue and #cQueue == 0 then
                    Spring.GiveOrderToUnit(idleUnits[i].unit, CMD.INSERT, {-1, CMD.FIGHT, CMD.OPT_SHIFT, idleUnits[i].side.attackXPos, 0, 1530}, {"alt"});
                end
            end
            table.remove(idleUnits, i)
        end
    end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    if dataSet then
        if unitID == leftSide.baseId then
            Spring.GameOver({rightSide.team.allyTeam})
        elseif unitID == rightSide.baseId then
            Spring.GameOver({leftSide.team.allyTeam})
        elseif unitID == leftSide.turretId then
            for i = 1, #rightSide.team.playerList do
                Spring.AddTeamResource(rightSide.team.playerList[i], "metal", 800)
            end
        elseif unitID == rightSide.turretId then
            for i = 1, #leftSide.team.playerList do
                Spring.AddTeamResource(leftSide.team.playerList[i], "metal", 800)
            end
        end
    end
end

function gadget:AllowFeatureCreation(featureDefID, teamID, x, y, z)
    return false
end

function gadget:UnitIdle(unitID, unitDefID, unitTeam)
    local cQueue = Spring.GetCommandQueue(unitID, 1)
    if unitTeam == leftTeam.nullAI then
        table.insert(idleUnits, IdleUnit.new(unitID, leftSide))
    elseif unitTeam == rightTeam.nullAI then
        table.insert(idleUnits, IdleUnit.new(unitID, rightSide))
    end
end

function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
    if newTeam == leftTeam.nullAI or newTeam == rightTeam.nullAI then
        return true
    end
    return false
end

-- Don't allow factories in center
function gadget:AllowUnitCreation(unitDefID, builderID, builderTeam, x, y, z, facing)
    local ud = UnitDefs[unitDefID]
    if dataSet then
        if ud.isBuilding then
            if ud.isFactory or ud.isStaticBuilder then
                return false
            end
            if ud.maxWeaponRange and ud.maxWeaponRange >= 1200 then
                return false
            end
        end
    elseif ud.isTransport then
        return false
    end
    return true
end