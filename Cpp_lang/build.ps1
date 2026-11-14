param(
    [string]$cmd,
    [string]$arg
)

# -----------------------------
# OS detect
# -----------------------------

$os = $env:OS

# -----------------------------
# project name
# -----------------------------

$project_name = Split-Path (Get-Location) -Leaf
$full_project_name = Get-Location

# -----------------------------
# compiler detect (Windows)
# -----------------------------

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

$gcc = find-gcc
$clang = find-clang
$clangpp = find-clangpp
$cmake = find-cmake

# -----------------------------
# dirs
# -----------------------------

$src_dir = "src"
$target_dir = "target"

$source = "$src_dir\main.cpp"
$target = "$target_dir\$project_name.exe"

# -----------------------------
# flags
# -----------------------------

$ldflags_common = "-std=c++2c -Wall -Wextra"
$ldflags_opt = "-std=c++2c -O2 -Wall -Wextra -g"

# -----------------------------
# helpers
# -----------------------------

function ensure-target {

    Remove-Item $target_dir -Recurse -Force -ErrorAction Ignore
    New-Item $target_dir -ItemType Directory | Out-Null
}

# -----------------------------
# compile clangpp
# -----------------------------

function r {

    ensure-target

    & $clangpp $ldflags_common -o $target $source

    & $target
}

# -----------------------------
# compile clangpp optimized
# -----------------------------

function ro {

    ensure-target

    & $clangpp $ldflags_opt -o $target $source

    & $target
}

# -----------------------------
# cmake build
# -----------------------------

function cr {

    Remove-Item build -Recurse -Force -ErrorAction Ignore
    New-Item build -ItemType Directory | Out-Null

    & $cmake -S . -B build -G "Ninja" `
        -D CMAKE_C_COMPILER="$clangpp"

    cmake --build build

}

# -----------------------------
# sanitize
# -----------------------------

function san($type) {

    ensure-target

    & $clangpp "-fsanitize=$type" "-g" $source -o $target

    & $target
}

# -----------------------------
# asm
# -----------------------------

function asm {

    ensure-target

    & $clangpp "-S" $source

}

# -----------------------------
# llvm
# -----------------------------

function ll {

    ensure-target

    & $clangpp "-S" "-emit-llvm" $source

}

# -----------------------------
# clean
# -----------------------------

function clean {

    Remove-Item target -Recurse -Force -ErrorAction Ignore
    Remove-Item build -Recurse -Force -ErrorAction Ignore
}

# -----------------------------
# init C project
# -----------------------------

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

# -----------------------------
# show compilers
# -----------------------------

function compilers {

    Write-Host "gcc   :" $gcc
    Write-Host "clangpp :" $clangpp
    Write-Host "cmake :" $cmake
}

# -----------------------------
# dispatcher
# -----------------------------

switch ($cmd) {

    "r" { r }
    "ro" { ro }
    "cr" { cr }
    "san" { san $arg }
    "asm" { asm }
    "ll" { ll }
    "clean" { clean }
    "init" { init }
    "compilers" { compilers }

    default {
        Write-Host ""
        Write-Host "commands:"
        Write-Host "r ro cr san asm ll clean init compilers"
    }
}
