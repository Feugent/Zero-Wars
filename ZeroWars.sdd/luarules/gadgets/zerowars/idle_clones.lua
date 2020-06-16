local Queue = VFS.Include("luarules/gadgets/util/queue.lua")

local spGetUnitAllyTeam = Spring.GetUnitAllyTeam

local IdleClones = {}
IdleClones.__index = IdleClones

function IdleClones.new(attackPos)
    local instance = {
        _idle = Queue.new(),
        _commanding = false,
        _attackPos = attackPos 
    }
    setmetatable(instance, IdleClones)
    return instance
end

function IdleClones:add(unitID)
    if not self._commanding then
        self._idle:push(unitID)
    end
end

function IdleClones:command()
    -- prevent noop orders from adding to idle queue while iterating
    self._commanding = true
    while self._idle:size() > 0 do
        local unitID = self._idle:pop()
        local success, err = pcall(self.command_unit, self, unitID)
        if not success then
            Spring.Echo("Error: IdleClones \n" .. err)
        end
    end
    self._commanding = false
end

function IdleClones:command_unit(unitID)
    local allyID = spGetUnitAllyTeam(unitID)
    local x1 = self._attackPos[allyID]

    if not Spring.GetUnitIsDead(unitID) then
        local cQueue = Spring.GetCommandQueue(unitID, 1)
        if cQueue and #cQueue == 0 then
            local x, y, z = Spring.GetUnitPosition(unitID)
            Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {x1, 0, z}, {"alt"})
        end
    end
end

return IdleClones