# Descargador de ISO de Windows

[English](README.md) · **Español**

Descarga ISOs de Windows 10 y Windows 11 directamente desde los servidores de
Microsoft: sin Media Creation Tool y sin navegador.

## Características

- Descarga las ISOs directamente desde el CDN oficial de Microsoft
- Compatible con **Windows 10** (multiedición: Home/Pro, 32 y 64 bits)
- Compatible con **Windows 11 x64** y **Windows 11 arm64**
- **Soporte de ID de edición en crudo** — pasa cualquier `ProductEditionId`
  numérico de la API de Microsoft
- **Verificación SHA-256** — el hash se calcula durante la descarga y se muestra
  al terminar; usa `--verify` para fallar si no coincide
- Asistente interactivo si se ejecuta sin argumentos
- Todos los idiomas disponibles soportados
- Barra de progreso con velocidad y tiempo estimado
- Modo `--url-only` para imprimir solo el enlace de descarga

## Requisitos

- Un entorno de Rust (`cargo`, estable 1.75+)
- Un compilador de C (`cc`/`gcc`/`clang`) — necesario para el SQLite embebido que
  usa el servidor opcional
- **No hace falta OpenSSL del sistema**: el TLS lo aporta `rustls` con raíces
  incluidas, así que la compilación es autocontenida en cualquier SO

## Instalación

```sh
cargo install --path .
# binario: wisodown
```

O compila manualmente:

```sh
cargo build --release
# binario en target/release/wisodown
```

### Compilación en Linux

El proyecto es totalmente multiplataforma y compila de forma nativa en Linux —
no hay código específico de Windows (`winapi`, `#[cfg(windows)]`, rutas con
`\`, …). Solo los *productos* ISO son Windows; la herramienta funciona en
cualquier sistema donde corra Rust.

```sh
git clone https://github.com/BENDER35/wisodown-lin
cd wisodown-lin
cargo build --release
# binario: target/release/wisodown
```

Para compilar también el servidor autoalojado opcional (necesita un compilador
de C para el SQLite embebido):

```sh
cargo build --release --features server
# binario: target/release/wisodown-server
```

### Compilación en Windows

La herramienta también compila de forma nativa en Windows:

1. Instala Rust desde <https://rustup.rs> (`rustup-init.exe`). El instalador
   descarga por defecto el toolchain MSVC (necesita los *Build Tools* de
   Visual Studio C++).
2. Compila:

```powershell
git clone https://github.com/BENDER35/wisodown-lin
cd wisodown-lin
cargo build --release
# binario: target\release\wisodown.exe

# con el servidor opcional (necesita el compilador de C para el SQLite embebido):
cargo build --release --features server
# binario: target\release\wisodown-server.exe
```

Windows soportados: **Windows 10 y Windows 11** (x64 y ARM64). Windows 7/8.1 ya
no están soportados por los toolchains actuales de Rust.

> **Releases precompiladas:** la release `v0.1.3` publica por ahora solo binarios
> de Linux. En Windows puedes compilar desde el código fuente, o usar el script
> auxiliar `scripts/get-iso.ps1` (no requiere compilar nada), o ejecutar el
> servidor/programa donde prefieras.

### Scripts auxiliares

| Script | Plataforma | Requisitos |
| ------ | ---------- | ---------- |
| `scripts/get-iso.sh` | Linux / macOS | `bash`, `curl`, `jq` |
| `scripts/get-iso.ps1` | Windows / Linux / macOS (PowerShell 7+) | `pwsh` |

Ambos usan la API alojada (`https://wiso.krnl64.win`) y pueden imprimir un enlace
de descarga o descargar la ISO directamente. En Linux el script de PowerShell se
ejecuta con
[`pwsh`](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux):

```sh
pwsh ./scripts/get-iso.ps1 -Edition x64 -Language English
# o, tras chmod +x:
./scripts/get-iso.ps1 -Edition x64 -Language English
```

## Uso

### Asistente interactivo

```sh
wisodown
```

Pregunta por la versión de Windows, el idioma y (para Windows 10) 32 o 64 bits.

### Ediciones con nombre

```sh
# Windows 11 x64, inglés
wisodown --edition x64 --language English

# Windows 11 arm64, francés
wisodown --edition arm64 --language French

# Windows 10, inglés (pregunta 32 vs 64 bits)
wisodown --edition win10 --language English

# Guardar en un directorio concreto
wisodown --edition x64 --language English --output ~/Downloads
```

### IDs de edición en crudo

Pasa cualquier `ProductEditionId` numérico directamente, saltándote los alias:

```sh
wisodown --edition-id 2618 --language English
wisodown --edition-id 3321 --language Japanese
```

Si usas un ID de edición para una página de producto distinta de Windows 11 x64,
indica también su URL para obtener las cookies correctas:

```sh
wisodown --edition-id 2618 \
         --page-url https://www.microsoft.com/en-us/software-download/windows10ISO \
         --language English
```

### Alias de `--edition`

| Valor   | Descripción                                              |
| ------- | -------------------------------------------------------- |
| `x64`   | Windows 11, 64 bits (x86-64)                             |
| `arm64` | Windows 11, ARM 64 bits                                  |
| `win10` | Windows 10, multiedición (Home/Pro, 32 + 64 bits)        |

### Verificación de hash

El digest SHA-256 siempre se calcula durante la descarga y se imprime en stderr:

```text
✔ Saved to Win11_English_x64.iso
  SHA-256: b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c
```

Usa `--verify` para exigir un hash esperado — el proceso termina con error si no
coincide:

```sh
wisodown --edition x64 --language English \
         --verify b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c
```

### Otros flags

```sh
# Listar los idiomas disponibles para una edición
wisodown --edition win10 --list-languages

# Imprimir la URL de descarga sin descargar
wisodown --edition x64 --language English --url-only
```

### Cookies anti-bot (si fallan las descargas)

La API de Microsoft usa una capa anti-bot llamada Sentinel. La herramienta intenta
obtener las cookies necesarias automáticamente, pero si falla puedes aportarlas
a mano:

1. Abre la página de descarga en un navegador
2. Abre DevTools → Network → cualquier petición a `microsoft.com` → Request
   Headers → Cookie
3. Copia la cadena de cookies y pásala:

```sh
wisodown --edition x64 --language English --cookie "MUID=...; fptctx2=..."
```

### Modo depuración

```sh
wisodown --edition x64 --language English --debug
```

Imprime todas las peticiones y respuestas de la API, y los pasos de intercambio
de cookies, en stderr.

## Cómo funciona

1. Carga la página de descarga de Microsoft para obtener las cookies de sesión
2. Llama a `ov-df.microsoft.com` para simular el paso de fingerprinting del
   navegador (cookies fptctx2/MUID) que exige Sentinel
3. Llama a `getSkuInformationByProductEdition` para listar los SKUs de idioma
4. Llama a `GetProductDownloadLinksBySku` para obtener un enlace de CDN temporal
5. Descarga la ISO a disco en streaming, calculando SHA-256 al vuelo, con barra
   de progreso

## Documentación

- [Guía técnica (inglés)](docs/guide/technical.md)
- [Referencia técnica (español)](docs/guide/technical.es.md)

## Licencia

GNU General Public License 3.0
