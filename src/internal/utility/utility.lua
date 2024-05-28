local fun = require("internal.fun")
local log = require("internal.log")

local utility = {}

--
-- Config
--

-- https://github.com/tailwindlabs/tailwindcss/blob/master/stubs/config.full.js
local configIn = {
  theme = {
    spacing = {
      ["px"] = "1px",
      ["0"] = "0px",
      ["0.5"] = "0.125rem",
      ["1"] = "0.25rem",
      ["1.5"] = "0.375rem",
      ["2"] = "0.5rem",
      ["2.5"] = "0.625rem",
      ["3"] = "0.75rem",
      ["3.5"] = "0.875rem",
      ["4"] = "1rem",
      ["5"] = "1.25rem",
      ["6"] = "1.5rem",
      ["7"] = "1.75rem",
      ["8"] = "2rem",
      ["9"] = "2.25rem",
      ["10"] = "2.5rem",
      ["11"] = "2.75rem",
      ["12"] = "3rem",
      ["14"] = "3.5rem",
      ["16"] = "4rem",
      ["20"] = "5rem",
      ["24"] = "6rem",
      ["28"] = "7rem",
      ["32"] = "8rem",
      ["36"] = "9rem",
      ["40"] = "10rem",
      ["44"] = "11rem",
      ["48"] = "12rem",
      ["52"] = "13rem",
      ["56"] = "14rem",
      ["60"] = "15rem",
      ["64"] = "16rem",
      ["72"] = "18rem",
      ["80"] = "20rem",
      ["96"] = "24rem",
    },
    width = function(c)
      return fun.Merge({
        {
          ["auto"] = "auto",
        },
        c.theme("spacing"),
        {
          ["1/2"] = "50%",
          ["1/3"] = "33.333333%",
          ["2/3"] = "66.666667%",
          ["1/4"] = "25%",
          ["2/4"] = "50%",
          ["3/4"] = "75%",
          ["1/5"] = "20%",
          ["2/5"] = "40%",
          ["3/5"] = "60%",
          ["4/5"] = "80%",
          ["1/6"] = "16.666667%",
          ["2/6"] = "33.333333%",
          ["3/6"] = "50%",
          ["4/6"] = "66.666667%",
          ["5/6"] = "83.333333%",
          ["1/12"] = "8.333333%",
          ["2/12"] = "16.666667%",
          ["3/12"] = "25%",
          ["4/12"] = "33.333333%",
          ["5/12"] = "41.666667%",
          ["6/12"] = "50%",
          ["7/12"] = "58.333333%",
          ["8/12"] = "66.666667%",
          ["9/12"] = "75%",
          ["10/12"] = "83.333333%",
          ["11/12"] = "91.666667%",
          ["full"] = "100%",
          ["screen"] = "100vw",
          ["svw"] = "100svw",
          ["lvw"] = "100lvw",
          ["dvw"] = "100dvw",
          ["min"] = "min-content",
          ["max"] = "max-content",
          ["fit"] = "fit-content",
        },
      })
    end,
  },
}

local function makeConfig(cIn)
  local c = {}
  c.theme = function(key)
    if type(cIn.theme[key]) == "table" then
      return cIn.theme[key]
    elseif type(cIn.theme[key]) == "function" then
      return cIn.theme[key](c)
    elseif cIn.theme[key] == nil then
      return {}
    else
      assert(false)
    end
  end

  local cOut = {}
  cOut.theme = (function()
    local t = {}
    for k, _ in pairs(cIn.theme) do
      t[k] = c.theme(k)
    end
    return t
  end)()

  return cOut
end

---@class utility.Config
---@field theme utility.ConfigTheme

---@class utility.ConfigTheme
---@field spacing { [string]: string }
---@field width { [string]: string }

---@type utility.Config
utility.Config = makeConfig(configIn)

--
-- Common
--

-- Matches the inside of square brackets.
local arbitraryValueRegex = re.compile([=[ "[" { [^]]* } "]" ]=])

--
-- Width
--

local widthRegex = re.compile([["w-"{.*}]])

---@param class string
---@param source string | nil
---@param config? utility.Config | nil # Defaults to utility.Config.
---@return string | nil
function utility.ParseWidth(class, source, config)
  config = config or utility.Config

  local w = widthRegex:match(class)
  if w == nil then
    return nil
  end

  local arbitraryValue = arbitraryValueRegex:match(w)
  if arbitraryValue ~= nil then
    return arbitraryValue
  end

  local value = config.theme.width[w]
  if value == nil then
    log.Warning("element uses an unknown width class (" .. w .. "), it is ignored", source)
  end

  return value
end

return utility
