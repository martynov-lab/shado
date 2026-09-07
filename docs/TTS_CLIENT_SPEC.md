# AI voice-over (Gemini TTS): what to do on the client

An addendum to `CLIENT_SPEC.md`. The general API rules (base URL, snake_case
JSON, the `Authorization` header, the error format) come from there; only what
is new is described here.

## 1. The idea and its place in the UI

On the lesson creation screen, next to the audio upload, a **«Озвучить через
ИИ»** button appears. The user types the text, taps the button, and the server
synthesizes speech through Gemini TTS and returns the result **in exactly the
same shape as the `POST /v1/audio` upload** (a file link plus the waveform).
From there the client treats it as an ordinary audio track: the same cache, the
same player, the same lesson creation with an `audio_id`.

- The button is visible to **lesson authors** only (`user-pro`, `admin`,
  `owner`) — the same place where uploading is available. A plain `user` does
  not get it, and the server would answer them with a `403`.
- For the client, uploading a file and voicing text are two doors into the same
  result. The only difference in the response is the `cached` field (see §3).

## 2. The request

```http
POST /v1/tts/synthesize
Authorization: Bearer <access>
Content-Type: application/json

{ "text": "Nice to meet you. Let's get started." }
```

- `text` is required. The model, the voice and the reading style are set by the
  **server**; the client does not pass them.
- Text limits: non-empty, **≤ 2000 characters** and ≤ ~3800 UTF-8 bytes. A
  violation gives a `422 validation_error` before the provider is called at all
  (no quota is spent). Check the length before sending.

## 3. The response

`200 OK`. The body is the one from `POST /v1/audio`, plus `cached`:

```json
{
  "id": "b21e…",
  "url": "http://127.0.0.1:8080/v1/audio/b21e…/file",
  "content_type": "audio/wav",
  "size_bytes": 204844,
  "sha256": "3f2a…",
  "duration_ms": 4200,
  "peaks": { "resolution": 2000, "minima": "<base64 int8>", "maxima": "<base64 int8>" },
  "cached": false
}
```

- The audio format is `audio/wav` (PCM 24 kHz, 16 bit, mono): that is exactly
  how the model returns the sound, and the server does not re-encode it so as
  not to lose quality. The files are accordingly larger than mp3 (~48 KB per
  second) — keep that in mind when caching on the device. `duration_ms` is
  computed by the server and `peaks` are decoded the same way as in
  `CLIENT_SPEC.md §5.2`.
- **The file is served by the same endpoint** `GET /v1/audio/{id}/file` (with
  `Authorization`, `Range`, `ETag`, immutable) — see `CLIENT_SPEC.md §5.3`.
  There is no separate path for a TTS file.
- Treat the result as an upload: put the file into the cache under the
  `audio_id` key right away, and then pass that `audio_id` in the lesson body
  (`CLIENT_SPEC.md §6`).
- `cached` means the synthesis came from the server cache (this phrase has been
  voiced before). It does not affect client behavior; you may optionally show
  "from cache". The point of the field is that such a repeat does **not** spend
  the free limit.
- AI audio is impersonal and shared: the same text returns the same `audio_id`
  to different authors. The file is immutable, so no invalidation is needed.

## 4. Errors

The format is the common one (`CLIENT_SPEC.md §1`). The specific codes:

| code | HTTP | When | What the client does |
| --- | --- | --- | --- |
| `validation_error` | 422 | empty text or text over the limit | show `message`, do not retry |
| `forbidden` | 403 | the `user` role without author rights | hide the button, do not retry |
| `unauthorized` | 401 | a missing or expired token | the usual refresh/sign-out path (§3 CLIENT_SPEC) |
| `tts_quota_exceeded` | 429 | the free voice-over limit is used up (per minute or per day) | show `message`, **do not retry**; offer to upload audio by hand |
| `tts_unavailable` | 503 | the AI service is temporarily down or not configured | show "try later" plus a retry |

`tts_quota_exceeded` is not an input error: the text is fine, but the free limit
is spent. There are two limits — per minute and per day — so the refusal may be
temporary ("wait a minute") or last the day. Do not lock the button forever, but
do not hammer it with automatic retries either — offer uploading your own file
as the fallback path.

## 4.1 The remaining limit

```http
GET /v1/tts/quota
Authorization: Bearer <access>
```

```json
{
  "provider": "gemini",
  "day":    { "used": 3, "limit": 14, "remaining": 11 },
  "minute": { "used": 0, "limit": 2,  "remaining": 2 },
  "month_chars": { "used": 812, "limit": 0 }
}
```

The rights are the same as for synthesis (lesson authors). A `limit: 0` means
"no cap" — and then the `remaining` field does not arrive at all. It is worth
showing `day.remaining` next to the button: there are not many free voice-overs
a day, and seeing the balance in advance is nicer than running into a refusal.
Voicing an already voiced phrase comes from the cache and spends **no** limit.

## 5. UX

- Synthesis is a network call of a few seconds (a live model answers slower than
  the previous voices): show a progress indicator and allow **cancellation**
  (`CancelToken`), as with an upload.
- One text, one call. Do not send a request on every typed character; synthesize
  on an explicit button tap.
- After success the flow is the same as after an upload: the waveform is drawn
  from `peaks`, the file is already cached, and segments can be marked up and
  the lesson created.

## 6. What is NOT included

- **The server does not return segment timings.** `/v1/tts/synthesize` returns
  one audio file and its total duration, but no word or phrase alignment in
  time. Segment markup stays on the client (as it does for uploaded audio).
- The voice, language and speed are not driven from the client — that is a
  server setting.

## 7. Acceptance checklist

- [ ] The «Озвучить через ИИ» button is visible to authors and hidden from `user`.
- [ ] Empty or overlong text is caught on the client before sending.
- [ ] A successful response is handled identically to `POST /v1/audio`: cached by
      `audio_id`, the waveform from `peaks`, then lesson creation.
- [ ] The file plays through `GET /v1/audio/{id}/file` (downloaded into the cache
      once).
- [ ] `tts_quota_exceeded` (429) and `tts_unavailable` (503) show a clear message
      and do not go into an automatic retry.
- [ ] The remaining daily voice-overs (`GET /v1/tts/quota`) are visible next to
      the button.
- [ ] A long synthesis can be cancelled.
