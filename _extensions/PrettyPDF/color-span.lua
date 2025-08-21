-- color-span.lua

local function get_color_from_style(style)
  if not style then return nil end
  local c = style:match("color:%s*([^;]+)")
  if c then c = c:gsub("^%s+", ""):gsub("%s+$", "") end
  return c
end

local function to_latex_color_spec(c)
  if not c then return nil end
  local hex = c:match("^#(%x%x%x%x%x%x)$")
  if hex then return { model = "HTML", value = hex:upper() } end
  return { model = nil, value = c } -- namn som 'blue', 'red', etc
end

local function is_htmlish()
  return FORMAT:match("html") or FORMAT:match("revealjs") or FORMAT:match("epub") or FORMAT:match("gfm")
end

local function is_latexish()
  return FORMAT:match("latex") or FORMAT:match("beamer")
end

local function merge_style(old_style, add_style)
  if not old_style or old_style == "" then return add_style end
  if old_style:sub(-1) ~= ";" then old_style = old_style .. ";" end
  return old_style .. add_style
end

return {
  {
    Span = function(el)
      -- 1) hämta färg från color/data-color/style
      local c = el.attributes["color"] or el.attributes["data-color"] or get_color_from_style(el.attributes["style"])
      if not c then return nil end

      if is_htmlish() then
        -- HTML: injicera inline-style
        el.attributes["style"] = merge_style(el.attributes["style"], "color: " .. c .. ";")
        -- städa “icke-HTML” attribut (frivilligt)
        el.attributes["color"] = nil
        el.attributes["data-color"] = nil
        return el
      end

      if is_latexish() then
        -- PDF/LaTeX: omslut med \textcolor...
        local spec = to_latex_color_spec(c)
        local open_cmd
        if spec and spec.model == "HTML" then
          open_cmd = string.format("\\textcolor[HTML]{%s}{", spec.value)
        else
          open_cmd = string.format("\\textcolor{%s}{", spec and spec.value or "black")
        end
        local out = { pandoc.RawInline("latex", open_cmd) }
        for i = 1, #el.content do out[#out+1] = el.content[i] end
        out[#out+1] = pandoc.RawInline("latex", "}")
        return out
      end

      -- andra format: lämna orört
      return el
    end
  }
}
