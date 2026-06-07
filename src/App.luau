--!nocheck
local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local React = require(script.Parent.Packages.React)
local useTheme = require(script.Parent.Hooks.useTheme)
local SearchBar = require(script.Parent.Components.SearchBar)
local IconGrid = require(script.Parent.Components.IconGrid)
local Assets = require(script.Parent.Modules.Assets)
local Matcher = require(script.Parent.Modules.Matcher)

local e = React.createElement

local ALL_ICONS = {}
local ALL_NAMES = {}
for name, pos in pairs(Assets.icons) do
	table.insert(ALL_ICONS, { name = name, spriteId = Assets.sprites[pos[1]], x = pos[2], y = pos[3] })
	table.insert(ALL_NAMES, name)
end
table.sort(ALL_ICONS, function(a, b) return a.name < b.name end)
table.sort(ALL_NAMES)

local function search(query: string)
	if query:match("^%s*$") then
		return ALL_ICONS
	end
	local ranked = Matcher.new(ALL_NAMES, true, true):match(query)
	local result = {}
	for _, name in ipairs(ranked) do
		local pos = Assets.icons[name]
		if pos then
			table.insert(result, { name = name, spriteId = Assets.sprites[pos[1]], x = pos[2], y = pos[3] })
		end
	end
	return result
end

local function applyIcon(name: string)
	local pos = Assets.icons[name]
	if not pos then return end
	local selection = Selection:Get()
	if #selection == 0 then return end

	local spriteId = Assets.sprites[pos[1]]
	local rectOffset = Vector2.new(pos[2], pos[3])
	local rectSize = Vector2.new(Assets.iconSize, Assets.iconSize)

	ChangeHistoryService:SetWaypoint("Apply icon " .. name)
	for _, obj in selection do
		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			obj.Image = spriteId
			obj.ImageRectOffset = rectOffset
			obj.ImageRectSize = rectSize
		else
			local label = Instance.new("ImageLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromOffset(50, 50)
			label.Image = spriteId
			label.ImageRectOffset = rectOffset
			label.ImageRectSize = rectSize
			label.Parent = obj
			local ratio = Instance.new("UIAspectRatioConstraint")
			ratio.AspectRatio = 1
			ratio.Parent = label
		end
	end
	ChangeHistoryService:SetWaypoint("Applied icon " .. name)
end

local function App()
	local theme = useTheme()
	local query, setQuery = React.useState("")
	local selected, setSelected = React.useState(nil :: string?)
	local icons = React.useMemo(function()
		return search(query)
	end, { query })
	local canApply = selected ~= nil
	local hoveredName, setHoveredName = React.useState(nil :: string?)
	local hoveredPos, setHoveredPos = React.useState(Vector2.zero)
	local framePos, setFramePos = React.useState(Vector2.zero)
	local frameSize, setFrameSize = React.useState(Vector2.new(280, 420))
	local hideTask = React.useRef(nil :: thread?)

	React.useEffect(function()
		return function()
			if hideTask.current then
				task.cancel(hideTask.current)
			end
		end
	end, {})

	local function onHover(name: string?, position: Vector2?)
		if hideTask.current then
			task.cancel(hideTask.current)
			hideTask.current = nil
		end
		if name then
			setHoveredName(name)
			setHoveredPos(position :: Vector2)
		else
			hideTask.current = task.delay(0.08, function()
				setHoveredName(nil)
				hideTask.current = nil
			end)
		end
	end

	local TOOLTIP_W = 160
	local localX = hoveredPos.X - framePos.X
	local localY = hoveredPos.Y - framePos.Y
	local tooltipX = if localX + 8 + TOOLTIP_W > frameSize.X then localX - TOOLTIP_W - 8 else localX + 8

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		[React.Change.AbsolutePosition] = function(rbx)
			setFramePos(rbx.AbsolutePosition)
		end,
		[React.Change.AbsoluteSize] = function(rbx)
			setFrameSize(rbx.AbsoluteSize)
		end,
	}, {
		Content = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
			BorderSizePixel = 0,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Search = e(SearchBar, {
				LayoutOrder = 1,
				query = query,
				onChange = setQuery,
				count = #icons,
			}),
			Grid = e(IconGrid, {
				LayoutOrder = 2,
				icons = icons,
				iconSize = Assets.iconSize,
				selected = selected,
				onSelect = setSelected,
				onHover = onHover,
			}),
			Footer = e("Frame", {
				LayoutOrder = 3,
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
				BorderSizePixel = 0,
			}, {
				Padding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
					PaddingTop = UDim.new(0, 6),
					PaddingBottom = UDim.new(0, 6),
				}),
				Button = e("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					Text = if canApply
						then 'Apply "' .. (selected :: string) .. '"'
						else "Select an icon above",
					Font = Enum.Font.SourceSansSemibold,
					TextSize = 14,
					TextColor3 = theme:GetColor(
						Enum.StudioStyleGuideColor.ButtonText,
						if canApply then Enum.StudioStyleGuideModifier.Default else Enum.StudioStyleGuideModifier.Disabled
					),
					BackgroundColor3 = theme:GetColor(
						Enum.StudioStyleGuideColor.Button,
						if canApply then Enum.StudioStyleGuideModifier.Default else Enum.StudioStyleGuideModifier.Disabled
					),
					AutoButtonColor = canApply,
					Active = canApply,
					[React.Event.Activated] = function()
						if selected then applyIcon(selected) end
					end,
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
				}),
			}),
		}),

		Tooltip = if hoveredName then e("TextLabel", {
			Size = UDim2.fromOffset(120, 24),
			Position = UDim2.fromOffset(tooltipX, localY - 28),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Tooltip),
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = hoveredName,
			Font = Enum.Font.SourceSans,
			TextSize = 14,
			ZIndex = 10,
			BorderSizePixel = 0.5,
			BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
		}, {
			-- Corner = e("UICorner", { CornerRadius = UDim.new(0, 5) }),
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
			}),
		}) else nil,
	})
end

return App
