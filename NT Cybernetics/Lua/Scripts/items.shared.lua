
NTCyb.AllowInHealthInterface = {
    -- general compatability if anything has a higher mod load order than us
    "crowbar",
    "screwdriver",
    "steel",
    "fpgacircuit",
    -- Immersive Repairs compatibility
    "weldingtool",
    "weldingstinger",
    "repairpack",
    "halligantool",
    -- EK Mods compatibility
    "ekutility_metalfoam_gun",
    "ekutility_hullrepairkit",
    "ekutility_arcwelder"
}

local function evaluateExtraUseInHealthInterface()
    LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.ItemPrefab"], "set_UseInHealthInterface")
    for _, tool in ipairs(NTCyb.AllowInHealthInterface) do
        if ItemPrefab.Prefabs.ContainsKey(tool) then
            ItemPrefab.Prefabs[tool].set_UseInHealthInterface(true)
        end
    end
end

-- todo: can we move these into a new type of xml file?
NTCyb.ExtraSkillRequirementHints = {
    [[
        <ExtraSkillRequirementHints identifier="steel">
            <SkillRequirementHint identifier="mechanical" level="60" />
        </ExtraSkillRequirementHints>
    ]],
    [[
        <ExtraSkillRequirementHints identifier="fpgacircuit">
            <SkillRequirementHint identifier="electrical" level="40" />
        </ExtraSkillRequirementHints>
    ]],
    [[
        <ExtraSkillRequirementHints identifier="screwdriver">
            <SkillRequirementHint identifier="mechanical" level="40" />
        </ExtraSkillRequirementHints>
    ]],
    [[
        <ExtraSkillRequirementHints identifier="screwdriverhardened">
            <SkillRequirementHint identifier="mechanical" level="40" />
        </ExtraSkillRequirementHints>
    ]],
    [[
        <ExtraSkillRequirementHints identifier="screwdriverdementonite">
            <SkillRequirementHint identifier="mechanical" level="40" />
        </ExtraSkillRequirementHints>
    ]],
    [[
        <ExtraSkillRequirementHints identifier="weldingtool">
            <SkillRequirementHint identifier="mechanical" level="50" />
        </ExtraSkillRequirementHints>
    ]],
    [[
        <ExtraSkillRequirementHints identifier="weldingstinger">
            <SkillRequirementHint identifier="mechanical" level="50" />
        </ExtraSkillRequirementHints>
    ]],
    [[
        <ExtraSkillRequirementHints identifier="repairpack">
            <SkillRequirementHint identifier="mechanical" level="40" />
        </ExtraSkillRequirementHints>
    ]],
    [[
        <ExtraSkillRequirementHints identifier="ekutility_metalfoam_gun">
            <SkillRequirementHint identifier="mechanical" level="60" />
        </ExtraSkillRequirementHints>
    ]],
    [[
        <ExtraSkillRequirementHints identifier="ekutility_hullrepairkit">
            <SkillRequirementHint identifier="mechanical" level="60" />
        </ExtraSkillRequirementHints>
    ]],
    [[
        <ExtraSkillRequirementHints identifier="ekutility_arcwelder">
            <SkillRequirementHint identifier="mechanical" level="50" />
        </ExtraSkillRequirementHints>
    ]],
}


local function addNullableImmutableArrayElements(builder, array)
    local success, length = pcall(function()
        return array.Length -- this throws (making pcall return false) if the array is null, and I can't find a better way to check for null
    end)
    if success then
        for i = 0, length - 1 do
            if not builder.Contains(array[i]) then
                builder.Add(array[i])
            end
        end
    end
end
local function evaluateExtraSkillRequirementHints()
    LuaUserData.RegisterType('System.Collections.Immutable.ImmutableArray`1')
    LuaUserData.RegisterType('System.Collections.Immutable.ImmutableArray')
    LuaUserData.RegisterType('System.Collections.Immutable.ImmutableArray`1+Builder') -- todo is this wanted
    local ImmutableArray = LuaUserData.CreateStatic('System.Collections.Immutable.ImmutableArray')
    LuaUserData.RegisterType('Barotrauma.SkillRequirementHint')
    SkillRequirementHint = LuaUserData.CreateStatic('Barotrauma.SkillRequirementHint')
    LuaUserData.MakeMethodAccessible(Descriptors['Barotrauma.ItemPrefab'], 'set_SkillRequirementHints')

    for _, xml in ipairs(NTCyb.ExtraSkillRequirementHints) do
        local xdoc = XDocument.Parse(xml)
        local itemIdentifier = xdoc.Root.GetAttributeString("identifier")
        if ItemPrefab.Prefabs.ContainsKey(itemIdentifier) then
            local item = ItemPrefab.Prefabs[itemIdentifier]
            local skillReqsBuilder = ImmutableArray.CreateBuilder(SkillRequirementHint)
            addNullableImmutableArrayElements(skillReqsBuilder, item.get_SkillRequirementHints())
            for element in xdoc.Root.Elements() do
                local skillReq = SkillRequirementHint.__new(ContentXElement(item.ContentPackage, element))
                if not skillReqsBuilder.Contains(skillReq) then
                    skillReqsBuilder.Add(skillReq)
                end
            end
            item.set_SkillRequirementHints(skillReqsBuilder.ToImmutable())
        end
    end
end

NTCyb.ExtraTreatmentSuitability = {
    [[
        <ExtraTreatmentSuitability identifier="steel">
            <SuitableTreatment identifier="ntc_materialloss" suitability="50"/>
        </ExtraTreatmentSuitability>
    ]],
    [[
        <ExtraTreatmentSuitability identifier="fpgacircuit">
            <SuitableTreatment identifier="ntc_damagedelectronics" suitability="50"/>
        </ExtraTreatmentSuitability>
    ]],
    [[
        <ExtraTreatmentSuitability identifier="screwdriver">
            <SuitableTreatment identifier="ntc_loosescrews" suitability="50"/>
        </ExtraTreatmentSuitability>
    ]],
    [[
        <ExtraTreatmentSuitability identifier="screwdriverhardened">
            <SuitableTreatment identifier="ntc_loosescrews" suitability="50"/>
        </ExtraTreatmentSuitability>
    ]],
    [[
        <ExtraTreatmentSuitability identifier="screwdriverdementonite">
            <SuitableTreatment identifier="ntc_loosescrews" suitability="50"/>
        </ExtraTreatmentSuitability>
    ]],
    [[
        <ExtraTreatmentSuitability identifier="weldingtool">
            <SuitableTreatment identifier="ntc_bentmetal" suitability="50"/>
        </ExtraTreatmentSuitability>
    ]],
    [[
        <ExtraTreatmentSuitability identifier="repairpack">
            <SuitableTreatment identifier="ntc_loosescrews" suitability="50"/>
        </ExtraTreatmentSuitability>
    ]],
    [[
        <ExtraTreatmentSuitability identifier="weldingstinger">
            <SuitableTreatment identifier="ntc_bentmetal" suitability="50"/>
        </ExtraTreatmentSuitability>
    ]],
    [[
        <ExtraTreatmentSuitability identifier="ekutility_metalfoam_gun">
            <SuitableTreatment identifier="ntc_materialloss" suitability="50"/>
        </ExtraTreatmentSuitability>
    ]],
    [[
        <ExtraTreatmentSuitability identifier="ekutility_hullrepairkit">
            <SuitableTreatment identifier="ntc_materialloss" suitability="50"/>
        </ExtraTreatmentSuitability>
    ]],
    [[
        <ExtraTreatmentSuitability identifier="ekutility_arcwelder">
            <SuitableTreatment identifier="ntc_bentmetal" suitability="50"/>
        </ExtraTreatmentSuitability>
    ]],
}

local function evaluateExtraTreatmentSuitability()
    LuaUserData.MakeFieldAccessible(Descriptors['Barotrauma.ItemPrefab'], 'treatmentSuitability')
    LuaUserData.RegisterType('System.Single')
    local SystemSingle = LuaUserData.CreateStatic('System.Single')
    LuaUserData.RegisterType('System.Collections.Immutable.ImmutableDictionary')
    LuaUserData.RegisterType('System.Collections.Immutable.ImmutableDictionary`2')
    LuaUserData.RegisterType('System.Collections.Immutable.ImmutableDictionary`2+Builder')
    local ImmutableDictionary = LuaUserData.CreateStatic('System.Collections.Immutable.ImmutableDictionary')

    for _, xml in ipairs(NTCyb.ExtraTreatmentSuitability) do
        local xdoc = XDocument.Parse(xml)
        local itemIdentifier = xdoc.Root.GetAttributeString("identifier")
        if ItemPrefab.Prefabs.ContainsKey(itemIdentifier) then
            local item = ItemPrefab.Prefabs[itemIdentifier]
            local dictBuilder = ImmutableDictionary.CreateBuilder(Identifier, SystemSingle)
            for element in xdoc.Root.Elements() do
                dictBuilder.Add(Identifier(element.GetAttributeString("identifier")), SystemSingle.Parse(element.GetAttributeString("suitability")))
            end
            item.treatmentSuitability = dictBuilder.ToImmutable()
            item.set_UseInHealthInterface(true)
        end
    end
end

local function addCyberOrgansToSuperSoldiersTalent()
    local supersoldiersTalent = TalentPrefab.TalentPrefabs["supersoldiers"]
    if supersoldiersTalent ~= nil then
        local xmlDefinition = [[
            <overwrite>
                <AddedRecipe itemidentifier="cyberliver" />
                <AddedRecipe itemidentifier="cyberkidney" />
                <AddedRecipe itemidentifier="cyberlung" />
                <AddedRecipe itemidentifier="cyberheart" />
                <AddedRecipe itemidentifier="cyberbrain" />
            </overwrite>
        ]]
        local xml = XDocument.Parse(xmlDefinition)
        for element in xml.Root.Elements() do
            supersoldiersTalent.ConfigElement.Element.Add(element)
        end

        for descNode in supersoldiersTalent.ConfigElement.GetChildElements("Description") do
            if descNode.GetAttributeString("tag") == "talentdescription.unlockrecipe" then
                for replaceTag in descNode.Elements() do
                    replaceTag.SetAttributeValue("value", replaceTag.GetAttributeString("value") .. ",entityname.cyberliver,entityname.cyberkidney,entityname.cyberlung,entityname.cyberheart,entityname.cyberbrain")
                    break
                end
            end
        end
        while TalentPrefab.TalentPrefabs.ContainsKey("supersoldiers") do
            -- remove all existing versions of this talent (including overrides), as we're going to add a new combined one on top
            TalentPrefab.TalentPrefabs.Remove(TalentPrefab.TalentPrefabs["supersoldiers"])
        end
        TalentPrefab.TalentPrefabs.Add(TalentPrefab.__new(supersoldiersTalent.ConfigElement, supersoldiersTalent.ContentFile), false)
    end
end


Timer.Wait(function()
    addCyberOrgansToSuperSoldiersTalent()
    evaluateExtraUseInHealthInterface()
    evaluateExtraSkillRequirementHints()
    evaluateExtraTreatmentSuitability()
end, 1)
