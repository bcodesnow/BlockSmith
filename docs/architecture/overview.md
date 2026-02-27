# Architecture Overview

BlockSmith is a Qt/QML desktop application with a C++ backend and a QML frontend.

The UI is built around a three-pane layout:

- Left: project navigation and file operations
- Center: multi-tab editor and viewers
- Right: blocks, prompts, and outline

## High-Level Design

- `AppController` is the main QML-facing singleton
- `TabModel` owns open documents and per-tab UI state
- Manager classes handle scanning, search, navigation, export, sync, and storage
- QML components focus on rendering and user interaction

## Core Capabilities

- Multi-format editing: markdown, JSON, YAML, plain text
- Read-only viewers: PDF and DOCX
- JSONL transcript viewer for Claude Code logs
- Reusable block registry with push/pull sync
- Prompt library with categories
- Global project search and quick switcher
- Export pipeline (PDF/HTML/DOCX)

## Design Priorities

- Keep the main UI responsive by moving heavy work off the UI thread
- Keep file operations explicit and local-first
- Keep features modular: manager-per-concern, component-per-view

See [component-map.md](component-map.md) and [runtime-flows.md](runtime-flows.md) for implementation detail.
