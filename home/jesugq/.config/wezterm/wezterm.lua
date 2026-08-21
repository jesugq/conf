-- startup
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local keys = wezterm.gui.default_keys()

-- theme
config.color_scheme = 'Tokyo Night'
config.window_padding = {
  left = '0pt',
  right = '0pt',
  top = '0pt',
  bottom = '0pt',
}

-- font
config.font_size = 20.0
config.font = wezterm.font('Maple Mono NF')

-- tab bar
config.hide_tab_bar_if_only_one_tab = true

-- keybindings
local function add_sendlinuxmod(target, inputs)
  for _, letter in ipairs(inputs) do
    local literal = string.char(string.byte(letter) - 96)
    table.insert(target, {
      key = letter,
      mods = 'CTRL',
      action = wezterm.action.SendString(literal),
    })
  end
end
local function add_sendmacosmod(target, inputs)
  for _, key in ipairs(inputs) do
    table.insert(target, {
      key = key,
      mods = 'SUPER',
      action = wezterm.action.SendString('\x1b' .. key),
    })
  end
end
local function add_keybindings(target, inputs)
  for _, binding in ipairs(inputs) do
    table.insert(target, {
      key = binding.key,
      mods = binding.mods,
      action = binding.action,
    })
  end
end

-- linux consistency
local linux_letters = {
  --   'i', 'f', 'm',
  --   'n',
  'a', 'b', 'c', 'd', 'e', 'g', 'h', 'j', 'k', 'l',
  'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
}

-- linux support
local linux_bindings = {
  { key = 'Enter', mods = 'ALT', action = wezterm.action.SendString('\x1b\r') },
  { key = '<', mods = 'CTRL|SHIFT', action = wezterm.action.ReloadConfiguration },
  { key = '/', mods = 'CTRL', action = wezterm.action.SendString('\x1b[47;5u') },
  { key = 'i', mods = 'CTRL', action = wezterm.action.SendString('\x1b[105;5u') },
  { key = 'PageUp', mods = 'CTRL', action = wezterm.action.SendKey({ key = 'PageUp', mods = 'CTRL' }) },
  { key = 'PageDown', mods = 'CTRL', action = wezterm.action.SendKey({ key = 'PageDown', mods = 'CTRL' }) },
}

-- macos consistency
local macos_letters = {
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
}

-- macos support
local macos_bindings = {
  { key = 'Enter', mods = 'SUPER', action = wezterm.action.SendString('\x1b\r') },
  { key = ',', mods = 'SUPER|SHIFT', action = wezterm.action.ReloadConfiguration },
  { key = '[', mods = 'SUPER', action = wezterm.action.SendString('\x1b[') },
  { key = ']', mods = 'SUPER', action = wezterm.action.SendString('\x1b]') },
  { key = '{', mods = 'SUPER|SHIFT', action = wezterm.action.SendString('\x1b{') },
  { key = '}', mods = 'SUPER|SHIFT', action = wezterm.action.SendString('\x1b}') },
}

-- globe support
local globe_bindings = {
  { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo('Clipboard') },
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom('Clipboard') },
  { key = 'l', mods = 'CTRL|SHIFT', action = wezterm.action.SendKey({ key = 'l', mods = 'CTRL' }) },
  { key = 'f', mods = 'CTRL|SHIFT', action = wezterm.action.Search('CurrentSelectionOrEmptyString') },
}

-- keybindings
add_sendlinuxmod(keys, linux_letters)
add_sendmacosmod(keys, macos_letters)
add_keybindings(keys, linux_bindings)
add_keybindings(keys, macos_bindings)
add_keybindings(keys, globe_bindings)
config.keys = keys

-- finish
return config
