# BlockSmith

A Qt6/QML desktop application for managing reusable content blocks across CLAUDE.md and agent instruction files.

<!-- block: Guidelines Standard [id:1d67c7] -->
## Guidelines

- Keep MD files up to date after significant changes
- Update dates in docs when modifying them
- Commit changes to git with sensible messages
- MAX 1256 LOC per file - no monolithic mega files
- Do not assume - if unsure, ask questions
- Do not decide for me about features - do not assume - ask if unsure!
- Less is more. We are embedded developers with passion. KISS DRY but keep it readable and maintainable do not overabstract.
- Do not write bloated code

<!-- /block:1d67c7 -->

## Build Environment

- Qt 6.10.1 with MinGW 13.1.0 on Windows
- CMake + Ninja build system
- PATH setup for builds:
  ```
  export PATH="/c/Qt/Tools/mingw1310_64/bin:/c/Qt/Tools/CMake_64/bin:/c/Qt/Tools/Ninja:/c/Qt/6.10.1/mingw_64/bin:$PATH"
  ```

## Build Commands

```bash
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH="C:/Qt/6.10.1/mingw_64" -DCMAKE_C_COMPILER="C:/Qt/Tools/mingw1310_64/bin/gcc.exe" -DCMAKE_CXX_COMPILER="C:/Qt/Tools/mingw1310_64/bin/g++.exe" -Wno-dev
cmake --build build
```

## Architecture

- **3-pane SplitView layout**: NavPanel (left), MainContent (center), RightPane (right)
- **QML module**: `BlockSmith`, loaded via `loadFromModule("BlockSmith", "Main")`
- **C++ backend**: AppController singleton exposes ConfigManager, ProjectTreeModel, ProjectScanner, MdDocument, BlockStore, PromptStore, SyncEngine, MdSyntaxHighlighter
- **Config**: `QStandardPaths::AppConfigLocation` (Windows: `AppData/Local/BlockSmith`)
- **Block format**: `<!-- block: name [id:hexid] -->\ncontent\n<!-- /block:hexid -->`

## Key Patterns

- `QML_ELEMENT` / `QML_SINGLETON` / `QML_UNCREATABLE` macros for QML registration (no manual qmlRegisterType)
- `qt_add_qml_module` with policies QTP0001 and QTP0004
- AppController singleton uses static `create(QQmlEngine*, QJSEngine*)` method
- Forward declarations insufficient for Q_PROPERTY pointer types — must include full headers
- QML files must start with uppercase for qt_add_qml_module public type registration
- `Q_INVOKABLE` methods must NOT be placed in the `signals:` section (moc treats them as signals)
- md4c (third_party) needs 6 files: md4c.h, md4c.c, md4c-html.h, md4c-html.c, entity.h, entity.c

## Project Structure

```
src/                    C++ backend classes
qml/Main.qml           Application window entry point
qml/components/         All QML UI components
third_party/md4c/       Markdown parser library
resources/              App icon and Windows .rc file
```

## Features

- Project scanning with configurable search paths, ignore patterns, and trigger files
- Tree view navigation with expand/collapse all
- Markdown editor with line numbers, block gutter markers, syntax highlighting
- Markdown preview via md4c
- Block store (create, edit, sync, push/pull blocks across files)
- Prompt store with clipboard support
- Find & Replace (Ctrl+F / Ctrl+H)
- Global search across all MD files (Ctrl+Shift+F)
- Block diff view for diverged blocks
- Auto-scan on startup (configurable)
- Syntax highlighting (configurable)
- Toast notifications
