# aigent.nvim

Zero-friction, muscle-memory LLM actions for Neovim. Run tailored prompts on any buffer or visual selection in two keystrokes.

---

## Why aigent.nvim?

Most Neovim AI plugins fall into two extremes: either heavy, conversational sidebars that pull you out of your editing flow, or rigid tools with hardcoded prompts. `aigent.nvim` focuses on speed and unobtrusive intent:

- **No Chat Panel Clutter**: Actions execute directly in place on your active buffer or visual selection.
- **0.1s Muscle Memory**: The last-used (or context-default) prompt is pinned to the top. Press `<leader>ag` followed immediately by `<CR>` to execute without typing.
- **Telescope Live Preview**: Browse prompts with a live preview showing the exact instructions, tone, and constraints before firing the request.
- **Context-Aware Intelligence**: Automatically re-ranks prompts and protects buffer structures based on `filetype` (e.g., auto-promoting reply actions and protecting RFC headers when editing mail).
- **Plain Markdown Templates**: Prompts are just `.md` files in `~/.config/nvim/prompts/`—no complex Lua configuration needed.
- **Hybrid Local and Cloud**: Seamlessly toggle between private local models ([Ollama](https://ollama.com/)) and fast cloud models via `agy`.

---

## Workflow

```text
[ Active Buffer or Visual Selection ]
                  │
                  │  Press <leader>ag
                  ▼
┌────────────────────────────────────────────────────────┐
│ Telescope Prompt Picker (Live Markdown Preview)        │
│  * default.md (current)                                │
│    explain.md                                          │
│    refactor.md                                         │
│    reply.md                                            │
└────────────────────────────────────────────────────────┘
                  │
                  │  Press <CR> (or pick & <CR>)
                  ▼
[ Instant Inline Response Insertion / Replacement ]
```

---

## Features

- **Picker-First with Live Preview**: Open a Telescope picker with `<leader>ag` showing your prompt rules and constraints in real-time.
- **Zero-Keystroke Repetition**: The last-used prompt is always top-ranked. To re-run or run the default, simply press `<leader>ag<CR>`.
- **Visual Selection & Inline Operations**: Highlight a code block, paragraph, or question in visual mode, press `<leader>ag`, and only that selection is transformed.
- **Smart Mail & Header Protection**: When `filetype == "mail"`, prompts are automatically reordered for communication (`reply`, `decline`, `reschedule`, `ack`), and insertions avoid email headers (`From:`, `Subject:`) to prevent metadata corruption.
- **Multi-Provider Switching**: Quick toggle (`<leader>ap` or `:AIgentToggleProvider`) between local Ollama and cloud CLI (`agy`).
- **Zero-Config Bundled Templates**: Works immediately out of the box while allowing user overrides in `~/.config/nvim/prompts/`.

---

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  "mickaeltemporao/aigent.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  opts = {
    -- Default provider: "ollama" or "agy"
    provider = "ollama",

    -- agy CLI configuration (fast cloud models)
    agy = {
      cmd = "agy",
      model = "gemini-3.8-flash-low",
    },

    -- Ollama / OpenAI-compatible endpoint
    ollama = {
      endpoint = "http://localhost:11434/v1/chat/completions",
      model = "llama3.2",
      api_key = os.getenv("OPENAI_API_KEY") or "",
    },

    -- Prompts directory (defaults to ~/.config/nvim/prompts)
    prompts_dir = vim.fn.stdpath("config") .. "/prompts",

    -- Automatically route mail buffers (filetype == "mail") to agy
    auto_mail_agy = true,
  },
}
```

> **Tip for local development**: Use `dir = "~/Documents/code/aigent"` (or your local clone path) inside the lazy spec.

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use({
  "mickaeltemporao/aigent.nvim",
  requires = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("aigent").setup({
      provider = "ollama",
    })
  end,
})
```

---

## Keymaps & Commands

| Keymap | Mode | Command | Action |
| :--- | :--- | :--- | :--- |
| **`<leader>ag`** | Normal / Visual | `:AIgent` | Open prompt picker (pre-selected to last/default prompt, live preview) and execute on `<CR>` |
| **`<leader>ap`** | Normal | `:AIgentProvider` | Open Telescope dropdown to switch provider (`ollama` vs `agy`) |

### Additional Commands

- `:AIgent [prompt_file]` – Run AIgent directly with a specific prompt file.
- `:AIgentPrompt` – Open prompt picker with live preview.
- `:AIgentToggleProvider` – Fast command to toggle default provider between Ollama and agy.

---

## Custom Prompts

Prompts are standard Markdown files located in `~/.config/nvim/prompts/` (or the directory specified in `prompts_dir`).

Example prompt (`~/.config/nvim/prompts/summary.md`):

```markdown
# Summarize Agent

## Goal
Summarize the input text into 3 bullet points.

## Constraints
- Length: Max 3 bullet points.
- Tone: Direct and factual.
- Formatting: Return raw plain text only. Do NOT wrap in markdown code blocks.
```

Any `.md` file added to your prompts directory will automatically appear in the Telescope picker on your next `<leader>ag` press.

---

## License

GPL-3.0 © [Mickael Temporao](LICENSE)

---

*Designed and developed with AI pair programming assistance.*
