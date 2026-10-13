# aigent.nvim

A fast, intent-driven LLM assistant for Neovim with built-in email reply workflows and multi-provider backends (defaults to local/remote Ollama).

---

## Features

- **Picker-First with Live Markdown Preview**: Press `<leader>ag` to open a Telescope prompt picker showing your prompt rules, tone, and signature in real-time.
- **0.1s Muscle Memory**: The last-used (or context-default) prompt is **pre-selected at the top**. To run the default, just press `<leader>ag` followed immediately by `<CR>`.
- **Smart NeoMutt & Email Safety**:
  - Automatically routes `filetype == "mail"` to fast cloud models (`gemini-3.8-flash-low` via `agy`, ~1.5s latency).
  - **Mail Header Protection**: If your cursor is resting inside email headers (`From:`, `Subject:`, etc.), the reply is automatically placed below the header separator into the message body—never corrupting email metadata.
  - Groups email action prompts (`reply`, `decline`, `reschedule`, `ack`) at the top of the picker when editing mail.
- **Visual Selection & Inline Replies**: Highlight a specific paragraph or quoted question in visual mode, press `<leader>ag`, and only that selection is sent to the LLM and answered inline.
- **Multi-Provider Support**:
  - **AGY CLI**: Fast cloud models (`gemini-3.8-flash-low`, `gemini-3.8-flash-medium`, etc.).
  - **Ollama / OpenAI-compatible**: Connects to local Ollama (`llama3.2`) or any remote endpoint.
- **Zero-Config Bundled Prompts**: Works immediately out of the box with bundled templates, while supporting user overrides in `~/.config/nvim/prompts/`.

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

    -- AGY configuration (fast cloud models)
    agy = {
      cmd = "agy",
      model = "gemini-3.8-flash-low",
    },

    -- Ollama / OpenAI compatible endpoint
    ollama = {
      endpoint = "http://localhost:11434/v1/chat/completions",
      model = "llama3.2",
      api_key = os.getenv("OPENAI_API_KEY") or "",
    },

    -- Prompts directory (defaults to ~/.config/nvim/prompts)
    prompts_dir = vim.fn.stdpath("config") .. "/prompts",

    -- Automatically use AGY when editing emails (filetype == "mail")
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
- `:AIgentToggleProvider` – Fast command to toggle default provider between Ollama and AGY.

---

## NeoMutt Email Workflow

When opening an email in Neovim from NeoMutt:

1. Press **`<leader>ag`**.
2. Telescope pops up showing your email actions:
   - `reply.md (current)` – Friendly, concise 3–5 sentence reply.
   - `ack.md` – 1–2 sentence confirmation of receipt.
   - `decline.md` – Warm, polite decline of an invitation/request.
   - `reschedule.md` – Apologetic request to reschedule with alternative times.
3. Hit **`<CR>`** immediately to send the standard reply, or type `dec` / `res` and hit **`<CR>`**.
4. The response is inserted directly below the email headers into the message body.

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

Any `.md` file added to your prompts directory will automatically appear in the Telescope picker on your next `<leader>ag` press!

---

## License

MIT © [Mickael Temporao](LICENSE)

---

*Designed and developed with AI pair programming assistance.*
