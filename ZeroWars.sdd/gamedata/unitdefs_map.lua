local unitTweaks = VFS.Include("gamedata/unit_tweaks.lua")
local unitPaybackTweaks = VFS.Include("gamedata/unit_payback_tweaks.lua")
local OverwriteTableInplace = Spring.Utilities.OverwriteTableInplace

-- replace shipFactory with chickenFactory
UnitDefs["factoryship"] = UnitDefs["factorychicken"]

for _, ud in pairs(UnitDefs) do
    if (ud.unitname:sub(1, 7) == "chicken") then
        -- set chicken cost
        ud.buildcostmetal = ud.buildtime
        ud.buildcostenergy = ud.buildtime
        -- make chickens reclaimable
        ud.reclaimable = true
    end

    if ud.weapondefs then
        -- remove friendly fire damage
        if (ud.unitname ~= "chicken_dodo") then
            for _, wd in pairs(ud.weapondefs) do
                if wd.customparams then
                    wd.customparams.nofriendlyfire = 1
                else
                    wd.customparams = {nofriendlyfire = 1}
                end
            end
        end

        -- d-guns can be fired by AI
        for _, wd in pairs(ud.weapondefs) do
            if wd.commandFire then
                wd.commandFire = false
            end
        end
    end

    -- set unit buildmast to 2
    if not (ud.builder or ud.isBuilder) then ud.buildingMask = 2 end

    -- removed friendly fire and collisions
    ud.avoidFriendly = false
    ud.collideFriendly = false
    ud.collideFirebase = false
end

-- apply unitTweaks
if unitTweaks and type(unitTweaks) == "table" then
    Spring.Echo("Loading custom units tweaks for zero-wars")
    for name, ud in pairs(UnitDefs) do
        if unitTweaks[name] then
            Spring.Echo("Loading custom units tweaks for " .. name)
            OverwriteTableInplace(ud, lowerkeys(unitTweaks[name]), true)
        end
    end
end

-- apply unitEnergy
local metalmult = (tonumber(Spring.GetModOptions().metalmult) or 1)
if unitPaybackTweaks and type(unitPaybackTweaks) == "table" then
    Spring.Echo("Loading custom units energy for zero-wars")
    for name, ud in pairs(UnitDefs) do
		if unitPaybackTweaks[name] then
			local payback = math.floor(math.sqrt(ud.buildcostmetal) * metalmult * 0.6) + unitPaybackTweaks[name]
            ud.customparams = ud.customparams or {}
            ud.customparams.deploy_income = ud.buildcostmetal / payback
            ud.customparams.deploy_efficiency = "Payback in " .. payback .. " waves"
        end
    end
end

