cmake_minimum_required(VERSION 3.21)
project(BlockSmith VERSION 0.1.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.10 REQUIRED COMPONENTS Quick QuickControls2 Core WebEngineQuick WebChannel Concurrent)
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

add_subdirectory(third_party/md4c)

# yaml-cpp for YAML format/validate support
find_package(yaml-cpp CONFIG QUIET)
if(NOT yaml-cpp_FOUND)
    include(FetchContent)
    FetchContent_Declare(
        yaml-cpp
        GIT_REPOSITORY https://github.com/jbeder/yaml-cpp.git
        GIT_TAG yaml-cpp-0.9.0
    )
    set(YAML_CPP_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(YAML_CPP_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
    set(YAML_CPP_BUILD_CONTRIB OFF CACHE BOOL "" FORCE)
    set(YAML_CPP_INSTALL OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(yaml-cpp)
endif()

qt_add_executable(BlockSmith
    src/main.cpp
    resources/blocksmith.rc
)

set_source_files_properties(qml/components/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(BlockSmith
    URI BlockSmith
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/components/Theme.qml
        qml/components/SettingsDialog.qml
        qml/components/NavPanel.qml
        qml/components/MainContent.qml
        qml/components/Editor.qml
        qml/components/MdPreview.qml
        qml/components/BlockCard.qml
        qml/components/BlockListPanel.qml
        qml/components/AddBlockDialog.qml
        qml/components/BlockEditorPopup.qml
        qml/components/PromptCard.qml
        qml/components/PromptListPanel.qml
        qml/components/PromptEditorPopup.qml
        qml/components/RightPane.qml
        qml/components/Toast.qml
        qml/components/BlockDiffPopup.qml
        qml/components/SearchDialog.qml
        qml/components/FindReplaceBar.qml
        qml/components/NewProjectDialog.qml
        qml/components/FileOperationDialog.qml
        qml/components/MdToolbar.qml
        qml/components/MdPreviewWeb.qml
        qml/components/SplashOverlay.qml
        qml/components/JsonlViewer.qml
        qml/components/JsonlEntryCard.qml
        qml/components/ExportDialog.qml
        qml/components/QuickSwitcher.qml
        qml/components/OutlinePanel.qml
        qml/components/EditorStatusBar.qml
        qml/components/NavContextMenu.qml
        qml/components/NavFooterBar.qml
        qml/components/JsonlFilterBar.qml
        qml/components/LineNumberGutter.qml
        qml/components/JsonToolbar.qml
        qml/components/FindReplaceController.qml
        qml/components/YamlToolbar.qml
        qml/components/SettingsProjectsTab.qml
        qml/components/SettingsEditorTab.qml
        qml/components/SettingsIntegrationsTab.qml
        qml/components/EditorPopupBase.qml
        qml/components/EditorHeader.qml
        qml/components/FileChangedBanner.qml
        qml/components/EditorContextMenu.qml
        qml/components/ImageDropZone.qml
        qml/components/UnsavedChangesDialog.qml
    SOURCES
        src/configmanager.h src/configmanager.cpp
        src/md4crenderer.h src/md4crenderer.cpp
        src/appcontroller.h src/appcontroller.cpp
        src/projecttreemodel.h src/projecttreemodel.cpp
        src/projectscanner.h src/projectscanner.cpp
        src/document.h src/document.cpp
        src/blockstore.h src/blockstore.cpp
        src/promptstore.h src/promptstore.cpp
        src/syncengine.h src/syncengine.cpp
        src/syntaxhighlighter.h src/syntaxhighlighter.cpp
        src/filemanager.h src/filemanager.cpp
        src/imagehandler.h src/imagehandler.cpp
        src/jsonlstore.h src/jsonlstore.cpp
        src/exportmanager.h src/exportmanager.cpp
        src/scrollbridge.h src/scrollbridge.cpp
        src/utils.h src/utils.cpp
)

qt_add_resources(BlockSmith "icons"
    PREFIX "/"
    FILES
        resources/icons/blocksmith.ico
        resources/icons/blocksmith_16.png
        resources/icons/blocksmith_24.png
        resources/icons/blocksmith_32.png
        resources/icons/blocksmith_48.png
        resources/icons/blocksmith_64.png
        resources/icons/blocksmith_96.png
        resources/icons/blocksmith_128.png
        resources/icons/blocksmith_256.png
        resources/icons/blocksmith_512.png
)

qt_add_resources(BlockSmith "preview"
    PREFIX "/preview"
    BASE "resources/preview"
    FILES
        resources/preview/index.html
        resources/preview/mermaid.min.js
)

target_include_directories(BlockSmith PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
if(MSVC)
    target_compile_options(BlockSmith PRIVATE /W4)
else()
    target_compile_options(BlockSmith PRIVATE -Wall -Wextra -Wpedantic)
endif()

target_link_libraries(BlockSmith PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Core
    Qt6::WebEngineQuick
    Qt6::WebChannel
    Qt6::Concurrent
    md4c
    yaml-cpp::yaml-cpp
)

if(WIN32)
    target_link_libraries(BlockSmith PRIVATE dwmapi)
endif()
