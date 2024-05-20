---@meta

---pandoc is a module that can be used in Lua filters, readers and writers. See
---https://pandoc.org/lua-filters.html.
pandoc = {}

-- Made by hand on 2024-05-20 from https://pandoc.org/lua-filters.html.

---@class List<T>: { [integer]: T }

---@class Pandoc
---@field blocks Blocks
---@field meta Meta
---@class Meta

---@class Block
---@class BlockQuote: Block
---@field content Blocks
---@field tag "BlockQuote"
---@class BulletList: Block
---@field content List<Blocks>
---@field tag "BulletList"
---@class CodeBlock: Block
---@field text string
---@field attr Attr
---@field tag "CodeBlock"
---@class DefinitionList: Block
---@field content any
---@field tag "DefinitionList"
---@class Div: Block
---@field content Blocks
---@field attr Attr
---@field tag "Div"
---@class Figure: Block
---@field content Blocks
---@field attr Attr
---@field tag "Figure"
---@class Header: Block
---@field level integer
---@field content Inlines
---@field attr Attr
---@field tag "Header"
---@class HorizontalRule: Block
---@field tag "HorizontalRule"
---@class LineBlock: Block
---@field content List<Inlines>
---@field tag "LineBlock"
---@class OrderedList: Block
---@field content List<Blocks>
---@field listAttributes ListAttributes
---@field tag "OrderedList"
---@class Para: Block
---@field content Inlines
---@field tag "Para"
---@class Plain: Block
---@field content Inlines
---@field tag "Plain"
---@class RawBlock: Block
---@field format string
---@field text string
---@field tag "RawBlock"
---@class Table: Block
---@field attr Attr
---@field caption Caption
---@field colspecs List<ColSpec>
---@field head TableHead
---@field bodies List<TableBody>
---@field foot TableFoot
---@field tag "Table"

---@alias Blocks List<Block>
---@alias BlocksLike List<Block>|Inlines|string

---@class Inline
---@class Cite: Inline
---@field content Inlines
---@field citations List<Citation>
---@field tag "Cite"
---@class Code: Inline
---@field text string
---@field attr Attr
---@field tag "Code"
---@class Emph: Inline
---@field content Inlines
---@field tag "Emph"
---@class Image: Inline
---@field caption Inlines
---@field src string
---@field title string
---@field attr Attr
---@field tag "Image"
---@class LineBreak: Inline
---@field tag "LineBreak"
---@class Link: Inline
---@field attr Attr
---@field content Inlines
---@field target string
---@field title string
---@field tag "Link"
---@class Math: Inline
---@field mathtype "InlineMath"|"DisplayMath"
---@field text string
---@field tag "Math"
---@class Note: Inline
---@field content Blocks
---@field tag "Note"
---@class Quoted: Inline
---@field quoteType "SingleQuote"|"DoubleQuote"
---@field content Inlines
---@field tag "Quoted"
---@class RawInline: Inline
---@field format string
---@field text string
---@field tag "RawInline"
---@class SmallCaps: Inline
---@field content Inlines
---@field tag "SmallCaps"
---@class SoftBreak: Inline
---@field tag "SoftBreak"
---@class Space: Inline
---@field tag "Space"
---@class Span: Inline
---@field attr Attr
---@field content Inlines
---@field tag "Span"
---@class Str: Inline
---@field text string
---@field tag "Str"
---@class Strikeout: Inline
---@field content Inlines
---@field tag "Strikeout"
---@class Strong: Inline
---@field content Inlines
---@field tag "Strong"
---@class Subscript: Inline
---@field content Inlines
---@field tag "Subscript"
---@class Superscript: Inline
---@field content Inlines
---@class Underline: Inline
---@field content Inlines

---@alias Inlines List<Inline>
---@alias InlinesLike List<Inline>|Inline|string

---@class Attr
---@field identifier string
---@field classes List<string>
---@field attributes Attributes
---@class Caption
---@field long Blocks
---@field short Inlines
---@class Cell
---@field attr Attr # cell attributes
---@field alignment Alignment # individual cell alignment
---@field contents Blocks # cell contents
---@field col_span integer # number of columns spanned by the cell; the width of the cell in columns
---@field row_span integer # number of rows spanned by the cell; the height of the cell in rows
---@class Citation
---@field id string
---@field mode string
---@field prefix Inlines
---@field suffix Inlines
---@field note_num integer
---@field hash integer
---@class ListAttributes
---@field start integer
---@field style string
---@field delimiter string
---@class Row
---@field attr Attr
---@field cells List<Cell>
---@class TableBody
---@field attr Attr # table body attributes
---@field body List<Row> # table body rows
---@field head List<Row> # intermediate head
---@field row_head_columns integer # number of columns taken up by the row head of each row of a TableBody. The row body takes up the remaining columns.
---@class TableFoot
---@field attr Attr
---@field rows List<Row>
---@class TableHead
---@field attr Attr
---@field rows List<Row>
---@class SimpleTable
---@field caption Caption
---@field aligns List<Alignment>
---@field widths List<number>
---@field headers List<Inlines>
---@field rows List<List<Blocks>>
---@class ReaderOptions
---@class WriterOptions

---List of key/value pairs. Values can be accessed by using keys as indices to the list table.
---Attributes values are equal in Lua if and only if they are equal in Haskell.
---@alias Attributes table

---Column alignment and width specification for a single table column. This is a pair, i.e., a
---plain table, with the following components: 1) cell alignment, 2) table column width, as a
---fraction of the page width.
---@alias ColSpec { [1]: Alignment, [2]: number }

---Alignment is a string value indicating the horizontal alignment of a table column. The default
---alignment is AlignDefault (often equivalent to centered).
---@alias Alignment "AlignLeft"|"AlignRight"|"AlignCenter"|"AlignDefault"

---Known as Pandoc(blocks[, meta]).
---@param blocks Blocks
---@param meta? Meta
---@return Pandoc
function pandoc.Pandoc(blocks, meta) end
---Known as Meta(table).
---@param table table
---@return Meta
function pandoc.Meta(table) end
---Known as MetaBlocks(blocks).
---@param blocks Blocks
---@return Blocks
function pandoc.MetaBlocks(blocks) end

---Known as MetaInlines(inlines).
---@param inlines Inlines
---@return Inlines
function pandoc.MetaInlines(inlines) end
---Known as MetaList(meta_values).
---@param meta_values List
---@return List
function pandoc.MetaList(meta_values) end
---Known as MetaMap(key_value_map).
---@param key_value_map table
---@return table
function pandoc.MetaMap(key_value_map) end
---Known as MetaString(str).
---@param str string
---@return string
function pandoc.MetaString(str) end
---Known as MetaBool(bool).
---@param bool boolean
---@return boolean
function pandoc.MetaBool(bool) end

---Known as BlockQuote(content).
---@param content Blocks
---@return BlockQuote
function pandoc.BlockQuote(content) end
---Known as BulletList(items).
---@param items List<Blocks>
---@return BulletList
function pandoc.BulletList(items) end
---Known as CodeBlock(text[, attr]).
---@param text string
---@param attr? Attr
---@return CodeBlock
function pandoc.CodeBlock(text, attr) end
---Known as DefinitionList(content). FIXME.
---@param content any
---@return DefinitionList
function pandoc.DefinitionList(content) end
---Known as Div(content[, attr]).
---@param content Blocks
---@param attr? Attr
---@return Div
function pandoc.Div(content, attr) end
---Known as Figure(content[, caption[, attr]]).
---@param content Blocks
---@param caption? Caption
---@param attr? Attr
---@return Figure
function pandoc.Figure(content, caption, attr) end
---Known as Header(level, content[, attr]).
---@param level integer
---@param content Inlines
---@param attr? Attr
---@return Header
function pandoc.Header(level, content, attr) end
---Known as HorizontalRule().
---@return HorizontalRule
function pandoc.HorizontalRule() end
---Known as LineBlock(content).
---@param content List<Inlines>
---@return LineBlock
function pandoc.LineBlock(content) end
---Known as OrderedList(items[, listAttributes]).
---@param items List<Blocks>
---@param listAttributes? ListAttributes
---@return OrderedList
function pandoc.OrderedList(items, listAttributes) end
---Known as Para(content).
---@param content Inlines
---@return Para
function pandoc.Para(content) end
---Known as Plain(content).
---@param content Inlines
---@return Plain
function pandoc.Plain(content) end
---Known as RawBlock(format, text).
---@param format string
---@param text string
---@return RawBlock
function pandoc.RawBlock(format, text) end
---Known as Table(caption, colspecs, head, bodies, foot[, attr]).
---@param caption Caption
---@param colspecs List<ColSpec>
---@param head TableHead
---@param bodies List<TableBody>
---@param foot TableFoot
---@param attr? Attr
---@return Table
function pandoc.Table(caption, colspecs, head, bodies, foot, attr) end

---Known as Blocks(block_like_elements).
---@param block_like_elements BlocksLike
---@return Blocks
function pandoc.Blocks(block_like_elements) end

---Known as Cite(content, citations).
---@param content Inlines
---@param citations List<Citation>
---@return Cite
function pandoc.Cite(content, citations) end
---Known as Code(text[, attr]).
---@param text string
---@param attr? Attr
---@return Code
function pandoc.Code(text, attr) end
---Known as Emph(content).
---@param content Inlines
---@return Emph
function pandoc.Emph(content) end
---Known as Image(caption, src[, title[, attr]]).
---@param caption Inlines
---@param src string
---@param title? string
---@param attr? Attr
---@return Image
function pandoc.Image(caption, src, title, attr) end
---Known as LineBreak().
---@return LineBreak
function pandoc.LineBreak() end
---Known as Link(content, target[, title[, attr]]).
---@param content Inlines
---@param target string
---@param title? string
---@param attr? Attr
---@return Link
function pandoc.Link(content, target, title, attr) end
---Known as Math(mathtype, text).
---@param mathtype "InlineMath"|"DisplayMath"
---@param text string
---@return Math
function pandoc.Math(mathtype, text) end
---Known as DisplayMath(text).
---@param text string
---@return Math
function pandoc.DisplayMath(text) end
---Known as InlineMath(text).
---@param text string
---@return Math
function pandoc.InlineMath(text) end
---Known as Note(content).
---@param content Blocks
---@return Note
function pandoc.Note(content) end
---Known as Quoted(quotetype, content).
---@param quotetype "SingleQuote"|"DoubleQuote"
---@param content Inlines
---@return Quoted
function pandoc.Quoted(quotetype, content) end
---Known as SingleQuoted(content).
---@param content Inlines
---@return Quoted
function pandoc.SingleQuoted(content) end
---Known as DoubleQuoted(content).
---@param content Inlines
---@return Quoted
function pandoc.DoubleQuoted(content) end
---Known as RawInline(format, text).
---@param format string
---@param text string
---@return RawInline
function pandoc.RawInline(format, text) end
---Known as SmallCaps(content).
---@param content Inlines
---@return SmallCaps
function pandoc.SmallCaps(content) end
---Known as SoftBreak().
---@return SoftBreak
function pandoc.SoftBreak() end
---Known as Space().
---@return Space
function pandoc.Space() end
---Known as Span(content[, attr]).
---@param content Inlines
---@param attr? Attr
---@return Span
function pandoc.Span(content, attr) end
---Known as Str(text).
---@param text string
---@return Str
function pandoc.Str(text) end
---Known as Strikeout(content).
---@param content Inlines
---@return Strikeout
function pandoc.Strikeout(content) end
---Known as Strong(content).
---@param content Inlines
---@return Strong
function pandoc.Strong(content) end
---Known as Subscript(content).
---@param content Inlines
---@return Subscript
function pandoc.Subscript(content) end
---Known as Superscript(content).
---@param content Inlines
---@return Superscript
function pandoc.Superscript(content) end
---Known as Underline(content).
---@param content Inlines
---@return Underline
function pandoc.Underline(content) end

---Known as Inlines(inline_like_elements).
---@param inline_like_elements InlinesLike
---@return Inlines
function pandoc.Inlines(inline_like_elements) end

---Known as Attr([identifier[, classes[, attributes]]]).
---@param identifier? string
---@param classes? List<string>
---@param attributes? Attributes
---@return Attr
function pandoc.Attr(identifier, classes, attributes) end
---Known as Cell(blocks[, align[, rowspan[, colspan[, attr]]]]).
---@param blocks Blocks
---@param align? Alignment
---@param rowspan? integer
---@param colspan? integer
---@param attr? Attr
---@return Cell
function pandoc.Cell(blocks, align, rowspan, colspan, attr) end
---Known as Citation(id, mode[, prefix[, suffix[, note_num[, hash]]]]).
---@param id string
---@param mode string
---@param prefix? Inlines
---@param suffix? Inlines
---@param note_num? integer
---@param hash? integer
---@return Citation
function pandoc.Citation(id, mode, prefix, suffix, note_num, hash) end
---Known as ListAttributes([start[, style[, delimiter]]]).
---@param start? integer
---@param style? string
---@param delimiter? string
---@return ListAttributes
function pandoc.ListAttributes(start, style, delimiter) end
---Known as Row([cells[, attr]]).
---@param cells List<Cell>
---@param attr? Attr
---@return Row
function pandoc.Row(cells, attr) end
---Known as TableFoot([rows[, attr]]).
---@param rows List<Row>
---@param attr? Attr
---@return TableFoot
function pandoc.TableFoot(rows, attr) end
---Known as TableHead([rows[, attr]]).
---@param rows List<Row>
---@param attr? Attr
---@return TableHead
function pandoc.TableHead(rows, attr) end
---Known as SimpleTable(caption, aligns, widths, headers, rows).
---@param caption Caption
---@param aligns List<Alignment>
---@param widths List<number>
---@param headers List<Inlines>
---@param rows List<List<Blocks>>
---@return SimpleTable
function pandoc.SimpleTable(caption, aligns, widths, headers, rows) end

---Known as ReaderOptions(opts).
---@param opts table
---@return ReaderOptions
function pandoc.ReaderOptions(opts) end
---Known as WriterOptions(opts).
---@param opts table
---@return WriterOptions
function pandoc.WriterOptions(opts) end
