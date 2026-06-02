return {
  {
    "navarasu/onedark.nvim",
    priority = 1000,
    config = function()
      require("onedark").setup({
        style = "deep", -- options: dark, darker, cool, deep, warm, warmer
        transparent = true, -- Make background transparent
        --   -- term_colors = true,
        --   code_style = {
        --     comments = "italic",
        --     keywords = "none",
        --     functions = "none",
        --     strings = "none",
        --     variables = "none",
        --   },
        --   colors = {}, -- you can override colors here
        --   highlights = {
        --     Normal = { bg = "none" },
        --     NormalNC = { bg = "none" },
        --     NormalFloat = { bg = "none" },
        --     FloatBorder = { bg = "none" },
        --     SignColumn = { bg = "none" },
        --     CursorLine = { bg = "none" },
        --     CursorLineNr = { bg = "none" },
        --     LineNr = { bg = "none" },
        --     StatusLine = { bg = "none" },
        --     StatusLineNC = { bg = "none" },
        --     EndOfBuffer = { bg = "none" },
        --   },
      })

      require("onedark").load()
    end,
  },
}
