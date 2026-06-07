--!strict
local React = require(script.Parent.Parent.Packages.React)
local useTheme = require(script.Parent.Parent.Hooks.useTheme)

local e = React.createElement

local function SearchBar(props: { query: string, onChange: (string) -> (), count: number, LayoutOrder: number? })
	local theme = useTheme()

	return e("Frame", {
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder),
		BorderSizePixel = 1,
	}, {
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		Input = e("TextBox", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = props.query,
			PlaceholderText = ("Search %d icons..."):format(props.count),
			Font = Enum.Font.SourceSans,
			TextSize = 16,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			PlaceholderColor3 = theme:GetColor(
				Enum.StudioStyleGuideColor.MainText,
				Enum.StudioStyleGuideModifier.Disabled
			),
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			[React.Change.Text] = function(rbx)
				props.onChange(rbx.Text)
			end,
		}),
	})
end

return SearchBar
