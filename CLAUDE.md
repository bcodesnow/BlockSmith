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
- Do not overpollute CLAUDE.md - this should just focus on orientation and guidelines
- **After context compaction:** Do not act on assumptions from the summary. Read the summary to understand context, then ask the user what they want to do next. Present what you learned and ask for direction.
<!-- /block:1d67c7 -->

## Build Environment

- Qt 6.10.1 with MSVC 2022 on Windows (+ WebEngine, WebChannel, Positioning)
- CMake + Ninja build system
- Requires: Visual Studio Build Tools 2022 ("Desktop development with C++")
- Build via `build_msvc.bat` or Developer Command Prompt:
  ```
  export PATH="/c/Qt/Tools/CMake_64/bin:/c/Qt/Tools/Ninja:/c/Qt/6.10.1/msvc2022_64/bin:$PATH"
  ```

## Build Commands

```bash
# Use the batch file (sets up vcvarsall + builds):
cmd.exe //c "C:\Projects\BlockSmith\build_msvc.bat"

# Or manually from Developer Command Prompt for VS 2022:
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH="C:/Qt/6.10.1/msvc2022_64" -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl -Wno-dev
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

## Docs

- See [docs/architecture.md](docs/architecture.md) for full architecture, project structure, features
- See [docs/user-manual.md](docs/user-manual.md) for shortcuts, data storage, workflows
