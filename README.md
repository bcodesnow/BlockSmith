# BlockSmith

A fast, native markdown editor for people who work with LLM agents.

Edit CLAUDE.md, AGENTS.md, and any markdown file with a real editor — not a text box. Keep reusable content blocks in sync across every project. Browse Claude Code transcripts without leaving the app.

Built with C++17, Qt 6, and zero Electron.

![BlockSmith](resources/screenshot.png)

## What it does

**Write markdown.** Split view with live preview, syntax highlighting, Mermaid diagrams, formatting toolbar, image paste/drop, scroll sync, export to PDF/HTML/DOCX.

**Sync blocks across projects.** Select text, wrap it as a block, push updates to every file that uses it. Pull changes back. Diff when they diverge. One source of truth for your coding standards, tool configs, agent instructions.

**Manage prompt libraries.** Store, categorize, and copy prompts. Build them in the editor, use them everywhere.

**Browse Claude Code logs.** Open `.jsonl` transcripts directly — role-based filtering, content previews for every API block type, expand to raw JSON.

**Navigate fast.** Quick Switcher (Ctrl+P), document outline, global search (Ctrl+Shift+F), project tree with file management.

## The block format

Blocks live inside your markdown files as HTML comments — invisible in rendered output, portable across any tool:

```markdown
<!-- block: code-style [id:a3f8b2] -->
## Code Style
- Use descriptive names
- Keep functions under 40 lines
- Write tests for edge cases
<!-- /block:a3f8b2 -->
```

Edit the block in BlockSmith's registry, push to all files. Or edit in a file and pull back. The sync engine handles the rest.

## Download

Grab the latest build from [GitHub Releases](https://github.com/bcodesnow/BlockSmith/releases).

## Build from source

Requires Qt 6.10+ (with WebEngine), CMake 3.21+, C++17 compiler.

```bash
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="<your-qt-path>"
cmake --build build
```

## Docs

- [User manual](docs/user-manual.md) — shortcuts, settings, workflows
- [Architecture](docs/architecture.md) — project structure, features, data format

## License

Copyright (C) 2026 Danube Mechatronics Kft.

Authors: kb (kb@danube-mechatronics.com) & Claude (Anthropic)

GPLv3 — see [LICENSE](LICENSE).
