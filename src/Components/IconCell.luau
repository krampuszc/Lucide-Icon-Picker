--!strict
local React = require(script.Parent.Parent.Packages.React)
local useTheme = require(script.Parent.Parent.Hooks.useTheme)

local e = React.createElement

local function IconCell(props: {
	name: string,
	spriteId: string,
	iconSize: number,
	cellSize: number,
	iconX: number,
	iconY: number,
	isSelected: boolean,
	onSelect: (string) -> (),
	position: UDim2,
})
	local theme = useTheme()
	local hovered, setHovered = React.useState(false)

	local modifier = if props.isSelected then Enum.StudioStyleGuideModifier.Selected
		elseif hovered then Enum.StudioStyleGuideModifier.Hover
		else Enum.StudioStyleGuideModifier.Default

	return e("TextButton", {
		Size = UDim2.fromOffset(props.cellSize, props.cellSize),
		Position = props.position,
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button, modifier),
		BackgroundTransparency = if props.isSelected or hovered then 0 else 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		[React.Event.Activated] = function()
			props.onSelect(props.name)
		end,
		[React.Event.MouseEnter] = function()
			setHovered(true)
		end,
		[React.Event.MouseLeave] = function()
			setHovered(false)
		end,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		Icon = e("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(props.iconSize, props.iconSize),
			BackgroundTransparency = 1,
			Image = props.spriteId,
			ImageRectOffset = Vector2.new(props.iconX, props.iconY),
			ImageRectSize = Vector2.new(props.iconSize, props.iconSize),
			ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText, modifier),
		}),
	})
end

return IconCell
