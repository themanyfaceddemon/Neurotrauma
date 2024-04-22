-- Hooks a Lua event "roundStart" to use for applying Neurotrauma specific
-- meta affliction named "modconflict", then console message about the name
-- of incompatible mod. Done also on server startup. 
-- It's important for patch to have the word "neurotrauma" in their name (case doesnt matter)
NT.modconflict = false
function NT.CheckModConflicts()
    NT.modconflict = false
    if NTConfig.Get("NT_ignoreModConflicts",false) then return end

    local itemsToCheck = {"antidama2","opdeco_hospitalbed"}

    for prefab in ItemPrefab.Prefabs do
        if HF.TableContains(itemsToCheck,prefab.Identifier.Value) then
            local mod = prefab.ConfigElement.ContentPackage.Name
            if not string.find(string.lower(mod), "neurotrauma") then
                NT.modconflict = true
				print("Found Neurotrauma incompatibility with mod: ", mod)
                print("WARNING! mod conflict detected! Neurotrauma may not function correctly and requires a patch!")
                return
            end
        end
    end

end
Timer.Wait(function()
    NT.CheckModConflicts()
end,1000)
Hook.Add("roundStart", "NT.RoundStart.modconflicts", function()
    Timer.Wait(function()
        NT.CheckModConflicts()
    end,10000)
    
end)
