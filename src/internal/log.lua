local log = {}

---@type "text"|"json"
log.Format = "text"

---@param type "panic" | "error" | "warning" | "note"
---@param message string
---@param source? string
---@param code? string|nil
local function makeTextLog(type, message, source, code)
  local s = ""

  local resetColor = "\27[0m"
  local codeColor = "\27[35m"
  local typeColor
  if type == "note" then
    typeColor = "\27[34m\27[1m"
  elseif type == "warning" then
    typeColor = "\27[33m\27[1m"
  elseif type == "error" then
    typeColor = "\27[31m\27[1m"
  else
    assert(false)
  end

  if source ~= nil then
    s = source .. ": "
  else
    s = "<unknown>: "
  end
  s = s .. typeColor .. type .. ": " .. resetColor .. message
  if code ~= nil then
    s = s .. " " .. codeColor .. "[" .. code .. "]" .. resetColor .. "\n"
  end

  return s
end

---@param type "panic" | "error" | "warning" | "note"
---@param message string
---@param source? string|nil
---@param code? string|nil
local function makeJsonLog(type, message, source, code)
  local d = { type = type, message = message, code = code, source = source }
  return pandoc.json.encode(d)
end

---@param type "panic" | "error" | "warning" | "note"
---@param message string
---@param source? string
---@param code? string|nil
function log.message(type, message, source, code)
  local s = ""

  if log.Format == "text" then
    s = makeTextLog(type, message, source, code)
  elseif log.Format == "json" then
    s = makeJsonLog(type, message, source, code)
  else
    assert(false)
  end

  io.stderr:write(s .. "\n")
end

---@param message string
---@param source? string|nil
---@param code? string|nil
function log.Error(message, source, code)
  log.message("error", message, source, code)
end

---@param message string
---@param source? string|nil
---@param code? string|nil
function log.Warning(message, source, code)
  log.message("warning", message, source, code)
end

---@param message string
---@param source? string|nil
---@param code? string|nil
function log.Note(message, source, code)
  log.message("note", message, source, code)
end

return log
