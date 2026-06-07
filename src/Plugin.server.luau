--!nocheck
local React = require(script.Packages.React)
local ReactRoblox = require(script.Packages.ReactRoblox)
local App = require(script.App)

local widget = plugin:CreateDockWidgetPluginGuiAsync(
	"BetterIconPicker",
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
	"BetterIconPicker_toggle",
	"Toggle Icon Picker",
	"rbxassetid://7734199131"
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
