param(
    [string]$cmd,
    [string]$arg
)

# =========================
# OS
# =========================

$IsWindows = $true

# =========================
# project
# =========================

$project_name = Split-Path (Get-Location) -Leaf
$full_project_name = Get-Location

$src_dir = "src"
$target_dir = "target"
$build_dir = "build"

$source = "$src_dir\main.c"
$target = "$target_dir\$project_name.exe"

# =========================
# tool detection
# =========================

function find-gcc {

    $c = Get-Command gcc -ErrorAction SilentlyContinue
    if ($c) { return $c.Path }

    $p = "C:\ProgramData\mingw64\mingw64\bin\gcc.exe"
    if (Test-Path $p) { return $p }

    return "gcc"
}

function find-clang {

    $c = Get-Command clang -ErrorAction SilentlyContinue
    if ($c) { return $c.Path }

    $p = "C:\Program Files\LLVM\bin\clang.exe"
    if (Test-Path $p) { return $p }

    return "clang"
}

function find-clangpp {

    $c = Get-Command clang++ -ErrorAction SilentlyContinue
    if ($c) { return $c.Path }

    $p = "C:\Program Files\LLVM\bin\clang++.exe"
    if (Test-Path $p) { return $p }

    return "clang++"
}

function find-cmake {

    $c = Get-Command cmake -ErrorAction SilentlyContinue
    if ($c) { return $c.Path }

    return "cmake"
}

function find-zig {

    $c = Get-Command zig -ErrorAction SilentlyContinue
    if ($c) { return $c.Path }

    return "zig"
}

$gcc = find-gcc
$clang = find-clang
$clangpp = find-clangpp
$cmake = find-cmake
$zig = find-zig

# =========================
# flags
# =========================

$ldflags_common = "-std=c23 -Wall -Wextra -g"
$ldflags_opt = "-std=c23 -O2 -Wall -Wextra -g"

# =========================
# helpers
# =========================

function reset-target {

    Remove-Item $target_dir -Recurse -Force -ErrorAction Ignore
    New-Item $target_dir -ItemType Directory | Out-Null
}

function reset-build {

    Remove-Item $build_dir -Recurse -Force -ErrorAction Ignore
    New-Item $build_dir -ItemType Directory | Out-Null
}

# =========================
# gcc build
# =========================

function r {

    reset-target

    & $gcc $ldflags_common -o $target $source

    & $target
}

# =========================
# clang optimized
# =========================

function ro {

    reset-target

    & $clang $ldflags_opt -o $target $source

    & $target
}

# =========================
# zig build
# =========================

function zr {

    reset-target

    & $zig cc $ldflags_common -o $target $source

    & $target
}

# =========================
# cmake
# =========================

function cr {

    reset-build

    & $cmake -S . -B build `
        -D CMAKE_C_COMPILER="$gcc" `
        -G "Ninja"

    cmake --build build
}

# =========================
# sanitize
# =========================

function san($type) {

    reset-target

    & $clang "-fsanitize=$type" "-g" $source -o $target

    & $target
}

function asan { san "address" }
function tsan { san "thread" }
function lsan { san "leak" }

# =========================
# llvm
# =========================

function ll {

    reset-target

    & $clang "-S" "-emit-llvm" $source
}

# =========================
# asm
# =========================

function asm {

    reset-target

    & $clang "-S" $source
}

# =========================
# objdump
# =========================

function obj {

    reset-target

    & $clang "-c" $source

    objdump -d main.o
}

# =========================
# hex
# =========================

function xx {

    reset-target

    & $clang $source -o $target

    Format-Hex $target | Out-File "$target_dir\hex.txt"
}

# =========================
# clang-format
# =========================

function fmt {

    Get-ChildItem -Recurse -Include *.c,*.h,*.cpp,*.hpp |
        ForEach-Object {

            clang-format -i $_.FullName
        }
}

# =========================
# fast fmt (fd)
# =========================

function fm {

    fd -e c -e h -e cpp -e hpp |
        ForEach-Object {

            clang-format -i $_
        }
}

# =========================
# clean
# =========================

function clean {

    Remove-Item target -Recurse -Force -ErrorAction Ignore
    Remove-Item build -Recurse -Force -ErrorAction Ignore
    Remove-Item *.o -Force -ErrorAction Ignore
    Remove-Item *.s -Force -ErrorAction Ignore
}

# =========================
# init
# =========================

function init {

    New-Item src -ItemType Directory -ErrorAction Ignore | Out-Null

@'
#include <stdio.h>

int main(void) {
    printf("Hello world C\n");
    return 0;
}
'@ | Out-File src/main.c

}

function init2 {

    New-Item src -ItemType Directory -ErrorAction Ignore | Out-Null

@'
#include <stdio.h>

int main(int argc, char* argv[]) {

    for(int i=0;i<argc;i++)
        printf("%s\n",argv[i]);

    return 0;
}
'@ | Out-File src/main.c

}

# =========================
# vscode
# =========================

function vscode {

    Remove-Item .vscode -Recurse -Force -ErrorAction Ignore
    New-Item .vscode -ItemType Directory | Out-Null

@'
{
 "version": "0.2.0",
 "configurations": [
  {
   "type": "cppdbg",
   "request": "launch",
   "name": "Launch",
   "program": "${workspaceFolder}/target/app.exe"
  }
 ]
}
'@ | Out-File .vscode/launch.json

}

# =========================
# compilers
# =========================

function compilers {

    Write-Host "gcc   :" $gcc
    Write-Host "clang :" $clang
    Write-Host "cmake :" $cmake
    Write-Host "zig   :" $zig
}

# =========================
# dispatcher
# =========================

switch ($cmd) {

    "r" { r }
    "ro" { ro }
    "zr" { zr }
    "cr" { cr }

    "san" { san $arg }
    "asan" { asan }
    "tsan" { tsan }
    "lsan" { lsan }

    "ll" { ll }
    "asm" { asm }
    "obj" { obj }
    "xx" { xx }

    "fmt" { fmt }
    "fm" { fm }

    "clean" { clean }

    "init" { init }
    "init2" { init2 }

    "vscode" { vscode }

    "compilers" { compilers }

    default {

        Write-Host ""
        Write-Host "Commands:"
        Write-Host "r ro zr cr san asan tsan lsan"
        Write-Host "ll asm obj xx"
        Write-Host "fmt fm clean"
        Write-Host "init init2 vscode"
        Write-Host "compilers"
    }
}
