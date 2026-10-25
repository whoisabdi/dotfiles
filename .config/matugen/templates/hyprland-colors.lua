local colors = {
    image = "{{image}}",
<* for name, value in colors *>
    {{name}} = "0xff{{value.default.hex_stripped}}",
<* endfor *>
}

setmetatable(colors, {
    __index = function(_, key)
        return "0xffffffff"
    end
})

return colors
