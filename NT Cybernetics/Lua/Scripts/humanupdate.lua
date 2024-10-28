

function NTCyb.UpdateHuman(character)

    local velocity = 0
    if 
        character ~= nil and 
        character.AnimController ~= nil and 
        character.AnimController.MainLimb ~= nil and 
        character.AnimController.MainLimb.body ~= nil and 
        character.AnimController.MainLimb.body.LinearVelocity ~= nil then
            velocity = character.AnimController.MainLimb.body.LinearVelocity.Length() end

    local function updateLimb(character,limbtype) 
        if not NTCyb.HF.LimbIsCyber(character,limbtype) then return end
        NTCyb.ConvertDamageTypes(character,limbtype)

        local limb = character.AnimController.GetLimb(limbtype)

        -- cyber stats
        local loosescrews = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_loosescrews",0)
        local damagedelectronics = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_damagedelectronics",0)
        local bentmetal = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_bentmetal",0)
        local materialloss = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_materialloss",0)
    
        -- water damage if unprotected
        if NTConfig.Get("NTCyb_waterDamage",0) > 0
            and character.PressureProtection <= 1000
            and not HF.HasAffliction(character,"stasis")
            and not HF.HasAffliction(character,"bodybagoverlay")
            and HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_waterproof",0) <= 0
        then
            -- in water?
            local inwater = false
            if limb~=nil and limb.InWater then inwater=true end
            if inwater then
                -- add damaged electronics
                Timer.Wait(function(limb)
                    if limb ~= nil then
                        local spawnpos = limb.WorldPosition
                        HF.SpawnItemAt("ntcvfx_malfunction",spawnpos) end
                end,math.random(1,500))
                HF.AddAfflictionLimb(character,"ntc_damagedelectronics",limbtype,(1+loosescrews/100)*(1+materialloss/100)*NTConfig.Get("NTCyb_waterDamage",0)*NT.Deltatime)
            end
        end

        -- moving around damages if loose screws high enough
        if loosescrews > 30 and velocity > 1 then
            HF.AddAfflictionLimb(character,"ntc_materialloss",limbtype,HF.Clamp(velocity,0,5)*(loosescrews/500)*NT.Deltatime)
            HF.AddAfflictionLimb(character,"ntc_loosescrews",limbtype,HF.Clamp(velocity,0,5)/50*NT.Deltatime)
        end
        

        -- losing the limb
        if materialloss >= 99 then
            NTCyb.UncyberifyLimb(character,limbtype)
            NT.TraumamputateLimbMinusItem(character,limbtype)
            HF.GiveItem(character,"ntcsfx_cyberdeath")
            HF.AddAfflictionLimb(character,"internaldamage",limbtype,HF.RandomRange(30,60))
            HF.AddAfflictionLimb(character,"foreignbody",limbtype,HF.RandomRange(10,25))
            return
        end

        -- limb malfunction due to damaged electronics
        local malfunction = (damagedelectronics > 20 and HF.Chance((damagedelectronics/120)^4))
        if malfunction then
            HF.SpawnItemAt("ntcvfx_malfunction",limb.WorldPosition)
        end
        local locklimb = damagedelectronics >= 99 or bentmetal >= 99 or malfunction
            
        local function lockLimb()
            local limbIdentifierLookup = {}
            limbIdentifierLookup[LimbType.LeftArm] = "lockleftarm"
            limbIdentifierLookup[LimbType.RightArm] = "lockrightarm"
            limbIdentifierLookup[LimbType.LeftLeg] = "lockleftleg"
            limbIdentifierLookup[LimbType.RightLeg] = "lockrightleg"
            if limbIdentifierLookup[limbtype]==nil then return end
            NTC.SetSymptomTrue(character,limbIdentifierLookup[limbtype])
        end

        if locklimb then lockLimb() end

        -- slowdown due to bent metal
        if bentmetal > 5 and (limbtype == LimbType.LeftLeg or limbtype==LimbType.RightLeg) then
            NTC.MultiplySpeed(character,1-(bentmetal/100)*0.5)
        end
    end

    updateLimb(character,LimbType.Torso)
    updateLimb(character,LimbType.Head)
    updateLimb(character,LimbType.LeftLeg)
    updateLimb(character,LimbType.RightLeg)
    updateLimb(character,LimbType.LeftArm)
    updateLimb(character,LimbType.RightArm)

    if HF.HasAfflictionLimb(character, "ntc_cyberliver", LimbType.Torso, 1) then
        NTC.SetMultiplier(character, "liverdamagegain", 1 - HF.GetAfflictionStrengthLimb(character, LimbType.Torso, "ntc_cyberliver", 0) / 200) -- 0.25 (augmented) or 0.5 (cybernetic)
    end
    if HF.HasAfflictionLimb(character, "ntc_cyberkidney", LimbType.Torso, 1) then
        NTC.SetMultiplier(character, "kidneydamagegain", 1 - HF.GetAfflictionStrengthLimb(character, LimbType.Torso, "ntc_cyberkidney", 0) / 200) -- 0.25 (augmented) or 0.5 (cybernetic)
    end
    if HF.HasAfflictionLimb(character, "ntc_cyberlung", LimbType.Torso, 1) then
        NTC.SetMultiplier(character, "lungdamagegain", 1 - HF.GetAfflictionStrengthLimb(character, LimbType.Torso, "ntc_cyberlung", 0) / 200) -- 0.25 (augmented) or 0.5 (cybernetic)
        NTC.SetMultiplier(character, "pneumothoraxchance", 1 - HF.GetAfflictionStrengthLimb(character, LimbType.Torso, "ntc_cyberlung", 0) / 200) -- 0.25 (augmented) or 0.5 (cybernetic)
        NTC.SetMultiplier(character, "hypoxemia", 1 - HF.GetAfflictionStrengthLimb(character, LimbType.Torso, "ntc_cyberlung", 0) / 200) -- 0.25 (augmented) or 0.5 (cybernetic)
    end
    if HF.HasAfflictionLimb(character, "ntc_cyberheart", LimbType.Torso, 1) then
        -- NT.Afflictions.ntc_cyberheart below also boosts blood pressure normalization rate
        NTC.SetMultiplier(character, "heartdamagegain", 1 - HF.GetAfflictionStrengthLimb(character, LimbType.Torso, "ntc_cyberheart", 0) / 200) -- 0.25 (augmented) or 0.5 (cybernetic)
    end
    if HF.HasAfflictionLimb(character, "ntc_cyberbrain", LimbType.Torso, 1) then
        -- NT.Afflictions.ntc_cyberbrain below also boosts neurotrauma healing rate
        NTC.SetMultiplier(character, "neurotraumagain", 1 - HF.GetAfflictionStrengthLimb(character, LimbType.Torso, "ntc_cyberbrain", 0) / 200) -- 0.25 (augmented) or 0.5 (cybernetic)
    end

    local cyberpsychosisChance = NTConfig.Get("NTCyb_cyberpsychosisChance", 1)
    if cyberpsychosisChance ~= 1 then
        HF.SetAffliction(character,"ntc_cyberpsychosis_resistance", 100 * (1-cyberpsychosisChance))
    else
        HF.SetAffliction(character,"ntc_cyberpsychosis_resistance", 0)
    end
end

function NTCyb.ConvertDamageTypes(character,limbtype)

    -- local function isExtremity() 
    --     return not limbtype==LimbType.Torso and not limbtype==LimbType.Head
    -- end

    if NTCyb.HF.LimbIsCyber(character,limbtype) then
        
        -- /// fetch stats ///

        -- physical damage types
        local bleeding = HF.GetAfflictionStrengthLimb(character,limbtype,"bleeding",0)
        local burn = HF.GetAfflictionStrengthLimb(character,limbtype,"burn",0)
        local lacerations = HF.GetAfflictionStrengthLimb(character,limbtype,"lacerations",0)
        local gunshotwound = HF.GetAfflictionStrengthLimb(character,limbtype,"gunshotwound",0)
        local bitewounds = HF.GetAfflictionStrengthLimb(character,limbtype,"bitewounds",0)
        local explosiondamage = HF.GetAfflictionStrengthLimb(character,limbtype,"explosiondamage",0)
        local blunttrauma = HF.GetAfflictionStrengthLimb(character,limbtype,"blunttrauma",0)
        local internaldamage = HF.GetAfflictionStrengthLimb(character,limbtype,"internaldamage",0)
        local foreignbody = HF.GetAfflictionStrengthLimb(character,limbtype,"foreignbody",0)

        -- cyber stats
        local loosescrews = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_loosescrews",0)
        local prevloosescrews = loosescrews
        local damagedelectronics = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_damagedelectronics",0)
        local prevdamagedelectronics = damagedelectronics
        local bentmetal = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_bentmetal",0)
        local prevbentmetal = bentmetal
        local materialloss = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_materialloss",0)
        local prevmaterialloss = materialloss

        -- calculate damage conversion

        local function damageChance(val,chance)
            if val > 0.01 and HF.Chance(chance) then return val end
            return 0
        end

        loosescrews = loosescrews + 1*(
            0.25*damageChance(lacerations,0.75)+
            1*damageChance(explosiondamage,0.8)+
            0.5*damageChance(blunttrauma,0.5)+
            1*damageChance(internaldamage,0.75)+
            0.5*damageChance(bitewounds,0.5)+
            0.75*damageChance(foreignbody,0.75))

        damagedelectronics = damagedelectronics + 0.5*(1+prevmaterialloss/50)*(
            2*damageChance(burn,0.75)+
            0.75*damageChance(gunshotwound,0.85)+
            0.25*damageChance(bitewounds,0.5)+
            0.5*damageChance(explosiondamage,0.5)+
            1*damageChance(blunttrauma,0.5)+
            1*damageChance(internaldamage,0.75)+
            0.75*damageChance(foreignbody,0.75))

        bentmetal = bentmetal + 1*(
            0.25*damageChance(burn,0.85)+
            0.25*damageChance(lacerations,0.5)+
            0.5*damageChance(bitewounds,0.5)+
            1*damageChance(explosiondamage,0.85)+
            2*damageChance(blunttrauma,0.75))

        materialloss = materialloss + (1+prevloosescrews/50)*(
            0.5*damageChance(lacerations,0.75)+
            0.8*damageChance(gunshotwound,0.8)+
            0.6*damageChance(bitewounds,0.75)+
            1*explosiondamage+
            0.5*damageChance(foreignbody,0.8))


        -- /// apply changes ///

        HF.ApplyAfflictionChangeLimb(character,limbtype,"burn",0,burn,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"bleeding",0,bleeding,0,100)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"lacerations",0,lacerations,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"gunshotwound",0,gunshotwound,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"bitewounds",0,bitewounds,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"explosiondamage",0,explosiondamage,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"blunttrauma",0,blunttrauma,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"internaldamage",0,internaldamage,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"foreignbody",0,foreignbody,0,100)
        
        HF.ApplyAfflictionChangeLimb(character,limbtype,"ntc_loosescrews",loosescrews,prevloosescrews,0,100)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"ntc_damagedelectronics",damagedelectronics,prevdamagedelectronics,0,100)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"ntc_bentmetal",bentmetal,prevbentmetal,0,100)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"ntc_materialloss",materialloss,prevmaterialloss,0,100)
        

        NT.DislocateLimb(character,limbtype,-1000)
        NT.BreakLimb(character,limbtype,-1000)
        NT.ArteryCutLimb(character,limbtype,-1000)

        HF.SetAfflictionLimb(character,"arteriesclamp",limbtype,0)
        HF.SetAfflictionLimb(character,"surgeryincision",limbtype,0)
        HF.SetAfflictionLimb(character,"clampedbleeders",limbtype,0)
        HF.SetAfflictionLimb(character,"drilledbones",limbtype,0)
        HF.SetAfflictionLimb(character,"retractedskin",limbtype,0)
        HF.SetAfflictionLimb(character,"suturedi",limbtype,0)
        HF.SetAfflictionLimb(character,"suturedw",limbtype,0)

        if limbtype == LimbType.LeftLeg then
            HF.SetAffliction(character,"tll_amputation",0)
            HF.SetAffliction(character,"sll_amputation",0)
        end
        if limbtype == LimbType.RightLeg then
            HF.SetAffliction(character,"trl_amputation",0)
            HF.SetAffliction(character,"srl_amputation",0)
        end
        if limbtype == LimbType.LeftArm then
            HF.SetAffliction(character,"tla_amputation",0)
            HF.SetAffliction(character,"sla_amputation",0)
        end
        if limbtype == LimbType.RightArm then
            HF.SetAffliction(character,"tra_amputation",0)
            HF.SetAffliction(character,"sra_amputation",0)
        end

    end
end

local limbtypes = {
    LimbType.Torso,
    LimbType.Head,
    LimbType.LeftArm,
    LimbType.RightArm,
    LimbType.LeftLeg,
    LimbType.RightLeg,
}

Timer.Wait(function() 

    -- override bone damage to factor in cyberlimbs
    NT.Afflictions.bonedamage={update=function(c,i)
        if c.stats.stasis then return end
        c.afflictions[i].strength = NT.organDamageCalc(c,c.afflictions.bonedamage.strength + NTC.GetMultiplier(c.character,"bonedamagegain")*(c.afflictions.sepsis.strength/500 + c.afflictions.hypoxemia.strength/1000 + math.max(c.afflictions.radiationsickness.strength-25,0)/600)*NT.Deltatime)
        if(c.afflictions[i].strength < 90) then c.afflictions[i].strength = c.afflictions[i].strength - (c.stats.bonegrowthCount*0.3) * NT.Deltatime
        elseif(c.stats.bonegrowthCount + c.stats.cyberlimbCount >= 6) then c.afflictions[i].strength = c.afflictions[i].strength - 2 * NT.Deltatime end
        if(c.afflictions.kidneydamage.strength > 70) then c.afflictions[i].strength = c.afflictions[i].strength + (c.afflictions.kidneydamage.strength-70)/30*0.15*NT.Deltatime end
    end}

    NT.CharStats.cyberlimbCount={getter=function(c)
        local res = 0
        for type in limbtypes do
            if NTCyb.HF.LimbIsCyber(c.character,type) then res=res+1 end
        end
        return res
    end
    }

    NT.Afflictions.ntc_cyberheart={update=function(c,i)
        if c.stats.stasis then return end
        if c.afflictions.cardiacarrest.strength < 0.1 then
            -- grant an extra 50-100% of the natural BP stabilization rate
            -- this helps BP restore to normal faster after bloodloss is fixed, and can reduce/slow the negative impact of the many BP modifying effects
            if (c.stats.bloodamount > c.afflictions.bloodpressure.strength and c.afflictions.bloodpressure.strength < 100)
            or (c.stats.bloodamount < c.afflictions.bloodpressure.strength and c.afflictions.bloodpressure.strength > 100) then
                local cyberorganQuality = c.afflictions.ntc_cyberheart.strength / 100 -- 0.5 for augmented, 1 for cybernetic
                c.afflictions.bloodpressure.strength = HF.Clamp(HF.Round(
                    HF.Lerp(c.afflictions.bloodpressure.strength, c.stats.bloodamount, 0.2 * cyberorganQuality * NT.Deltatime)
                ,2),5,200)
            end
        end
    end}
    NT.Afflictions.ntc_cyberbrain={update=function(c,i)
        if c.stats.stasis then return end

        -- calculate (using base NT formula) new neurotrauma
        local gain =
            ( -0.1*c.stats.healingrate +                        -- passive regen
            c.afflictions.hypoxemia.strength/100 +              -- from hypoxemia
            HF.Clamp(c.afflictions.stroke.strength,0,20)*0.1 +  -- from stroke
            c.afflictions.sepsis.strength/100*0.4 +             -- from sepsis
            c.afflictions.liverdamage.strength/800 +            -- from liverdamage
            c.afflictions.kidneydamage.strength/1000 +          -- from kidneydamage
            c.afflictions.traumaticshock.strength/100           -- from traumatic shock
        ) * NT.Deltatime

        local cyberorganQuality = c.afflictions.ntc_cyberbrain.strength / 100 -- 0.5 for augmented, 1 for cybernetic
        local healingByMannitol = 0
        local healingNatural = 0
        if c.afflictions.hypoxemia.strength <= 30 and c.afflictions.bloodpressure.strength >= 70 then
            -- double healing rate of mannitol (1)
            healingByMannitol = (c.afflictions.afmannitol.strength / 100)
        end
        if gain < 0 then
            -- they're naturally getting better, triple natural healing rate
            healingNatural = 0.2 * c.stats.healingrate
        end
        local healing = (healingByMannitol > healingNatural and healingByMannitol or healingNatural)
        if c.afflictions.cerebralhypoxia.strength > 100 then
            -- they're unconcious due to neurotrauma, which is really annoying, and they're getting better so lets just double that again hahahaha
            healing = healing * 2
        end
        c.afflictions.cerebralhypoxia.strength = c.afflictions.cerebralhypoxia.strength - healing * cyberorganQuality * NT.Deltatime
    end}
end,100)