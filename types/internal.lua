---@meta

---@class length: { ["pt" | "%"]: number | nil }
--
---@class contentCellWithContent
---@field Type "contentCell"
---@field Content Inlines
---@field RowSpan integer
---@field ColSpan integer

---@class contentCellWithContentAlignment: contentCellWithContent
---@field Alignment "left" | "center" | "right"

---@class contentCellWithContentAlignmentWidth: contentCellWithContentAlignment
---@field Width length | nil

---@class contentCellWithContentAlignmentWidthBorder: contentCellWithContentAlignmentWidth
---@field Border { T: length, B: length, L: length, R: length }

---@alias contentCell contentCellWithContentAlignmentWidthBorder

---@class mergeCell
---@field Type "mergeCell"
---@field Of { X: integer, Y: integer }

---@class config
---@field arrayRuleWidth length # https://tex.stackexchange.com/questions/122956/how-thick-a-rule-does-hline-produce
