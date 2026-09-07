# A server for Shado: what needs to be done

> **A historical document.** This is the original plan the server was built
> from; it describes lessons as personal records of a user (`lessons.user_id`,
> "`audio_id` belongs to the same user"). The access model has changed since:
> lessons became a shared catalog curated by the `admin` and `owner` roles, and
> the column is named `author_id`. The current rules are in
> [README](../README.md) and [CLIENT_SPEC](CLIENT_SPEC.md), and the schema is in
> `migrations/`.

The app currently works entirely locally. The task is to move lessons (text,
segmentation, audio) to a server and add authorization without rewriting the
domain and the UI.

The seams for this were laid from the start (see `SHADOWING_MVP_PROMPT.md`,
section 9): identifiers are client-side UUIDs, the models are already
JSON-serializable, and `LessonRepositoryImpl` is the single place a remote
source is added to.

---

## 1. The open fork: the stack

The only decision that has to be made before the work starts.

| Option | What it gives | What it costs |
| --- | --- | --- |
| **Our own API** (recommended: Dart + `dart_frog`/`shelf` + Postgres + S3-compatible storage) | Full control, the same language as the app, the `freezed` models can be reused as server DTOs | Authentication, file storage, migrations and deployment are written by us |
| **BaaS** (Supabase: Postgres + Auth + Storage + RLS) | Registration, tokens, refresh, file uploads and access rights out of the box, in a day | Transcoding and precomputing the peaks are still ours (an Edge Function); a lock-in to the platform |

The recommendation: if the goal is to get working synchronization quickly, take
**Supabase** and move audio processing into a single function. If the server is
meant to grow (sharing lessons, generation, payments) — **our own API in Dart**.

Everything below is independent of that choice: the contract, the data schema
and the order of work are the same. From here on, "the server" means either
implementation.

---

## 2. The data model on the server

Postgres. Segments, as locally, are part of the lesson aggregate (`jsonb`): they
are always read and written together with the lesson, and separate queries over
them are not needed.

```sql
create table users (
  id            uuid primary key,
  email         text not null unique,
  password_hash text not null,           -- argon2id
  created_at    timestamptz not null default now()
);

create table refresh_tokens (
  id          uuid primary key,
  user_id     uuid not null references users on delete cascade,
  token_hash  text not null unique,      -- we store the hash, not the token
  family_id   uuid not null,             -- the rotation chain, for reuse detection
  expires_at  timestamptz not null,
  revoked_at  timestamptz,
  user_agent  text
);

-- Audio lives apart from the lesson: the file is uploaded BEFORE the lesson is
-- created (see §5).
create table audio_files (
  id            uuid primary key,
  user_id       uuid not null references users on delete cascade,
  storage_key   text not null,           -- the key in S3 / Storage
  content_type  text not null,
  size_bytes    bigint not null,
  sha256        text not null,
  duration_ms   integer not null,        -- computed by the server
  peaks         bytea not null,          -- the envelope, int8, high resolution
  peaks_count   integer not null,
  created_at    timestamptz not null default now(),
  unique (user_id, sha256)               -- re-uploading the same file is free
);

create table lessons (
  id          uuid primary key,          -- the UUID comes from the client
  user_id     uuid not null references users on delete cascade,
  audio_id    uuid not null references audio_files,
  title       text not null,
  duration_ms integer not null,
  segments    jsonb not null,            -- [{index, text, start_ms, end_ms}]
  created_at  timestamptz not null,      -- comes from the client
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz,               -- a soft delete, so it spreads across devices
  version     integer not null default 1 -- for If-Match
);

create index on lessons (user_id, updated_at desc);
```

The invariants the server is obliged to check (the app domain checks them too,
but the server must not trust the client):

- at least one segment, with `index` running `0..N-1` without gaps;
- the boundaries strictly increase, `segments[0].start_ms = 0`,
  `segments[N-1].end_ms = duration_ms`;
- the `duration_ms` of the lesson equals the `duration_ms` of its audio;
- the `audio_id` belongs to the same user.

---

## 3. Authentication

Email and password, JWT: a short access token and a long refresh token with
rotation.

| Method | Path | Body / response |
| --- | --- | --- |
| POST | `/v1/auth/register` | `{email, password}` → `{user, access_token, refresh_token, expires_in}` |
| POST | `/v1/auth/login` | the same |
| POST | `/v1/auth/refresh` | `{refresh_token}` → a new pair (the old refresh is retired) |
| POST | `/v1/auth/logout` | `{refresh_token}` → 204 |
| GET | `/v1/me` | → `{id, email, created_at}` |

The requirements:

- passwords use argon2id (or bcrypt with cost ≥ 12), at least 8 characters;
- the access token lasts 15 minutes, the refresh 60 days, **rotated on every
  refresh**; if an already retired refresh arrives, the whole `family_id` chain
  is revoked (a sign of theft);
- a rate limit on `/auth/*`: say 10 attempts a minute per IP and per email;
- the same answer for "no such email" and "wrong password" — we do not hint at
  which addresses are registered;
- one error format across the whole API:
  `{"error": {"code": "invalid_credentials", "message": "..."}}`, with an HTTP
  code that fits the meaning.

On the client: the refresh token goes into `flutter_secure_storage` only (not
`SharedPreferences`), and the access token stays in memory. An interceptor on
401: a single concurrent refresh request, with the rest waiting for it and being
retried.

---

## 4. The lessons API

The JSON shape deliberately matches the current `LessonModel` / `SegmentModel`
(`snake_case`, times in ISO-8601 UTC, everything in milliseconds), plus the
server fields.

```json
{
  "id": "9f1c…",
  "title": "TED: How to learn",
  "duration_ms": 183400,
  "created_at": "2026-07-28T10:00:00.000Z",
  "updated_at": "2026-07-28T10:12:03.000Z",
  "version": 3,
  "audio": {
    "id": "b21e…",
    "url": "https://api.shado.app/v1/audio/b21e…/file",
    "content_type": "audio/mpeg",
    "size_bytes": 2938471,
    "sha256": "3f2a…",
    "duration_ms": 183400
  },
  "segments": [
    { "index": 0, "text": "Hello there.", "start_ms": 0, "end_ms": 2100 },
    { "index": 1, "text": "How are you?", "start_ms": 2100, "end_ms": 4300 }
  ]
}
```

| Method | Path | Meaning |
| --- | --- | --- |
| GET | `/v1/lessons?since=<iso>&limit=&cursor=` | the list, `updated_at desc`; with `since` it is a delta, including the deleted ones (`deleted_at`) |
| GET | `/v1/lessons/{id}` | one lesson, returns `ETag: "<version>"` |
| PUT | `/v1/lessons/{id}` | create **or** update: `{title, audio_id, created_at, segments}`; on an update `If-Match: "<version>"` |
| DELETE | `/v1/lessons/{id}` | a soft delete, 204 |

Why `PUT` and not `POST`: the lesson UUID is generated by the client (`_uuid.v4()`
in `LessonRepositoryImpl`), so creation is idempotent — a repeat after a lost
connection creates no duplicate. The same method serves lesson edits too: the
segments arrive in full, because they are an aggregate (this is exactly how
`LessonLocalDataSource.upsertLesson` and the `UpdateLessonContent` use case
work).

A version conflict gives a `409` with the current state of the lesson in the
body. For a single-user app this is rare (two devices editing one lesson), but
the rule is cheap, and without it edits are lost silently.

---

## 5. Audio: upload, peaks, delivery

This is where the server helps most, and the order of the steps matters — it has
to match how the lesson creation screen already works.

### The upload happens BEFORE the lesson is created

The "Add" screen works like this today: pick a file → find out the duration →
draw the waveform with markers → and only then "Create lesson". So the server
must be able to accept a file on its own and return everything needed for
drawing right away:

```http
POST /v1/audio            multipart: file
→ 201 { id, content_type, size_bytes, sha256, duration_ms,
        url, peaks: { resolution: 2000, minima: "<base64 int8>", maxima: "…" } }
```

If the user already has a file with that `sha256`, it is a `200` with the same
record, without a repeated upload and processing.

What the server does on an upload:

1. checks the type (`mp3, m4a, wav, flac, ogg`) and the size (say ≤ 50 MB);
2. computes `duration_ms` — **this takes the local measurement off the client**
   (`AudioFileDataSource.resolveDurationMs` through `just_audio`/libmpv);
3. builds the envelope (ffmpeg/ffprobe) at a high resolution and stores it in
   `audio_files.peaks`;
4. optionally normalizes the format: re-encodes to mp3 at 44.1 kHz. **This cures
   an existing limitation**: on Windows/Linux the `flutter_soloud` decoder does
   not read m4a/aac, so a lesson uploaded from an iPhone currently ends up
   without a waveform.

### The peaks come from the server

```http
GET /v1/audio/{id}/peaks?resolution=2000
→ { resolution, minima: "<base64>", maxima: "<base64>" }
```

`int8` in base64: 2000 points are 4 KB instead of ~30 KB of JSON numbers. The
values are normalized the same way as on the client today (`maxima` 0..1,
`minima` -1..0, with the peak pinned to one).

This pays off three times over: opening a lesson no longer waits seconds for
decoding, the desktop no longer needs `flutter_soloud`, and the waveform looks
**the same on every platform** — today mobile draws real min/max while the
desktop draws an RMS envelope.

In the app this is exactly one new implementation of the existing
`WaveformDataSource` interface (`RemoteWaveformDataSource`), with the local ones
staying as the fallback path for offline use.

### Serving the file for playback

```http
GET /v1/audio/{id}/file      Authorization: Bearer <access>
→ 200, Accept-Ranges: bytes, ETag, Cache-Control: private, immutable
```

`Range` support is mandatory — without it a dropped download cannot be resumed.

**There is no need to play over the network directly.** In shadowing, fragments
are looped every 2–3 seconds, and a `ClippingAudioSource` on top of a network
source would stutter on every repeat. The right path: on the first opening of a
lesson the file is downloaded once into the app cache (where the audio already
lives), and the player works with `AudioSource.file` as it does today. Integrity
is checked by the `sha256` from the response.

If the storage is S3-compatible, hand out a presigned link for 10–15 minutes
instead of proxying: `GET /v1/audio/{id}/url → {url, expires_at}`.

---

## 6. What changes in the app

The domain and presentation do not change at all — on one condition: **the
repository keeps returning `Lesson.audioPath` as a local path to a file that is
ready to play**, only now it downloads that file when needed. Then the player,
the waveform and every screen stay as they are.

| Layer | What is added |
| --- | --- |
| `data/datasources` | `LessonRemoteDataSource` (lessons), `AudioRemoteDataSource` (upload/download), `RemoteWaveformDataSource` (peaks) |
| `data/models` | separate DTOs for the API (`LessonDto`, `AudioDto`). `LessonModel` stays for sqflite: locally we store the cache path, on the server it is `audio_id`, and mixing them in one model is a bad idea |
| `data/repositories` | `LessonRepositoryImpl`: the server is the source of truth, sqflite is the cache; audio is downloaded in `getLesson` |
| `features/auth` (a new feature) | `domain`: `AuthRepository`, the `login`/`register`/`logout`/`currentUser` use cases; `data`: the API client plus `flutter_secure_storage`; `presentation`: the sign-in and registration screens |
| `core/network` | an http client (`dio`) with interceptors: `Authorization`, a refresh on 401, retries on network failures |
| `core/router` | a `redirect` by the authorization state: without a token, to `/login` |
| Dependencies | `dio`, `flutter_secure_storage`; the local duration measurement and `flutter_soloud` can be dropped later, once the server becomes mandatory |

The order of creating a lesson on the client after the move:

1. pick a file → `POST /v1/audio` (with progress) → get `duration_ms` and the
   peaks;
2. draw the waveform and place the markers — as today, only the data is not our
   own;
3. "Create lesson" → `PUT /v1/lessons/{uuid}` with the `audio_id` and the
   segments;
4. write the lesson into the local cache; the audio is already there from step 1.

---

## 7. Synchronization: what to do now and what later

A simple scheme is enough for now, and it is worth writing it down explicitly so
as not to slide into full offline-first ahead of time:

- **the server is the source of truth**, and the local sqflite becomes a
  read cache;
- on start and on pull-to-refresh —
  `GET /v1/lessons?since=<the last updated_at>`, apply the delta and drop the
  deleted ones (`deleted_at`);
- writes (create, edit, delete) go to the server and, on success, into the
  cache; with no connection there is an honest error in the UI, as there is
  today on a database failure;
- audio is cached by `audio_id`, and the cache is cleaned by LRU and by deleted
  lessons.

A full offline queue (`pending_operations`, conflict resolution, deferred
uploads) is a separate stage, and it is only needed if editing lessons without a
connection is genuinely required. The seams for it — `version`/`If-Match` and
the soft delete — are already in the contract.

---

## 8. Non-functional requirements

- HTTPS and HSTS only; no access to files without a token or a presigned link;
- limits: the request size, the file size, a per-user quota (say 2 GB), a rate
  limit on the API;
- `deleted_at` is cleaned by a background job after N days together with the
  orphaned audio (carefully: a file may be shared by several lessons through
  `sha256`);
- schema migrations under control (no hand-written `create table if not exists`);
- `GET /healthz`, structured logs with a request id, metrics on upload
  processing time;
- backups of Postgres and of the storage, with restore drills;
- account deletion: erase everything, including the files (the stores require
  this too).

---

## 9. Order of work

Every stage leaves the app in a working state.

1. **Infrastructure.** Choose the stack (§1), the domain name, TLS, Postgres,
   the storage, migrations, `/healthz`, deployment.
2. **Authorization.** The `/v1/auth/*` and `/v1/me` endpoints; on the client,
   the `auth` feature, secure token storage, the interceptors, the sign-in
   screen and the router `redirect`. Lessons are still local at this step.
3. **Audio.** `POST /v1/audio` with the duration and the peaks, and serving the
   file with `Range`. On the client, `RemoteWaveformDataSource` and uploading on
   the creation screen. This is also where waveform behavior is aligned across
   platforms.
4. **Lessons.** `GET/PUT/DELETE /v1/lessons`, `LessonRemoteDataSource`,
   assembling the "server plus cache" repository, downloading audio when a
   lesson is opened.
5. **Delta synchronization** by `since` and cache cleanup.
6. **Later, if needed:** an offline write queue, lesson sharing, sign-in through
   Apple/Google (mandatory for iOS if social sign-in appears).

Testing: keep `LessonRemoteDataSource` and `AuthRepository` behind interfaces,
as the local sources are today — then the repository and the controllers are
tested on fakes without a network. For the server, contract tests on every
endpoint and checks of the invariants from §2.

---

## 10. What we deliberately do NOT do

- we do not move speech recognition and automatic segmentation to the server —
  the principle of the app does not change, the markup is manual;
- we do not stream audio from the server (see §5);
- we do not introduce a separate segments table and per-segment endpoints: they
  are an aggregate of the lesson;
- we do not build offline writing in the first version.
