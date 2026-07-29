multiTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local keyCode = event:getKeyCode()
  local flags = event:getFlags()

  if keyCode == 33 then
    if flags.ctrl and not (flags.alt or flags.cmd or flags.shift) then
      hs.eventtap.keyStroke({}, "escape", 0)
      return true
    end
  end

  if keyCode == 48 then
    if flags.cmd and not (flags.alt or flags.ctrl or flags.shift) then
      hs.eventtap.keyStroke({"alt"}, "tab", 0)
      return true
    end
  end

if keyCode == 39 then
    if flags.ctrl and not (flags.alt or flags.cmd or flags.shift) then
      hs.eventtap.keyStroke({"alt"}, "tab", 0)
      return true
    end
  end

  if keyCode == 33 then
    if flags.cmd and not (flags.ctrl or flags.alt or flags.shift) then
      hs.eventtap.keyStroke({"cmd", "shift"}, "[", 0)
      return true
    end
  end

  if keyCode == 30 then
    if flags.cmd and not (flags.ctrl or flags.alt or flags.shift) then
      hs.eventtap.keyStroke({"cmd", "shift"}, "]", 0)
      return true
    end
  end

  return false
end)

multiTap:start()
hs.alert.show("Hammerspoon Config Loaded")

