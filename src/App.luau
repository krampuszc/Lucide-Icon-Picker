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

	ChangeHistoryService:SetWaypoint("Apply icon " .. name)
	for _, obj in selection do
		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			obj.Image = Assets.spriteId
			obj.ImageRectOffset = Vector2.new(pos[1], pos[2])
			obj.ImageRectSize = Vector2.new(Assets.iconSize, Assets.iconSize)
		else
			local label = Instance.new("ImageLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromOffset(50, 50)
			label.Image = Assets.spriteId
			label.ImageRectOffset = Vector2.new(pos[1], pos[2])
			label.ImageRectSize = Vector2.new(Assets.iconSize, Assets.iconSize)
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

	return e("Frame", {
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
	})
end

return App
