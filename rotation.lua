Rotation = {}

local abilities = {}
local time = 0
local function log(message)
    TextLogAddEntry("Chat", SystemData.ChatLogFilters.SAY, towstring(message))
end
local function slash(input)
    local mode,ability = input:match("^([a-z1-6]+) ([A-Za-z0-9]+)")
    if not ability or not mode then
        log("You need to set ability("..tostring(ability)..") and mode("..tostring(mode)..")!")
        return
    elseif mode:match("^[1-6][1-6]$") then
        local frequency = input:match(" ([0-9]+)$")
        frequency = tonumber(frequency)
        if frequency < 1 or frequency > 60 then
            log("Frequency out of bounds(1-60)")
            return
        end
        local groups, chars = mode:match("^([1-6])([1-6])$")
        log("Ability "..ability.." turned on!")
        groups = tonumber(groups)
        chars = tonumber(chars)
        abilities[ability] = {
            frequency=math.ceil(frequency/chars/groups),
            chars=chars,
            groups=groups,
            counter=0,
            now=0,
        }
    elseif mode == "off" then
        log("Ability "..ability.." turned off!")
        abilities[ability] = nil
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
        settings.now = settings.now + 1
        if settings.now == settings.frequency then
            local person = settings.counter%settings.chars + 1
            local party = math.floor(settings.counter%settings.chars * settings.groups)/settings.chars+1
            if settings.groups > 1 and (IsWarBandActive() or AutoChannel.isScenario()) then
                AutoChannel.sendChatBandSay(ability..": Party "..tostring(party).." Person "..tostring(person))
            else
                AutoChannel.sendChatPartySay(ability..": Person "..tostring(person))
            end
            settings.counter = settings.counter + 1
            settings.now = 0
            return
        end
    end
end
function Rotation.OnInitialize()
    LibSlash.RegisterSlashCmd("rotate", slash)
end
