# Running the server locally — in detail

All you need is Rust and the repository itself. Neither Postgres, nor Docker,
nor ffmpeg is required — the database is a SQLite file and the audio is parsed
by a library inside the process.

---

## 1. What to install

### Rust

```powershell
winget install Rustlang.Rustup     # or download from https://rustup.rs
rustup default stable
```

A check (1.75+ is required, the project was built on 1.97):

```powershell
cargo --version
rustc --version
```

### A C compiler (Windows only, once)

`libsqlite3-sys` builds C code, so the MSVC linker is needed. If the first build
reports `error: linker 'link.exe' not found`, install **Visual Studio Build
Tools** with the "Desktop development with C++" workload:

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools
```

On macOS it is `xcode-select --install`, on Linux `build-essential`.

---

## 2. The first run

```powershell
cd c:\Users\arovit\Projects\shado_server
Copy-Item .env.example .env
cargo run
```

The first build takes a couple of minutes (277 dependencies), the next ones take
seconds.

What happens on start:

1. `.env` and the environment variables are read;
2. the `shado.db` database file is created and the migrations from `migrations/`
   are applied;
3. the `storage/` folder is created (plus `storage/tmp/` for uploads);
4. if a user with `SHADO_OWNER_EMAIL` is already registered, they are given the
   `owner` role;
5. the server listens on `http://127.0.0.1:8080`.

The log will look roughly like this (the server logs in Russian):

```text
INFO shado_server: конфигурация загружена owner_email=arovitm@gmail.com storage="./storage"
INFO shado_server: shado-server слушает на http://127.0.0.1:8080
```

A check:

```powershell
curl.exe http://127.0.0.1:8080/healthz
# {"status":"ok"}
```

`Ctrl+C` stops it.

### The minimum worth fixing in `.env`

```env
SHADO_JWT_SECRET=any-long-random-string
```

Without it the server starts with a default secret and prints a warning — that
is acceptable for local development and for nothing else.

---

## 3. Environment variables

They are all optional and each has a default. They are read from `.env` and from
the environment (the environment wins).

| Variable | Default | Meaning |
| --- | --- | --- |
| `SHADO_BIND_ADDR` | `127.0.0.1:8080` | the address and the port. `0.0.0.0:8080` accepts from the local network |
| `SHADO_PUBLIC_BASE_URL` | `http://127.0.0.1:8080` | the base for the `audio.url` links in responses |
| `SHADO_DATABASE_URL` | `sqlite://./shado.db?mode=rwc` | the path to the database file |
| `SHADO_STORAGE_DIR` | `./storage` | where to put the audio |
| `SHADO_JWT_SECRET` | an insecure default plus a warning | the signature of access tokens |
| `SHADO_OWNER_EMAIL` | `arovitm@gmail.com` | who is granted the `owner` role |
| `SHADO_ACCESS_TTL_SECS` | `900` (15 min) | the access token lifetime |
| `SHADO_REFRESH_TTL_SECS` | `5184000` (60 days) | the refresh token lifetime |
| `SHADO_MAX_UPLOAD_BYTES` | `52428800` (50 MB) | the per-file limit |
| `SHADO_AUTH_RATE_LIMIT` | `10` | attempts a minute on `/v1/auth/*` (per IP and per email) |
| `SHADO_PEAKS_RESOLUTION` | `4000` | the resolution the envelope is stored at |
| `SHADO_LOG` | `info` | the log level, in `env_filter` syntax |

One-off, without editing `.env` (PowerShell):

```powershell
$env:SHADO_BIND_ADDR = "0.0.0.0:8080"; cargo run
```

---

## 4. The whole live scenario

Below is the full path "registered → uploaded audio → created a lesson → read it
back". The commands are for PowerShell; in bash it is the same with `curl` and
`jq`.

**1. Registering the owner.** The `owner` role is granted automatically because
the email matches `SHADO_OWNER_EMAIL`:

```powershell
$credentials = @{ email = "arovitm@gmail.com"; password = "password123" } | ConvertTo-Json

$auth = $credentials | curl.exe -s -X POST http://127.0.0.1:8080/v1/auth/register `
  -H "Content-Type: application/json" --data-binary "@-" | ConvertFrom-Json

$token = $auth.access_token
$auth.user.role     # owner
```

Quoting in PowerShell behaves treacherously when JSON is passed to native
commands, so here and below the body goes through stdin (`--data-binary "@-"`)
rather than through `-d '…'`.

If the user already exists, use `login` instead of `register` with the same body.

**2. Who am I:**

```powershell
curl.exe -s http://127.0.0.1:8080/v1/me -H "Authorization: Bearer $token"
```

**3. Uploading audio.** Any mp3/m4a/wav/flac/ogg up to 50 MB. The catalog is
curated by `admin` and `owner` — with a plain `user` token, steps 3–5 answer
`403 forbidden`:

```powershell
$audio = curl.exe -s -X POST http://127.0.0.1:8080/v1/audio `
  -H "Authorization: Bearer $token" `
  -F "file=@C:\path\to\lesson.mp3" | ConvertFrom-Json

$audio.id
$audio.duration_ms          # computed by the server
$audio.peaks.resolution     # points in the envelope
```

Re-uploading the same file returns the same record and status `200` instead of
`201`.

**4. Creating a lesson.** The client generates the UUID; the markup is segments
back to back from 0 to `duration_ms`. The accent (`US`/`UK`) and the level
(`a1`..`c2`) are required, and the topic comes from the directory
(`curl.exe -s http://127.0.0.1:8080/v1/topics -H "Authorization: Bearer $token"`);
if it is not passed, it will be "Other":

```powershell
$lessonId = [guid]::NewGuid().ToString()
$half = [int]($audio.duration_ms / 2)
$body = @{
  title      = "Trial lesson"
  audio_id   = $audio.id
  created_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
  accent     = "US"
  level      = "b1"
  segments   = @(
    @{ index = 0; text = "First segment";  start_ms = 0;     end_ms = $half },
    @{ index = 1; text = "Second segment"; start_ms = $half; end_ms = $audio.duration_ms }
  )
} | ConvertTo-Json -Depth 5

$lesson = $body | curl.exe -s -X PUT "http://127.0.0.1:8080/v1/lessons/$lessonId" `
  -H "Authorization: Bearer $token" -H "Content-Type: application/json" `
  --data-binary "@-" | ConvertFrom-Json

$lesson.version    # 1
```

**5. Reading and editing:**

```powershell
# the list
curl.exe -s "http://127.0.0.1:8080/v1/lessons?limit=10" -H "Authorization: Bearer $token"

# filters combine with AND: accent, level, topic
curl.exe -s "http://127.0.0.1:8080/v1/lessons?accent=UK&level=c1" -H "Authorization: Bearer $token"

# one lesson; the headers carry ETag: "1"
curl.exe -s -i "http://127.0.0.1:8080/v1/lessons/$lessonId" -H "Authorization: Bearer $token"

# an edit needs If-Match with the current version; without it you get a 409
$renamed = ($body | ConvertFrom-Json)
$renamed.title = "Lesson renamed"
$renamed | ConvertTo-Json -Depth 5 | curl.exe -s -X PUT "http://127.0.0.1:8080/v1/lessons/$lessonId" `
  -H "Authorization: Bearer $token" -H "Content-Type: application/json" `
  -H 'If-Match: "1"' --data-binary "@-"
```

**6. Audio and peaks:**

```powershell
# the envelope at the width of the widget
curl.exe -s "http://127.0.0.1:8080/v1/audio/$($audio.id)/peaks?resolution=800" `
  -H "Authorization: Bearer $token"

# the whole file
curl.exe -s -o out.mp3 "http://127.0.0.1:8080/v1/audio/$($audio.id)/file" `
  -H "Authorization: Bearer $token"

# a slice of the file: a 206 response plus Content-Range
curl.exe -s -i -H "Range: bytes=0-1023" "http://127.0.0.1:8080/v1/audio/$($audio.id)/file" `
  -H "Authorization: Bearer $token" | Select-Object -First 12
```

**7. The admin area (owner only):**

```powershell
curl.exe -s "http://127.0.0.1:8080/v1/admin/users?limit=50" -H "Authorization: Bearer $token"

# the role: user | admin | owner. admin curates the lesson catalog but does not see this admin area
@{ role = "admin" } | ConvertTo-Json | curl.exe -s -X PATCH `
  "http://127.0.0.1:8080/v1/admin/users/<user-id>/role" `
  -H "Authorization: Bearer $token" -H "Content-Type: application/json" --data-binary "@-"

# deletion: 204; the lessons and audio of the deleted user pass to the owner, the catalog stays intact
curl.exe -s -i -X DELETE "http://127.0.0.1:8080/v1/admin/users/<user-id>" `
  -H "Authorization: Bearer $token"
```

Yourself and the owner from `SHADO_OWNER_EMAIL` cannot be deleted — the answer
is `422`.

**8. Topics (everyone reads, the owner edits):**

```powershell
curl.exe -s http://127.0.0.1:8080/v1/topics -H "Authorization: Bearer $token"

$topic = @{ name = "Podcasts" } | ConvertTo-Json | curl.exe -s -X POST `
  http://127.0.0.1:8080/v1/topics `
  -H "Authorization: Bearer $token" -H "Content-Type: application/json" `
  --data-binary "@-" | ConvertFrom-Json

@{ name = "Podcasts & Talks" } | ConvertTo-Json | curl.exe -s -X PATCH `
  "http://127.0.0.1:8080/v1/topics/$($topic.id)" `
  -H "Authorization: Bearer $token" -H "Content-Type: application/json" --data-binary "@-"

# deletion: the lessons of the topic move to "Other"
curl.exe -s -i -X DELETE "http://127.0.0.1:8080/v1/topics/$($topic.id)" `
  -H "Authorization: Bearer $token"
```

---

## 5. Connecting the app

| From where | Which base URL |
| --- | --- |
| Flutter on the same machine (Windows/macOS/Linux, web) | `http://127.0.0.1:8080` |
| The Android emulator | `http://10.0.2.2:8080` — that is the host machine from inside the emulator |
| The iOS simulator | `http://127.0.0.1:8080` |
| A real phone on the same Wi-Fi network | `http://<the machine IP>:8080` |

A real device needs three more things:

1. The server must listen beyond loopback:

   ```env
   SHADO_BIND_ADDR=0.0.0.0:8080
   SHADO_PUBLIC_BASE_URL=http://192.168.1.50:8080
   ```

   Look the IP up with `ipconfig` (the IPv4 line of the active adapter).

2. Allow the port through the Windows firewall (once, from an elevated
   PowerShell):

   ```powershell
   New-NetFirewallRule -DisplayName "shado-server" -Direction Inbound `
     -Protocol TCP -LocalPort 8080 -Action Allow -Profile Private
   ```

3. Android forbids HTTP without TLS by default. For a debug build use
   `android:usesCleartextTraffic="true"` in `AndroidManifest.xml` (in the debug
   variant of the manifest, not in release) or a `network_security_config` that
   allows the development server address only.

`SHADO_PUBLIC_BASE_URL` drives the `audio.url` field in the responses: leave it
at `127.0.0.1` and the phone will follow that link into itself.

---

## 6. Where the data lives and how to wipe it

| What | Where |
| --- | --- |
| The database | `shado.db` (plus `shado.db-wal`, `shado.db-shm` — the WAL journal) |
| The audio | `storage/<who uploaded it>/<sha256>.<ext>` — the path is fixed at upload time and never changes, even if the record later passes to the owner |
| Unfinished uploads | `storage/tmp/` |

All of it is in `.gitignore`. A full reset is stopping the server and deleting:

```powershell
Remove-Item shado.db* -Force
Remove-Item storage -Recurse -Force
```

The next `cargo run` recreates the database and the folders. There is no
separate migration command — they are applied on start.

**Check a new migration against a copy of a working database, not only with
tests.** Tests always start from an empty database, and some SQLite constraints
only fire on a table with rows (an `alter table add column` with `references`
and a non-null default, for instance, passes on an empty table and fails on a
populated one):

```powershell
Copy-Item shado.db check.db
$env:SHADO_DATABASE_URL = "sqlite:./check.db?mode=rw"; cargo run   # migration errors show in the first log lines
```

The database contents can be inspected with any SQLite client (DB Browser for
SQLite, the SQLite plugin for VS Code) — the file is an ordinary one.

---

## 7. Tests and quality

```powershell
cargo test              # 33 tests: units plus contract tests on every endpoint
cargo test -- --nocapture   # with the output
cargo clippy --all-targets  # the lint
cargo fmt                   # formatting
```

The contract tests bring the whole application up in a temporary folder and
touch neither `shado.db` nor `storage/` — they can be run while the server is
up.

---

## 8. Building a release binary

```powershell
cargo build --release
.\target\release\shado-server.exe
```

The binary is self-contained: the only thing it needs beside it is `migrations/`
(they are baked into the binary at compile time) — in practice the exe itself,
`.env` and write access to `SHADO_STORAGE_DIR` are enough. A separate SQLite
installation is not needed, it is built in.

For production, add a reverse proxy with TLS (nginx/Caddy), pass the real client
IP in `X-Forwarded-For` (the rate limiter reads it) and set `SHADO_JWT_SECRET`
without fail.

---

## 9. Common problems

| Symptom | The cause and what to do |
| --- | --- |
| `SHADO_JWT_SECRET не задан, используется небезопасный дефолт` | a warning, not an error. Set the secret in `.env` |
| `Address already in use` on start | port 8080 is taken. Use `SHADO_BIND_ADDR=127.0.0.1:8090` or find the process: `Get-NetTCPConnection -LocalPort 8080` |
| `error: linker 'link.exe' not found` | the MSVC Build Tools are missing, see §1 |
| `миграции: ...` on start | the database file comes from an incompatible schema version. Delete `shado.db*` (the data is lost) |
| `401 unauthorized` on every request | the `Authorization: Bearer …` header is missing, or the access token is older than 15 minutes → `POST /v1/auth/refresh` |
| Every token stopped working at once | `SHADO_JWT_SECRET` changed: the access tokens are signed with the old key. The refresh tokens are still alive — they live in the database |
| `415 unsupported_media_type` on upload | the extension is not on the list (`mp3, m4a, aac, wav, flac, ogg`) or the file is corrupted. The file name in the multipart must carry an extension |
| `413 payload_too_large` | the file is larger than `SHADO_MAX_UPLOAD_BYTES` |
| `429 rate_limited` on sign-in | more than 10 attempts a minute. Wait a minute or raise `SHADO_AUTH_RATE_LIMIT` for debugging |
| `409 version_conflict` on a `PUT` | `If-Match: "<version>"` was not passed or the version is stale. The current lesson is in `error.current` |
| `404 not_found` on a lesson | the lesson was soft deleted (`deleted_at`) or never existed: the catalog is shared and holds no "other people's" lessons |
| `404 not_found` on an `audio_id` while creating a lesson | the audio was uploaded by another editor and is not published in a live lesson yet. Upload the file with your own token |
| `403 forbidden` on `POST /v1/audio`, `PUT`/`DELETE /v1/lessons` | the user has the `user` role. The catalog is curated by `admin` and `owner` — grant the role through the admin area (§4, step 7) |
| `403 forbidden` on `/v1/admin/users` or `POST/PATCH/DELETE /v1/topics` | the `owner` role is required; `admin` edits neither users nor the topic directory |
| A `422` about `accent` or `level` while creating a lesson | the fields are required: `accent` is `US`/`UK`, `level` is `a1`..`c2`. Case does not matter, everything else is rejected |
| `404 not_found` on a `topic_id` | there is no topic with that id (it may have been deleted). Re-read `GET /v1/topics` |
| The `user` role instead of `owner` | the email did not match `SHADO_OWNER_EMAIL` (compared by the normalized address: trim + lowercase). Fix `.env` and restart — the role is granted on start |
| The phone does not see the server | `SHADO_BIND_ADDR` listens on `127.0.0.1` only, or the firewall, or different networks — see §5 |

More detail is in the log: `SHADO_LOG=debug`, or targeted
`SHADO_LOG=shado_server=debug,tower_http=debug`.
