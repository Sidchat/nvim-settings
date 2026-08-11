--[[
=====================================================================
  init.lua — single-file Neovim configuration
  Target: Neovim >= 0.10 (on Linux Mint, install via the unstable PPA,
  the .appimage, or `sudo snap install nvim --classic`; the apt repo
  version is too old for these plugins).

  Location: ~/.config/nvim/init.lua

  Languages: Python, C/C++, Rust, JavaScript/TypeScript, Bash, YAML,
             XML, TOML/INI/JSON (config files), Meson, Terraform
  Colorschemes: tokyonight (default), gruvbox, rose-pine, everforest,
                kanagawa  ->  switch with <leader>c1..c5 or <leader>cs
  Runner keymaps: <leader>r...  (gcc, g++, clang, rustc, cargo,
                python, uv, pip, zsh, terraform, meson)

  First launch: plugins bootstrap automatically, then run :Mason to
  watch LSP servers install. Requires: git, gcc, unzip, curl,
  ripgrep (`sudo apt install ripgrep`) and fd (`sudo apt install fd-find`)
  for Telescope, and nodejs/npm for a few language servers.
=====================================================================
--]]

-- =====================================================================
-- 1. Leader keys (must be set before plugins load)
-- =====================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- =====================================================================
-- 2. Core options — sensible developer defaults
-- =====================================================================
local opt = vim.opt

opt.number = true                 -- absolute line number on cursor line
opt.relativenumber = true         -- relative numbers elsewhere
opt.cursorline = true
opt.signcolumn = "yes"            -- no layout shift when diagnostics appear
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.termguicolors = true

-- Indentation (4 spaces default; overridden per-filetype below)
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.breakindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true              -- case-sensitive if query has capitals
opt.incsearch = true
opt.hlsearch = true

-- Files / persistence
opt.swapfile = false
opt.backup = false
opt.undofile = true               -- persistent undo across sessions
opt.undodir = vim.fn.stdpath("state") .. "/undo"
opt.autoread = true

-- UI / behavior
opt.splitright = true
opt.splitbelow = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"     -- share system clipboard
opt.updatetime = 250
opt.timeoutlen = 400
opt.completeopt = { "menu", "menuone", "noselect" }
opt.inccommand = "split"          -- live preview for :s///
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.confirm = true                -- ask instead of failing on unsaved quit

-- Per-filetype indentation
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "json", "yaml", "xml", "lua",
              "html", "css", "toml", "meson", "terraform" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
})

-- Highlight yanked text briefly
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() (vim.hl or vim.highlight).on_yank({ timeout = 150 }) end,
})

-- Return to last cursor position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- =====================================================================
-- 3. Helper: detect Python virtual environment
--    Shows the *project* name when the venv folder is just ".venv"/"venv"
-- =====================================================================
local function python_venv()
  local venv = vim.env.VIRTUAL_ENV
  if venv == nil or venv == "" then
    return ""
  end
  local name = vim.fn.fnamemodify(venv, ":t")
  if name == ".venv" or name == "venv" or name == "env" or name == ".env" then
    name = vim.fn.fnamemodify(venv, ":h:t")   -- parent dir = project name
  end
  return "󰌠 " .. name
end

-- Helper: "parent/current" directory context for the statusline
local function dir_context()
  local cwd = vim.fn.getcwd()
  local cur = vim.fn.fnamemodify(cwd, ":t")
  local parent = vim.fn.fnamemodify(cwd, ":h:t")
  if parent == "" or parent == "/" then
    return cur
  end
  return parent .. "/" .. cur
end

-- =====================================================================
-- 4. Bootstrap lazy.nvim (plugin manager)
-- =====================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
opt.rtp:prepend(lazypath)

-- =====================================================================
-- 5. Plugins
-- =====================================================================
require("lazy").setup({

  -- ------------------------------------------------------------------
  -- Local AI chat inside neovim
  -- ------------------------------------------------------------------
  {
    "olimorris/codecompanion.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("codecompanion").setup({
        adapters = {
          http = {
	          qwen = function()
	            return require("codecompanion.adapters").extend("openai_compatible", {
	              env = {
	                url = "http://localhost:1234",
	                api_key = "TERM",   -- dummy; LM Studio doesn't check it
	              },
	              schema = {
	                model = { default = "qwen/qwen3-coder-3b-instruct" },  -- match /v1/models exactly
	              },
	            })
	          end,
	        },
        },
        strategies = {
          chat   = { adapter = "qwen" },
          inline = { adapter = "qwen" },
        },
        interactions = {
          chat = {
            opts = {
              prompt_decorator = function(message, adapter, context)
                return string.format("**My Question:**\n\n%s", message)
              end,
            }
          }
        },
        display = {
          chat = {
            separator = "─",           -- Character used between messages
            show_header_separator = false,  -- Toggle header separators (set to false if using markdown plugins)
          },
        },
      })
      vim.keymap.set("n", "<leader>aa", "<cmd>CodeCompanionChat Toggle<CR>", { desc = "AI chat" })
      vim.keymap.set("v", "<leader>ai", ":CodeCompanion ", { desc = "AI inline edit" })
    end,
  },

  -- ------------------------------------------------------------------
  -- Mini icons plugin
  -- ------------------------------------------------------------------
  { 'nvim-mini/mini.icons', version = '*' },

  -- ------------------------------------------------------------------
  -- Markdown plugin
  -- ------------------------------------------------------------------
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },            -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    -- @module 'render-markdown'
    -- @type render.md.UserConfig
    opts = {},
},

  -- ------------------------------------------------------------------
  -- Neovim auto-completions via local AI model
  -- ------------------------------------------------------------------
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("minuet").setup({
        provider = "openai_fim_compatible",
        provider_options = {
          openai_fim_compatible = {
            api_key = "TERM",   -- dummy; Ollama needs none
            name = "LM Studio",
            end_point = "http://localhost:11434/v1/completions",
            model = "qwen2.5-coder-3b-instruct",
            optional = { max_tokens = 128, top_p = 0.9 },
          },
        },
      })
    end,
  },
  -- ------------------------------------------------------------------
  -- Text-to-speech via piper
  -- ------------------------------------------------------------------
  {
    "wolandark/vim-piper",
    init = function()
      -- init runs before the plugin loads, which matters for g: config vars
      vim.g.piper_bin   = vim.fn.expand("~/.local/share/piper/app/piper")
      vim.g.piper_voice = vim.fn.expand("~/.local/share/piper/voices/en_US-joe-medium.onnx")
    end,
     -- runs AFTER the plugin loads: replace its default keymaps
    config = function()
      -- remove the plugin's t-prefix defaults (pcall = don't error if absent)
      for _, m in ipairs({ {"n","tw"}, {"n","tc"}, {"n","tp"}, {"n","tf"}, {"v","tv"} }) do
        pcall(vim.keymap.del, m[1], m[2])
      end
      -- rebind under Space+p
      vim.keymap.set("n", "<leader>pw", "<cmd>call SpeakWord()<CR>",             { desc = "Speak word" })
      vim.keymap.set("n", "<leader>pl", "<cmd>call SpeakCurrentLine()<CR>",      { desc = "Speak line" })
      vim.keymap.set("n", "<leader>pp", "<cmd>call SpeakCurrentParagraph()<CR>", { desc = "Speak paragraph" })
      vim.keymap.set("n", "<leader>pF", "<cmd>call SpeakCurrentFile()<CR>",      { desc = "Speak file" })
      vim.keymap.set("v", "<leader>pv", ":call SpeakVisualSelection()<CR>",      { desc = "Speak selection" })
    end,
  },
  -- ------------------------------------------------------------------
  -- Colorschemes
  -- ------------------------------------------------------------------
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({ style = "night" })
      vim.cmd.colorscheme("tokyonight")   -- << default colorscheme
    end,
  },
  { "ellisonleao/gruvbox.nvim",  lazy = false, priority = 999 },
  { "rose-pine/neovim",          name = "rose-pine", lazy = false, priority = 999 },
  { "sainnhe/everforest",        lazy = false, priority = 999,
    config = function()
      vim.g.everforest_background = "hard"
      vim.g.everforest_better_performance = 1
    end,
  },
  { "rebelot/kanagawa.nvim",     lazy = false, priority = 999 },

  -- ------------------------------------------------------------------
  -- Treesitter — syntax highlighting, indentation, text objects
  -- ------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",   -- rewrite required for Nvim 0.12+; master is frozen (0.11-only)
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        "python", "c", "cpp", "rust", "javascript", "typescript",
        "bash", "yaml", "xml", "toml", "json",  "ini",
        "meson", "terraform", "hcl", "lua", "vim", "vimdoc",
        "markdown", "markdown_inline", "regex", "diff", "gitcommit",
        "make", "cmake", "dockerfile", "requirements", "ssh_config",
      })

      -- Enable highlighting + treesitter indentation whenever a parser exists
--       vim.api.nvim_create_autocmd("FileType", {
--         callback = function(args)
--           local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
--           if lang and pcall(vim.treesitter.language.add, lang) then
--             vim.treesitter.start(args.buf, lang)
--             vim.bo[args.buf].indentexpr =
--               "v:lua.require'nvim-treesitter'.indentexpr()"
--           end
--         end,
--       })
-- Enable highlighting + treesitter indentation whenever a parser exists
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if not lang then return end
          local ok, added = pcall(vim.treesitter.language.add, lang)
          if not (ok and added ~= false and added ~= nil or ok and vim.fn.has("nvim-0.11") == 0) then
            return
          end
          if pcall(vim.treesitter.start, args.buf, lang) then
            vim.bo[args.buf].indentexpr =
              "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

    end,
  },

  -- ------------------------------------------------------------------
  -- Telescope — fuzzy finder
  -- ------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          path_display = { "truncate" },
          file_ignore_patterns = {
            "%.git/", "node_modules/", "__pycache__/", "%.venv/",
            "target/", "build/", "dist/", "%.o$", "%.class$",
          },
        },
      })
      pcall(telescope.load_extension, "fzf")
    end,
  },

  -- ------------------------------------------------------------------
  -- Statusline (lualine) — filename, parent/current dir, venv
  -- ------------------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",                 -- follows active colorscheme
          globalstatus = true,
          section_separators = { left = "", right = "" },
          component_separators = { left = "│", right = "│" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = {
            { dir_context, icon = "" },              -- parent/current dir
            { "filename", path = 0, symbols = { modified = " ●", readonly = " " } },
          },
          lualine_x = {
            { python_venv, color = { fg = "#8ec07c", gui = "bold" } },
            "encoding",
            "filetype",
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- ------------------------------------------------------------------
  -- LSP: mason (installer) + lspconfig
  -- ------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "williamboman/mason.nvim", config = true },
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      { "j-hui/fidget.nvim", opts = {} },   -- LSP progress notifications
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local servers = {
        pyright = {                          -- Python types/navigation
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        ruff = {},                           -- Python lint + fixes
        clangd = {                           -- C / C++
          cmd = { "clangd", "--background-index", "--clang-tidy",
                  "--header-insertion=iwyu" },
        },
        rust_analyzer = {                    -- Rust
          settings = {
            ["rust-analyzer"] = {
              check = { command = "clippy" },
              cargo = { allFeatures = true },
            },
          },
        },
        ts_ls = {},                          -- JavaScript / TypeScript
        bashls = {},                         -- Bash / sh / zsh scripts
        yamlls = {                           -- YAML
          settings = {
            yaml = { keyOrdering = false, format = { enable = true } },
          },
        },
        lemminx = {},                        -- XML
        taplo = {},                          -- TOML config files
        jsonls = {},                         -- JSON config files
        mesonlsp = {},                       -- Meson build files
        terraformls = {},                    -- Terraform
        lua_ls = {                           -- for editing this config
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false },
            },
          },
        },
      }

      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
        automatic_installation = true,
        automatic_enable = false,   -- we enable explicitly below
      })

      -- Native Nvim 0.11+ API; nvim-lspconfig now only supplies the
      -- per-server defaults that vim.lsp.config() merges our settings into.
      for name, cfg in pairs(servers) do
        cfg.capabilities = capabilities
        vim.lsp.config(name, cfg)
        vim.lsp.enable(name)
      end

      -- Diagnostics appearance
      vim.diagnostic.config({
        virtual_text = { prefix = "●" },
        severity_sort = true,
        float = { border = "rounded", source = true },
      })

      -- Buffer-local LSP keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local map = function(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = "LSP: " .. desc })
          end
          map("gd", require("telescope.builtin").lsp_definitions, "Goto definition")
          map("gr", require("telescope.builtin").lsp_references, "Goto references")
          map("gI", require("telescope.builtin").lsp_implementations, "Goto implementation")
          map("gD", vim.lsp.buf.declaration, "Goto declaration")
          map("K",  vim.lsp.buf.hover, "Hover docs")
          map("<leader>lr", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>la", vim.lsp.buf.code_action, "Code action")
          map("<leader>ls", require("telescope.builtin").lsp_document_symbols, "Document symbols")
          map("<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
          map("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Prev diagnostic")
          map("]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
        end,
      })
    end,
  },

  -- ------------------------------------------------------------------
  -- Autocompletion
  -- ------------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = false }),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
      })
    end,
  },

  -- ------------------------------------------------------------------
  -- Formatting on demand (conform.nvim)
  -- ------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          python = { "ruff_format" },
          c = { "clang-format" }, cpp = { "clang-format" },
          rust = { "rustfmt" },
          javascript = { "prettier" }, typescript = { "prettier" },
          json = { "prettier" }, yaml = { "prettier" },
          xml = { "xmlformatter" },
          sh = { "shfmt" }, bash = { "shfmt" }, zsh = { "shfmt" },
          lua = { "stylua" },
          terraform = { "terraform_fmt" },
        },
      })
      vim.keymap.set({ "n", "v" }, "<leader>f", function()
        require("conform").format({ async = true, lsp_fallback = true })
      end, { desc = "Format buffer" })
    end,
  },

  -- ------------------------------------------------------------------
  -- Quality of life
  -- ------------------------------------------------------------------
  { "windwp/nvim-autopairs", event = "InsertEnter", config = true },
  { "lewis6991/gitsigns.nvim", opts = {} },
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl",
    opts = { scope = { enabled = false } } },
  { "numToStr/Comment.nvim", opts = {} },      -- gcc / gc to comment
  { "kylechui/nvim-surround", event = "VeryLazy", config = true },

}, {
  ui = { border = "rounded" },
})

-- =====================================================================
-- 6. General keymaps
-- =====================================================================
local map = vim.keymap.set

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })

-- Resize windows with arrows
map("n", "<C-Up>",    "<cmd>resize +2<CR>")
map("n", "<C-Down>",  "<cmd>resize -2<CR>")
map("n", "<C-Left>",  "<cmd>vertical resize -2<CR>")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>")

-- Move visual selection up/down
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep selection when indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Center cursor on jumps
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Buffers
map("n", "<S-l>", "<cmd>bnext<CR>",     { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Save / quit
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<CR>",  { desc = "Quit window" })

-- Exit terminal mode with double-Esc
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Telescope
local tb = require("telescope.builtin")
map("n", "<leader>sf", tb.find_files,  { desc = "Search files" })
map("n", "<leader>sg", tb.live_grep,   { desc = "Search by grep" })
map("n", "<leader>sw", tb.grep_string, { desc = "Search word under cursor" })
map("n", "<leader>sb", tb.buffers,     { desc = "Search open buffers" })
map("n", "<leader>sh", tb.help_tags,   { desc = "Search help" })
map("n", "<leader>sr", tb.oldfiles,    { desc = "Search recent files" })
map("n", "<leader>sd", tb.diagnostics, { desc = "Search diagnostics" })
map("n", "<leader>sk", tb.keymaps,     { desc = "Search keymaps" })
map("n", "<leader>/",  tb.current_buffer_fuzzy_find, { desc = "Fuzzy find in buffer" })

-- Colorscheme switching
map("n", "<leader>cs", tb.colorscheme, { desc = "Colorscheme picker" })
map("n", "<leader>c1", "<cmd>colorscheme tokyonight<CR>", { desc = "Theme: tokyonight" })
map("n", "<leader>c2", "<cmd>colorscheme gruvbox<CR>",    { desc = "Theme: gruvbox" })
map("n", "<leader>c3", "<cmd>colorscheme rose-pine<CR>",  { desc = "Theme: rose-pine" })
map("n", "<leader>c4", "<cmd>colorscheme everforest<CR>", { desc = "Theme: everforest" })
map("n", "<leader>c5", "<cmd>colorscheme kanagawa<CR>",   { desc = "Theme: kanagawa" })

-- =====================================================================
-- 7. Runner keymaps — compile / run in a bottom split terminal
--    %  = current file,  %<  = current file without extension
-- =====================================================================
local function run_in_term(cmd)
  vim.cmd("write")                       -- save first
  vim.cmd("botright 14split | terminal " .. cmd)
  vim.cmd("startinsert")
end

local function runner(keys, cmd_fn, desc)
  map("n", keys, function() run_in_term(cmd_fn()) end, { desc = "Run: " .. desc })
end

local function file()   return vim.fn.shellescape(vim.fn.expand("%:p")) end
local function noext()  return vim.fn.shellescape(vim.fn.expand("%:p:r")) end

-- Python / uv / pip
runner("<leader>rp", function() return "python3 " .. file() end,        "python <file>")
runner("<leader>ru", function() return "uv run " .. file() end,         "uv run <file>")
runner("<leader>rU", function() return "uv sync" end,                   "uv sync")
runner("<leader>ri", function() return "pip install -r requirements.txt" end, "pip install -r requirements.txt")

-- C / C++
runner("<leader>rg", function()
  return "gcc -Wall -Wextra -g " .. file() .. " -o " .. noext() .. " && " .. noext()
end, "gcc compile + run")
runner("<leader>rG", function()
  return "g++ -Wall -Wextra -std=c++20 -g " .. file() .. " -o " .. noext() .. " && " .. noext()
end, "g++ compile + run")
runner("<leader>rl", function()
  return "clang -Wall -Wextra -g " .. file() .. " -o " .. noext() .. " && " .. noext()
end, "clang compile + run")
runner("<leader>rL", function()
  return "clang++ -Wall -Wextra -std=c++20 -g " .. file() .. " -o " .. noext() .. " && " .. noext()
end, "clang++ compile + run")

-- Rust
runner("<leader>rr", function()
  return "rustc " .. file() .. " -o " .. noext() .. " && " .. noext()
end, "rustc compile + run")
runner("<leader>rc", function() return "cargo run" end,   "cargo run")
runner("<leader>rC", function() return "cargo build" end, "cargo build")
runner("<leader>rT", function() return "cargo test" end,  "cargo test")

-- Shell
runner("<leader>rz", function() return "zsh " .. file() end,  "zsh <file>")
runner("<leader>rb", function() return "bash " .. file() end, "bash <file>")

-- Terraform
runner("<leader>rti", function() return "terraform init" end,  "terraform init")
runner("<leader>rtp", function() return "terraform plan" end,  "terraform plan")
runner("<leader>rta", function() return "terraform apply" end, "terraform apply")

-- Meson
runner("<leader>rms", function() return "meson setup build" end,       "meson setup build")
runner("<leader>rmc", function() return "meson compile -C build" end,  "meson compile")
runner("<leader>rmt", function() return "meson test -C build" end,     "meson test")

-- Plain toggle-style terminal
map("n", "<leader>tt", function()
  vim.cmd("botright 14split | terminal")
  vim.cmd("startinsert")
end, { desc = "Open terminal split" })
