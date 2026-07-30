# Локальный запуск сервера — подробно

Всё, что нужно: Rust и сам репозиторий. Ни Postgres, ни Docker, ни ffmpeg не
требуются — БД это файл SQLite, аудио разбирается библиотекой внутри процесса.

---

## 1. Что поставить

### Rust

```powershell
winget install Rustlang.Rustup     # или скачать с https://rustup.rs
rustup default stable
```

Проверка (нужен 1.75+, проект собран на 1.97):

```powershell
cargo --version
rustc --version
```

### Компилятор C (только Windows, один раз)

`libsqlite3-sys` собирает C-код, поэтому нужен линковщик MSVC. Если при первой
сборке появится `error: linker 'link.exe' not found` — поставить
**Visual Studio Build Tools** с рабочей нагрузкой «Разработка классических
приложений на C++»:

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools
```

На macOS — `xcode-select --install`, на Linux — `build-essential`.

---

## 2. Первый запуск

```powershell
cd c:\Users\arovit\Projects\shado_server
Copy-Item .env.example .env
cargo run
```

Первая сборка занимает пару минут (277 зависимостей), дальше — секунды.

Что произойдёт при старте:

1. читается `.env` и переменные окружения;
2. создаётся файл БД `shado.db` и накатываются миграции из `migrations/`;
3. создаётся папка `storage/` (и `storage/tmp/` под загрузки);
4. если пользователь с `SHADO_OWNER_EMAIL` уже зарегистрирован, ему проставляется
   роль `owner`;
5. сервер слушает `http://127.0.0.1:8080`.

В логе будет примерно так:

```text
INFO shado_server: конфигурация загружена owner_email=arovitm@gmail.com storage="./storage"
INFO shado_server: shado-server слушает на http://127.0.0.1:8080
```

Проверка:

```powershell
curl.exe http://127.0.0.1:8080/healthz
# {"status":"ok"}
```

Остановка — `Ctrl+C`.

### Минимум, что стоит поправить в `.env`

```env
SHADO_JWT_SECRET=любая-длинная-случайная-строка
```

Без него сервер стартует с дефолтным секретом и пишет предупреждение — для
локальной разработки это допустимо, для чего-либо ещё нет.

---

## 3. Переменные окружения

Все необязательны, у каждой есть дефолт. Читаются из `.env` и из окружения
(окружение имеет приоритет).

| Переменная | По умолчанию | Смысл |
| --- | --- | --- |
| `SHADO_BIND_ADDR` | `127.0.0.1:8080` | адрес и порт. `0.0.0.0:8080` — принимать из локальной сети |
| `SHADO_PUBLIC_BASE_URL` | `http://127.0.0.1:8080` | база для ссылок `audio.url` в ответах |
| `SHADO_DATABASE_URL` | `sqlite://./shado.db?mode=rwc` | путь к файлу БД |
| `SHADO_STORAGE_DIR` | `./storage` | куда складывать аудио |
| `SHADO_JWT_SECRET` | небезопасный дефолт + warning | подпись access-токенов |
| `SHADO_OWNER_EMAIL` | `arovitm@gmail.com` | кому выдаётся роль `owner` |
| `SHADO_ACCESS_TTL_SECS` | `900` (15 мин) | время жизни access-токена |
| `SHADO_REFRESH_TTL_SECS` | `5184000` (60 дней) | время жизни refresh-токена |
| `SHADO_MAX_UPLOAD_BYTES` | `52428800` (50 МБ) | лимит на файл |
| `SHADO_AUTH_RATE_LIMIT` | `10` | попыток в минуту на `/v1/auth/*` (на IP и на email) |
| `SHADO_PEAKS_RESOLUTION` | `4000` | в каком разрешении хранить огибающую |
| `SHADO_LOG` | `info` | уровень логов, синтаксис `env_filter` |

Разово, без правки `.env` (PowerShell):

```powershell
$env:SHADO_BIND_ADDR = "0.0.0.0:8080"; cargo run
```

---

## 4. Живой сценарий целиком

Ниже — полный путь «зарегистрировался → загрузил аудио → создал урок → прочитал
его». Команды для PowerShell; в bash то же самое с `curl` и `jq`.

**1. Регистрация владельца.** Роль `owner` выдаётся автоматически, потому что
email совпадает с `SHADO_OWNER_EMAIL`:

```powershell
$credentials = @{ email = "arovitm@gmail.com"; password = "password123" } | ConvertTo-Json

$auth = $credentials | curl.exe -s -X POST http://127.0.0.1:8080/v1/auth/register `
  -H "Content-Type: application/json" --data-binary "@-" | ConvertFrom-Json

$token = $auth.access_token
$auth.user.role     # owner
```

Кавычки в PowerShell при передаче JSON в нативные команды ведут себя коварно,
поэтому здесь и дальше тело уходит через stdin (`--data-binary "@-"`), а не
через `-d '…'`.

Если пользователь уже создан, вместо `register` — `login` с тем же телом.

**2. Кто я:**

```powershell
curl.exe -s http://127.0.0.1:8080/v1/me -H "Authorization: Bearer $token"
```

**3. Загрузка аудио.** Любой mp3/m4a/wav/flac/ogg до 50 МБ. Каталог ведут
`admin` и `owner` — с токеном обычного `user` шаги 3–5 ответят `403 forbidden`:

```powershell
$audio = curl.exe -s -X POST http://127.0.0.1:8080/v1/audio `
  -H "Authorization: Bearer $token" `
  -F "file=@C:\путь\к\lesson.mp3" | ConvertFrom-Json

$audio.id
$audio.duration_ms          # посчитан сервером
$audio.peaks.resolution     # точек в огибающей
```

Повторная загрузка того же файла вернёт ту же запись и статус `200` вместо `201`.

**4. Создание урока.** UUID генерирует клиент; разметка — сегменты встык от 0 до
`duration_ms`. Акцент (`US`/`UK`) и уровень (`a1`..`c2`) обязательны, тема
берётся из справочника (`curl.exe -s http://127.0.0.1:8080/v1/topics -H "Authorization: Bearer $token"`);
не передали — будет «Other»:

```powershell
$lessonId = [guid]::NewGuid().ToString()
$half = [int]($audio.duration_ms / 2)
$body = @{
  title      = "Пробный урок"
  audio_id   = $audio.id
  created_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
  accent     = "US"
  level      = "b1"
  segments   = @(
    @{ index = 0; text = "Первый кусок";  start_ms = 0;     end_ms = $half },
    @{ index = 1; text = "Второй кусок";  start_ms = $half; end_ms = $audio.duration_ms }
  )
} | ConvertTo-Json -Depth 5

$lesson = $body | curl.exe -s -X PUT "http://127.0.0.1:8080/v1/lessons/$lessonId" `
  -H "Authorization: Bearer $token" -H "Content-Type: application/json" `
  --data-binary "@-" | ConvertFrom-Json

$lesson.version    # 1
```

**5. Чтение и правка:**

```powershell
# список
curl.exe -s "http://127.0.0.1:8080/v1/lessons?limit=10" -H "Authorization: Bearer $token"

# фильтры складываются по «и»: акцент, уровень, тема
curl.exe -s "http://127.0.0.1:8080/v1/lessons?accent=UK&level=c1" -H "Authorization: Bearer $token"

# один урок, в заголовках придёт ETag: "1"
curl.exe -s -i "http://127.0.0.1:8080/v1/lessons/$lessonId" -H "Authorization: Bearer $token"

# правка требует If-Match с текущей версией; без него будет 409
$renamed = ($body | ConvertFrom-Json)
$renamed.title = "Урок переименован"
$renamed | ConvertTo-Json -Depth 5 | curl.exe -s -X PUT "http://127.0.0.1:8080/v1/lessons/$lessonId" `
  -H "Authorization: Bearer $token" -H "Content-Type: application/json" `
  -H 'If-Match: "1"' --data-binary "@-"
```

**6. Аудио и пики:**

```powershell
# огибающая под ширину виджета
curl.exe -s "http://127.0.0.1:8080/v1/audio/$($audio.id)/peaks?resolution=800" `
  -H "Authorization: Bearer $token"

# файл целиком
curl.exe -s -o out.mp3 "http://127.0.0.1:8080/v1/audio/$($audio.id)/file" `
  -H "Authorization: Bearer $token"

# кусок файла: ответ 206 + Content-Range
curl.exe -s -i -H "Range: bytes=0-1023" "http://127.0.0.1:8080/v1/audio/$($audio.id)/file" `
  -H "Authorization: Bearer $token" | Select-Object -First 12
```

**7. Админка (только owner):**

```powershell
curl.exe -s "http://127.0.0.1:8080/v1/admin/users?limit=50" -H "Authorization: Bearer $token"

# роль: user | admin | owner. admin ведёт каталог уроков, но не видит эту админку
@{ role = "admin" } | ConvertTo-Json | curl.exe -s -X PATCH `
  "http://127.0.0.1:8080/v1/admin/users/<user-id>/role" `
  -H "Authorization: Bearer $token" -H "Content-Type: application/json" --data-binary "@-"

# удаление: 204; уроки и аудио удалённого переходят к owner, каталог не рушится
curl.exe -s -i -X DELETE "http://127.0.0.1:8080/v1/admin/users/<user-id>" `
  -H "Authorization: Bearer $token"
```

Себя и владельца из `SHADO_OWNER_EMAIL` удалить нельзя — ответ `422`.

**8. Темы (читают все, правит owner):**

```powershell
curl.exe -s http://127.0.0.1:8080/v1/topics -H "Authorization: Bearer $token"

$topic = @{ name = "Podcasts" } | ConvertTo-Json | curl.exe -s -X POST `
  http://127.0.0.1:8080/v1/topics `
  -H "Authorization: Bearer $token" -H "Content-Type: application/json" `
  --data-binary "@-" | ConvertFrom-Json

@{ name = "Podcasts & Talks" } | ConvertTo-Json | curl.exe -s -X PATCH `
  "http://127.0.0.1:8080/v1/topics/$($topic.id)" `
  -H "Authorization: Bearer $token" -H "Content-Type: application/json" --data-binary "@-"

# удаление: уроки темы переезжают на «Other»
curl.exe -s -i -X DELETE "http://127.0.0.1:8080/v1/topics/$($topic.id)" `
  -H "Authorization: Bearer $token"
```

---

## 5. Подключение приложения

По умолчанию приложение ходит на боевой сервер
(`https://shado-martin.duckdns.org`) — этот раздел про то, как переключить его
на локальный. Адрес передаётся сборке:
`flutter run --dart-define=SHADO_API_BASE_URL=<URL из таблицы>`.

| Откуда | Какой базовый URL |
| --- | --- |
| Flutter на этой же машине (Windows/macOS/Linux, web) | `http://127.0.0.1:8080` |
| Android-эмулятор | `http://10.0.2.2:8080` — это хост-машина изнутри эмулятора |
| iOS-симулятор | `http://127.0.0.1:8080` |
| Реальный телефон в той же Wi-Fi сети | `http://<IP машины>:8080` |

Для реального устройства нужно ещё три вещи:

1. Сервер должен слушать не только loopback:

   ```env
   SHADO_BIND_ADDR=0.0.0.0:8080
   SHADO_PUBLIC_BASE_URL=http://192.168.1.50:8080
   ```

   IP смотреть через `ipconfig` (строка IPv4 активного адаптера).

2. Разрешить порт в брандмауэре Windows (один раз, из PowerShell с правами
   администратора):

   ```powershell
   New-NetFirewallRule -DisplayName "shado-server" -Direction Inbound `
     -Protocol TCP -LocalPort 8080 -Action Allow -Profile Private
   ```

3. Android по умолчанию запрещает HTTP без TLS. Для отладочной сборки —
   `android:usesCleartextTraffic="true"` в `AndroidManifest.xml` (в debug-варианте
   манифеста, не в release) или `network_security_config` с разрешением только на
   адрес сервера разработки.

`SHADO_PUBLIC_BASE_URL` влияет на поле `audio.url` в ответах: если оставить
`127.0.0.1`, телефон по этой ссылке попадёт сам в себя.

---

## 6. Где лежат данные и как всё сбросить

| Что | Где |
| --- | --- |
| БД | `shado.db` (+ `shado.db-wal`, `shado.db-shm` — журнал WAL) |
| Аудио | `storage/<кто загрузил>/<sha256>.<ext>` — путь фиксируется при загрузке и не меняется, даже если запись потом перешла к owner |
| Незавершённые загрузки | `storage/tmp/` |

Всё это в `.gitignore`. Полный сброс — остановить сервер и удалить:

```powershell
Remove-Item shado.db* -Force
Remove-Item storage -Recurse -Force
```

При следующем `cargo run` база и папки создадутся заново. Отдельной команды
миграции не нужно — они накатываются на старте.

**Новую миграцию проверяйте на копии рабочей базы, а не только тестами.** Тесты
всегда стартуют с пустой БД, а часть ограничений SQLite срабатывает только на
таблице со строками (так, `alter table add column` с `references` и ненулевым
значением по умолчанию проходит на пустой таблице и падает на заполненной):

```powershell
Copy-Item shado.db check.db
$env:SHADO_DATABASE_URL = "sqlite:./check.db?mode=rw"; cargo run   # ошибки миграции видно в первых строках лога
```

Посмотреть содержимое БД можно любым SQLite-клиентом (DB Browser for SQLite,
плагин SQLite в VS Code) — файл обычный.

---

## 7. Тесты и качество

```powershell
cargo test              # 33 теста: юниты + контрактные тесты на все эндпоинты
cargo test -- --nocapture   # с выводом
cargo clippy --all-targets  # линт
cargo fmt                   # форматирование
```

Контрактные тесты поднимают приложение целиком во временной папке и не трогают
ни `shado.db`, ни `storage/` — их можно гонять при запущенном сервере.

---

## 8. Сборка релизного бинарника

```powershell
cargo build --release
.\target\release\shado-server.exe
```

Бинарник самодостаточный: рядом нужны только `migrations/` (они вшиты в
бинарник на этапе компиляции) — фактически достаточно самого exe, `.env` и права
писать в `SHADO_STORAGE_DIR`. Отдельная установка SQLite не нужна, он внутри.

Для прода добавить обратный прокси с TLS (nginx/Caddy), передавать реальный IP
клиента в `X-Forwarded-For` (rate limiter читает его) и обязательно задать
`SHADO_JWT_SECRET`.

---

## 9. Частые проблемы

| Симптом | Причина и что делать |
| --- | --- |
| `SHADO_JWT_SECRET не задан, используется небезопасный дефолт` | предупреждение, а не ошибка. Задать секрет в `.env` |
| `Address already in use` при старте | порт 8080 занят. `SHADO_BIND_ADDR=127.0.0.1:8090` или найти процесс: `Get-NetTCPConnection -LocalPort 8080` |
| `error: linker 'link.exe' not found` | нет MSVC Build Tools, см. §1 |
| `миграции: ...` при старте | файл БД от несовместимой версии схемы. Удалить `shado.db*` (данные потеряются) |
| `401 unauthorized` на любом запросе | нет заголовка `Authorization: Bearer …`, либо access-токен старше 15 минут → `POST /v1/auth/refresh` |
| Все токены разом перестали работать | сменился `SHADO_JWT_SECRET`: access-токены подписаны старым ключом. Refresh-токены при этом живы — они в БД |
| `415 unsupported_media_type` при загрузке | расширение не из списка (`mp3, m4a, aac, wav, flac, ogg`) или файл повреждён. Имя файла в multipart должно быть с расширением |
| `413 payload_too_large` | файл больше `SHADO_MAX_UPLOAD_BYTES` |
| `429 rate_limited` на входе | больше 10 попыток в минуту. Подождать минуту или поднять `SHADO_AUTH_RATE_LIMIT` для отладки |
| `409 version_conflict` при `PUT` | не передан `If-Match: "<version>"` или версия устарела. Актуальный урок — в `error.current` |
| `404 not_found` на уроке | урок мягко удалён (`deleted_at`) или его никогда не было: каталог общий, «чужих» уроков в нём нет |
| `404 not_found` на `audio_id` при создании урока | аудио загружено другим редактором и ещё не опубликовано в живом уроке. Загрузить файл своим токеном |
| `403 forbidden` на `POST /v1/audio`, `PUT`/`DELETE /v1/lessons` | у пользователя роль `user`. Каталог ведут `admin` и `owner` — назначить роль через админку (§4, шаг 7) |
| `403 forbidden` на `/v1/admin/users` или `POST/PATCH/DELETE /v1/topics` | нужна роль `owner`; `admin` ни пользователей, ни справочник тем не правит |
| `422` про `accent` или `level` при создании урока | поля обязательны: `accent` — `US`/`UK`, `level` — `a1`..`c2`. Регистр не важен, всё остальное отклоняется |
| `404 not_found` на `topic_id` | темы с таким id нет (могли удалить). Перечитать `GET /v1/topics` |
| Роль `user` вместо `owner` | email не совпал с `SHADO_OWNER_EMAIL` (сравнение по нормализованному адресу: trim + lowercase). Поправить `.env` и перезапустить — роль проставится на старте |
| Телефон не видит сервер | `SHADO_BIND_ADDR` слушает только `127.0.0.1`, либо брандмауэр, либо разные сети — см. §5 |

Больше деталей в логе: `SHADO_LOG=debug` или точечно
`SHADO_LOG=shado_server=debug,tower_http=debug`.
