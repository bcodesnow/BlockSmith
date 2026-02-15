# BlockSmith

Manage reusable content blocks across CLAUDE.md and agent instruction files. One block, synced everywhere.

Built with C++17 / Qt 6 / QML.

![BlockSmith](resources/screenshot.png)

## Why

Agent instruction files (CLAUDE.md, AGENTS.md) live in every project. Common sections — coding standards, tool configs, response style — drift out of sync. BlockSmith gives you a central registry to push, pull, diff, and sync blocks across all your projects.

## Features

- **Project discovery** — configurable search paths, trigger file detection (.git, CLAUDE.md, etc.), auto-scan on startup
- **Tree navigation** — expand/collapse all, block usage highlighting, right-click context menu (Open, Reveal in Explorer, Copy Path)
- **Markdown editor** — syntax highlighting, line numbers, block gutter markers with sync status, edit/preview toggle (Ctrl+E)
- **Live preview** — rendered HTML via md4c
- **Block system** — create blocks from editor selection, bidirectional push/pull sync, diff view for conflicts, tag-based filtering
- **Prompt library** — categorized prompts, one-click clipboard copy, create from editor selection
- **Global search** — search across all project files (Ctrl+Shift+F)
- **Find & Replace** — in-editor search with replace (Ctrl+F / Ctrl+H)
- **New project scaffolding** — create projects with folder picker and trigger file selection
- **Dark theme** — 3-pane layout, toast notifications, status bar with word/char/line count, keyboard shortcuts

## Block Format

```markdown
<!-- block: code-style [id:a3f8b2] -->
Your reusable content here...
<!-- /block:a3f8b2 -->
```

## Download

Grab the latest release from [GitHub Releases](https://github.com/bcodesnow/BlockSmith/releases).

## Build from Source

Requires Qt 6.10+, CMake 3.21+, C++17 compiler.

```bash
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH="<your-qt-path>"
cmake --build build
```

## Docs

- [User manual — shortcuts, data storage, workflows](docs/user-manual.md)
- [Architecture, project structure & data storage](docs/architecture.md)

## License

Copyright (C) 2026 Danube Mechatronics Kft.

Authors: kb (kb@danube-mechatronics.com) & Claude (Anthropic)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

See [LICENSE](LICENSE) for details.
