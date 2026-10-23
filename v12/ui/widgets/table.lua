--[[
    ui/widgets/table.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    A simple data table: a header row and a scrolling list of rows.

    Used for the roll history, the spawn log and the entity lists.
]]

local Widget = {}

Widget.__index = Widget

function Widget.Create(window, parent, options)
    options = options or {}

    local theme = window.Theme
    local self = setmetatable({}, Widget)

    local columns = options.columns or {}
    local maxRows = options.maxRows or 8

    local container = Instance.new("Frame")
    container.Name = "Table"
    container.Size = UDim2.new(1, 0, 0, 30 + maxRows * 22 + 8)
    container.BackgroundColor3 = theme.surfaceAlt
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, -20, 0, 22)
    header.Position = UDim2.new(0, 10, 0, 6)
    header.BackgroundTransparency = 1
    header.Parent = container

    local headerLayout = Instance.new("UIListLayout")
    headerLayout.FillDirection = Enum.FillDirection.Horizontal
    headerLayout.Padding = UDim.new(0, 6)
    headerLayout.Parent = header

    for _, column in ipairs(columns) do
        local columnLabel = Instance.new("TextLabel")
        columnLabel.Name = column
        columnLabel.Size = UDim2.new(column.width or 0.33, -6, 1, 0)
        columnLabel.BackgroundTransparency = 1
        columnLabel.Text = column
        columnLabel.TextColor3 = theme.textDim
        columnLabel.Font = Enum.Font.GothamBold
        columnLabel.TextSize = 11
        columnLabel.TextXAlignment = Enum.TextXAlignment.Left
        columnLabel.Parent = header
    end

    local body = Instance.new("ScrollingFrame")
    body.Name = "Body"
    body.Size = UDim2.new(1, -20, 1, -36)
    body.Position = UDim2.new(0, 10, 0, 30)
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.ScrollBarThickness = 3
    body.ScrollBarImageColor3 = theme.accent
    body.CanvasSize = UDim2.new(0, 0, 0, 0)
    body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    body.Parent = container

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.Padding = UDim.new(0, 2)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent = body

    local rowWidgets = {}

    local function clearRows()
        for _, row in ipairs(rowWidgets) do
            pcall(function()
                row:Destroy()
            end)
        end
        rowWidgets = {}
    end

    --- rows: array of arrays of strings, newest first.
    function self:SetRows(rows)
        clearRows()

        for index, row in ipairs(rows or {}) do
            if index > maxRows then
                break
            end

            local rowFrame = Instance.new("Frame")
            rowFrame.Name = "Row"
            rowFrame.LayoutOrder = index
            rowFrame.Size = UDim2.new(1, -4, 0, 20)
            rowFrame.BackgroundTransparency = 1
            rowFrame.Parent = body

            local rowLayout = Instance.new("UIListLayout")
            rowLayout.FillDirection = Enum.FillDirection.Horizontal
            rowLayout.Padding = UDim.new(0, 6)
            rowLayout.Parent = rowFrame

            for columnIndex, column in ipairs(columns) do
                local cell = Instance.new("TextLabel")
                cell.Name = column
                cell.Size = UDim2.new(column.width or 0.33, -6, 1, 0)
                cell.BackgroundTransparency = 1
                cell.Text = tostring(row[columnIndex] or "")
                cell.TextColor3 = (columnIndex == 1) and theme.text or theme.textDim
                cell.Font = (columnIndex == 1) and Enum.Font.GothamSemibold or Enum.Font.Gotham
                cell.TextSize = 11
                cell.TextXAlignment = Enum.TextXAlignment.Left
                cell.Parent = rowFrame
            end

            table.insert(rowWidgets, rowFrame)
        end
    end

    function self:Clear()
        clearRows()
    end

    self.Element = container

    function self:Destroy()
        clearRows()
        pcall(function()
            container:Destroy()
        end)
    end

    return self
end

return Widget
