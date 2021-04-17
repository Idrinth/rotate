Rotation = {Abilities={}}

local time = 0
local persons = {t={},h={},r={},m={}}
local types = {t=L"Tank",h=L"Healer",r=L"Ranged",m=L"Melee"}
local function paint()
    local counter = 0
    for ability,settings in pairs(Rotation.Abilities) do
        local offset = 30 * counter
        local window = "RotationAbility"..ability
        if not DoesWindowExist(window) then
            CreateWindowFromTemplate( window, "RotationAbilityTemplate", "Root" )
            LabelSetText(window.."Ability", towstring(ability))
            ButtonSetText(window.."Start", L"Start")
            ButtonSetText(window.."Stop", L"Stop")
        end
        WindowSetShowing(window.."Start", not settings.active)
        WindowSetShowing(window.."Stop", settings.active)
        WindowClearAnchors(window)
        LabelSetText(window.."Type", types[settings.chars])
        LabelSetText(window.."Cooldown", towstring(tostring(settings.frequency).."s"))
        WindowAddAnchor(window, "topleft", "RotationAnchor", "topleft", 0, offset)
        WindowSetShowing(window, true)
        counter = counter + 1
    end
end
local function log(message)
    TextLogAddEntry("Chat", SystemData.ChatLogFilters.SAY, towstring(message))
end
local function delete(ability)
    log("Ability "..ability.." turned off!")
    Rotation.Abilities[ability] = nil
    DestroyWindow("RotationAbility"..ability)
    paint()
end
local function slash(input)
    local mode,ability = input:match("^([a-z1-6]+) ([A-Za-z0-9]+)")
    if not ability or not mode then
        log("You need to set ability("..tostring(ability)..") and mode("..tostring(mode)..")!")
        return
    elseif mode:match("^[tmhr]$") then
        local frequency = input:match(" ([0-9]+)$")
        frequency = tonumber(frequency)
        if frequency < 1 or frequency > 120 then
            log("Frequency out of bounds(1-120)")
            return
        end
        log("Ability "..ability.." turned on!")
        Rotation.Abilities[ability] = {
            frequency=frequency,
            chars=mode,
            counter=0,
            now=0,
            active=true
        }
        paint()
    elseif mode == "off" then
        delete(ability)
    else
        log("Mode "..mode.." unknown")
    end
end
function Rotation.Delete()
    local mouseWin = SystemData.MouseOverWindow.name
    local ability = mouseWin:match("^RotationAbility(.+)Ability$")
    if not ability then
        return
    end
    delete(ability)
end
function Rotation.OnUpdate(elapsed)
    time = time + elapsed
    if time < 1 then
        return
    end
    time = time - 1
    if not GameData.Player.inCombat then
        for ability,settings in pairs(Rotation.Abilities) do
            settings.now = 0
            settings.counter = 0
        end
        return
    end
    for ability,settings in pairs(Rotation.Abilities) do
        if settings.active and #persons[settings.chars] > 0 then
            settings.now = settings.now + 1
        end
    end
    for ability,settings in pairs(Rotation.Abilities) do
        if settings.active and #persons[settings.chars] > 0 then
            local frequency = math.ceil(settings.frequency/#persons[settings.chars])
            if settings.now >= frequency then
                local person = settings.counter%(#persons[settings.chars]) + 1
                AutoChannel.sendChatBand(L"@"..persons[settings.chars][person]..L" "..towstring(ability))
                settings.counter = settings.counter + 1
                if settings.counter > #persons[settings.chars] then
                    settings.counter = 1
                end
                settings.now = settings.now - frequency
                return
            end
        end
    end
end
function Rotation.OnInitialize()
    Rotation.Abilities = Rotation.Abilities or {}
    LibSlash.RegisterSlashCmd("rotate", slash)
    CreateWindow("RotationAnchor", true)
    WindowSetShowing("RotationAnchor", true)
    LayoutEditor.RegisterWindow( "RotationAnchor", L"RotationAnchor",L"", false, false, false, nil )
    RegisterEventHandler(SystemData.Events.GROUP_UPDATED, "Rotation.OnGroupChange")
    Rotation.OnGroupChange()
    paint()
end
function Rotation.OnStop()
    local mouseWin = SystemData.MouseOverWindow.name
    local ability = mouseWin:match("^RotationAbility(.+)Stop")
    if not ability then
        return
    end
    WindowSetShowing("RotationAbility"..ability.."Start", true)
    WindowSetShowing("RotationAbility"..ability.."Stop", false)
    if Rotation.Abilities[ability] then
        Rotation.Abilities[ability].active = false
    end
end
function Rotation.OnStart()
    local mouseWin = SystemData.MouseOverWindow.name
    local ability = mouseWin:match("^RotationAbility(.+)Start")
    if not ability then
        return
    end
    WindowSetShowing("RotationAbility"..ability.."Start", false)
    WindowSetShowing("RotationAbility"..ability.."Stop", true)
    if Rotation.Abilities[ability] then
        Rotation.Abilities[ability].active = true
    end
end
function addPlayer(name, career)
    if not career then
        return
    end
    career = career:match(L"(.*)\^.*")
    if career == L"Disciple of Khaine" or career == L"Zealot" or career == L"Shaman" or career == L"Runepriest" or career == L"Archmage" or career == L"Warrior Priest" then
        persons.h[#persons.h +1] = name
    elseif career == L"Black Orc" or career == L"Blackguard" or career == L"Chosen" or career == L"Ironbreaker" or career == L"Swordmaster" or career == L"Knight of the Blazing Sun" then
        persons.t[#persons.t +1] = name
    elseif career == L"Choppa" or career == L"Marauder" or career == L"Witch Elf" or career == L"Witch Hunter" or career == L"White Lion" or career == L"Slayer" then
        persons.m[#persons.m +1] = name
    elseif career == L"Engineer" or career == L"Magus" or career == L"Squig Herder" or career == L"Sorcerer" or career == L"Bright Wizard" or career == L"Shadow Warrior" then
        persons.r[#persons.r +1] = name
    else
        d(career)
    end
end
function Rotation.OnGroupChange()
    persons = {t={},h={},r={},m={}}
    if IsWarBandActive() or AutoChannel.isScenario() then
        for group, members in pairs(GetBattlegroupMemberData()) do
            for _, player in pairs(members.players) do
                if player and player.name then
                    addPlayer(player.name, player.careerName)
                end
            end
        end
    else
        addPlayer(GameData.Player.name, GameData.Player.career.name)
        for _,player in pairs(GetGroupData()) do
            if player and player.name then
                addPlayer(player.name, player.careerName)
            end
        end
    end
end