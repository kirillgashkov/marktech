local function is_citation(
  link -- pandoc.Link
)
  return link.content == pandoc.Inlines({ pandoc.Str("@") })
end

local function validate_citation(
  link -- pandoc.Link
)
  if link.target:sub(1, 1) ~= "#" then
    error("Citation target doesn't start with '#': " .. link.target)
  end
end

local function citation_to_citation_id(
  link -- pandoc.Link
)
  return link.target:sub(2)
end

local link = {}

---@param e pandoc.Link
---@return any
function link.MakeCitationLatex(e)
  if not is_citation(e) then
    return e
  end

  validate_citation(e)

  return pandoc.RawInline("latex", "\\autocite{" .. citation_to_citation_id(e) .. "}")
end

return link
