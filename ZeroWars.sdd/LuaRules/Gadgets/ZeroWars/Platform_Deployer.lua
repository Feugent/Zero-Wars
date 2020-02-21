include("LuaRules/Configs/customcmds.h.lua")

local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit
local spGetUnitIsDead = Spring.GetUnitIsDead
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitHealth = Spring.GetUnitHealth
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
local spGetUnitCmdDescs = Spring.GetUnitCmdDescs
local spEditUnitCmdDesc = Spring.EditUnitCmdDesc
local spGetUnitStates = Spring.GetUnitStates
local spGetUnitMass = Spring.GetUnitMass
local spGiveOrderArrayToUnitArray = Spring.GiveOrderArrayToUnitArray

local heavyTimeout = 7000  -- 3.88m
local normalTimeout = 5000 -- 2.77m
local skirmTimeout = 4000  -- 2.22m
local artyTimeout = 3000   -- 1.66m

PlatformDeployer = {
    deployQueue,
    heavyUnits,
    normalUnits,
    skirmUnits,
    artyUnits,
}

function PlatformDeployer:new ()
    o = {}
    setmetatable(o, self)
    self.__index = self
    self.deployQueue = {}
    self.heavyUnits = {}
    self.normalUnits = {}
    self.skirmUnits = {}
    self.artyUnits = {}
    return o
end

-- adds platform's units to deploy queue
function PlatformDeployer:Deploy (platform, deployRect, faceDir, teamID, attackXPos)
    for i = 1, #platform.playerList do
        local units = platform:GetUnits(platform.playerList[i])
        if units then
            local posOffset = platform.rect:GetPosOffset(deployRect)
            local deployData = {
                posOffset = posOffset,
                faceDir = faceDir,
                teamID = teamID,
                attackXPos = attackXPos,
                units = units,
            }
            table.insert(self.deployQueue, deployData)
        end
    end
end

function PlatformDeployer:IterateQueue(spawnAmount, frame)
    if #self.deployQueue > 0 then
        self:DeployUnits(self.deployQueue[1], spawnAmount, frame)
        if #self.deployQueue[1].units == 0 then
            table.remove(self.deployQueue, 1)
        end
    end
end

function PlatformDeployer:DeployUnits(deployData, spawnAmount, frame)
    local spawnCount = 0
    local units = deployData.units
    local heavyWave = {units = {}, frame = frame}
    local normalWave = {units = {}, frame = frame}
    local skirmWave = {units = {}, frame = frame}
    local artyWave = {units = {}, frame = frame}
    for i = #units, 1, -1 do
        local unitDefID = spGetUnitDefID(units[i])
        local ud = UnitDefs[unitDefID]
        if self:IsValidUnit(units[i], ud) then
            local x, y, z = spGetUnitPosition(units[i])      
            local unit = spCreateUnit(unitDefID, deployData.posOffset.x + x, 150, deployData.posOffset.y + z, deployData.faceDir, deployData.teamID)

            local states = spGetUnitStates(units[i])
            spGiveOrderArrayToUnitArray({ unit }, {
                { CMD.FIRE_STATE, { states.firestate },             { } },
                { CMD.MOVE_STATE, { states.movestate },             { } },
                { CMD.REPEAT,     { states["repeat"] and 1 or 0 },  { } },
                { CMD.CLOAK,      { states.cloak     and 1 or ud.initCloaked },  { } },
                { CMD.ONOFF,      { 1 },                            { } },
                { CMD.TRAJECTORY, { states.trajectory and 1 or 0 }, { } },
            })

            self:CopyUnitState(units[i], unit, CMD_UNIT_AI)
            self:CopyUnitState(units[i], unit, CMD_AIR_STRAFE)
            self:CopyUnitState(units[i], unit, CMD_PUSH_PULL)
            self:CopyUnitState(units[i], unit, CMD_AP_FLY_STATE)
            self:CopyUnitState(units[i], unit, CMD_UNIT_BOMBER_DIVE_STATE)
            self:CopyUnitState(units[i], unit, CMD_AP_FLY_STATE)

            spGiveOrderToUnit(unit, CMD.FIGHT, {deployData.attackXPos, 0, deployData.posOffset.y + z}, 0)

            local range = ud.maxWeaponRange
            local mass = spGetUnitMass(unit)

            if mass > 1000 then -- Strider
                table.insert(heavyWave.units, unit)
            elseif range >= 600 then -- Arty
                table.insert(artyWave.units, unit)
            elseif mass > 252 then -- Heavy
                table.insert(heavyWave.units, unit)
            elseif range >= 455 then -- skirm
                table.insert(skirmWave.units, unit)
            else -- normal 
                table.insert(normalWave.units, unit)
            end

            table.remove(units, i)

            spawnCount = spawnCount + 1
            if spawnCount > spawnAmount then
                break
            end
        else
            table.remove(units, i)
        end
    end

    if #heavyWave.units > 0 then
        table.insert(self.heavyUnits, heavyWave)
    end
    if #normalWave.units > 0 then
        table.insert(self.normalUnits, normalWave)
    end
    if #skirmWave.units > 0 then
        table.insert(self.skirmUnits, skirmWave)
    end
    if #artyWave.units > 0 then
        table.insert(self.artyUnits, artyWave)
    end
end

function PlatformDeployer:ClearUnitType(unitType, timeout, frame)
    while #unitType > 0 and unitType[1].frame + timeout < frame do
        local units = unitType[1].units
        for i = 1, #units do
            if not spGetUnitIsDead(units[i]) then
                spDestroyUnit(units[i], false, true)
            end
        end
        table.remove(unitType, 1)
    end
end

function PlatformDeployer:ClearTimedOut(frame)
    self:ClearUnitType(self.heavyUnits, heavyTimeout, frame)
    self:ClearUnitType(self.normalUnits, normalTimeout, frame)
    self:ClearUnitType(self.skirmUnits, skirmTimeout, frame)
    self:ClearUnitType(self.artyUnits, artyTimeout, frame)
end

function PlatformDeployer:IsValidUnit(unitID, ud)
    local buildProgress = select(5, spGetUnitHealth(unitID))
    if not ud.isImmobile and (not ud.isMobileBuilder or ud.isAirUnit) and buildProgress == 1 then
        return true end
    return false 
end

function PlatformDeployer:CopyUnitState(original, clone, cmd)
    local CMDDescID = spFindUnitCmdDesc(original, cmd)
    if CMDDescID then
        local cmdDesc = spGetUnitCmdDescs(original, CMDDescID, CMDDescID)
        local nparams = cmdDesc[1].params
        spEditUnitCmdDesc(clone, cmd, cmdDesc[1])
        spGiveOrderToUnit(clone, cmd, {nparams[1]}, {})
    end
end


return PlatformDeployer