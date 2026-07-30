-- startup
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local keys = wezterm.gui.default_keys()
local key_tables = wezterm.gui.default_key_tables()

-- theme
config.color_scheme = 'Tokyo Night'
config.skip_close_confirmation_for_processes_named = {}

-- font
config.font = wezterm.font('CommitMono')
config.font_size = 20.0

-- tab bar
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 32
config.status_update_interval = 500
config.colors = {
  tab_bar = {
    background = '#16161e',
    active_tab = {
      bg_color = '#3b4261',
      fg_color = '#bec8f3',
      intensity = 'Normal',
    },
    inactive_tab = {
      bg_color = '#16161e',
      fg_color = '#737aa2',
      intensity = 'Normal',
    },
  },
}

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

-- leader
config.leader = { key = ' ', mods = 'CTRL', timeout_milliseconds = 1000 }

-- linux consistency
local linux_letters = {
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
}

-- linux support
local linux_bindings = {
  { key = '<', mods = 'CTRL|SHIFT', action = wezterm.action.ReloadConfiguration },
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
  { key = '[', mods = 'SUPER', action = wezterm.action.ActivateTabRelative(-1) },
  { key = ']', mods = 'SUPER', action = wezterm.action.ActivateTabRelative(1) },
  { key = '{', mods = 'SUPER', action = wezterm.action.ActivateTabRelative(-1) },
  { key = '}', mods = 'SUPER', action = wezterm.action.ActivateTabRelative(1) },
}

-- globe support
local globe_bindings = {
  { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo('Clipboard') },
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom('Clipboard') },
  { key = 'l', mods = 'CTRL|SHIFT', action = wezterm.action.SendKey({ key = 'l', mods = 'CTRL' }) },
}

-- windows
local window_bindings = {
  { key = '[', mods = 'LEADER', action = wezterm.action.MoveTabRelative(-1) },
  { key = ']', mods = 'LEADER', action = wezterm.action.MoveTabRelative(1) },
  { key = 'c', mods = 'LEADER', action = wezterm.action.SpawnTab('CurrentPaneDomain') },
  { key = 'x', mods = 'LEADER', action = wezterm.action.CloseCurrentTab({ confirm = true }) },
  {
    key = 'r',
    mods = 'LEADER',
    action = wezterm.action.PromptInputLine({
      description = 'Enter new name for tab',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    }),
  },
  {
    key = 'R',
    mods = 'LEADER',
    action = wezterm.action.PromptInputLine({
      description = 'Enter new name for workspace',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
        end
      end),
    }),
  },
  { key = 'f', mods = 'LEADER', action = wezterm.action.ActivateCopyMode },
}

-- copy mode
local copy_bindings = {
  { key = '/', mods = 'NONE', action = wezterm.action.CopyMode 'EditPattern' },
  { key = '?', mods = 'NONE', action = wezterm.action.CopyMode 'EditPattern' },
  { key = 'n', mods = 'NONE', action = wezterm.action.CopyMode 'NextMatch' },
  { key = 'N', mods = 'SHIFT', action = wezterm.action.CopyMode 'PriorMatch' },
  { key = 'q', mods = 'NONE', action = wezterm.action.CopyMode 'Close' },
  {
    key = 'y',
    mods = 'NONE',
    action = wezterm.action.Multiple {
      wezterm.action.CopyTo 'PrimarySelection',
      wezterm.action.ClearSelection,
      wezterm.action.CopyMode 'ClearSelectionMode',
    }
  },
  { key = 'Escape', mods = 'NONE', action = wezterm.action.Nop },
}
local search_bindings = {
  { key = 'Enter', mods = 'NONE', action = wezterm.action.CopyMode 'AcceptPattern' },
  {
    key = 'Escape',
    mods = 'NONE',
    action = wezterm.action.Multiple({
      wezterm.action.CopyMode 'ClearPattern',
      wezterm.action.CopyMode 'AcceptPattern',
    })
  },
  { key = 'Escape', mods = 'NONE', action = wezterm.action.CopyMode 'ClearPattern' },
}

-- plugins
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
tabline.setup {
  options = {
    icons_enabled = true,
    theme = 'Tokyo Night',
    tabs_enabled = false,
  },
  sections = {
    tabline_a = { 'mode' },
    tabline_b = { { 'domain', fmt = function(str) return ' ' .. str end, } },
    tabline_c = {},
    tabline_x = {},
    tabline_y = { { 'workspace', fmt = function(str) return ' ' .. str end, } },
    tabline_z = { 'datetime' },
  },
}

-- keybindings
add_sendlinuxmod(keys, linux_letters)
add_sendmacosmod(keys, macos_letters)
add_keybindings(keys, linux_bindings)
add_keybindings(keys, macos_bindings)
add_keybindings(keys, globe_bindings)
add_keybindings(keys, window_bindings)
add_keybindings(key_tables.copy_mode, copy_bindings)
add_keybindings(key_tables.search_mode, search_bindings)

-- finish
config.keys = keys
config.key_tables = key_tables
return config
