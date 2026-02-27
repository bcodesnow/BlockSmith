# BlockSmith

BlockSmith is a native desktop editor for documentation-heavy projects, especially repositories that use `CLAUDE.md`, `AGENTS.md`, and related markdown workflows.

It is built with C++17 and Qt 6, with a focus on clear editing workflows, reusable content blocks, and fast project navigation.

![BlockSmith](resources/screenshot.png)

## What You Can Do Today

- Edit markdown, JSON, YAML, and plain text in one workspace
- Work across multiple open files with tabs and session restore
- Use split markdown preview with scroll sync and Mermaid rendering
- Create reusable blocks, track divergence, and push/pull updates across files
- Keep a prompt library with categories and one-click copy
- Navigate large projects with quick switcher, outline, global search, and back/forward history
- Open Claude Code `.jsonl` transcripts with role filters and expandable raw JSON
- Export markdown to PDF, HTML, or DOCX

## File Format Support

| Format | Edit | Preview | Notes |
|--------|------|---------|-------|
| Markdown (`.md`, `.markdown`) | Yes | Yes | Full toolbar, blocks, preview, export |
| JSON (`.json`) | Yes | No | Syntax highlight + format |
| YAML (`.yaml`, `.yml`) | Yes | No | Syntax highlight + format |
| Plain text (`.txt`) | Yes | No | Lightweight editing mode |
| JSONL (`.jsonl`) | Viewer | No | Transcript-focused viewer |
| PDF (`.pdf`) | No | Yes | Read-only viewer |
| DOCX (`.docx`) | No | Yes | Read-only via pandoc conversion |

## Project Direction

BlockSmith is actively evolving. Current roadmap focus is on editor quality and workflow depth:

- Markdown table editing
- Spell checking
- Git-aware project view and diff workflows
- Multi-tab lifecycle hardening and close-flow safety

See [docs/ROADMAP.md](docs/ROADMAP.md) for current priorities.

## Build From Source

Requirements:

- Qt 6.10.1 or later (`Quick`, `QuickControls2`, `WebEngineQuick`, `WebChannel`, `Concurrent`)
- CMake 3.21+
- C++17 compiler

Windows build:

```bash
cmd.exe //c "C:\Projects\BlockSmith\build_msvc.bat"
```

Linux/macOS build:

```bash
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="/path/to/qt6"
cmake --build build
```

## Documentation

- [Documentation Index](docs/README.md)
- [User Guide](docs/user/quickstart.md)
- [Architecture](docs/architecture/overview.md)
- [Roadmap](docs/roadmap/now-next-later.md)

## Contributing

Development guidelines are in [CLAUDE.md](CLAUDE.md).

## License

GPLv3. See [LICENSE](LICENSE).
