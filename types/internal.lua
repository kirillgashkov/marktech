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
---@alias cell contentCell | mergeCell

---@class mergeCell
---@field Type "mergeCell"
---@field Of { X: integer, Y: integer }

---@class config
---@field ArrayRuleWidth length # https://tex.stackexchange.com/questions/122956/how-thick-a-rule-does-hline-produce

---@class tbl
---@field Id string
---@field Caption Inline | nil
---@field ColAlignments List<"left" | "center" | "right">
---@field ColWidths List<length | nil>
---@field ColBorders List<{ L: length, R: length }>
---@field FirstTopBorder length
---@field LastBottomBorder length
---@field HeadRows List<List<cell>>
---@field BodyRows List<List<cell>>
---@field FootRows List<List<cell>>

---@class tableConfig
---@field OuterBorderWidth length
---@field InnerBorderWidth length
---@field SeparateHead boolean
---@field RepeatHead boolean
---@field SeparateFoot boolean
---@field RepeatFoot boolean

---@class colSpec
---@field Alignment "left" | "center" | "right"
---@field Width length | nil
---@field Border { L: length, R: length }
