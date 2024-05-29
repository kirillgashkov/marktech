local function is_list_of_references_div(
  div -- pandoc.Div
)
  return div.identifier == "list-of-references"
end

local function check_list_of_references_div(
  div -- pandoc.Div
)
  if #div.content > 0 then
    warn("'List of References' div isn't empty. Ignoring its content.")
  end
end

local div = {}

---@param e pandoc.Div
---@return any
function div.MakeLorLatex(e)
  if not is_list_of_references_div(e) then
    return e
  end

  check_list_of_references_div(e)

  local rendered_references = table.concat({
    "\\nocite{*}",
    "\\printbibliography[env=scholar,heading=none]",
  }, "\n")

  return pandoc.RawBlock("latex", rendered_references)
end

return div
