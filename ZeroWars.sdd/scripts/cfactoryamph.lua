include "constants.lua"

local base, turret, arm_1, arm_2, arm_3, nanobase, nanoemit, pad, nozzle, cylinder, body =
    piece("base", "turret", "arm_1", "arm_2", "arm_3", "nanobase", "nanoemit", "pad", "nozzle", "cylinder", "body")

local nanoPieces = {nanoemit}
local smokePiece = {base}

local function Open()
    Signal(1)
    SetSignalMask(1)

    Turn(arm_1, x_axis, math.rad(-85), math.rad(85))
    Turn(arm_2, x_axis, math.rad(170), math.rad(170))
    Turn(arm_3, x_axis, math.rad(-60), math.rad(60))
    Turn(nanobase, x_axis, math.rad(10), math.rad(10))

    SetUnitValue(COB.YARD_OPEN, 1)
    SetUnitValue(COB.INBUILDSTANCE, 1)
    SetUnitValue(COB.BUGGER_OFF, 1)
end

function script.Create()
    StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
    Spring.SetUnitNanoPieces(unitID, nanoPieces)
    Open()
end

function script.QueryNanoPiece()
    GG.LUPS.QueryNanoPiece(unitID, unitDefID, Spring.GetUnitTeam(unitID), nanoemit)
    return nanoemit
end

function script.QueryBuildInfo()
    return pad
end

local explodables = {nozzle, cylinder, arm_1, arm_2, arm_3}
function script.Killed(recentDamage, maxHealth)
    local severity = recentDamage / maxHealth

    for i = 1, #explodables do
        if (severity > math.random()) then
            Explode(explodables[i], SFX.SMOKE + SFX.FIRE)
        end
    end

    if (severity <= .5) then
        return 1
    else
        Explode(body, SFX.SHATTER)
        return 2
    end
end
