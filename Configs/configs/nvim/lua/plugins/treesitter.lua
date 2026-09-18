-- treesitter.lua
--
-- `branch = "master"` is load-bearing, not cosmetic.
--
-- nvim-treesitter's default branch is now `main`, a ground-up rewrite with a
-- different API: there is no nvim-treesitter.configs module, and setup() takes
-- only { install_dir }. The opts below (auto_install / highlight / indent) are
-- the *master* API. lazy.nvim, given opts and no config function, calls
-- require("nvim-treesitter").setup(opts) -- and the main-branch setup() simply
-- ignores keys it does not know, without erroring. So pinned to main this
-- config produced no warning, no error, and no treesitter highlighting or
-- indentation at all.
--
-- If you ever want to move to the main branch, it is not a one-line change:
-- drop these opts, list parsers explicitly, and start highlighting yourself
-- with a FileType autocmd calling vim.treesitter.start().
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  opts = {
      auto_install = true,  -- installs missing parsers automatically
      highlight = { enable = true },
      indent = { enable = true },
  },
}
