---
name: resolving-dart-static-analysis-errors
description: >-
  Fixing flutter analyze and linter errors in Shado: null safety, generics,
  overrides, errors after freezed/json_serializable code generation.
  Use when going through analyzer diagnostics and after build_runner.
---

# Analyzer errors

Configuration — `analysis_options.yaml` (`package:flutter_lints` + excluded
generated files). Code rules —
[docs/code_style.md](../../../docs/code_style.md).

## Order

- [ ] `flutter analyze`
- [ ] Errors in `*.freezed.dart` / `*.g.dart` — never fix by hand:
      `dart run build_runner build --force-jit` (on a conflict — `--delete-conflicting-outputs`)
- [ ] `dart fix --apply` for mechanical fixes
- [ ] The rest — by hand (below)
- [ ] Verify: `flutter analyze` and `flutter test`

## Common diagnostics

**Nullable receiver.** `?.` or `??`; `!` — only when "not null" is guaranteed
earlier in the code and that is visible from the line. A field that is surely
initialized before the first read, but not in the constructor, is `late`.

**Type mismatch** (`List<dynamic> can't be assigned`). Give the literal an
explicit type argument: `<Segment>[]`, `<String, Object?>{}`.

**Non-exhaustive switch.** For a `sealed` type or an `enum`, add the missing
cases, not `default` — otherwise the next variant silently falls through at
runtime. See the `dart-pattern-matching` skill.

**Invalid override.** A parameter cannot be narrowed in a subclass — either
widen the type or mark it `covariant` if the narrowing is deliberate.

**`use_build_context_synchronously`.** After `await`, check `mounted`
(in a `State`) or `context.mounted` before touching `context`, rather than
`// ignore`.

**Unused code.** Remove what is left over from your own change. Do not touch
someone else's dead code — name it in the reply.

## About `// ignore`

Suppression is a last resort, only with a comment on why it is there. Do not
disable a rule in `analysis_options.yaml` for the sake of one file.

## Code generation

Changes to `@freezed` and `@JsonSerializable` models require regeneration:

```bash
dart run build_runner build --force-jit
```

Errors like "`_$LessonModel` not found" or "the part file is outdated" are
cured by it too, not by editing generated code.
