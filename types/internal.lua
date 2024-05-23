---@meta

---@class contentCellWithContent
---@field Type "contentCell"
---@field Content Inlines
---@field RowSpan integer
---@field ColSpan integer

---@class contentCellWithContentAlignment: contentCellWithContent
---@field Alignment "left" | "center" | "right"

---@class contentCellWithContentAlignmentWidth: contentCellWithContentAlignment
---@field Width "max-width" | number

---@class contentCellWithContentAlignmentWidthBorder: contentCellWithContentAlignmentWidth
---@field Border { T: number | nil, B: number | nil, L: number | nil, R: number | nil }

---@alias contentCell contentCellWithContentAlignmentWidthBorder

---@class mergeCell
---@field Type "mergeCell"
---@field Of { X: integer, Y: integer }
