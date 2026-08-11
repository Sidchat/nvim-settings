# Neovim Configuration — Single-File `init.lua`

A feature-rich, single-file Neovim configuration targeting **Neovim ≥ 0.10**. Batteries included: LSP with Mason, Treesitter syntax highlighting, Telescope fuzzy finding, autocompletion, AI-assisted coding (chat + completions), on-demand formatting, text-to-speech, and one-key runners for compiling / executing code across 8+ languages — all powered by [lazy.nvim](https://github.com/folke/lazy.nvim).

> **Note:** The `Plugin/` directory in this repository contains separate, standalone plugin projects. They are **not** part of this Neovim configuration. The entire setup lives in a single `init.lua` file.

---

## Requirements

| Tool | Purpose | Install |
|---|---|---|
| **Neovim ≥ 0.10** | Editor runtime | `sudo snap install nvim --classic`, [AppImage](https://github.com/neovim/neovim/releases), or [unstable PPA](https://launchpad.net/~neovim-ppa/+archive/ubuntu/unstable) |
| **git** | Plugin bootstrap | `sudo apt install git` |
| **gcc / unzip** | Treesitter & plugin compilation | `sudo apt install gcc unzip` |
| **curl** | LSP downloads | `sudo apt install curl` |
| **ripgrep** | Telescope live grep | `sudo apt install ripgrep` |
| **fd-find** | Telescope file search | `sudo apt install fd-find` |
| **nodejs + npm** | A few language servers | `sudo apt install nodejs npm` |

---

## Installation

1. **Clone or copy** `init.lua` into your Neovim config directory:
   ```bash
   mkdir -p ~/.config/nvim
   cp init.lua ~/.config/nvim/init.lua
   ```

2. **Launch Neovim.** On first run, `lazy.nvim` auto-bootstraps and installs every plugin. Wait for it to finish.

3. **Install LSP servers.** Once plugins are loaded, run:
   ```
   :Mason
   ```
   This opens the Mason UI where language servers install automatically (pyright, ruff, clangd, rust-analyzer, ts_ls, bashls, yamlls, lemminx, taplo, jsonls, mesonlsp, terraformls, lua_ls). Watch the progress and confirm each one finishes.

4. **Restart Neovim.** Everything is ready.

---

## Supported Languages

| Language / Format | LSP | Formatter | Treesitter | Runner |
|---|---|---|---|---|
| **Python** | pyright + ruff | ruff_format | ✅ | `python3`, `uv run`, `uv sync`, `pip install -r` |
| **C** | clangd | clang-format | ✅ | `gcc`, `clang` |
| **C++** | clangd | clang-format | ✅ | `g++`, `clang++` |
| **Rust** | rust-analyzer | rustfmt | ✅ | `rustc`, `cargo run/build/test` |
| **JavaScript / TypeScript** | ts_ls | prettier | ✅ | — |
| **Bash / Zsh / Sh** | bashls | shfmt | ✅ | `bash`, `zsh` |
| **YAML** | yamlls | prettier | ✅ | — |
| **XML** | lemminx | xmlformatter | ✅ | — |
| **TOML / INI / JSON** | taplo + jsonls | prettier | ✅ | — |
| **Terraform (HCL)** | terraformls | terraform_fmt | ✅ | `init`, `plan`, `apply` |
| **Meson** | mesonlsp | — | ✅ | `setup`, `compile`, `test` |
| **Lua** | lua_ls | stylua | ✅ | — |
| **Markdown** | — | — | ✅ (with inline) | — |
| **Dockerfile, CMake, Make, SSH config** | — | — | ✅ | — |

---

## Colorschemes

Five bundled themes. Switch live with a single key:

| Key | Theme |
|---|---|
| `c1` | Tokyo Night *(default)* |
| `c2` | Gruvbox |
| `c3` | Rosé Pine |
| `c4` | Everforest |
| `c5` | Kanagawa |
| `cs` | Colorscheme picker (Telescope fuzzy selector) |

---

## Plugin Overview

### AI & Coding Assistance
- **CodeCompanion.nvim** — Local AI chat inside Neovim (configured for LM Studio / Ollama with Qwen models). Chat with `aa`, inline edit with `ai` (visual mode).
- **Minuet-ai.nvim** — AI-powered autocompletions via local model (FIM-compatible, Ollama endpoint).

### Editing & Navigation
- **nvim-treesitter** — Syntax highlighting, indentation, text objects for 30+ languages.
- **telescope.nvim** (+ fzf-native) — Fuzzy finder for files, grep, buffers, help, diagnostics, keymaps, and more.
- **nvim-cmp** (+ LuaSnip + friendly-snippets) — LSP-powered autocompletion with snippet expansion.
- **conform.nvim** — On-demand formatting with `f`.
- **nvim-autopairs** — Auto-close brackets and quotes.
- **Comment.nvim** — `gcc` / `gc` to toggle comments.
- **nvim-surround** — Add/change/delete surrounding pairs.

### UI & Quality of Life
- **lualine.nvim** — Statusline showing mode, git branch, diagnostics, Python venv, file path, encoding, progress.
- **which-key.nvim** — Popup showing available keymaps as you type.
- **gitsigns.nvim** — Inline git diff markers.
- **indent-blankline.nvim** — Indentation guides.
- **render-markdown.nvim** — Preview Markdown styling in-editor.
- **fidget.nvim** — LSP progress notifications.

### Extras
- **vim-piper** — Text-to-speech via Piper TTS (offline). Keymaps under `p`.
- **mini.icons** — Rich icon set for filetypes and UI.

---

## Keymaps Reference

### General

| Key | Action |
|---|---|
| `` | Leader key |
| `` | Clear search highlight |
| `` | Navigate between windows |
| `` | Resize windows |
| `` / `` | Next / previous buffer |
| `bd` | Delete buffer |
| `w` | Save file |
| `q` | Quit window |
| `tt` | Open terminal split |
| `J` / `K` (visual) | Move selection down / up |
| `<` / `>` (visual) | Indent (preserves selection) |
| `n` / `N` | Next/prev search match (centers cursor) |
| `` (terminal) | Exit terminal mode |

### Telescope (Fuzzy Finder)

| Key | Action |
|---|---|
| `sf` | Find files |
| `sg` | Live grep |
| `sw` | Grep word under cursor |
| `sb` | Open buffers |
| `sh` | Help tags |
| `sr` | Recent files |
| `sd` | Diagnostics |
| `sk` | Keymaps |
| `/` | Fuzzy find in current buffer |

### LSP

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gr` | Go to references |
| `gI` | Go to implementation |
| `gD` | Go to declaration |
| `K` | Hover documentation |
| `lr` | Rename symbol |
| `la` | Code action |
| `ls` | Document symbols |
| `ld` | Line diagnostics float |
| `[d` / `]d` | Jump to prev/next diagnostic |
| `f` | Format buffer (conform) |

### Code Companion (AI)

| Key | Action |
|---|---|
| `aa` | Toggle AI chat |
| `ai` (visual) | AI inline edit on selection |

### Text-to-Speech (Piper)

| Key | Action |
|---|---|
| `pw` | Speak word |
| `pl` | Speak current line |
| `pp` | Speak current paragraph |
| `pF` | Speak entire file |
| `pv` (visual) | Speak visual selection |

### Runner — Compile & Execute

All runners open a bottom-split terminal, save the file first, then execute.

| Key | Command |
|---|---|
| **Python** | |
| `rp` | `python3 ` |
| `ru` | `uv run ` |
| `rU` | `uv sync` |
| `ri` | `pip install -r requirements.txt` |
| **C / C++** | |
| `rg` | `gcc ...  -o  && ` |
| `rG` | `g++ -std=c++20 ...  -o  && ` |
| `rl` | `clang ...  -o  && ` |
| `rL` | `clang++ -std=c++20 ...  -o  && ` |
| **Rust** | |
| `rr` | `rustc  -o  && ` |
| `rc` | `cargo run` |
| `rC` | `cargo build` |
| `rT` | `cargo test` |
| **Shell** | |
| `rz` | `zsh ` |
| `rb` | `bash ` |
| **Terraform** | |
| `rti` | `terraform init` |
| `rtp` | `terraform plan` |
| `rta` | `terraform apply` |
| **Meson** | |
| `rms` | `meson setup build` |
| `rmc` | `meson compile -C build` |
| `rmt` | `meson test -C build` |

---

## AI Setup (Optional)

The config ships with two AI integrations wired for local models:

1. **Chat (`aa`)** — CodeCompanion connects to LM Studio at `http://localhost:1234` using the `qwen/qwen3-coder-3b-instruct` model. Change the URL and model in the `adapters.http.qwen` block to match your setup (Ollama, llama.cpp server, etc.).

2. **Autocompletions** — Minuet-ai connects to Ollama at `http://localhost:11434/v1/completions` using `qwen2.5-coder-3b-instruct`. Adjust the endpoint and model in the `minuet` plugin config.

3. **Text-to-Speech** — Piper TTS expects the binary at `~/.local/share/piper/app/piper` and voice model at `~/.local/share/piper/voices/en_US-joe-medium.onnx`. Install from [Piper's releases](https://github.com/rhasspy/piper/releases) if you want TTS.

---

## Customization

- **Change the default colorscheme** — Edit the `vim.cmd.colorscheme("tokyonight")` line in the tokyonight plugin block.
- **Add a language LSP** — Add a new entry to the `servers` table and the corresponding Treesitter parser.
- **Add a runner** — Use the `runner()` helper pattern: `runner("rx", function() return "your-command " .. file() end, "description")`.
- **Disable AI features** — Comment out or remove the `codecompanion` and `minuet-ai` plugin specs.

---

## License

MIT — use, modify, and share freely.
