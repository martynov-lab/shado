# Translation in a lesson: specification

The goal is to add two kinds of translation to the lesson screen:

1. **Phrase (fragment) translation.** The user taps the «Перевод» button and the
   translation of the fragment currently on screen appears under the text — and
   that fragment is the **active segment range** (`SegmentRange`), not a single
   segment. Two segments shown means we translate the joined text of both.
2. **Word translation.** The user taps a word inside the fragment and a popup
   comes up next to it: the word translation, part of speech, synonyms,
   transcription (absent — a placeholder), examples in context.

The provider is **Azure Translator** (both the phrase translation and the
dictionary, under a single key). Plan for moving the dictionary to **Yandex
Dictionary** without changing the contract. We stay strictly within the **free
tiers**: going over the limit gives a clear error from our own server, not a
silent failure. Paid subscriptions come with the production launch, as a
separate task.

**Order: the server first, in full, then the client** (§8).

The document follows the style of [CLIENT_SPEC.md](CLIENT_SPEC.md): the same API
rules (§1 there), `Bearer` authorization, `snake_case`, one error format.

---

## 1. Key decisions

Fixed here so that the server and the client do not drift apart.

1. **The contract is provider agnostic.** The client does not know whether it is
   Azure or Yandex. The server returns a unified response and the provider
   mapping stays inside the server.
2. **Two independent providers.** The phrase translation and the dictionary are
   switched by separate settings (`PHRASE_PROVIDER`, `DICTIONARY_PROVIDER`).
   Today both are `azure`; tomorrow the dictionary becomes `yandex` while the
   phrase stays `azure` — neither the contract nor the client changes.
3. **A phrase is translated by text, not by lesson.** The request body carries
   the ready fragment text; the server knows nothing about segments and lessons.
   The cache key is the hash of the normalized text. Simpler, reusable, and not
   tied to the lesson model.
4. **Transcription is nullable.** Azure does not provide it → `transcription:
   null` → the client shows a placeholder. Yandex will later fill the very same
   field, with the same contract.
5. **The default direction is `en → ru`.** The app teaches English to Russian
   speakers. `source_lang`/`target_lang` are optional in the request and default
   to `en`/`ru`. They are there for the future but are not required.
6. **«The word is not in the dictionary» is not an error.** An empty dictionary
   answer is a `200` with `meanings: []`; the client shows "no dictionary entry"
   rather than an error.

---

## 2. API contract

Both paths sit behind `Bearer` authorization, like the whole of `/v1/*`
(§1 CLIENT_SPEC).

### 2.1 Phrase translation

```http
POST /v1/translate/phrase
Authorization: Bearer <access>
Content-Type: application/json

{
  "text": "Hello there. How are you?",
  "source_lang": "en",   // optional, defaults to "en"
  "target_lang": "ru"    // optional, defaults to "ru"
}
```

A `200` response:

```json
{
  "text": "Hello there. How are you?",
  "translation": "Здравствуйте. Как поживаете?",
  "source_lang": "en",
  "target_lang": "ru",
  "provider": "azure"
}
```

- `text` — no longer than **2000 characters** (several segments are well under
  that); more gives a `validation_error` (422). This caps the quota spent on an
  accidentally huge input.
- `provider` — informational (diagnostics, analytics). The client does not
  depend on it.

### 2.2 Word translation (dictionary)

```http
POST /v1/dictionary/lookup
Authorization: Bearer <access>
Content-Type: application/json

{
  "word": "learn",
  "source_lang": "en",   // optional, defaults to "en"
  "target_lang": "ru"    // optional, defaults to "ru"
}
```

A `200` response:

```json
{
  "word": "learn",
  "source_lang": "en",
  "target_lang": "ru",
  "provider": "azure",
  "transcription": null,
  "meanings": [
    {
      "part_of_speech": "verb",
      "translations": [
        { "text": "учиться",  "synonyms": ["study", "master"], "confidence": 0.45 },
        { "text": "узнавать", "synonyms": [],                  "confidence": 0.18 }
      ]
    }
  ],
  "examples": [
    { "source": "I want to learn English.", "target": "Я хочу учить английский." }
  ]
}
```

- `word` — a single word, no longer than **100 characters**; more gives a
  `validation_error`.
- `transcription` — the phonetic spelling of the word or `null` (Azure always
  gives `null`).
- `meanings` — grouped **by part of speech** (`part_of_speech`): that shape fits
  both Azure (we group its flat list by `posTag`) and Yandex (which has
  `def[].pos`). An empty array means the word is not in the dictionary.
- `translations[].synonyms` — closely related words. For Azure these are
  `backTranslations` (back translations, which read as "synonyms/related"), for
  Yandex it is `syn`.
- `examples` — examples for the top translation; an empty array when there are
  none.

This shape (`meanings → part_of_speech → translations → synonyms`, `examples`)
is defined by **us**, not by Azure. Both providers map into it (§4.2, §4.5).

### 2.3 New error codes

The format is the common one (§1 CLIENT_SPEC): `{ "error": { "code", "message" } }`.
The message is already fit to show to the user (in Russian).

| code | HTTP | When | What the client does |
| --- | --- | --- | --- |
| `translation_quota_exceeded` | 429 | the free monthly provider limit is used up | show `message` («Бесплатный лимит переводов на этот месяц исчерпан, попробуйте позже»); do not hammer with retries |
| `translation_unavailable` | 503 | the provider is down or returned a failure | show `message`, offer a retry |
| `unsupported_language` | 422 | the language pair is not supported (relevant for the dictionary) | show `message`, hide translation for this pair |
| `validation_error` | 422 | empty input or a length overrun | show `message` |

A note for the client: even without a new value in `ApiErrorCode` these errors
show correctly — `ApiClient.mapError` takes `message` from the body and an
unknown code becomes `unknown`. For typed handling, though,
`translation_quota_exceeded` is worth adding to the enum (§7).

---

## 3. Free limits and how they are controlled (server)

The Azure Translator **F0** tier gives roughly **2,000,000 characters a month**
in total across all operations (translate + dictionary lookup + examples). Our
job is to **stay under the ceiling and never get billed**, and to return a clear
error as we approach it.

1. **A character counter for the calendar month** (UTC), persisted in the
   database: every successful provider call adds the number of characters sent
   (`examples` counts too — it is a separately billed call).
2. **A threshold from the configuration** (`TRANSLATION_MONTHLY_CHAR_LIMIT`,
   defaulting with a margin — say `1_900_000`, ~95 % of the limit). Once the
   threshold is reached, new requests get `translation_quota_exceeded` (429)
   **before Azure is called**.
3. **The provider itself returned 403/429** (an overrun on the Azure side) — we
   catch it and map it to the same `translation_quota_exceeded`, so the behavior
   is uniform.
4. The counter resets on the first day of the month (or by the period field in
   the table).

The cache (§5) cuts the spend sharply: translating the same phrase or word again
costs no characters.

---

## 4. Server: implementation

### 4.1 The provider abstraction

Two independent interfaces (traits), so that the dictionary can be switched
apart from the phrase:

```
PhraseTranslator:
  translate(text, source_lang, target_lang) -> PhraseTranslation

DictionaryProvider:
  lookup(word, source_lang, target_lang) -> WordDefinition   // unified
```

- `AzureTranslator` implements `PhraseTranslator`.
- `AzureDictionary` implements `DictionaryProvider`.
- Later `YandexDictionary` implements `DictionaryProvider` — and that is all,
  there is a single point of choice (a factory keyed by `DICTIONARY_PROVIDER`).
- Both return **unified** structures (`WordDefinition` and friends);
  provider-specific JSON never leaves the provider layer.

### 4.2 Azure: endpoints and mapping

The base is `https://api.cognitive.microsofttranslator.com`. Headers on every
request: `Ocp-Apim-Subscription-Key: <key>`, `Ocp-Apim-Subscription-Region:
<region>`, `Content-Type: application/json`. The key and the region live in the
server config only and never reach the client.

**Phrase translation** — `POST /translate?api-version=3.0&from=en&to=ru`, body
`[{ "Text": "…" }]`, response `[{ "translations": [{ "text": "…", "to": "ru" }] }]`.
We take `translations[0].text`.

**Dictionary** — `POST /dictionary/lookup?api-version=3.0&from=en&to=ru`, body
`[{ "Text": "learn" }]`. The response (abridged):

```json
[{ "translations": [
   { "normalizedTarget": "учиться", "posTag": "VERB", "confidence": 0.45,
     "backTranslations": [{ "normalizedText": "study" }, { "normalizedText": "master" }] }
]}]
```

Mapping Azure → unified `WordDefinition`:
- group `translations` by `posTag` → `meanings[].part_of_speech`
  (`VERB→verb`, `NOUN→noun`, … lowercased);
- `normalizedTarget → translations[].text`, `confidence → confidence`;
- `backTranslations[].normalizedText → translations[].synonyms`;
- `transcription = null`.

**Examples** — `POST /dictionary/examples?api-version=3.0&from=en&to=ru`, body
`[{ "Text": "learn", "Translation": "учиться" }]` (the translation comes from
the top lookup result). The response carries `examples[]` with
`sourcePrefix/sourceTerm/sourceSuffix` and the matching `target*`; we glue them
into `source`/`target` sentences.

Examples are a **separate Azure call** (it spends characters). Make it right
after the lookup for the top translation and put the result into `examples`. If
saving quota matters, move it behind a flag (see the open questions, §9), but by
default we return the examples: the popup needs them.

### 4.3 Cache

Two tables (or one with a `kind` field). We cache the **already unified**
response.

| What | Key | Value |
| --- | --- | --- |
| Phrase | `sha256(source_lang \| target_lang \| provider \| normalized_text)` | `translation` |
| Word | `(normalized_word, source_lang, target_lang, provider)` | `WordDefinition` (JSON) |

- **Phrase normalization:** `trim`, collapse repeated spaces; **case is
  preserved** (proper nouns translate differently).
- **Word normalization:** `trim` + `lowercase` (the dictionary is case
  insensitive).
- `provider` sits in the key so that moving the dictionary to Yandex does not
  serve stale Azure entries; it also lets the cache be recomputed simply by
  changing the value.
- A cache hit does **not** touch Azure and does **not** advance the character
  counter.

### 4.4 Errors

- Empty or overlong input — `validation_error` (422) with the reason in the text.
- A language pair the dictionary does not support — `unsupported_language` (422).
- The monthly threshold is reached — `translation_quota_exceeded` (429),
  **before** calling Azure.
- Azure returned 403/429 — also `translation_quota_exceeded` (429).
- Any other Azure failure or timeout — `translation_unavailable` (503).
- An empty dictionary answer is **not an error**: `200` with `meanings: []`.

### 4.5 Configuration (env)

| Variable | Meaning |
| --- | --- |
| `PHRASE_PROVIDER` | `azure` (the only one so far) |
| `DICTIONARY_PROVIDER` | `azure` now, `yandex` later |
| `AZURE_TRANSLATOR_KEY` | the Azure subscription key |
| `AZURE_TRANSLATOR_REGION` | the subscription region |
| `TRANSLATION_MONTHLY_CHAR_LIMIT` | the monthly character threshold (defaults to `1_900_000`) |

Placeholders for Yandex (`YANDEX_DICTIONARY_KEY`) are added at the moment of the
move, not now.

### 4.6 Server tests

- mapping Azure `lookup`/`examples` → unified (grouping by part of speech,
  `backTranslations → synonyms`, `transcription == null`);
- a cache hit: a second identical request does **not** call the provider and
  does **not** move the counter (the provider is a fake with a call counter);
- the limit: with the counter at the threshold →
  `translation_quota_exceeded` **before** the provider is called;
- Azure 429/403 → `translation_quota_exceeded`; a timeout →
  `translation_unavailable`;
- an empty lookup → `200`, `meanings: []`;
- a length overrun or empty input → `validation_error`.

---

## 5. Client (Flutter): implementation — stage 2

Start once the server is ready. Clean architecture, feature-first: a new
`features/translation` feature (reusable and provider agnostic), shown on the
lesson screen.

### 5.1 Domain (`features/translation/domain`)

- `entities/phrase_translation.dart` — `{ text, translation }`.
- `entities/word_definition.dart` — `{ word, transcription?, meanings, examples }`.
- `entities/word_meaning.dart` — `{ partOfSpeech, translations }`.
- `entities/word_translation.dart` — `{ text, synonyms }`.
- `entities/translation_example.dart` — `{ source, target }`.
- `repositories/translation_repository.dart`:
  `translatePhrase(text)` / `lookupWord(word)`.
- `usecases/translate_phrase.dart`, `usecases/lookup_word.dart`.

### 5.2 Data (`features/translation/data`)

- `models/…_dto.dart` — DTOs for the §2.1/§2.2 responses (freezed +
  json_serializable, `snake_case`). `transcription` is nullable.
- `datasources/translation_remote_datasource.dart` — behind an interface, on top
  of `ApiClient` (`post('/v1/translate/phrase', …)`,
  `post('/v1/dictionary/lookup', …)`).
- `repositories/translation_repository_impl.dart` — an **in-memory cache** keyed
  by text or word: in shadowing one fragment is opened and looped many times, so
  hitting the network on every showing is unacceptable. The server cache (§4.3)
  duplicates this, but the client one removes the network round trip inside the
  lesson.

### 5.3 Presentation

Providers (`features/translation/presentation/controllers`):
- DI for the use cases and the repository (following `lesson_providers.dart`).
- `phraseTranslationProvider(String text)` — a `FutureProvider.family` keyed by
  the fragment text.
- `wordLookupProvider(String word)` — a `FutureProvider.family` keyed by the word.

The lesson screen (`features/lessons/presentation`):
- Add to `LessonState` what exactly is on screen right now:
  `displayedRange = activeRange ?? selection ?? SegmentRange.single(currentIndex)`
  and `displayedText` — the segment texts of the range joined by a space. This is
  where "two segments shown → two segments translated" comes from.
- `LessonTranscriptPanel` (a stub today) — replace it: the «Перевод» button
  becomes a toggle; when it is on, we show
  `phraseTranslationProvider(state.displayedText)` under the text
  (loading/error/ready). The translation is fetched **lazily, on tap**, not
  ahead of time.
- Make the fragment text **clickable word by word**: `Text.rich` with a
  `TextSpan` per word and a `TapGestureRecognizer` (one widget — one file; move
  the word-splitting logic out of `build`). A tap on a word opens the popup.
- `features/translation/presentation/widgets/word_popup_card.dart` — a pure
  dictionary entry card: it takes a `WordDefinition` and draws the translation,
  the part of speech, the synonyms, the transcription (a placeholder when absent)
  and the examples. It is positioned next to the word
  (`OverlayPortal`/`showMenu`/a custom `Overlay`).

The design system is mandatory (§6 CLAUDE): the `context.colors`, `AppSpacing`
and `AppText` tokens, and the components in `lib/widgets/`. No spacing or color
literals inside widgets.

### 5.4 Client tests

- the repository: a fake `TranslationRemoteDataSource`; a second identical
  request comes from the cache and the datasource is not called;
- DTO parsing: a `word_definition` with `transcription: null` → a domain entity
  with a placeholder;
- `LessonState.displayedText`: with two segments selected the text is their
  concatenation;
- widget tests: the «Перевод» button shows the translation; a tap on a word
  opens the popup with the parsed entry.

---

## 6. Order of work

The server (first):
1. The contract §2, the new error codes §2.3, the config §4.5.
2. The provider abstraction §4.1 plus `AzureTranslator` and `AzureDictionary` §4.2.
3. The cache §4.3.
4. The monthly limit counter and the error mapping §3, §4.4.
5. The tests §4.6.

The client (after the server):
6. `domain` + `data` §5.1–5.2; add `translation_quota_exceeded` to
   `ApiErrorCode` (§7).
7. The providers §5.3; the «Перевод» button and showing the fragment translation.
8. Clickable words plus `WordPopupCard`.
9. The tests §5.4.

---

## 7. A change to the client `ApiErrorCode`

Add the value (in `lib/core/network/api_exception.dart`):

```dart
translationQuotaExceeded('translation_quota_exceeded'),
```

`translation_unavailable`/`unsupported_language` need no special handling — they
show as a generic error built from `message`; give them their own values only
once they get a UI of their own.

---

## 8. Acceptance checklist

- [ ] «Перевод» shows the translation of exactly the current fragment; with two
      segments selected the translation covers the text of both;
- [ ] reopening the same fragment does not hit the network (the client cache);
- [ ] the same fragment across different users does not spend the quota twice
      (the server cache);
- [ ] a tap on a word opens the popup: translation, part of speech, synonyms,
      examples;
- [ ] a word without a transcription (Azure) gets a placeholder in the popup
      rather than a blank;
- [ ] a word missing from the dictionary gives "no entry", not an error;
- [ ] when the monthly limit is used up the server answers with a clear message
      instead of failing silently, and the client shows that message;
- [ ] changing `DICTIONARY_PROVIDER` requires no changes to the client or the
      contract.

---

## 9. Open questions

1. **The transcription on Azure is always a placeholder** (Azure does not return
   it). Is that fine for the first stage? It appears once the dictionary moves to
   Yandex.
2. **Examples** are a second Azure call per lookup (it spends quota). Do we keep
   them always on, or hide them behind an `include_examples` flag to save?
3. **`en → ru` is fixed** at this stage. Will other pairs be needed any time
   soon?
