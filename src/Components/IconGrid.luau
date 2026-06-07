--!strict
local React = require(script.Parent.Parent.Packages.React)
local useTheme = require(script.Parent.Parent.Hooks.useTheme)
local IconCell = require(script.Parent.IconCell)

local e = React.createElement

local CELL_SIZE = 36

local function IconGrid(props: {
	icons: { { name: string, spriteId: string, x: number, y: number } },
	iconSize: number,
	selected: string?,
	onSelect: (string) -> (),
	LayoutOrder: number?,
	onHover: (name:string?, position:Vector2?) -> ()
})
	local theme = useTheme()
	local scrollY, setScrollY = React.useState(0)
	local viewSize, setViewSize = React.useState(Vector2.new(280, 380))

	local cols = math.max(1, math.floor(viewSize.X / CELL_SIZE))
	local totalRows = math.ceil(#props.icons / cols)
	local totalHeight = totalRows * CELL_SIZE

	local BUFFER = 2
	local firstRow = math.max(0, math.floor(scrollY / CELL_SIZE) - BUFFER)
	local lastRow = math.min(totalRows - 1, math.ceil((scrollY + viewSize.Y) / CELL_SIZE) + BUFFER)

	local cells: { [string]: React.ReactElement<any> } = {}
	for row = firstRow, lastRow do
		for col = 0, cols - 1 do
			local idx = row * cols + col + 1
			local icon = props.icons[idx]
			if not icon then break end
			cells[icon.name] = e(IconCell, {
				key = icon.name,
				name = icon.name,
				spriteId = icon.spriteId,
				iconSize = props.iconSize,
				cellSize = CELL_SIZE,
				iconX = icon.x,
				iconY = icon.y,
				isSelected = props.selected == icon.name,
				onSelect = props.onSelect,
				position = UDim2.fromOffset(col * CELL_SIZE, row * CELL_SIZE),
				onHover = props.onHover,
			})
		end
	end

	return e("ScrollingFrame", {
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.new(1, 0, 1, -34 - 40),
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
		BorderSizePixel = 1,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar),
		CanvasSize = UDim2.fromOffset(0, totalHeight),
		[React.Change.CanvasPosition] = function(rbx: ScrollingFrame)
			setScrollY(rbx.CanvasPosition.Y)
		end,
		[React.Change.AbsoluteSize] = function(rbx: ScrollingFrame)
			setViewSize(rbx.AbsoluteSize)
		end,
		[React.Event.MouseLeave] = function()
			props.onHover(nil, nil)
		end,
	}, cells)
end

return IconGrid
