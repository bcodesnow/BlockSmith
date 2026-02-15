@echo off
set BUILD_DIR=build\Desktop_Qt_6_10_1_MSVC2022_64bit-Debug
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
set PATH=C:\Qt\Tools\CMake_64\bin;C:\Qt\Tools\Ninja;C:\Qt\6.10.1\msvc2022_64\bin;%PATH%
cd /d C:\Projects\BlockSmith
if not exist %BUILD_DIR%\CMakeCache.txt (
    cmake -B %BUILD_DIR% -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH=C:/Qt/6.10.1/msvc2022_64 -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl -Wno-dev
    if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
)
cmake --build %BUILD_DIR%
