# Windows ISO Downloader

**English** · [Español](README.es.md)

Download Windows 10 and Windows 11 ISOs directly from Microsoft's servers — no Media Creation Tool, no browser required.

## Features

- Downloads ISOs straight from Microsoft's official CDN
- Supports **Windows 10** (multi-edition: Home/Pro, 32-bit and 64-bit)
- Supports **Windows 11 x64** and **Windows 11 arm64**
- **Raw edition ID support** — pass any numeric `ProductEditionId` from Microsoft's API
- **SHA-256 verification** — hash is computed while streaming and printed after download; pass `--verify` to fail on mismatch
- Interactive wizard when run without arguments
- All available languages supported
- Progress bar with speed and ETA
- `--url-only` mode to just print the download link

## Requirements

- A Rust toolchain (`cargo`, stable 1.75+)
- A C compiler (`cc`/`gcc`/`clang`) — required by the bundled SQLite used by the optional server
- **No system OpenSSL needed**: TLS is provided by `rustls` with bundled roots, so the build is self-contained on any OS

## Install

```sh
cargo install --path .
# binary: wisodown
```

Or build manually:

```sh
cargo build --release
# binary at target/release/wisodown
```

### Building on Linux

The project is fully cross-platform and builds natively on Linux — there is no
Windows-specific code (`winapi`, `#[cfg(windows)]`, backslash paths, …). Only
the ISO *products* are Windows; the tool itself runs anywhere Rust runs.

```sh
git clone https://github.com/BENDER35/wisodown-lin
cd wisodown-lin
cargo build --release
# binary: target/release/wisodown
```

To also build the optional self-hosted server (needs a C compiler for bundled
SQLite):

```sh
cargo build --release --features server
# binary: target/release/wisodown-server
```

### Building on Windows

The tool builds natively on Windows too:

1. Install Rust from <https://rustup.rs> (`rustup-init.exe`). The installer uses
   the MSVC toolchain by default (requires the Visual Studio C++ Build Tools).
2. Build:

```powershell
git clone https://github.com/BENDER35/wisodown-lin
cd wisodown-lin
cargo build --release
# binary: target\release\wisodown.exe

# with the optional server (needs the C compiler for bundled SQLite):
cargo build --release --features server
# binary: target\release\wisodown-server.exe

# 32-bit (x86) build — needs the Visual Studio x86 C++ toolset:
rustup target add i686-pc-windows-msvc
cargo build --release --target i686-pc-windows-msvc
# binary: target\i686-pc-windows-msvc\release\wisodown.exe
```

Supported Windows: **Windows 10 and Windows 11** — x64, ARM64 and 32-bit x86
(`i686`). Windows 7/8.1 are not supported by current Rust toolchains.

> **Prebuilt releases:** each release ships ready-to-run archives:
> `wisodown-linux-x86_64.zip`, `wisodown-macos-*.zip`,
> `wisodown-windows-x86_64.zip` (64-bit) and `wisodown-windows-i686.zip`
> (32-bit). You can also build from source, or use the helper script
> `scripts/get-iso.ps1` (no compilation needed).

### Helper scripts

| Script | Platform | Requirements |
| ------ | -------- | ------------ |
| `scripts/get-iso.sh` | Linux / macOS | `bash`, `curl`, `jq` |
| `scripts/get-iso.ps1` | Windows / Linux / macOS (PowerShell 7+) | `pwsh` |

Both talk to the hosted API (`https://wiso.krnl64.win`) and can print a download
link or download the ISO directly. On Linux the PowerShell script runs with
[`pwsh`](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux):

```sh
pwsh ./scripts/get-iso.ps1 -Edition x64 -Language English
# or, after chmod +x:
./scripts/get-iso.ps1 -Edition x64 -Language English
```

## Usage

### Interactive wizard

```sh
wisodown
```

Prompts for Windows version, language, and (for Windows 10) 32-bit vs 64-bit.

### Named editions

```sh
# Windows 11 x64, English
wisodown --edition x64 --language English

# Windows 11 arm64, French
wisodown --edition arm64 --language French

# Windows 10, English (prompts for 32-bit vs 64-bit)
wisodown --edition win10 --language English

# Save to a specific directory
wisodown --edition x64 --language English --output ~/Downloads
```

### Raw edition IDs

Pass any numeric `ProductEditionId` directly, bypassing the named aliases:

```sh
wisodown --edition-id 2618 --language English
wisodown --edition-id 3321 --language Japanese
```

When using a custom edition ID for a product page other than Windows 11 x64,
supply the corresponding page URL so the correct cookies are acquired:

```sh
wisodown --edition-id 2618 \
         --page-url https://www.microsoft.com/en-us/software-download/windows10ISO \
         --language English
```

### `--edition` aliases

| Value   | Description                                           |
| ------- | ----------------------------------------------------- |
| `x64`   | Windows 11, 64-bit (x86-64)                           |
| `arm64` | Windows 11, ARM 64-bit                                |
| `win10` | Windows 10, multi-edition (Home/Pro, 32-bit + 64-bit) |

### Hash verification

The SHA-256 digest is always computed during the download and printed to stderr:

```text
✔ Saved to Win11_English_x64.iso
  SHA-256: b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c
```

Pass `--verify` to assert an expected hash — the process exits with an error on mismatch:

```sh
wisodown --edition x64 --language English \
         --verify b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c
```

### Other flags

```sh
# List available languages for an edition
wisodown --edition win10 --list-languages

# Print the download URL without downloading
wisodown --edition x64 --language English --url-only
```

### Anti-bot cookies (if downloads fail)

Microsoft's API uses a Sentinel bot-detection layer. The tool attempts to obtain the required cookies automatically, but if it fails you can supply them manually:

1. Open the download page in a browser
2. Open DevTools → Network → any request to `microsoft.com` → Request Headers → Cookie
3. Copy the cookie string and pass it:

```sh
wisodown --edition x64 --language English --cookie "MUID=...; fptctx2=..."
```

### Debug mode

```sh
wisodown --edition x64 --language English --debug
```

Prints all API requests, responses, and cookie exchange steps to stderr.

## How it works

1. Loads the Microsoft software download page to acquire session cookies
2. Calls `ov-df.microsoft.com` to simulate the browser fingerprinting step (fptctx2/MUID cookies) that Sentinel requires
3. Calls `getSkuInformationByProductEdition` to list available language SKUs
4. Calls `GetProductDownloadLinksBySku` to get a time-limited CDN link
5. Streams the ISO to disk, computing SHA-256 on the fly, with a progress bar

## Documentation

- [Technical reference (English)](docs/guide/technical.md)
- [Referencia técnica (Español)](docs/guide/technical.es.md)

## License

GNU General Public License 3.0
