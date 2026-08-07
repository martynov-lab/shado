# Перевод в уроке: спецификация

Задача — добавить два вида перевода на экране урока:

1. **Перевод фразы (фрагмента).** Пользователь нажимает кнопку «Перевод», под
   текстом появляется перевод того фрагмента, что сейчас отображается —
   а это **активный отрезок сегментов** (`SegmentRange`), а не один сегмент.
   Показаны 2 сегмента — переводим объединённый текст двух сегментов.
2. **Перевод слова.** Пользователь нажимает на слово внутри фрагмента, рядом со
   словом всплывает попап: перевод слова, часть речи, синонимы, транскрипция
   (нет — заглушка), примеры в контексте.

Провайдер — **Azure Translator** (и перевод фразы, и словарь — одним ключом).
Заложить переезд словаря на **Yandex Dictionary** без смены контракта. Работаем
только в **бесплатных лимитах**: превышение — понятная ошибка от нашего сервера,
не молчаливый сбой. Платные подписки — при выходе в прод, отдельной задачей.

**Порядок: сначала сервер целиком, потом клиент** (§8).

Документ в стиле [CLIENT_SPEC.md](CLIENT_SPEC.md): те же правила API (§1 там),
`Bearer`-авторизация, `snake_case`, единый формат ошибок.

---

## 1. Ключевые решения

Зафиксированы здесь, чтобы не расходились между сервером и клиентом.

1. **Контракт провайдер-агностичен.** Клиент не знает, Azure это или Yandex.
   Сервер отдаёт унифицированный ответ, маппинг провайдера — внутри сервера.
2. **Два независимых провайдера.** Перевод фразы и словарь переключаются
   отдельными настройками (`PHRASE_PROVIDER`, `DICTIONARY_PROVIDER`). Сегодня оба
   `azure`; завтра словарь станет `yandex`, а фраза останется `azure` — контракт
   и клиент не меняются.
3. **Фразу переводим по тексту, не по уроку.** Тело запроса несёт готовый текст
   фрагмента; сервер про сегменты и уроки ничего не знает. Кеш — по хешу
   нормализованного текста. Проще, переиспользуемо, не завязано на модель урока.
4. **Транскрипция — nullable.** Azure её не даёт → `transcription: null` →
   клиент показывает заглушку. Yandex позже заполнит это же поле, контракт тот же.
5. **Направление по умолчанию `en → ru`.** Приложение учит английский
   русскоязычных. `source_lang`/`target_lang` в запросе опциональны, значения по
   умолчанию — `en`/`ru`. Заложены на будущее, но не обязательны.
6. **«Слова нет в словаре» — не ошибка.** Пустой словарный ответ — это `200` с
   `meanings: []`, клиент показывает «нет словарной статьи», а не ошибку.

---

## 2. Контракт API

Оба пути — под `Bearer`-авторизацией, как весь `/v1/*` (§1 CLIENT_SPEC).

### 2.1 Перевод фразы

```http
POST /v1/translate/phrase
Authorization: Bearer <access>
Content-Type: application/json

{
  "text": "Hello there. How are you?",
  "source_lang": "en",   // опционально, по умолчанию "en"
  "target_lang": "ru"    // опционально, по умолчанию "ru"
}
```

Ответ `200`:

```json
{
  "text": "Hello there. How are you?",
  "translation": "Здравствуйте. Как поживаете?",
  "source_lang": "en",
  "target_lang": "ru",
  "provider": "azure"
}
```

- `text` — не длиннее **2000 символов** (несколько сегментов — это заведомо
  меньше); больше — `validation_error` (422). Так закрываем расход квоты на
  случайный огромный вход.
- `provider` — справочно (диагностика, аналитика). Клиент на него не завязывается.

### 2.2 Перевод слова (словарь)

```http
POST /v1/dictionary/lookup
Authorization: Bearer <access>
Content-Type: application/json

{
  "word": "learn",
  "source_lang": "en",   // опционально, по умолчанию "en"
  "target_lang": "ru"    // опционально, по умолчанию "ru"
}
```

Ответ `200`:

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

- `word` — одно слово, не длиннее **100 символов**; больше — `validation_error`.
- `transcription` — фонетическая запись слова или `null` (Azure всегда `null`).
- `meanings` — сгруппировано **по части речи** (`part_of_speech`): так словарь
  ложится и на Azure (группируем плоский список по `posTag`), и на Yandex (у него
  `def[].pos`). Пустой массив — слова в словаре нет.
- `translations[].synonyms` — близкие слова. Для Azure это `backTranslations`
  (обратные переводы — по смыслу «синонимы/родственные»), для Yandex — `syn`.
- `examples` — примеры для верхнего перевода; пустой массив, если их нет.

Такая форма (`meanings → part_of_speech → translations → synonyms`, `examples`)
задаётся **нами**, а не Azure. Оба провайдера маппятся в неё (§4.2, §4.5).

### 2.3 Новые коды ошибок

Формат — общий (§1 CLIENT_SPEC): `{ "error": { "code", "message" } }`.
Сообщение уже готово к показу пользователю (по-русски).

| code | HTTP | Когда | Что делает клиент |
| --- | --- | --- | --- |
| `translation_quota_exceeded` | 429 | исчерпан бесплатный месячный лимит провайдера | показать `message` («Бесплатный лимит переводов на этот месяц исчерпан, попробуйте позже»); не долбить повторами |
| `translation_unavailable` | 503 | провайдер недоступен или вернул сбой | показать `message`, дать «Повторить» |
| `unsupported_language` | 422 | пара языков не поддержана (актуально для словаря) | показать `message`, скрыть перевод для этой пары |
| `validation_error` | 422 | пустой ввод или превышение длины | показать `message` |

Замечание для клиента: даже без нового значения в `ApiErrorCode` эти ошибки
покажутся корректно — `ApiClient.mapError` берёт `message` из тела, а неизвестный
код становится `unknown`. Но для типизированной обработки
`translation_quota_exceeded` стоит добавить в enum (§7).

---

## 3. Бесплатные лимиты и их контроль (сервер)

Azure Translator тариф **F0**: суммарно ~**2 000 000 символов в месяц** на все
операции (translate + dictionary lookup + examples). Наша задача — **не выйти за
предел и не словить биллинг**, а при подходе к нему отдавать понятную ошибку.

1. **Счётчик символов за календарный месяц** (UTC), с persist в БД: на каждый
   успешный вызов провайдера прибавляем число отправленных символов (для
   `examples` — тоже, это отдельный оплачиваемый вызов).
2. **Порог из конфигурации** (`TRANSLATION_MONTHLY_CHAR_LIMIT`, по умолчанию с
   запасом — например `1_900_000`, ~95 % от лимита). Достигли порога — на новые
   запросы отдаём `translation_quota_exceeded` (429) **до обращения к Azure**.
3. **Провайдер сам вернул 403/429** (превышение на стороне Azure) — ловим и
   маппим в тот же `translation_quota_exceeded`, чтобы поведение было единым.
4. Счётчик сбрасывается 1-го числа месяца (или по полю периода в таблице).

Кеш (§5) резко снижает расход: повторный перевод той же фразы/слова символы не
тратит.

---

## 4. Сервер: реализация

### 4.1 Провайдерная абстракция

Два независимых интерфейса (trait) — чтобы словарь переключался отдельно от
фразы:

```
PhraseTranslator:
  translate(text, source_lang, target_lang) -> PhraseTranslation

DictionaryProvider:
  lookup(word, source_lang, target_lang) -> WordDefinition   // unified
```

- `AzureTranslator` реализует `PhraseTranslator`.
- `AzureDictionary` реализует `DictionaryProvider`.
- Позже `YandexDictionary` реализует `DictionaryProvider` — и всё, точка выбора
  одна (фабрика по `DICTIONARY_PROVIDER`).
- Оба возвращают **унифицированные** структуры (`WordDefinition` и т.д.),
  провайдер-специфичный JSON дальше слоя провайдера не уходит.

### 4.2 Azure: эндпоинты и маппинг

База: `https://api.cognitive.microsofttranslator.com`. Заголовки на каждый
запрос: `Ocp-Apim-Subscription-Key: <ключ>`, `Ocp-Apim-Subscription-Region:
<регион>`, `Content-Type: application/json`. Ключ и регион — только в конфиге
сервера, в клиент не попадают.

**Перевод фразы** — `POST /translate?api-version=3.0&from=en&to=ru`, тело
`[{ "Text": "…" }]`, ответ `[{ "translations": [{ "text": "…", "to": "ru" }] }]`.
Берём `translations[0].text`.

**Словарь** — `POST /dictionary/lookup?api-version=3.0&from=en&to=ru`, тело
`[{ "Text": "learn" }]`. Ответ (сокращённо):

```json
[{ "translations": [
   { "normalizedTarget": "учиться", "posTag": "VERB", "confidence": 0.45,
     "backTranslations": [{ "normalizedText": "study" }, { "normalizedText": "master" }] }
]}]
```

Маппинг Azure → unified `WordDefinition`:
- сгруппировать `translations` по `posTag` → `meanings[].part_of_speech`
  (`VERB→verb`, `NOUN→noun`, … привести к нижнему регистру);
- `normalizedTarget → translations[].text`, `confidence → confidence`;
- `backTranslations[].normalizedText → translations[].synonyms`;
- `transcription = null`.

**Примеры** — `POST /dictionary/examples?api-version=3.0&from=en&to=ru`, тело
`[{ "Text": "learn", "Translation": "учиться" }]` (перевод берём из верхнего
результата lookup). Ответ несёт `examples[]` с `sourcePrefix/sourceTerm/
sourceSuffix` и такими же `target*`; склеиваем в `source`/`target` предложения.

Примеры — **отдельный вызов Azure** (тратит символы). Делать его сразу после
lookup для верхнего перевода и класть в `examples`. Если экономия важна — вынести
за флаг (см. открытые вопросы, §9), но по умолчанию отдаём с примерами: они
нужны в попапе.

### 4.3 Кеш

Две таблицы (или одна с полем `kind`). Кешируем **уже унифицированный** ответ.

| Что | Ключ | Значение |
| --- | --- | --- |
| Фраза | `sha256(source_lang | target_lang | provider | нормализованный_текст)` | `translation` |
| Слово | `(нормализованное_слово, source_lang, target_lang, provider)` | `WordDefinition` (JSON) |

- **Нормализация фразы:** `trim`, схлопнуть повторные пробелы; **регистр
  сохраняем** (имена собственные переводятся иначе).
- **Нормализация слова:** `trim` + `lowercase` (словарь регистронезависим).
- `provider` в ключе — чтобы переезд словаря на Yandex не отдавал старые
  Azure-статьи; заодно кеш можно просто пересчитать сменой значения.
- Кеш-хит **не** трогает Azure и **не** увеличивает счётчик символов.

### 4.4 Ошибки

- Пустой/слишком длинный ввод — `validation_error` (422) с текстом причины.
- Пара языков не поддержана словарём — `unsupported_language` (422).
- Порог месячного лимита достигнут — `translation_quota_exceeded` (429), **до**
  вызова Azure.
- Azure вернул 403/429 — тоже `translation_quota_exceeded` (429).
- Прочий сбой/таймаут Azure — `translation_unavailable` (503).
- Пустой словарный ответ — **не ошибка**: `200` с `meanings: []`.

### 4.5 Конфигурация (env)

| Переменная | Смысл |
| --- | --- |
| `PHRASE_PROVIDER` | `azure` (пока единственный) |
| `DICTIONARY_PROVIDER` | `azure` сейчас, `yandex` позже |
| `AZURE_TRANSLATOR_KEY` | ключ подписки Azure |
| `AZURE_TRANSLATOR_REGION` | регион подписки |
| `TRANSLATION_MONTHLY_CHAR_LIMIT` | порог символов в месяц (по умолчанию `1_900_000`) |

Заготовки под Yandex (`YANDEX_DICTIONARY_KEY`) добавляются в момент переезда, не
сейчас.

### 4.6 Тесты сервера

- маппинг Azure `lookup`/`examples` → unified (группировка по части речи,
  `backTranslations → synonyms`, `transcription == null`);
- кеш-хит: второй одинаковый запрос **не** зовёт провайдера и **не** двигает
  счётчик (провайдер — подделка со счётчиком вызовов);
- лимит: счётчик у порога → `translation_quota_exceeded` **до** вызова провайдера;
- Azure 429/403 → `translation_quota_exceeded`; таймаут → `translation_unavailable`;
- пустой lookup → `200`, `meanings: []`;
- превышение длины/пустой ввод → `validation_error`.

---

## 5. Клиент (Flutter): реализация — этап 2

Начинать после готового сервера. Чистая архитектура, feature-first: новая фича
`features/translation` (переиспользуема и провайдер-агностична), её показ — на
экране урока.

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

- `models/…_dto.dart` — DTO под ответы §2.1/§2.2 (freezed + json_serializable,
  `snake_case`). `transcription` — nullable.
- `datasources/translation_remote_datasource.dart` — за интерфейсом, поверх
  `ApiClient` (`post('/v1/translate/phrase', …)`,
  `post('/v1/dictionary/lookup', …)`).
- `repositories/translation_repository_impl.dart` — **in-memory кеш** по ключу
  (текст / слово): в shadowing один фрагмент открывают и зацикливают много раз,
  сеть на каждый показ недопустима. Серверный кеш (§4.3) это дублирует, но
  клиентский убирает сетевой round-trip внутри урока.

### 5.3 Presentation

Провайдеры (`features/translation/presentation/controllers`):
- DI use case'ов и репозитория (по образцу `lesson_providers.dart`).
- `phraseTranslationProvider(String text)` — `FutureProvider.family` по тексту
  фрагмента.
- `wordLookupProvider(String word)` — `FutureProvider.family` по слову.

Экран урока (`features/lessons/presentation`):
- В `LessonState` добавить, что именно сейчас показывается:
  `displayedRange = activeRange ?? selection ?? SegmentRange.single(currentIndex)`
  и `displayedText` — тексты сегментов диапазона, склеенные через пробел. Отсюда
  берётся «показал 2 сегмента → переводим 2 сегмента».
- `LessonTranscriptPanel` (сейчас заглушка) — заменить: кнопка «Перевод»
  становится тумблером; включён → под текстом показываем
  `phraseTranslationProvider(state.displayedText)` (загрузка/ошибка/готово).
  Перевод грузим **лениво, по нажатию**, а не заранее.
- Текст фрагмента сделать **кликабельным по словам**: `Text.rich` со `TextSpan`
  на каждое слово и `TapGestureRecognizer` (один виджет — один файл; логику
  разбивки на слова вынести из `build`). Тап по слову открывает попап.
- `features/translation/presentation/widgets/word_popup_card.dart` — чистая
  карточка словарной статьи: принимает `WordDefinition`, рисует перевод, часть
  речи, синонимы, транскрипцию (нет — заглушка), примеры. Позиционируется рядом
  со словом (`OverlayPortal`/`showMenu`/кастомный `Overlay`).

Дизайн-система обязательна (§6 CLAUDE): токены `context.colors`, `AppSpacing`,
`AppText`, компоненты `lib/widgets/`. Литералов отступов и цветов в виджетах нет.

### 5.4 Тесты клиента

- репозиторий: подделка `TranslationRemoteDataSource`; второй одинаковый запрос
  берётся из кеша, датасорс не зовётся;
- парсинг DTO: `word_definition` с `transcription: null` → доменная сущность с
  заглушкой;
- `LessonState.displayedText`: выбраны 2 сегмента → текст — их объединение;
- виджет-тесты: кнопка «Перевод» показывает перевод; тап по слову открывает
  попап с разобранной статьёй.

---

## 6. Порядок работ

Сервер (сначала):
1. Контракт §2, новые коды ошибок §2.3, конфиг §4.5.
2. Провайдерная абстракция §4.1 + `AzureTranslator` и `AzureDictionary` §4.2.
3. Кеш §4.3.
4. Счётчик месячного лимита и маппинг ошибок §3, §4.4.
5. Тесты §4.6.

Клиент (после сервера):
6. `domain` + `data` §5.1–5.2; добавить `translation_quota_exceeded` в
   `ApiErrorCode` (§7).
7. Провайдеры §5.3; кнопка «Перевод» и показ перевода фрагмента.
8. Кликабельные слова + `WordPopupCard`.
9. Тесты §5.4.

---

## 7. Правка клиентского `ApiErrorCode`

Добавить значение (файл `lib/core/network/api_exception.dart`):

```dart
translationQuotaExceeded('translation_quota_exceeded'),
```

`translation_unavailable`/`unsupported_language` специальной обработки не требуют
— показываются как общая ошибка по `message`; отдельные значения заводить только
если под них появится особый UI.

---

## 8. Чек-лист приёмки

- [ ] «Перевод» показывает перевод именно текущего фрагмента; выбраны 2 сегмента
      — перевод по тексту двух сегментов;
- [ ] повторное открытие того же фрагмента не ходит в сеть (клиентский кеш);
- [ ] один и тот же фрагмент у разных пользователей не тратит квоту дважды
      (серверный кеш);
- [ ] тап по слову открывает попап: перевод, часть речи, синонимы, примеры;
- [ ] у слова без транскрипции (Azure) в попапе стоит заглушка, а не пустота;
- [ ] слова нет в словаре → «нет статьи», а не ошибка;
- [ ] при исчерпании месячного лимита сервер отвечает понятным сообщением, а не
      молча падает; клиент показывает это сообщение;
- [ ] смена `DICTIONARY_PROVIDER` не требует правок клиента и контракта.

---

## 9. Открытые вопросы

1. **Транскрипция на Azure всегда заглушка** (Azure её не отдаёт). Ок для первого
   этапа? Появится после переезда словаря на Yandex.
2. **Примеры** — второй вызов Azure на каждый lookup (тратит квоту). Оставляем
   всегда включёнными или прячем за флагом `include_examples` ради экономии?
3. **`en → ru` фиксировано** на этом этапе. Другие пары не понадобятся в
   ближайшее время?
