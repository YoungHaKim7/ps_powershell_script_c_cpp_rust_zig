param(
    [string]$cmd,
    [string]$arg
)

$project_name = Split-Path (Get-Location) -Leaf

function a($search) {
    just -l | rg -i $search
}

function toolremove($tool) {
    rustup toolchain remove $tool
}

function rupdate {
    rustup component add rust-analyzer
}

function rustupdate {
    rustup update stable
}

function doc {
    cargo doc --open
}

function r {
    cargo run 2>&1
}

function rr {
    cargo run --release 2>&1
}

function w {
    cargo watch -x check -x test -x run
}

function ws {
    cargo watch -x run
}

function fi {
    cargo fmt --all -- --check
    cargo check --all-features --all-targets --all
    cargo nextest run --all-features --no-fail-fast --workspace --no-capture
    cargo clippy --all-features --all-targets -- -D warnings
    cargo doc --open
    cargo audit
}

function c {
    cargo check --all-features --all-targets --all
}

function t {
    cargo test 2>&1
}

function tex {
    cargo expand --lib --tests
}

function tp {
    cargo test -- --nocapture 2>&1
}

function tn {
    cargo nextest run 2>&1
}

function tnp {
    cargo nextest run --nocapture 2>&1
}

function ex {
    cargo expand
}

function mir {
    cargo rustc -- -Zunpretty=mir > "target/$project_name.mir"
}

function es {
    cargo rustc -- --emit asm="target/$project_name.s"
}

function eos {
    cargo rustc --release -- --emit asm > "target/$project_name.s"
}

function llvm {
    cargo rustc -- --emit llvm-ir="target/$project_name.ll"
}

function hir {
    cargo rustc -- -Zunpretty=hir > "target/$project_name.hir"
}

function asm($method) {
    cargo asm "$project_name::$method"
}

function san($san) {

    $env:RUSTFLAGS="-Zsanitizer=$san"
    $env:RUSTDOCFLAGS="-Zsanitizer=$san"

    n

    cargo run -Zbuild-std --target x86_64-unknown-linux-gnu
}

function xx {

    cargo run

    $bin = "target/debug/$project_name.exe"

    Format-Hex $bin | Out-File target/debug/hex_print.txt
}

function xv($str) {

    xx

    Get-Content target/debug/hex_print.txt |
        Select-String $str
}

function clean {

    Remove-Item target -Recurse -Force -ErrorAction Ignore
    Remove-Item rust-toolchain.toml -Force -ErrorAction Ignore
    Remove-Item *.lock -Force -ErrorAction Ignore
}

function n {

    Remove-Item .cargo -Recurse -Force -ErrorAction Ignore
    Remove-Item rust-toolchain.toml -Force -ErrorAction Ignore

    New-Item .cargo -ItemType Directory | Out-Null

@"
[toolchain]
channel = "nightly"
components = ["rustfmt", "rust-src"]
"@ | Out-File rust-toolchain.toml

@"
[build]
rustflags = ["-Z","threads=8"]
"@ | Out-File .cargo/config.toml
}

function gi {

    Add-Content README.md "# Result"
    Add-Content README.md ""

@"
.vs/
.vscode/
target/
debug/
Cargo.lock
*.pdb
dist/
pkg/
"@ | Out-File .gitignore
}


# compiler path helper

function compilers {

    $gcc = Get-Command gcc -ErrorAction SilentlyContinue
    $clang = Get-Command clang -ErrorAction SilentlyContinue

    if ($gcc) { $gcc.Path }
    if ($clang) { $clang.Path }
}


# command dispatcher

switch ($cmd) {

    "a" { a $arg }
    "toolremove" { toolremove $arg }
    "rupdate" { rupdate }
    "rustupdate" { rustupdate }
    "doc" { doc }
    "r" { r }
    "rr" { rr }
    "w" { w }
    "ws" { ws }
    "fi" { fi }
    "c" { c }
    "t" { t }
    "tex" { tex }
    "tp" { tp }
    "tn" { tn }
    "tnp" { tnp }
    "ex" { ex }
    "mir" { mir }
    "es" { es }
    "eos" { eos }
    "llvm" { llvm }
    "hir" { hir }
    "asm" { asm $arg }
    "san" { san $arg }
    "xx" { xx }
    "xv" { xv $arg }
    "clean" { clean }
    "n" { n }
    "gi" { gi }
    "compilers" { compilers }

    default {
        Write-Host "commands:"
        Write-Host "r rr w ws fi c t tex tp tn tnp ex mir es eos llvm hir asm san xx xv clean n gi compilers"
    }
}
