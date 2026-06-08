-- !nocheck
-- Lucide Icon Picker | krampuszc 2026
-- Because i was bored on a sunday night!

if not plugin then
	return
end

local React = require(script.Packages.React)
local ReactRoblox = require(script.Packages.ReactRoblox)
local App = require(script.App)

local widget = plugin:CreateDockWidgetPluginGuiAsync(
	"LucideIconPicker",
	DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Right,
		false, false,
		280, 420,
		200, 300
	)
)
widget.Title = "Icon Picker"
widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local toolbar = plugin:CreateToolbar("Icon Picker")
local button = toolbar:CreateButton(
	"Icon Picker",
	"Toggle Lucide Icon Picker",
	"rbxassetid://138603030095322"
)
button.ClickableWhenViewportHidden = true

button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	button:SetActive(widget.Enabled)
end)

widget:BindToClose(function()
	widget.Enabled = false
	button:SetActive(false)
end)

local root = ReactRoblox.createRoot(widget)
root:render(React.createElement(App, { plugin = plugin }))

plugin.Unloading:Connect(function()
	root:unmount()
end)
