--!nocheck
local React = require(script.Parent.Packages.React)
local ReactRoblox = require(script.Parent.Packages.ReactRoblox)
local App = require(script.Parent.App)

return function(target)
	local root = ReactRoblox.createRoot(target)
	root:render(React.createElement(App))

	return function()
		root:unmount()
	end
end
