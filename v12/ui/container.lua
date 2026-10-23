--[[
    ui/container.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    The widget container mixin.

    Both a tab page and a collapsible section can hold widgets, so both
    share the same Add* API. The methods ask the window to build the
    widget, which keeps the widget modules independent of each other and
    avoids a require cycle between the section widget and the rest.
]]

local Container = {}

Container.__index = Container

function Container:_parent()
    return self._container
end

function Container:AddToggle(text, default, callback)
    return self._window:CreateWidget("Toggle", self._container, {
        text = text,
        default = default,
        callback = callback,
    })
end

function Container:AddSlider(text, min, max, default, step, suffix, callback)
    return self._window:CreateWidget("Slider", self._container, {
        text = text,
        min = min,
        max = max,
        default = default,
        step = step,
        suffix = suffix,
        callback = callback,
    })
end

function Container:AddDropdown(text, options, default, callback)
    return self._window:CreateWidget("Dropdown", self._container, {
        text = text,
        options = options,
        default = default,
        callback = callback,
    })
end

function Container:AddButton(text, style, callback)
    return self._window:CreateWidget("Button", self._container, {
        text = text,
        style = style,
        callback = callback,
    })
end

function Container:AddInput(text, placeholder, default, callback)
    return self._window:CreateWidget("Input", self._container, {
        text = text,
        placeholder = placeholder,
        default = default,
        callback = callback,
    })
end

function Container:AddSection(text, expanded)
    return self._window:CreateWidget("Section", self._container, {
        text = text,
        expanded = expanded,
    })
end

function Container:AddLabel(text, value, valueColor)
    return self._window:CreateWidget("Label", self._container, {
        text = text,
        value = value,
        valueColor = valueColor,
    })
end

function Container:AddStat(title, value, color)
    return self._window:CreateWidget("Stat", self._container, {
        title = title,
        value = value,
        color = color,
    })
end

function Container:AddTable(columns, maxRows)
    return self._window:CreateWidget("Table", self._container, {
        columns = columns,
        maxRows = maxRows,
    })
end

return Container
