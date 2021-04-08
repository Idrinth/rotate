Rotation = {}

local abilities = {}
local time = 0
local function paint()
    local counter = 0
    for ability,settings in pairs(abilities) do
        local offset = 30 * counter
        local window = "RotationAbility"..ability
        if not DoesWindowExist(window) then
            CreateWindowFromTemplate( window, "RotationAbilityTemplate", "Root" )
            LabelSetText(window.."Ability", towstring(ability))
            ButtonSetText(window.."Start", L"Start")
            ButtonSetText(window.."Stop", L"Stop")
            WindowSetShowing(window.."Start", false)
            WindowSetShowing(window.."Stop", true)
        end
        WindowClearAnchors(window)
        ButtonSetCheckButtonFlag(window.."Group", settings.groups==1)
        WindowAddAnchor(window, "topleft", "RotationAnchor", "topleft", 0, offset)
        WindowSetShowing(window, true)
        counter = counter + 1
    end
end
local function log(message)
    TextLogAddEntry("Chat", SystemData.ChatLogFilters.SAY, towstring(message))
end
local function slash(input)
    local mode,ability = input:match("^([a-z1-6]+) ([A-Za-z0-9]+)")
    if not ability or not mode then
        log("You need to set ability("..tostring(ability)..") and mode("..tostring(mode)..")!")
        return
    elseif mode:match("^[14][1-6]$") then
        local frequency = input:match(" ([0-9]+)$")
        frequency = tonumber(frequency)
        if frequency < 1 or frequency > 60 then
            log("Frequency out of bounds(1-60)")
            return
        end
        local groups, chars = mode:match("^([14])([1-6])$")
        log("Ability "..ability.." turned on!")
        groups = tonumber(groups)
        chars = tonumber(chars)
        abilities[ability] = {
            frequency=frequency,
            chars=chars,
            groups=groups,
            counter=0,
            now=0,
            active=true
        }
        paint()
    elseif mode == "off" then
        log("Ability "..ability.." turned off!")
        abilities[ability] = nil
        DestroyWindow("RotationAbility"..ability)
        paint()
    else
        log("Mode "..mode.." unknown")
    end
end
function Rotation.OnUpdate(elapsed)
    time = time + elapsed
    if time < 1 then
        return
    end
    time = time - 1
    if not GameData.Player.inCombat then
        for ability,settings in pairs(abilities) do
            settings.now = 0
            settings.counter = 0
        end
        return
    end
    for ability,settings in pairs(abilities) do
        if settings.active then
            settings.now = settings.now + 1
            local multiparty = settings.groups > 1 and (IsWarBandActive() or AutoChannel.isScenario());
            local frequency = settings.frequency/settings.chars
            if multiparty then
                frequency = frequency/settings.groups
            end
            frequency = math.ceil(frequency)
            if settings.now == frequency then
                local person = settings.counter%settings.chars + 1
                local party = math.floor(settings.counter%settings.chars * settings.groups)/settings.chars+1
                if multiparty then
                    AutoChannel.sendChatBandSay(ability..": Party "..tostring(party).." Person "..tostring(person))
                else
                    AutoChannel.sendChatPartySay(ability..": Person "..tostring(person))
                end
                settings.counter = settings.counter + 1
                if settings.counter > settings.chars * settings.groups then
                    settings.counter = 1
                end
                settings.now = 0
                return
            end
        end
    end
end
function Rotation.OnInitialize()
    LibSlash.RegisterSlashCmd("rotate", slash)
    CreateWindow("RotationAnchor", true)
    WindowSetShowing("RotationAnchor", true)
    LayoutEditor.RegisterWindow( "RotationAnchor", L"RotationAnchor",L"", false, false, false, nil )
end
function Rotation.OnStop()
    local mouseWin = SystemData.MouseOverWindow.name
    local ability = mouseWin:match("^RotationAbility(.+)Stop")
    WindowSetShowing("RotationAbility"..ability.."Start", true)
    WindowSetShowing("RotationAbility"..ability.."Stop", false)
    if abilities[ability] then
        abilities[ability].active = false
    end
end
function Rotation.OnStart()
    local mouseWin = SystemData.MouseOverWindow.name
    local ability = mouseWin:match("^RotationAbility(.+)Start")
    WindowSetShowing("RotationAbility"..ability.."Start", false)
    WindowSetShowing("RotationAbility"..ability.."Stop", true)
    if abilities[ability] then
        abilities[ability].active = true
    end
end
function Rotation.SwitchMode()
    local mouseWin = SystemData.MouseOverWindow.name
    local ability = mouseWin:match("^RotationAbility(.+)Start")
    local isGroup = not ButtonGetCheckButtonFlag(SystemData.MouseOverWindow.name)
    ButtonSetCheckButtonFlag(SystemData.MouseOverWindow.name, isGroup)
    if isGroup and abilities[ability] then
        abilities[ability].groups = 1
    elseif abilities[ability] then
        abilities[ability].groups = 4
    end
end