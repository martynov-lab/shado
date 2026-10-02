# Shado

An app for learning English with the **shadowing** technique: you upload audio
and text, manually mark chunk boundaries on the waveform, then play and loop
each chunk, repeating after the speaker.

Lessons and audio live on the server ([shado_server](../shado_server), the
contract is in [docs/CLIENT_SPEC.md](docs/CLIENT_SPEC.md)); a local cache stays
on the device: the lesson list in sqflite and the downloaded audio files. There
is still no speech recognition — all markup is manual.

## Running

```bash
flutter pub get
dart run build_runner build --force-jit   # freezed + json_serializable
flutter run
```

The default server is production, `https://shado-martin.duckdns.org`: a release
built without flags works out of the box. A local `shado_server` is set with a
flag:

```bash
flutter run --dart-define=SHADO_API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` is the host machine as seen from inside the Android emulator;
`127.0.0.1` there points to the emulator itself. On the iOS simulator and the
desktop use `127.0.0.1`, on a real phone — the machine's LAN address (see
[docs/RUNNING.md](docs/RUNNING.md), §5).

Target platforms are Android, iOS and Windows/Linux.

### What the server does and what the client does

| Task | Where it is computed |
| --- | --- |
| Audio duration | server, on `POST /v1/audio` |
| Waveform peaks | server, `GET /v1/audio/{id}/peaks` |
| Chunk markup, trimming, looping | client |
| Playback | client, from the downloaded file |

Audio plays from a local copy, not over the network: in shadowing, chunks of two
or three seconds are looped, and every repeat over a network source would
stutter. The file is downloaded into the cache once by `audio_id`, verified by
`sha256` and never changes — the content under one `audio_id` is immutable.

### How the desktop differs

`just_audio` and `sqflite` have no native implementations for Windows and
Linux, so replacements are plugged in there (see
`lib/core/platform/platform_setup.dart`, called from `main` before `runApp`):

| Task | Android / iOS | Windows / Linux |
| --- | --- | --- |
| Playback | `just_audio` | `just_audio_media_kit` (libmpv) |
| Database | `sqflite` | `sqflite_common_ffi` |
| Offline waveform peaks | `just_waveform` | `flutter_soloud` (miniaudio) |

The waveform is now the same on all platforms — the server builds it. The local
builders remain as a fallback for when the server is unreachable but the file is
already downloaded; with `flutter_soloud` it handles only `mp3, wav, flac, ogg`
and draws an RMS envelope symmetric around the center.

## Session

- sign-in and registration use email and password (at least 8 characters);
- the refresh token is kept in the platform's secure storage and survives a
  restart: the app signs in by itself, the user never sees the sign-in screen;
- the access token lives 15 minutes and is refreshed silently; several parallel
  requests share one refresh;
- if the server rejects the refresh, the session is closed entirely: tokens, the
  lesson cache and downloaded audio are cleared;
- the owner (whose email is set on the server) gets a "Users" section in the
  account menu for changing roles.

## How to use

1. The **"Add"** tab: a title, text with chunks separated by `|`, an audio pick
   button. Accepted formats are `mp3, m4a, aac, wav, flac, ogg` up to 50 MB.
2. The chosen file is uploaded to the server right away — with progress and a
   "Cancel" button. The server responds with the duration and peaks, and a
   waveform with boundary markers appears under the form: chunks are laid out
   evenly, markers can be moved immediately, even before the lesson is created.
   Editing the text fits the markup to the new chunk count — markers already
   placed from the start are kept. The same file uploaded again is recognized by
   the server by its checksum and not processed a second time.
3. "Create lesson": the lesson goes to the server in one request, the audio is
   already in the local cache — no need to download it back.
4. The lesson screen: a "Slow / Normal" switch (0.75× / 1.0×) and a list of
   chunks with "play / stop" and "repeat" buttons. There is no waveform here —
   the lesson is already cut, the screen is only for practice.
5. The ✏️ button in the lesson header opens editing: the title, splitting the
   text into chunks and the boundaries on the waveform. For `N` chunks there is
   one marker per inner joint — `N - 1` of them. After saving, the lesson is
   re-read and the player is reset.

### Several chunks at once

A checkbox on a tile selects a chunk, and a panel appears at the bottom: how many
are selected, how long they sound, "play / stop" and "repeat". The selected
chunks play in a row and loop as a whole.

Only adjacent chunks can be selected (or all at once with the header button) —
otherwise it is unclear what "play the selection" means. A nice consequence:
adjacent chunks are contiguous, so any selection is one continuous piece of
audio that the player plays and loops like a regular chunk. The selection rules
live in `SegmentRange.toggled`: a neighbor extends the selection, an edge chunk
removes itself, a chunk from the middle or far away starts a new selection.

### Keyboard on the lesson screen

| Keys | What they do |
| --- | --- |
| ↑ / ↓ | move between chunks; the list scrolls to the current one |
| Shift + ↑ / ↓ | add adjacent chunks starting from the one you began with |
| Space | plays or stops — the selection, or the framed chunk if nothing is selected |
| Ctrl + A | select all chunks |
| Esc | clear the selection |

The keyboard chunk has a frame, the selected ones are filled with color: these
are different things and can be on one tile at the same time.

### Waveform

The waveform lives on the create and edit screens (`WaveformCard` →
`WaveformEditor`) and can be zoomed so a marker can be placed more precisely. A
gesture never means two things at once: markers are grabbed only by their
handles, everything else moves the waveform itself.

| Action | Mouse / trackpad | Touch |
| --- | --- | --- |
| Move a boundary marker | drag the circle on top | drag the circle on top |
| Move the playhead | drag the triangle below, or click the waveform | drag the triangle below, or tap |
| Move the waveform | drag with the left button away from handles, wheel | drag with one finger away from handles |
| Zoom | `Ctrl` + wheel, trackpad pinch | two-finger pinch |
| Play / pause | ▶ button or space | ▶ button |

There are no zoom buttons: the current zoom is shown in the bottom-right corner
while it is above one, and the visible window is shown by a bar at the bottom.
A marker dragged to the window edge pulls the waveform along. A time scale with
round steps runs along the top, a dragged marker shows its exact time, and
chunks show their numbers.

The playback playhead appears only where `onSeek` is set — currently the edit
screen. The ▶ button plays the whole file from the playhead, a second press
pauses and leaves the playhead where the audio stopped: this lets you hear
whether a marker falls into the pause between phrases. On the keyboard the
**space** bar does the same — but only when the screen itself has focus: in a
text field space stays a space, and touching the waveform takes the focus so
space works again.

## Architecture

Clean architecture, feature-first; dependencies point inward:
`presentation → domain ← data`.

```text
lib/
  core/            constants, theme, router, failure types, formatting
  features/lessons/
    domain/        entities, repositories (interface), usecases
    data/          models (freezed + json), datasources, repositories
    presentation/  pages (Elementary: page, widget model, model), widgets
```

The domain knows nothing about Flutter, the database or the network. Everything
is hidden behind interfaces: the lesson cache behind `LessonLocalDataSource`,
the server behind `LessonRemoteDataSource` and `AudioRemoteDataSource`, audio
files behind `AudioCache`, peaks behind `WaveformDataSource`. So the repository
and screen models are tested on fakes, without a network.

```text
lib/
  core/
    config/          base URL and limits
    network/         ApiClient, ApiException, AuthInterceptor
    storage/         TokenStorage on top of flutter_secure_storage
  di/                Riverpod providers: services, repositories, use cases
  features/auth/     sign-in, registration, session
  features/admin/    users and roles (owner only)
  features/lessons/  domain / data / presentation
```

What happens where:

- **the server is the source of truth**, sqflite is a read cache. On start and
  on pull-to-refresh the app sends `GET /v1/lessons?since=<last updated_at>`;
  the "watermark" is taken from the received records, not from the device
  clock.
- **creating a lesson is one `PUT`** by a client-generated UUID: a retry after a
  dropped connection does not create a duplicate.
- **editing goes with `If-Match`**. If the lesson was changed on another device,
  the server responds with a version conflict, the latest version goes into the
  cache, and the user sees a message — silently overwriting someone else's edit
  is not allowed.
- **deletion is soft**: the lesson is marked deleted and disappears on other
  devices after sync. Audio is removed from the cache only when no live lesson
  references it: the server deduplicates uploads by `sha256`, and one `audio_id`
  can belong to several lessons at once.

### Trimming and the server

The server requires the chunks to cover the whole audio (`0..duration_ms`), so
trimming remains a client-side markup tool: it helps place markers precisely in
the middle of the file, but the saved lesson gets the whole audio — the cut-off
edges go to the outer chunks.

## Tests

```bash
flutter test                              # 110 tests, no network needed
flutter test test/live/live_contract.dart # contract against a live server
```

The domain logic is covered: even splitting, boundary recalculation, parsing the
text by the delimiter, boundary normalization, fitting the markup to a changed
chunk count and the contiguous selection rules (`SegmentRange`). Widget tests
on `WaveformEditor` check gesture separation (by the handle — a marker, away
from handles — the waveform), fixed outer boundaries, pinch and `Ctrl` + wheel
zoom, and the playback playhead.

The network layer: parsing every error code from the spec, retrying only
idempotent requests, injecting `Authorization`, one token refresh for several
parallel `401`s, a full sign-out on a `401` from the refresh itself. Then the
repository (stretching boundaries to the whole file, `If-Match`, version
conflict, delta with deleted records, cache cleanup) and routing by session
state.

`test/live/live_contract.dart` walks the same path against the real server:
registration, audio upload with deduplication, peaks, file download, creating
and editing a lesson, version conflict, soft deletion, `403` in the admin area,
refresh token rotation, a file size rejection and upload cancellation. The name
lacks the `_test` suffix on purpose, so a regular `flutter test` does not pick
it up.

The desktop infrastructure (peaks via miniaudio, chunk playback, writing a
lesson to sqlite) is checked by an integration test on a generated wav — it
requires a running platform:

```bash
flutter test integration_test/desktop_pipeline_test.dart -d windows
```
