# Studied language and voice choice: what is left to do on the client

A work plan for the server-side changes. The contract lives in
[`CLIENT_SPEC.md §6.0`](./CLIENT_SPEC.md) (language, accents, catalog) and
[`TTS_CLIENT_SPEC.md`](./TTS_CLIENT_SPEC.md) (voices, previewing); this document
says what exactly to touch in the app and in what order.

## 1. What changed in the contract

| Before | After |
| --- | --- |
| `studied_language` — a free-form string in the profile | a code from `GET /v1/languages`; an unknown one gives `422` and it cannot be cleared |
| one catalog shared by everyone | the catalog is **single-language**: `/v1/lessons`, `/v1/folders`, `/v1/library` return the profile language when no parameter is given |
| `accent` — `US`/`UK`, hardcoded in the client | accents arrive inside the language; English has three (`US`, `UK`, **`AU`**), the others have none |
| a lesson has no language | `lesson.language`, `folder.language`; `lesson.accent` may be **`null`** |
| the voice-over voice and language are a server setting | `GET /v1/tts/voices`, `voice`/`accent` in the request, `POST /v1/tts/preview` |

No request gains a mandatory field: the server fills the language in from the
profile itself. Only response parsing breaks — see §4.

## 2. Order of work

Every stage leaves the app in a working state.

1. **Response parsing.** `accent` becomes nullable, the value `AU` stops being
   unknown, and `LessonDto`/`FolderDto` gain `language`. It is half an hour of
   work, but without it the app crashes on the very first lesson once the server
   is deployed — do it first and ship it on its own (§4.1).
2. **The directory and the language choice.** `GET /v1/languages`, the
   "Settings" screen: a language dropdown, `PATCH /v1/me { studied_language }`,
   and a reset of the cache and the catalog after a successful answer (§3.4).
3. **The catalog.** Send nothing in the requests — the server returns the right
   language itself; show the accent filter only when the chosen language has a
   non-empty `accents`; key the cursors and the sync watermark on the language.
4. **Lesson creation.** Build the accent picker from the language directory; for
   languages without accents do not show the field and do not send it. Do not
   pass `language` in the body.
5. **Voice-over (owner).** The list of voices with a ▶ button on each, the
   chosen voice in `POST /v1/tts/synthesize`; the voice-over accent picker sits
   next to the voice and only for languages that have accents.

## 3. Layer by layer

### 3.1 `data/models`

```dart
class LanguageDto { String code; String name; String nativeName;
                    bool isDefault; List<AccentDto> accents; }
class AccentDto   { String code; String name; bool isDefault; }
class VoiceDto    { String name; String description; }
```

- `LessonDto`: `+ String language`, `String? accent` (it used to be non-null);
- `FolderDto`: `+ String language`;
- the synthesis and preview responses: `+ voice`, `+ language`, `+ accent`
  (nullable), and the preview also carries `text` — the spoken phrase;
- `LessonModel` (sqflite) gets a `language` column too, see §3.3.

### 3.2 `data/datasources`

- a new `LanguageRemoteDataSource.getLanguages()` — the answer may be kept in
  memory for the session, the directory only changes with a server release;
- `TtsRemoteDataSource`: `getVoices()`, `preview({voice, accent})`, and
  `synthesize` gains optional `voice` and `accent`;
- `LessonRemoteDataSource` and the folders are **left alone**: the `language`
  parameter need not be sent to the server, it takes it from the profile. Pass
  it explicitly only if a "browse another language catalog" screen shows up.

### 3.3 The local cache

- add `language` to the `lessons` and `folders` tables;
- old rows have no language and there is nowhere on the client to derive it
  from — it is **simpler to bump the schema version and drop the cache**: it
  mirrors the server rather than holding user data, and a full reload costs one
  request;
- keep the watermark (the `updated_at` of the last delta) **per language**:
  `last_sync_at_<code>`. A single shared watermark would leave the new catalog
  half-loaded after a language switch.

### 3.4 Switching the language is a scenario of its own

The order matters, otherwise the old catalog lands on top of the new one:

1. `PATCH /v1/me { studied_language }` and **wait for the `200`** (on a `422`
   show the message and keep the previous language);
2. clear the lesson and folder caches, the watermark and the pagination cursors;
3. reset the catalog filters — the server will not accept an accent of the
   previous language (§4.4);
4. reload `/v1/library` from scratch (without `since`) and repaint the screen.

It is worth warning in the UI that "the lesson list will change" — the whole
catalog disappearing after a switch looks like data loss when you do not expect
it.

### 3.5 The voice-over screen (owner)

- the list of voices from `GET /v1/tts/voices` (name plus description), with
  `default_voice` selected by default; `voices: []` means the provider offers no
  choice and the whole block is hidden;
- a ▶ button on each voice → `POST /v1/tts/preview { voice }`: the server
  supplies a phrase in the current language itself. The first tap spends one
  voice-over from the daily basket, repeats do not (the cache), so the button is
  never locked;
- next to it, the balance from `GET /v1/tts/quota` (`day.remaining`): the basket
  is small;
- the voice-over accent picker comes from the `accents` of the current language
  and is hidden for languages without accents;
- the preview sample **must not** go into the lesson audio cache — it is a
  utility phrase.

## 4. Traps

**4.1 Parsing `accent` is the most likely place to break.** If the client has
`enum Accent { us, uk }`, then after the server deploy it will meet `AU` (a new
English accent) and `null` (for French and Turkish) and crash while parsing the
lesson list. Keep the accent as a string and take the labels from the language
directory.

**4.2 A cache from the old version.** Rows without `language` will not be picked
up by a query filtered on language and will hang around as dead weight — drop
the cache when the schema is updated (§3.3).

**4.3 The `since` delta is per language now.** Only the current language arrives
into the cache. A language switch cannot be expressed as a delta — only a full
reload.

**4.4 An accent filter that survived a language switch** gives a `422` on the
very first catalog request: the server checks the accent against the language of
the query. Reset it together with the language.

**4.5 A folder is single-language.** A lesson of another language cannot be put
into it (`422`). In practice this will not come up — the lesson picker only
shows the current language anyway — but show the error in human terms rather
than as "unknown server error".

**4.6 The `recent_lesson_ids` from `/v1/progress`** may point at lessons of
another language (the history survives a switch). Such a lesson opens fine by a
direct link; decide whether to show it under "recent" or filter it out by
`lesson.language`.

**4.7 `language` in a `PUT` body** need not be sent. If you do send it, the
value must match the profile language (and, for an existing lesson, its own
language), otherwise `422`. The language of a created lesson cannot be changed
by an edit.

**4.8 The same text in different voices** returns different audio, but the
**same** text in the same voice comes from the cache (`cached: true`) with the
same `audio_id` — that is not a failure but a saving on the limit.

## 4a. Implementation assumptions

`CLIENT_SPEC.md` and `TTS_CLIENT_SPEC.md` describe the previous contract, so the
response shapes were taken from §3 of this plan. What the client assumes, to be
verified against the server:

| Request | The response the client parses |
| --- | --- |
| `GET /v1/languages` | `{"languages": [{code, name, native_name, is_default, accents: [{code, name, is_default}]}]}`; an `items` key is accepted too |
| `GET /v1/tts/voices` | `{"voices": [{name, description}], "default_voice": "…"}`; an `items` key is accepted too |
| `POST /v1/tts/preview` | `{voice}` (plus `accent` for languages with accents) → an audio object plus `text` and `cached` |
| `POST /v1/tts/synthesize` | `{text}` plus optional `voice` and `accent` |

Other assumptions:

- `lesson.accent` and `folder.language` are strings; an empty string reads as
  "not set";
- the preview `audio_id` is downloaded through the same
  `GET /v1/audio/{id}/file` as lesson audio, but lands in a temporary
  `tts_samples` folder;
- catalog filtering stays on the client: `accent` is not sent in
  `GET /v1/lessons`, so trap §4.4 does not fire.

## 5. Acceptance checklist

The full one is in `CLIENT_SPEC.md` ("Acceptance checklist") and
`TTS_CLIENT_SPEC.md §10`. In short, what to check by hand:

- [ ] the language list in "Settings" came from the server with the current one
      selected;
- [ ] switching to French: the catalog and the feed show French content only,
      the accent filter is gone, the cache was re-read;
- [ ] switching back to English brings the previous catalog back;
- [ ] English shows three accents in the filters and on the creation screen,
      including `AU`;
- [ ] a French lesson is created without an accent field and comes back with
      `accent: null`;
- [ ] the voice list and the ▶ on each one work; replaying a preview is instant
      and spends no quota;
- [ ] the voice-over of a French lesson sounds French without a single language
      field in the request;
- [ ] one text voiced by two different voices sounds different.
