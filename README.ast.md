# Descargador de ISO de Windows

[English](README.md) · [Español](README.es.md) · **Asturianu (bable)**

Baxa ISOs de Windows 10 y Windows 11 direutamente de los servidores de Microsoft — y tamién Windows 7, 8 y 8.1 dende archive.org — ensin Media Creation Tool y ensin navegador.

## Carauterístiques

- Baxa les ISOs direutamente del CDN oficial de Microsoft
- Compatible con **Windows 10** (multiedición: Home/Pro, 32 y 64 bits)
- Compatible con **Windows 11 x64** y **Windows 11 arm64**
- Compatible con **Windows 7, 8 y 8.1** dende **[archive.org](https://archive.org)** (Microsoft yá nun publica eses ISOs de consumu)
- **Soporte d'ID d'edición en crudu** — pasa cualquier `ProductEditionId` numbéricu de la API de Microsoft
- **Verificación SHA-256** — el hash calcúlase mientres la descarga y amuésase al terminar; usa `--verify` pa fallar si nun coincide
- Asistente interactivu si s'executa ensin argumentos
- Toes les llingües disponibles soportaes
- Barra de progresu con velocidá y tiempu envaloráu
- Modu `--url-only` pa imprimir namás l'enllaz de descarga

## Qué puedes baxar

| `--edition` | Versión de Windows | Arquiteutura | Nome del ficheru ISO |
| ----------- | ------------------ | ------------ | -------------- |
| `x64` | Windows 11 **25H2** | x64 (64 bits) | `Win11_25H2_<Lang>_x64_v2.iso` |
| `arm64` | Windows 11 **25H2** | Arm64 | `Win11_25H2_<Lang>_Arm64_v2.iso` |
| `win10` | Windows 10 **22H2** | x86 (32 bits) **y** x64 (64 bits) | `Win10_22H2_<Lang>_x32v1.iso` / `Win10_22H2_<Lang>_x64v1.iso` |
| `win11-cn-home` | Windows 11 **25H2** Home (China) | — | namái chinu simplificáu |
| `win11-cn-pro` | Windows 11 **25H2** Pro (China) | — | namái chinu simplificáu |
| `win7` | Windows 7 **Ultimate SP1** — archive.org | x86 (32 bits) **y** x64 (64 bits) | `Win7_Ult_SP1_English_x32.iso` / `Win7_Ult_SP1_Spanish_x32.iso` / `..._x64.iso` / `..._x64.es.iso` |
| `win8` | Windows 8 **RTM** — archive.org | x86 (32 bits) **y** x64 (64 bits) | `en_windows_8_x86_dvd_915417.iso` / `..._x64_...iso` |
| `win8.1` | Windows 8.1 **Home/Pro** — archive.org | x86 (32 bits) **y** x64 (64 bits) | `Win8.1_<Lang>_x32.iso` / `Win8.1_<Lang>_x64.iso` |

- Les ISOs son **multiedición** (Home/Pro/Edu/…): la clave de productu escueye la edición mientres la instalación.
- Hai **38 llingües** pa Windows 10/11 (x64 y Arm64).
- Windows 11 **nun tien ISO de 32 bits**; Windows 10 dexa escoyer **32 o 64 bits**.
- Les imáxenes **LTSC / IoT** (Enterprise) *non* tán nes páxines públiques de Microsoft.
- Cualquier otru productu: pasa'l so `ProductEditionId` numbéricu con `--edition-id`.
- **Windows 7 / 8 / 8.1 sírvense dende [archive.org](https://archive.org)**, non de Microsoft: eses ISOs de consumu retiráronse de les páxines públiques. `win8.1` ye **multiidioma**; `win7`/`win8` almiten **inglés y español** (les ISOs n'español tan disponibles per archive.org). La llista de ficheros lléese de la API de metadatos d'archive.org en tiempu real, y les descargues verifíquense col **MD5** publicáu equí (`--verify` sigue almitiendo un SHA-256).

## Requisitos

- Un entornu de Rust (`cargo`, estable 1.75+)
- Un compilador de C (`cc`/`gcc`/`clang`) — necesariu pal SQLite embebíu qu'usa'l servidor opcional
- **Nun fai falta OpenSSL del sistema**: el TLS apuérta-lo `rustls` con raíces incluyíes, polo que la compilación ye autocontenida en cualquier sistema operativu

## Ciclu de vida del soporte de Windows

La política de soporte de Microsoft de Windows afecta a qué versiones d'ISO puedes usar con seguridá con esta ferramienta:

- **Windows 7** el soporte principal terminó'l **13 de xineru de 2015**, el soporte estendíu terminó'l **14 de xineru de 2020**. Yá nun recibe actualizaciones de seguridá.
- **Windows 8** el soporte terminó'l **12 de xineru de 2016**. Yá nun recibe actualizaciones de seguridá.
- **Windows 8.1** el soporte terminó'l **10 de xineru de 2018**. Yá nun recibe actualizaciones de seguridá.
- **Windows 10** el soporte principal terminó'l **13 d'ochobre de 2020**. El soporte estendíu termina'l **14 d'ochobre de 2025**.
- **Windows 10 ESU** (Actualizaciones de Seguridá Estendíes) ta disponible pa Windows 10 Enterprise hasta **xineru de 2028** (per aciu de Volume Licensing). ESU recibe actualizaciones de seguridá crítiques inclusive dempués de que termine'l soporte estendíu.
- **Rotación de certificaos raíz**: dende 2023, Microsoft empezó a rotar los certificaos raíz de confianza. Los sistemes que executen Windows 7/8/8.1 **ensin ESU** pueden perder la capacidá de conectase a Windows Update y a dalgunos servicios de Microsoft a midida que caduquen les raíces antigües y nun s'instalen les nueves. Windows 10 con ESU recibe les actualizaciones de certificaos. Esto pue afectar a la capacidá de la ferramienta pa llograr cookies de la API de Microsoft en sistemes ensin actualizar.

> **Recomendación**: si inda se requier pa flujos de trabayu heredados, usa Windows 10 con ESU, o migra a un sistema operativu soportáu anguaño. La ferramienta misma execútase en cualquier sistema operativu con Rust, pero les ISOs de Windows que baxa tienen el ciclu de vida enriba indicáu.

## Instalación

```sh
cargo install --path .
# binary: wisodown
```

O compila a mano:

```sh
cargo build --release
# binary at target/release/wisodown
```

### Compilación en Linux

El proyeutu ye dafechu multiplataforma y compila de forma nativa en Linux — nun hai códigu específico de Windows (`winapi`, `#[cfg(windows)]`, rutes con `\`, …). Namás los *productos* ISO son de Windows; la ferramienta funciona en cualquier sistema onde corra Rust.

```sh
git clone https://github.com/BENDER35/wisodown-lin
cd wisodown-lin
cargo build --release
# binary: target/release/wisodown
```

Pa compilar tamién el servidor autoalloxáu opcional (necesita un compilador de C pal SQLite embebíu):

```sh
cargo build --release --features server
# binary: target/release/wisodown-server
```

### Compilación en Windows

La ferramienta tamién compila de forma nativa en Windows:

1. Instala Rust dende <https://rustup.rs> (`rustup-init.exe`). L'instalador usa por defectu la cadena de ferramientes MSVC (riquen les *Build Tools* de Visual Studio C++).
2. Compila:

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

Soporte del **sistema operativu anfitrión**: **Windows 10 y Windows 11** — x64, ARM64 y x86 de 32 bits (`i686`). Windows 7/8.1 yá nun tán soportaos poles cadenes de ferramientes actuales de Rust. (Esto refierse a *ónde s'executa'l binariu* — les ISOs que baxa son de Windows 7/8/8.1/10/11; mira [Qué puedes baxar](#qué-puedes-baxar).)

> **Lanzamientos precompilaos:** cada lanzamientu incluye archivos listos pa executar:
> `wisodown-linux-x86_64.zip`, `wisodown-macos-*.zip`,
> `wisodown-windows-x86_64.zip` (64 bits) y `wisodown-windows-i686.zip`
> (32 bits). Tamién puedes compilar dende'l códigu fonte, o usar el script
> auxiliar `scripts/get-iso.ps1` (nun rique compilación).

### Scripts auxiliares

| Script | Plataforma | Requisitos |
| ------ | ---------- | ---------- |
| `scripts/get-iso.sh` | Linux / macOS | `bash`, `curl`, `jq` |
| `scripts/get-iso.ps1` | Windows / Linux / macOS (PowerShell 7+) | `pwsh` |

Dambos comuníquense con un `wisodown-server` en funcionamientu y pueden imprimir un enllaz de descarga o baxar la ISO direutamente. Por defectu usen `http://localhost:3000` (puedes cambialo con `-a <url>` / `WISODOWN_API=<url>` en bash, o `-ApiBase <url>` / `WISODOWN_API=<url>` en PowerShell), asina qu'antes has d'alcender un servidor:

```sh
cargo run --release --features server -- --port 3000     # terminal 1
./scripts/get-iso.sh -e x64 -l English                   # terminal 2
```

En Linux el script de PowerShell execútase con
[`pwsh`](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux):

```sh
pwsh ./scripts/get-iso.ps1 -Edition x64 -Language English
# or, after chmod +x:
./scripts/get-iso.ps1 -Edition x64 -Language English
```

## Usu

### Asistente interactivu

```sh
wisodown
```

Pregunta pola versión de Windows, la llingua y (pa Windows 10) si quieres 32 o 64 bits.

### Ediciones con nome

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

### Ediciones antigües — Windows 7 / 8 / 8.1 (archive.org)

Microsoft yá nun publica les ISOs de consumu de Windows 7 / 8 / 8.1, asina que estes
ediciones báxense dende **[archive.org](https://archive.org)**:

```sh
# Windows 7 Ultimate SP1, 64-bit (Spanish)
wisodown --edition win7 --language Spanish

# Windows 7 Ultimate SP1, 64-bit (English)
wisodown --edition win7 --language English

# Windows 8 RTM, 32-bit (English)
wisodown --edition win8 --language English

# Windows 8 RTM, 64-bit (English)
wisodown --edition win8 --language English

# Windows 8.1 — pick a language; both 32-bit and 64-bit are offered
wisodown --edition win8.1 --language Spanish

# See every ISO available for an edition
wisodown --edition win8.1 --list-languages

# Just print the archive.org URL
wisodown --edition win7 --language English --url-only
```

Pa `--language`, `win8.1` usa la llingua que apaez nel nome del ficheru
(`Spanish`, `German`, `Chinese(Simplified)`, …); si hai coincidencia exacta usaesa,
y si non busca per subcadena. `win7` y `win8` almiten **inglés y español**
(les ISOs n'español tan disponibles per archive.org).

> Son **espeyos de la comunidá** alloxaos n'Internet Archive, non
> servidores de Microsoft. Les descargues verifíquense col MD5 publicáu
> por archive.org.

### IDs d'edición en crudu

Pasa cualquier `ProductEditionId` numbéricu directamente, saltándote los alias con nome:

```sh
wisodown --edition-id 2618 --language English
wisodown --edition-id 3321 --language Japanese
```

Si usas un ID d'edición pa una páxina de productu distinta de Windows 11 x64,
aporta tamién la so URL pa llograr les cookies correutes:

```sh
wisodown --edition-id 2618 \
         --page-url https://www.microsoft.com/en-us/software-download/windows10ISO \
         --language English
```

### Alias de `--edition`

| Valor   | Descripción                                                     |
| ------- | --------------------------------------------------------------- |
| `x64`   | Windows 11 25H2, 64 bits (x86-64)                                |
| `arm64` | Windows 11 25H2, Arm64                                          |
| `win10` | Windows 10 22H2, multiedición (pregunta 32 vs 64 bits)          |
| `win11-cn-home` | Windows 11 25H2 Home (China, namái chinu simplificáu)   |
| `win11-cn-pro`  | Windows 11 25H2 Pro (China, namái chinu simplificáu)    |
| `win7`          | Windows 7 Ultimate SP1, inglés y español (**archive.org**)        |
| `win8`          | Windows 8 RTM, inglés (**archive.org**)                 |
| `win8.1`        | Windows 8.1 Home/Pro, multiidioma (**archive.org**)   |

Tamién s'acepten los alias `win11`, `win11-x64`, `win11-arm64`, `amd64`,
`aarch64`, `cn-home` y `cn-pro`. Les ediciones antigües almiten amás `windows7`,
`windows8`, `windows8.1`, `win81`, `windows81` y los valores sueltos `7`, `8`, `8.1`.

### Verificación de hash

El digest SHA-256 calcúlase siempre mientres la descarga y imprentase en stderr:

```text
✔ Saved to Win11_English_x64.iso
  SHA-256: b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c
```

Usa `--verify` pa esixir un hash esperáu — el procesu termina con error si nun coincide:

```sh
wisodown --edition x64 --language English \
         --verify b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c
```

### Otros flags

```sh
# List available languages for an edition
wisodown --edition win10 --list-languages

# Print the download URL without downloading
wisodown --edition x64 --language English --url-only
```

### Cookies anti-bot (si fallen les descargues)

La API de Microsoft usa una capa anti-bot llamada Sentinel. La ferramienta intenta
llograr les cookies necesaries automáticamente, pero si falla puedes apurtales a mano:

1. Abre la páxina de descarga nun navegador
2. Abre DevTools → Network → cualquier petición a `microsoft.com` → Request Headers → Cookie
3. Copia la cadena de cookies y pásala:

```sh
wisodown --edition x64 --language English --cookie "MUID=...; fptctx2=..."
```

### Modu depuración

```sh
wisodown --edition x64 --language English --debug
```

Imprime toles peticiones y respuestes de la API, y los pasos d'intercambiu de cookies, en stderr.

## Cómo funciona

1. Carga la páxina de descarga de Microsoft pa llograr les cookies de sesión
2. Llama a `ov-df.microsoft.com` pa simular el pasu de fingerprinting del
   navegador (cookies fptctx2/MUID) que rique Sentinel
3. Llama a `getSkuInformationByProductEdition` pa llistar los SKUs de llingua disponibles
4. Llama a `GetProductDownloadLinksBySku` pa llograr un enllaz de CDN con llímite de tiempu
5. Baxa la ISO a discu en streaming, calculando SHA-256 sobre la marcha, con barra de progresu

Pa les ediciones antigües **Windows 7 / 8 / 8.1** nun hai llamada a la API de
Microsoft: la ferramienta consulta la **API de metadatos d'archive.org** pa llograr
la llista d'ISOs (nomes, tamaños, MD5) y baxa dende
`https://archive.org/download/<item>/<file>`, reutilizando'l mesmu descargador
multihilo y comprobando'l MD5 d'archive.org. Almita llingua inglesa y española.

## Documentación

- [Technical reference (English)](docs/guide/technical.md)
- [Referencia téunica (Español)](docs/guide/technical.es.md)

## Llicencia

GNU General Public License 3.0
