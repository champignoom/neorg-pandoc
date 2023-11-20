# norg-pandoc

Custom pandoc reader for [Norg
format](https://github.com/nvim-neorg/norg-specs).

> **NOTE**: This is WIP project. May not work in some edge cases.

## As lazy.nvim plugin

Sample config for lazy.nvim:

``` lua
require("lazy").setup({
  -- ...
  {
      "nvim-neorg/neorg",
      -- ...
      config = function()
          require("neorg").setup {
              load = {
                  ["core.defaults"] = {},
                  ["external.pandoc"] = {},
              },
          }
      end,
  },
  {
      "champignoom/norg-pandoc",
      branch = "neorg-plugin",
      config = true,
  },
})
```

You can now run `:Neorg pandoc output-file.pdf` to generate
`output-file.pdf` from the currently opened norg file.

You can tweak pandoc by writing options in the metadata section. Two
options are supported:

- `pandoc-ignore-metadata`: do not render the metadata block in the
  output pdf

- `pandoc-args`: extra arguments for pandoc

For example:

``` norg
@document.meta
title: a document
authors: someone

pandoc-ignore-metadata: true
pandoc-args: [
    --to=context
    --template=template.mkiv
]
@end

* heading
** subheading

   - list item
   - another list item
```

Now run `:Neorg pandoc output-file.pdf`. According to the metadata, a
pdf will be generated from this norg file by ConTeXt, using a template
file named `template.mkiv`, without rendering metadata block.

## Command-line Usage

``` bash
pandoc --from=init.lua # more pandoc options
```

### Example: Convert norg file to markdown file

This is CI code used in this repo to convert Norg README file to
Github-Flavored-Markdown

``` bash
pandoc --from=init.lua --to=gfm README.norg --output=README.md
```

## why?

There is already a [haskell
parser](https://github.com/Simre1/neorg-haskell-parser) that tried to
implement a native pandoc reader, but the project is stalled. Haskell is
good language to make custom parser, but there aren't many people who
can use it.

Many of Neorg's features are already written in Lua, and pandoc has
built-in support for Lua custom parsers. This project is started to
provide full pandoc support as soon as possible.

## Parser Implementation State

Currently most parts of Layer1~4 are done. The left parts are:

- [ ] **Tables**: It's really hard to implement as parser

- [ ] **Macros** (including all kinds of Tags): Waiting for macro
  support in Norg

- [ ] **Complex Links** (links to other Norg files, etc): Waiting for
  standard link resolver module

You can see detailed implement state in [todo.norg](./todo.norg)

## Contributing

All contributions are welcome!

You can test with [busted](https://github.com/lunarmodules/busted) or
[neotest-plenary](https://github.com/nvim-neotest/neotest-plenary)
before making a PR.

All test files should be named like: `test/*_spec.lua`.
