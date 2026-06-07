--!strict
local React = require(script.Parent.Parent.Packages.React)

local function useTheme()
	local theme, setTheme = React.useState(settings().Studio.Theme)

	React.useEffect(function()
		local conn = settings().Studio.ThemeChanged:Connect(function()
			setTheme(settings().Studio.Theme)
		end)
		return function()
			conn:Disconnect()
		end
	end, {})

	return theme
end

return useTheme
