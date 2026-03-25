# Supermaven Setup Notes

Replaced GitHub Copilot with [Supermaven](https://supermaven.com) for AI inline completion.

## What changed

- `vim/nvim-lazy-plugins.lua`: Replaced `github/copilot.vim` with `supermaven-inc/supermaven-nvim`, removed `CopilotC-Nvim/CopilotChat.nvim`
- `vim/neovim/vimrc`: Removed copilot settings (`g:copilot_settings`, `g:copilot_filetypes`)
- `vim/neovim/mappings.vim`: Removed stale copilot/S-Tab comment

## First launch

On first launch Neovim will install the plugin. Supermaven will then prompt you to log in — a free account is sufficient.

## Keymaps

| Key     | Action               |
|---------|----------------------|
| `<C-f>` | Accept full suggestion |
| `<C-j>` | Accept next word     |
| `<C-]>` | Clear suggestion     |

## Alternatives considered

| Option | Notes |
|--------|-------|
| Codeium | Free, fast, not Claude |
| minuet-ai + Claude API | Claude-backed inline completions, higher latency (~300-800ms) |
| Ollama + local model | Fully local (qwen2.5-coder:7b works well on Apple Silicon), no API costs |
