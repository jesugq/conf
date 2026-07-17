multiTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local keyCode = event:getKeyCode()
    local flags = event:getFlags()

    if keyCode == 48 then
        if flags.cmd and not (flags.alt or flags.ctrl or flags.shift) then
            hs.eventtap.keyStroke({"alt"}, "tab", 0)
            return true
        end
    end

    if keyCode == 33 then
        if flags.ctrl then
            hs.eventtap.keyStroke({}, "escape", 0)
            return true
        end
    end

    if keyCode == 33 then
        if flags.alt and not (flags.ctrl or flags.cmd or flags.shift) then
            hs.eventtap.keyStroke({"alt", "shift"}, "[", 0)
            return true
        end
    end

    if keyCode == 33 then
        if flags.alt and not (flags.ctrl or flags.cmd or flags.shift) then
            hs.eventtap.keyStroke({"alt", "shift"}, "[", 0)
            return true
        end
    end

    return false
end)

multiTap:start()
hs.alert.show("Hammerspoon Config Loaded")

