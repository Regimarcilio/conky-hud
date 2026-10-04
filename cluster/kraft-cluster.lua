--[[
    kraft-cluster.lua — cluster analógico Kraft, adaptado de wim66/conky-dashboard
    Coluna única à direita: CPU · TEMP · MEM · REDE + faixa LCD (hora/BTC/clima)
    Núcleo: mostrador com agulha amortecida + varredura de self-test no arranque.
]]
require("cairo")

local function get_draw_surface()
    -- conky_surface é nil neste build (1.19.6 Ubuntu): usa fallback xlib
    if conky_surface ~= nil then
        local ok, s = pcall(conky_surface)
        if ok and s then return s, false end
    end
    if conky_window ~= nil and cairo_xlib_surface_create ~= nil then
        local ok, s = pcall(cairo_xlib_surface_create,
            conky_window.display, conky_window.drawable,
            conky_window.visual, conky_window.width, conky_window.height)
        if ok and s then return s, true end
    end
    return nil, false
end

-- ================= configuração =================
local CFG = {
    gauge_radius = 58,
    gauge_gap = 12,
    top_margin = 14,
    lcd_strip_h = 30,
    ease_rate = 0.22,
    startup_frames = 30,
    net_interface = "__IFACE__",
    net_max_down = 10, -- MB/s (teto do mostrador de rede)
    start_angle = math.pi * 0.75,
    sweep = math.pi * 1.5,
    -- Kraft (0-1): pergaminho, âmbar, couro, ferrugem, fibra
    colors = {
        bezel_light = { 0.85, 0.60, 0.17 },   -- D99A2B
        bezel_dark  = { 0.23, 0.18, 0.12 },   -- 3A2E1F
        face_center = { 0.14, 0.10, 0.05 },   -- 241A0E
        face_edge   = { 0.11, 0.08, 0.05 },   -- 1C150C
        face_alpha  = 1,
        tick_major  = { 0.91, 0.86, 0.76 },   -- E8DCC3
        tick_minor  = { 0.55, 0.48, 0.36 },   -- 8C7B5D
        text        = { 0.91, 0.86, 0.76 },
        needle      = { 0.85, 0.60, 0.17 },   -- D99A2B
        needle_edge = { 0.85, 0.64, 0.25 },   -- D9A441
        hub_light   = { 0.85, 0.64, 0.25 },
        hub_dark    = { 0.35, 0.25, 0.12 },
        lcd_bg      = { 0.08, 0.06, 0.03 },
        lcd_border  = { 0.55, 0.48, 0.36 },
        lcd_text    = { 0.85, 0.60, 0.17 },
    },
    zone_colors = {
        low  = { 0.65, 0.42, 0.17 },  -- A66A2C couro
        mid  = { 0.85, 0.60, 0.17 },  -- D99A2B âmbar
        high = { 0.78, 0.36, 0.22 },  -- C75B39 ferrugem
    },
}

local GAUGES = {
    { key = "cpu",  label = "CPU",  unit = "%",    min = 0,  max = 100, redline = 85, major = 20 },
    { key = "temp", label = "TEMP", unit = "C",    min = 20, max = 100, redline = 80, major = 20 },
    { key = "mem",  label = "MEM",  unit = "%",    min = 0,  max = 100, redline = 90, major = 20 },
    { key = "down", label = "REDE", unit = "MB/s", min = 0,  max = CFG.net_max_down,
      redline = CFG.net_max_down * 0.85, major = CFG.net_max_down / 5, is_net = true },
}

local W = {
    cache = { cpu = 0, temp = 35, mem = 0, down = 0, last_check = 0 },
    display = { cpu = 0, temp = 35, mem = 0, down = 0 },
    updates = 0,
}

-- ================= helpers =================
local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function lerp(a, b, t) return a + (b - a) * t end

local function safe_number(s, default)
    return tonumber(s) or default or 0
end

local function value_to_angle(value, g)
    local t = clamp((value - g.min) / (g.max - g.min), 0, 1)
    return CFG.start_angle + CFG.sweep * t
end

local function zone_color_for(value, g)
    local t = clamp((value - g.min) / (g.max - g.min), 0, 1)
    local rt = clamp((g.redline - g.min) / (g.max - g.min), 0, 1)
    if t <= rt * 0.55 then
        local lt = t / (rt * 0.55 + 1e-6)
        return { lerp(CFG.zone_colors.low[1], CFG.zone_colors.mid[1], lt),
                 lerp(CFG.zone_colors.low[2], CFG.zone_colors.mid[2], lt),
                 lerp(CFG.zone_colors.low[3], CFG.zone_colors.mid[3], lt) }
    end
    local lt = clamp((t - rt * 0.55) / (1 - rt * 0.55 + 1e-6), 0, 1)
    return { lerp(CFG.zone_colors.mid[1], CFG.zone_colors.high[1], lt),
             lerp(CFG.zone_colors.mid[2], CFG.zone_colors.high[2], lt),
             lerp(CFG.zone_colors.mid[3], CFG.zone_colors.high[3], lt) }
end

-- ================= dados =================
local function read_data()
    local cpu = safe_number(conky_parse and conky_parse("${cpu cpu0}"))
    local mem = safe_number(conky_parse and conky_parse("${memperc}"))
    local temp = safe_number(conky_parse and conky_parse("${hwmon 1 temp 2}"), W.cache.temp)
    if temp <= 0 then temp = W.cache.temp end
    local down_kb = safe_number(conky_parse and conky_parse(
        string.format("${downspeedf %s}", CFG.net_interface)))
    return cpu, mem, temp, down_kb / 1024
end

local function refresh_data()
    W.cache.cpu = clamp(safe_number(conky_parse and conky_parse("${cpu cpu0}")), 0, 100)
    W.cache.mem = clamp(safe_number(conky_parse and conky_parse("${memperc}")), 0, 100)
    local temp = safe_number(conky_parse and conky_parse("${hwmon 1 temp 2}"), W.cache.temp)
    W.cache.temp = (temp > 0) and clamp(temp, 0, 120) or W.cache.temp
    local down_kb = safe_number(conky_parse and conky_parse(
        string.format("${downspeedf %s}", CFG.net_interface)))
    W.cache.down = clamp(down_kb / 1024, 0, CFG.net_max_down)
end

-- ================= desenho =================
local function draw_bezel(cr, cx, cy, r)
    local inner = r * 0.90
    local grad = cairo_pattern_create_radial(cx - r * 0.3, cy - r * 0.3, r * 0.1, cx, cy, r * 1.05)
    cairo_pattern_add_color_stop_rgba(grad, 0, CFG.colors.bezel_light[1], CFG.colors.bezel_light[2], CFG.colors.bezel_light[3], 1)
    cairo_pattern_add_color_stop_rgba(grad, 0.6, CFG.colors.bezel_dark[1], CFG.colors.bezel_dark[2], CFG.colors.bezel_dark[3], 1)
    cairo_pattern_add_color_stop_rgba(grad, 1, 0.03, 0.03, 0.04, 1)
    cairo_arc(cr, cx, cy, r, 0, 2 * math.pi)
    cairo_new_sub_path(cr)
    cairo_arc_negative(cr, cx, cy, inner, 0, -2 * math.pi)
    cairo_set_fill_rule(cr, CAIRO_FILL_RULE_EVEN_ODD)
    cairo_set_source(cr, grad)
    cairo_fill(cr)
    cairo_set_fill_rule(cr, CAIRO_FILL_RULE_WINDING)
    cairo_pattern_destroy(grad)
end

local function draw_face(cr, cx, cy, r)
    local inner = r * 0.90
    local grad = cairo_pattern_create_radial(cx, cy, inner * 0.1, cx, cy, inner)
    cairo_pattern_add_color_stop_rgba(grad, 0, CFG.colors.face_center[1], CFG.colors.face_center[2], CFG.colors.face_center[3], CFG.colors.face_alpha)
    cairo_pattern_add_color_stop_rgba(grad, 1, CFG.colors.face_edge[1], CFG.colors.face_edge[2], CFG.colors.face_edge[3], CFG.colors.face_alpha)
    cairo_arc(cr, cx, cy, inner, 0, 2 * math.pi)
    cairo_set_source(cr, grad)
    cairo_fill(cr)
    cairo_pattern_destroy(grad)
end

local function draw_backlight(cr, cx, cy, r, g, value)
    local zc = zone_color_for(value, g)
    local ring_r = r * 0.86
    cairo_set_line_width(cr, 2.4)
    cairo_set_source_rgba(cr, zc[1], zc[2], zc[3], 0.85)
    cairo_arc(cr, cx, cy, ring_r, CFG.start_angle, value_to_angle(value, g))
    cairo_stroke(cr)
    return zc
end

local function draw_ticks(cr, cx, cy, r, g)
    local num_major = math.floor((g.max - g.min) / g.major + 0.5)
    for i = 0, num_major do
        local v = g.min + i * g.major
        local ang = value_to_angle(v, g)
        local x1, y1 = cx + math.cos(ang) * r * 0.90, cy + math.sin(ang) * r * 0.90
        local x2, y2 = cx + math.cos(ang) * r * 0.74, cy + math.sin(ang) * r * 0.74
        cairo_move_to(cr, x1, y1)
        cairo_line_to(cr, x2, y2)
        cairo_set_line_width(cr, 2.0)
        cairo_set_source_rgba(cr, CFG.colors.tick_major[1], CFG.colors.tick_major[2], CFG.colors.tick_major[3], 0.95)
        cairo_stroke(cr)
        local lx, ly = cx + math.cos(ang) * r * 0.60, cy + math.sin(ang) * r * 0.60
        cairo_select_font_face(cr, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
        cairo_set_font_size(cr, 9)
        local txt = tostring(math.floor(v + 0.5))
        local ext = cairo_text_extents_t:create()
        cairo_text_extents(cr, txt, ext)
        cairo_set_source_rgba(cr, CFG.colors.text[1], CFG.colors.text[2], CFG.colors.text[3], 0.9)
        cairo_move_to(cr, lx - ext.width / 2, ly + ext.height / 2)
        cairo_show_text(cr, txt)
    end
end

local function draw_needle(cr, cx, cy, r, angle)
    local len, tail, hw = r * 0.70, r * 0.16, 3.0
    local tip_x, tip_y = cx + math.cos(angle) * len, cy + math.sin(angle) * len
    local perp = angle + math.pi / 2
    local bx, by = math.cos(perp) * hw, math.sin(perp) * hw
    local tx, ty = cx - math.cos(angle) * tail, cy - math.sin(angle) * tail
    local grad = cairo_pattern_create_linear(tx, ty, tip_x, tip_y)
    cairo_pattern_add_color_stop_rgba(grad, 0, CFG.colors.needle[1], CFG.colors.needle[2], CFG.colors.needle[3], 1)
    cairo_pattern_add_color_stop_rgba(grad, 1, CFG.colors.needle_edge[1], CFG.colors.needle_edge[2], CFG.colors.needle_edge[3], 1)
    cairo_move_to(cr, tx + bx, ty + by)
    cairo_line_to(cr, tip_x, tip_y)
    cairo_line_to(cr, tx - bx, ty - by)
    cairo_close_path(cr)
    cairo_set_source(cr, grad)
    cairo_fill(cr)
    cairo_pattern_destroy(grad)
end

local function draw_hub(cr, cx, cy, r)
    local grad = cairo_pattern_create_radial(cx - 2, cy - 2, 1, cx, cy, r * 0.11)
    cairo_pattern_add_color_stop_rgba(grad, 0, CFG.colors.hub_light[1], CFG.colors.hub_light[2], CFG.colors.hub_light[3], 1)
    cairo_pattern_add_color_stop_rgba(grad, 1, CFG.colors.hub_dark[1], CFG.colors.hub_dark[2], CFG.colors.hub_dark[3], 1)
    cairo_arc(cr, cx, cy, r * 0.11, 0, 2 * math.pi)
    cairo_set_source(cr, grad)
    cairo_fill(cr)
    cairo_pattern_destroy(grad)
end

local function draw_lcd(cr, cx, cy, r, g, value, zc)
    local lw, lh = r * 1.30, r * 0.30
    local lx, ly = cx - lw / 2, cy + r * 0.28
    cairo_rectangle(cr, lx, ly, lw, lh)
    cairo_set_source_rgba(cr, CFG.colors.lcd_bg[1], CFG.colors.lcd_bg[2], CFG.colors.lcd_bg[3], 0.9)
    cairo_fill_preserve(cr)
    cairo_set_source_rgba(cr, CFG.colors.lcd_border[1], CFG.colors.lcd_border[2], CFG.colors.lcd_border[3], 0.8)
    cairo_set_line_width(cr, 1)
    cairo_stroke(cr)
    local txt
    if g.is_net then
        txt = (value < 1) and string.format("%3dKB", math.floor(value * 1024 + 0.5))
                            or string.format("%.1fMB", value)
    elseif g.key == "temp" then
        txt = string.format("%3dC", math.floor(value + 0.5))
    else
        txt = string.format("%3d%s", math.floor(value + 0.5), g.unit)
    end
    cairo_select_font_face(cr, "Monospace", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
    cairo_set_font_size(cr, lh * 0.58)
    local ext = cairo_text_extents_t:create()
    cairo_text_extents(cr, txt, ext)
    cairo_set_source_rgba(cr, zc[1] * 0.6 + 0.4, zc[2] * 0.6 + 0.4, zc[3] * 0.6 + 0.4, 0.95)
    cairo_move_to(cr, cx - ext.width / 2, ly + lh / 2 + ext.height / 2)
    cairo_show_text(cr, txt)
end

local function draw_label(cr, cx, cy, r, label)
    cairo_select_font_face(cr, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
    cairo_set_font_size(cr, 10)
    local ext = cairo_text_extents_t:create()
    cairo_text_extents(cr, label, ext)
    cairo_set_source_rgba(cr, CFG.colors.text[1], CFG.colors.text[2], CFG.colors.text[3], 1)
    cairo_move_to(cr, cx - ext.width / 2, cy - r * 0.20)
    cairo_show_text(cr, label)
end

local function draw_gauge(cr, cx, cy, r, g, value)
    draw_bezel(cr, cx, cy, r)
    draw_face(cr, cx, cy, r)
    local zc = zone_color_for(value, g)
    draw_backlight(cr, cx, cy, r, g, value)
    draw_ticks(cr, cx, cy, r, g)
    draw_label(cr, cx, cy, r, g.label)
    draw_lcd(cr, cx, cy, r, g, value, zc)
    draw_needle(cr, cx, cy, r, value_to_angle(value, g))
    draw_hub(cr, cx, cy, r)
end

-- ================= faixa LCD =================

local function draw_strip(cr, x, y, w, h)
    cairo_rectangle(cr, x, y, w, h)
    cairo_set_source_rgba(cr, CFG.colors.lcd_bg[1], CFG.colors.lcd_bg[2], CFG.colors.lcd_bg[3], 0.55)
    cairo_fill_preserve(cr)
    cairo_set_source_rgba(cr, CFG.colors.lcd_border[1], CFG.colors.lcd_border[2], CFG.colors.lcd_border[3], 0.8)
    cairo_set_line_width(cr, 1)
    cairo_stroke(cr)
    local btc = (conky_parse and conky_parse("${execi 60 ~/.config/conky/scripts/btc.sh}")) or ""
    btc = btc:gsub("%s+", "")
    local tmp = (conky_parse and conky_parse("${execi 300 jq -r '.current_condition[0].temp_C' ~/.cache/conky/weather.json}")) or ""
    tmp = tmp:gsub("%s+", "")
    local txt = string.format("%s  %sC  %s", os.date("%H:%M:%S"), tmp ~= "" and tmp or "--", btc ~= "" and btc or "$--")
    cairo_select_font_face(cr, "Monospace", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
    cairo_set_font_size(cr, h * 0.42)
    local ext = cairo_text_extents_t:create()
    cairo_text_extents(cr, txt, ext)
    cairo_set_source_rgba(cr, CFG.colors.lcd_text[1], CFG.colors.lcd_text[2], CFG.colors.lcd_text[3], 0.9)
    cairo_move_to(cr, x + (w - ext.width) / 2, y + h / 2 + ext.height / 2)
    cairo_show_text(cr, txt)
end

local function update_display()
    W.updates = W.updates + 1
    if W.updates < CFG.startup_frames then
        local half = CFG.startup_frames / 2
        local t = (W.updates < half) and (W.updates / half) or (1 - (W.updates - half) / half)
        for _, g in ipairs(GAUGES) do
            W.display[g.key] = g.min + (g.max - g.min) * clamp(t, 0, 1)
        end
    else
        for _, g in ipairs(GAUGES) do
            W.display[g.key] = lerp(W.display[g.key], W.cache[g.key], CFG.ease_rate)
        end
    end
end

-- ================= hook =================
function conky_kraft_main()
    refresh_data()
    update_display()
    local surface, owns = get_draw_surface()
    if not surface then return end
    local cr = cairo_create(surface)
    local r = CFG.gauge_radius
    local cx = 160
    local cy = CFG.top_margin + r
    for _, g in ipairs(GAUGES) do
        draw_gauge(cr, cx, cy, r, g, W.display[g.key])
        cy = cy + 2 * r + CFG.gauge_gap
    end
    draw_strip(cr, 14, cy + 2, 292, CFG.lcd_strip_h)
    cairo_destroy(cr)
    if owns then cairo_surface_destroy(surface) end
end
