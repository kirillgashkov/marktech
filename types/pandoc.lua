---@meta

-- Made by hand on 2024-05-20 from https://pandoc.org/lua-filters.html.

---pandoc is a module that can be used in Lua filters, readers and writers. See
---https://pandoc.org/lua-filters.html.
---@type table
pandoc = {}
---@type table
lpeg = {}
---@type table
re = {}
---@type string
FORMAT = ""
---@type {[1]: integer, [2]: integer, [3]: integer}
PANDOC_VERSION = {}
---@type {[1]: integer, [2]: integer, [3]: integer}
PANDOC_API_VERSION = {}
---@type string
PANDOC_SCRIPT_FILE = ""
---@type table
PANDOC_STATE = {}

-- As much as I'd like to declare the List type at least with fields, only the
-- monstrosity you are about to see works as expected. In any case, the fields
-- version is here to make maintenance easier.
-- ---@class List<T>: { [integer]: T }
-- ---@field __concat fun(self: List<T>, list: List<T>): List<T>
-- ---@field __eq fun(a: List<T>, b: List<T>): boolean
-- ---@field clone fun(self: List<T>): List<T>
-- ---@field extend fun(self: List<T>, list: List<T>): List<T>
-- ---@field find fun(self: List<T>, value: T, start_at: integer): any|nil
-- ---@field find_if fun(self: List<T>, predicate: fun(value: T): boolean, start_at: integer): any|nil
-- ---@field filter fun(self: List<T>, predicate: fun(value: T): boolean): List<T>
-- ---@field includes fun(self: List<T>, value: T, start_at?: integer | nil): boolean
-- ---@field insert (fun(self: List<T>, index: integer, value: T): nil) | (fun(self: List<T>, value: T): nil)
-- ---@field map  fun(self: List<T>, fn: fun(value: T): any): List<any>
-- ---@field new fun(self: List<T>, table_: any[]): List<any>
-- ---@field remove fun(self: List<T>, index: integer): T
-- ---@field sort fun(self: List<T>, comparator: fun(left: T, right: T): boolean): nil

---Known methods:
---
---* List:__concat(list).
---* List:__eq(a, b).
---* List:clone(). Shallow copy. walk can be used to get a deep copy.
---* List:extend(list).
---* List:find(needle, init). Returns first item equal to the needle, or nil if no such item exists.
---* List:find_if(pred, init). Returns first item for which `test` succeeds, or nil if no such item exists.
---* List:filter(pred).
---* List:includes(needle, init). Checks if the list has an item equal to the given needle.
---* List:insert([pos], value). Inserts element value at position pos in list, shifting elements to the next-greater
---  index if necessary.
---* List:map(fn).
---* List:new(table).
---* List:remove(pos).
---* List:sort(comp).
---@class pandoc.List<T>: { [integer]: T, __concat: (fun(self: pandoc.List<T>, list: pandoc.List<T>): pandoc.List<T>), __eq: (fun(a: pandoc.List<T>, b: pandoc.List<T>): boolean), clone: (fun(self: pandoc.List<T>): pandoc.List<T>), extend: (fun(self: pandoc.List<T>, list: pandoc.List<T>): pandoc.List<T>), find: (fun(self: pandoc.List<T>, value: T, start_at: integer): any|nil), find_if: (fun(self: pandoc.List<T>, predicate: fun(value: T): boolean, start_at: integer): any|nil), filter: (fun(self: pandoc.List<T>, predicate: fun(value: T): boolean): pandoc.List<T>), includes: (fun(self: pandoc.List<T>, value: T, start_at?: integer | nil): boolean), insert: ((fun(self: pandoc.List<T>, index: integer, value: T): nil) | (fun(self: pandoc.List<T>, value: T): nil)), map: (fun(self: pandoc.List<T>, fn: fun(value: T): any): pandoc.List<any>), new: (fun(self: pandoc.List<T>, table_: any[]): pandoc.List<any>), remove: (fun(self: pandoc.List<T>, index: integer): T), sort: (fun(self: pandoc.List<T>, comparator: fun(left: T, right: T): boolean): nil) }

---@generic T
---@param table_? T[]
---@return pandoc.List<T>
function pandoc.List(table_) end

---@class pandoc.Pandoc
---@field blocks pandoc.Blocks
---@field meta pandoc.Meta
local Pandoc = {}
---@param lua_filter table
---@return pandoc.Pandoc
function Pandoc:walk(lua_filter) end
---@alias pandoc.Meta table

---@class pandoc.Block
local Block = {}
---@return pandoc.Block
function Block:clone() end
---@class pandoc.BlockQuote: pandoc.Block
---@field content pandoc.Blocks
---@field tag "BlockQuote"
---@class pandoc.BulletList: pandoc.Block
---@field content pandoc.List<pandoc.Blocks>
---@field tag "BulletList"
---@class pandoc.CodeBlock: pandoc.Block
---@field text string
---@field attr pandoc.Attr
---@field tag "CodeBlock"
---@class pandoc.DefinitionList: pandoc.Block
---@field content any
---@field tag "DefinitionList"
---@class pandoc.Div: pandoc.Block
---@field content pandoc.Blocks
---@field attr pandoc.Attr
---@field tag "Div"
---@class pandoc.Figure: pandoc.Block
---@field content pandoc.Blocks
---@field attr pandoc.Attr
---@field tag "Figure"
---@class pandoc.Header: pandoc.Block
---@field level integer
---@field content pandoc.Inlines
---@field attr pandoc.Attr
---@field tag "Header"
---@class pandoc.HorizontalRule: pandoc.Block
---@field tag "HorizontalRule"
---@class pandoc.LineBlock: pandoc.Block
---@field content pandoc.List<pandoc.Inlines>
---@field tag "LineBlock"
---@class pandoc.OrderedList: pandoc.Block
---@field content pandoc.List<pandoc.Blocks>
---@field listAttributes pandoc.ListAttributes
---@field tag "OrderedList"
---@class pandoc.Para: pandoc.Block
---@field content pandoc.Inlines
---@field tag "Para"
---@class pandoc.Plain: pandoc.Block
---@field content pandoc.Inlines
---@field tag "Plain"
---@class pandoc.RawBlock: pandoc.Block
---@field format string
---@field text string
---@field tag "RawBlock"
---@class pandoc.Table: pandoc.Block
---@field attr pandoc.Attr
---@field caption pandoc.Caption
---@field colspecs pandoc.List<pandoc.ColSpec>
---@field head pandoc.TableHead
---@field bodies pandoc.List<pandoc.TableBody>
---@field foot pandoc.TableFoot
---@field tag "Table"

---@alias pandoc.Blocks pandoc.List<pandoc.Block>
---Inferred.
---@alias pandoc.BlocksLike pandoc.List<pandoc.Block>|pandoc.Inlines|string

---@class pandoc.Inline
local Inline = {}
---@return pandoc.Inline
function Inline:clone() end
---@class pandoc.Cite: pandoc.Inline
---@field content pandoc.Inlines
---@field citations pandoc.List<pandoc.Citation>
---@field tag "Cite"
---@class pandoc.Code: pandoc.Inline
---@field text string
---@field attr pandoc.Attr
---@field tag "Code"
---@class pandoc.Emph: pandoc.Inline
---@field content pandoc.Inlines
---@field tag "Emph"
---@class pandoc.Image: pandoc.Inline
---@field caption pandoc.Inlines
---@field src string
---@field title string
---@field attr pandoc.Attr
---@field tag "Image"
---@class pandoc.LineBreak: pandoc.Inline
---@field tag "LineBreak"
---@class pandoc.Link: pandoc.Inline
---@field attr pandoc.Attr
---@field content pandoc.Inlines
---@field target string
---@field title string
---@field tag "Link"
---@class pandoc.Math: pandoc.Inline
---@field mathtype "InlineMath"|"DisplayMath"
---@field text string
---@field tag "Math"
---@class pandoc.Note: pandoc.Inline
---@field content pandoc.Blocks
---@field tag "Note"
---@class pandoc.Quoted: pandoc.Inline
---@field quoteType "SingleQuote"|"DoubleQuote"
---@field content pandoc.Inlines
---@field tag "Quoted"
---@class pandoc.RawInline: pandoc.Inline
---@field format string
---@field text string
---@field tag "RawInline"
---@class pandoc.SmallCaps: pandoc.Inline
---@field content pandoc.Inlines
---@field tag "SmallCaps"
---@class pandoc.SoftBreak: pandoc.Inline
---@field tag "SoftBreak"
---@class pandoc.Space: pandoc.Inline
---@field tag "Space"
---@class pandoc.Span: pandoc.Inline
---@field attr pandoc.Attr
---@field content pandoc.Inlines
---@field tag "Span"
---@class pandoc.Str: pandoc.Inline
---@field text string
---@field tag "Str"
---@class pandoc.Strikeout: pandoc.Inline
---@field content pandoc.Inlines
---@field tag "Strikeout"
---@class pandoc.Strong: pandoc.Inline
---@field content pandoc.Inlines
---@field tag "Strong"
---@class pandoc.Subscript: pandoc.Inline
---@field content pandoc.Inlines
---@field tag "Subscript"
---@class pandoc.Superscript: pandoc.Inline
---@field content pandoc.Inlines
---@class pandoc.Underline: pandoc.Inline
---@field content pandoc.Inlines

---@alias pandoc.Inlines pandoc.List<pandoc.Inline>
---Inferred.
---@alias pandoc.InlinesLike pandoc.List<pandoc.Inline>|pandoc.Inline|string

---@class pandoc.Attr
---@field identifier string
---@field classes pandoc.List<string>
---@field attributes pandoc.Attributes
---@class pandoc.Caption
---@field long pandoc.Blocks
---@field short pandoc.Inlines | nil
---@class pandoc.Cell
---@field attr pandoc.Attr # cell attributes
---@field alignment pandoc.Alignment # individual cell alignment
---@field contents pandoc.Blocks # cell contents
---@field col_span integer # number of columns spanned by the cell; the width of the cell in columns
---@field row_span integer # number of rows spanned by the cell; the height of the cell in rows
---@class pandoc.Citation
---@field id string
---@field mode string
---@field prefix pandoc.Inlines
---@field suffix pandoc.Inlines
---@field note_num integer
---@field hash integer
---@class pandoc.ListAttributes
---@field start integer
---@field style string
---@field delimiter string
---@class pandoc.Row
---@field attr pandoc.Attr
---@field cells pandoc.List<pandoc.Cell>
---@class pandoc.TableBody
---@field attr pandoc.Attr # table body attributes
---@field body pandoc.List<pandoc.Row> # table body rows
---@field head pandoc.List<pandoc.Row> # intermediate head
---@field row_head_columns integer # number of columns taken up by the row head of each row of a TableBody. The row body takes up the remaining columns.
---@class pandoc.TableFoot
---@field attr pandoc.Attr
---@field rows pandoc.List<pandoc.Row>
---@class pandoc.TableHead
---@field attr pandoc.Attr
---@field rows pandoc.List<pandoc.Row>
---@class pandoc.SimpleTable
---@field caption pandoc.Caption
---@field aligns pandoc.List<pandoc.Alignment>
---@field widths pandoc.List<number>
---@field headers pandoc.List<pandoc.Inlines>
---@field rows pandoc.List<pandoc.List<pandoc.Blocks>>
---@class pandoc.Template
---@class pandoc.ReaderOptions
---@field abbreviations any # set of known abbreviations, originally set of strings
---@field columns integer # number of columns in terminal
---@field default_image_extension string # default extension for images
---@field extensions string[] # string representation of the syntax extensions bit field, originally sequence of strings
---@field indented_code_classes string[] # default classes for indented code blocks, originally list of strings
---@field standalone boolean # whether the input was a standalone document with header
---@field strip_comments boolean # HTML comments are stripped instead of parsed as raw HTML
---@field tab_stop integer # width (i.e. equivalent number of spaces) of tab stops
---@field track_changes string # track changes setting for docx; one of accept-changes, reject-changes, and all-changes
---@class pandoc.WriterOptions
---@field chunk_template string # Template used to generate chunked HTML filenames
---@field cite_method string # How to print cites – one of ‘citeproc’, ‘natbib’, or ‘biblatex’
---@field columns integer # Characters in a line (for text wrapping)
---@field dpi integer # DPI for pixel to/from inch/cm conversions
---@field email_obfuscation string # How to obfuscate emails – one of ‘none’, ‘references’, or ‘javascript’
---@field epub_chapter_level integer # Header level for chapters, i.e., how the document is split into separate files
---@field epub_fonts string[] # Paths to fonts to embed, originally sequence of strings
---@field epub_metadata string|nil # Metadata to include in EPUB
---@field epub_subdirectory string # Subdir for epub in OCF
---@field extensions string[] # Markdown extensions that can be used, originally sequence of strings
---@field highlight_style table|nil # Style to use for highlighting; see the output of pandoc --print-highlight-style=... for an example structure. The value nil means that no highlighting is used.
---@field html_math_method string|table # How to print math in HTML; one ‘plain’, ‘gladtex’, ‘webtex’, ‘mathml’, ‘mathjax’, or a table with keys method and url.
---@field html_q_tags boolean # Use <q> tags for quotes in HTML
---@field identifier_prefix string # Prefix for section & note ids in HTML and for footnote marks in markdown
---@field incremental boolean # True if lists should be incremental
---@field listings boolean # Use listings package for code
---@field number_offset integer[] # Starting number for section, subsection, …, originally sequence of integers
---@field number_sections boolean # Number sections in LaTeX
---@field prefer_ascii boolean # Prefer ASCII representations of characters when possible
---@field reference_doc string|nil # Path to reference document if specified
---@field reference_links boolean # Use reference links in writing markdown, rst
---@field reference_location string # Location of footnotes and references for writing markdown; one of ‘end-of-block’, ‘end-of-section’, ‘end-of-document’. The common prefix may be omitted when setting this value.
---@field section_divs boolean # Put sections in div tags in HTML
---@field setext_headers boolean # Use setext headers for levels 1-2 in markdown
---@field slide_level integer|nil # Force header level of slides
---@field tab_stop integer # Tabstop for conversion btw spaces and tabs
---@field table_of_contents boolean # Include table of contents
---@field template pandoc.Template|nil # Template to use
---@field toc_depth integer # Number of levels to include in TOC
---@field top_level_division string # Type of top-level divisions; one of ‘top-level-part’, ‘top-level-chapter’, ‘top-level-section’, or ‘top-level-default’. The prefix top-level may be omitted when setting this value.
---@field variables { [string]: pandoc.Variable } # Variables to set in template; string-indexed table
---@field wrap_text string # Option for wrapping text; one of ‘wrap-auto’, ‘wrap-none’, or ‘wrap-preserve’. The wrap- prefix may be omitted when setting this value.

---List of key/value pairs. Values can be accessed by using keys as indices to the list table.
---Attributes values are equal in Lua if and only if they are equal in Haskell.
---@alias pandoc.Attributes table<string, string>

---Column alignment and width specification for a single table column. This is a pair, i.e., a
---plain table, with the following components: 1) cell alignment, 2) table column width, as a
---fraction of the page width.
---@alias pandoc.ColSpec { [1]: pandoc.Alignment, [2]: number | nil }

---Alignment is a string value indicating the horizontal alignment of a table column. The default
---alignment is AlignDefault (often equivalent to centered).
---@alias pandoc.Alignment "AlignLeft"|"AlignRight"|"AlignCenter"|"AlignDefault"

---Known as Pandoc(blocks[, meta]).
---@param blocks pandoc.Blocks
---@param meta? pandoc.Meta
---@return pandoc.Pandoc
function pandoc.Pandoc(blocks, meta) end
---Known as Meta(table).
---@param table table
---@return pandoc.Meta
function pandoc.Meta(table) end
---Known as MetaBlocks(blocks).
---@param blocks pandoc.Blocks
---@return pandoc.Blocks
function pandoc.MetaBlocks(blocks) end

---Known as MetaInlines(inlines).
---@param inlines pandoc.Inlines
---@return pandoc.Inlines
function pandoc.MetaInlines(inlines) end
---Known as MetaList(meta_values).
---@param meta_values pandoc.List
---@return pandoc.List
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
---@param content pandoc.Blocks
---@return pandoc.BlockQuote
function pandoc.BlockQuote(content) end
---Known as BulletList(items).
---@param items pandoc.List<pandoc.Blocks>
---@return pandoc.BulletList
function pandoc.BulletList(items) end
---Known as CodeBlock(text[, attr]).
---@param text string
---@param attr? pandoc.Attr
---@return pandoc.CodeBlock
function pandoc.CodeBlock(text, attr) end
---Known as DefinitionList(content). FIXME.
---@param content any
---@return pandoc.DefinitionList
function pandoc.DefinitionList(content) end
---Known as Div(content[, attr]).
---@param content pandoc.Blocks
---@param attr? pandoc.Attr
---@return pandoc.Div
function pandoc.Div(content, attr) end
---Known as Figure(content[, caption[, attr]]).
---@param content pandoc.Blocks
---@param caption? pandoc.Caption
---@param attr? pandoc.Attr
---@return pandoc.Figure
function pandoc.Figure(content, caption, attr) end
---Known as Header(level, content[, attr]).
---@param level integer
---@param content pandoc.Inlines
---@param attr? pandoc.Attr
---@return pandoc.Header
function pandoc.Header(level, content, attr) end
---Known as HorizontalRule().
---@return pandoc.HorizontalRule
function pandoc.HorizontalRule() end
---Known as LineBlock(content).
---@param content pandoc.List<pandoc.Inlines>
---@return pandoc.LineBlock
function pandoc.LineBlock(content) end
---Known as OrderedList(items[, listAttributes]).
---@param items pandoc.List<pandoc.Blocks>
---@param listAttributes? pandoc.ListAttributes
---@return pandoc.OrderedList
function pandoc.OrderedList(items, listAttributes) end
---Known as Para(content).
---@param content pandoc.Inlines
---@return pandoc.Para
function pandoc.Para(content) end
---Known as Plain(content).
---@param content pandoc.Inlines
---@return pandoc.Plain
function pandoc.Plain(content) end
---Known as RawBlock(format, text).
---@param format string
---@param text string
---@return pandoc.RawBlock
function pandoc.RawBlock(format, text) end
---Known as Table(caption, colspecs, head, bodies, foot[, attr]).
---@param caption pandoc.Caption
---@param colspecs pandoc.List<pandoc.ColSpec>
---@param head pandoc.TableHead
---@param bodies pandoc.List<pandoc.TableBody>
---@param foot pandoc.TableFoot
---@param attr? pandoc.Attr
---@return pandoc.Table
function pandoc.Table(caption, colspecs, head, bodies, foot, attr) end

---Known as Blocks(block_like_elements).
---@param block_like_elements pandoc.BlocksLike
---@return pandoc.Blocks
function pandoc.Blocks(block_like_elements) end

---Known as Cite(content, citations).
---@param content pandoc.Inlines
---@param citations pandoc.List<pandoc.Citation>
---@return pandoc.Cite
function pandoc.Cite(content, citations) end
---Known as Code(text[, attr]).
---@param text string
---@param attr? pandoc.Attr
---@return pandoc.Code
function pandoc.Code(text, attr) end
---Known as Emph(content).
---@param content pandoc.Inlines
---@return pandoc.Emph
function pandoc.Emph(content) end
---Known as Image(caption, src[, title[, attr]]).
---@param caption pandoc.Inlines
---@param src string
---@param title? string
---@param attr? pandoc.Attr
---@return pandoc.Image
function pandoc.Image(caption, src, title, attr) end
---Known as LineBreak().
---@return pandoc.LineBreak
function pandoc.LineBreak() end
---Known as Link(content, target[, title[, attr]]).
---@param content pandoc.Inlines
---@param target string
---@param title? string
---@param attr? pandoc.Attr
---@return pandoc.Link
function pandoc.Link(content, target, title, attr) end
---Known as Math(mathtype, text).
---@param mathtype "InlineMath"|"DisplayMath"
---@param text string
---@return pandoc.Math
function pandoc.Math(mathtype, text) end
---Known as DisplayMath(text).
---@param text string
---@return pandoc.Math
function pandoc.DisplayMath(text) end
---Known as InlineMath(text).
---@param text string
---@return pandoc.Math
function pandoc.InlineMath(text) end
---Known as Note(content).
---@param content pandoc.Blocks
---@return pandoc.Note
function pandoc.Note(content) end
---Known as Quoted(quotetype, content).
---@param quotetype "SingleQuote"|"DoubleQuote"
---@param content pandoc.Inlines
---@return pandoc.Quoted
function pandoc.Quoted(quotetype, content) end
---Known as SingleQuoted(content).
---@param content pandoc.Inlines
---@return pandoc.Quoted
function pandoc.SingleQuoted(content) end
---Known as DoubleQuoted(content).
---@param content pandoc.Inlines
---@return pandoc.Quoted
function pandoc.DoubleQuoted(content) end
---Known as RawInline(format, text).
---@param format string
---@param text string
---@return pandoc.RawInline
function pandoc.RawInline(format, text) end
---Known as SmallCaps(content).
---@param content pandoc.Inlines
---@return pandoc.SmallCaps
function pandoc.SmallCaps(content) end
---Known as SoftBreak().
---@return pandoc.SoftBreak
function pandoc.SoftBreak() end
---Known as Space().
---@return pandoc.Space
function pandoc.Space() end
---Known as Span(content[, attr]).
---@param content pandoc.Inlines
---@param attr? pandoc.Attr
---@return pandoc.Span
function pandoc.Span(content, attr) end
---Known as Str(text).
---@param text string
---@return pandoc.Str
function pandoc.Str(text) end
---Known as Strikeout(content).
---@param content pandoc.Inlines
---@return pandoc.Strikeout
function pandoc.Strikeout(content) end
---Known as Strong(content).
---@param content pandoc.Inlines
---@return pandoc.Strong
function pandoc.Strong(content) end
---Known as Subscript(content).
---@param content pandoc.Inlines
---@return pandoc.Subscript
function pandoc.Subscript(content) end
---Known as Superscript(content).
---@param content pandoc.Inlines
---@return pandoc.Superscript
function pandoc.Superscript(content) end
---Known as Underline(content).
---@param content pandoc.Inlines
---@return pandoc.Underline
function pandoc.Underline(content) end

---Known as Inlines(inline_like_elements).
---@param inline_like_elements pandoc.InlinesLike
---@return pandoc.Inlines
function pandoc.Inlines(inline_like_elements) end

---Known as Attr([identifier[, classes[, attributes]]]).
---@param identifier? string
---@param classes? pandoc.List<string>
---@param attributes? pandoc.Attributes
---@return pandoc.Attr
function pandoc.Attr(identifier, classes, attributes) end
---Known as Cell(blocks[, align[, rowspan[, colspan[, attr]]]]).
---@param blocks pandoc.Blocks
---@param align? pandoc.Alignment
---@param rowspan? integer
---@param colspan? integer
---@param attr? pandoc.Attr
---@return pandoc.Cell
function pandoc.Cell(blocks, align, rowspan, colspan, attr) end
---Known as Citation(id, mode[, prefix[, suffix[, note_num[, hash]]]]).
---@param id string
---@param mode string
---@param prefix? pandoc.Inlines
---@param suffix? pandoc.Inlines
---@param note_num? integer
---@param hash? integer
---@return pandoc.Citation
function pandoc.Citation(id, mode, prefix, suffix, note_num, hash) end
---Known as ListAttributes([start[, style[, delimiter]]]).
---@param start? integer
---@param style? string
---@param delimiter? string
---@return pandoc.ListAttributes
function pandoc.ListAttributes(start, style, delimiter) end
---Known as Row([cells[, attr]]).
---@param cells pandoc.List<pandoc.Cell>
---@param attr? pandoc.Attr
---@return pandoc.Row
function pandoc.Row(cells, attr) end
---Known as TableFoot([rows[, attr]]).
---@param rows pandoc.List<pandoc.Row>
---@param attr? pandoc.Attr
---@return pandoc.TableFoot
function pandoc.TableFoot(rows, attr) end
---Known as TableHead([rows[, attr]]).
---@param rows pandoc.List<pandoc.Row>
---@param attr? pandoc.Attr
---@return pandoc.TableHead
function pandoc.TableHead(rows, attr) end
---Known as SimpleTable(caption, aligns, widths, headers, rows).
---@param caption pandoc.Caption
---@param aligns pandoc.List<pandoc.Alignment>
---@param widths pandoc.List<number>
---@param headers pandoc.List<pandoc.Inlines>
---@param rows pandoc.List<pandoc.List<pandoc.Blocks>>
---@return pandoc.SimpleTable
function pandoc.SimpleTable(caption, aligns, widths, headers, rows) end

---Known as ReaderOptions(opts).
---@param opts table
---@return pandoc.ReaderOptions
function pandoc.ReaderOptions(opts) end
---Known as WriterOptions(opts).
---@param opts table
---@return pandoc.WriterOptions
function pandoc.WriterOptions(opts) end

---Source hasn't been found in the official documentation but it has been inferred.
---@class pandoc.Source
---@field name string # Source name. E.g. "input.txt".
---@field text string # Source text. E.g. "# Hello world".

---Sources hasn't been found in the official documentation but it has been inferred.
---@class pandoc.Sources: pandoc.List<pandoc.Source>
---@field __tostring fun(): string  # (Probably) returns just the concatenated text of all sources.

---Variable hasn't been found in the official documentation but it has been inferred.
---@class pandoc.Variable
---@field render fun(): string # (Probably) returns the value of the variable.
