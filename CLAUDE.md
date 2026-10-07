# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Siber Kalkan: a Flutter app (Android, iOS, web) that teaches cyber-security awareness to non-technical users in Turkey. Topic reading, a quiz, a "real or trap?" exercise with fictional messages, a password strength meter and generator, security checklists, and step-by-step guides for victims.

It is fully offline: no backend, no account, no network requests. Progress and the optional profile are stored only on the device, and passwords typed into the tools are never stored.

All identifiers, comments, UI strings and data keys are Turkish. Keep new code consistent with that.

## Commands

The files live in `C:\Users\YASİN EMİNE\Desktop\sibergüvenlik`. That path contains `İ`, `ü` and a space, which crashes the Dart analysis server and breaks Android builds, so **run every Flutter/Dart command from the ASCII junction `C:\src\siber_kalkan`**, which points at this directory. Flutter and Git are not on the default PATH.

```powershell
$env:Path = "C:\src\flutter\bin;C:\Program Files\Git\cmd;" + $env:Path
$env:PUB_CACHE = "C:\src\pub_cache"
Set-Location C:\src\siber_kalkan

flutter analyze
flutter test
flutter test --plain-name "yaygın parolalar"   # single test by name
flutter run -d chrome
flutter build web
```

Local preview is served from `build\web` on port 8766 (8765 belongs to the separate Trafik Saha project in `Desktop\Deneme`).

The repository is `github.com/ysnbilici06/siberguvenlik` (GitHub does not allow `ü` in names), branch `main`. Every push to `main` runs `.github/workflows/web-yayimla.yml`, which tests, builds and publishes the web version to `https://ysnbilici06.github.io/siberguvenlik/`; changes to `.md` files alone do not trigger it. The session sets `GCM_INTERACTIVE=never`, so run `$env:GCM_INTERACTIVE = "always"` before `git push`.

If the folder is moved or renamed, the junction breaks; recreate it with `cmd /c rmdir C:\src\siber_kalkan` followed by `New-Item -ItemType Junction -Path C:\src\siber_kalkan -Target <new folder>`.

## Architecture

- `assets/veri/icerik.json` — all content, hand-authored: `ipuclari`, `konular`, `sorular`, `senaryolar`, `listeler`, `kanallar`, `rehberler`. Questions and scenarios reference a topic by `konu`; guides reference official channels by key. `ikon` and `renk` are names resolved through the `ikonlar` / `renkler` maps in `ekranlar/ortak.dart`. `flutter test` fails on dangling references, unknown icon/colour names, and scenario marks that do not occur in the message.
- `veri/depo.dart` — `Depo.i`, a singleton `ChangeNotifier` holding the loaded content and the user's progress (read topics, question and scenario results, checklist ticks) as one JSON blob in SharedPreferences (`durum`). Screens rebuild through `ListenableBuilder(listenable: Depo.i)`. Progress counters only count ids that still exist in the content.
- Profile (`veri/profil.dart`, `ekranlar/profil.dart`) — first name, age range and province, asked once on the skippable `Karsilama` screen (`Depo.karsilandi`) and editable or deletable later from "Bilgilerim" on the home page. It lives in the same `durum` blob; `Depo._profiliAta` rejects unknown age groups and provinces and caps the name at `adSiniri`. `Depo.sifirla` clears progress only; `profilSil` clears the profile only.
- Personalised scenarios — a scenario may carry `kisisel: {metin, isaretler}` with `{ad}` / `{sehir}` placeholders. `Senaryo.uyarla` returns a filled copy (`kisisel == true`) only when every placeholder it uses has a value, otherwise the generic scenario; `Depo.siradakiSenaryolar` applies it. After a personalised scenario is answered the screen explains that the user supplied those details and that scammers get them from leaks. Keep some safe scenarios personalised too, so users do not learn "knows my name = trap".
- Age-based suggestions — a topic's optional `yas` list (keys of `yasGruplari`) puts it under "Yaş grubunuza önerilen konular" on the home page until it is read.
- `veri/parola.dart` — pure functions, no UI: `parolaDegerlendir` (heuristic strength estimate: common-password list, character pool, penalties for repeats, sequences, keyboard runs and years), `parolaUret`, `parolaCumlesiUret` and their bit estimates. The passphrase bit count is computed from the actual word-list size; do not hardcode it.
- `ekranlar/` — one file per bottom-nav area (`ana_sayfa`, `ogren`, `alistirma`, `araclar`); `ortak.dart` has shared widgets and helpers. Each tool's icon, accent colour and description live once in `aracGorunumu` (`araclar.dart`), keyed by the page title, so a new tool needs an entry there.
- `alistirma.dart` — `TestEkrani` and `SenaryoEkrani` take their item list from the caller (`Depo.testSorulari` / `siradakiSenaryolar` order unanswered first, then wrong, then correct). `Ileti` draws a scenario by `tur` (`sms`, `eposta`, `arama`, `adres`) and, once answered, highlights each `isaretler[].parca`, which must occur verbatim in the sender, subject or body.

## Content rules

- Everything in the scenarios is fictional: institutions are "Örnek …", domains end in `.example`, IP addresses come from the documentation range `198.51.100.0/24`, phone numbers are masked. Never imitate a real institution; a test enforces the domain rule.
- Official channels in `kanallar` are never written from memory. Each one is checked on the institution's own site and carries that page in `kaynak`; anything that cannot be verified there is left out (USOM's report address is absent for this reason).
- Content is defensive: attack methods are described only as far as needed to recognise and avoid them.
- The profile is deliberately minimal: first name, age range, province, all optional and skippable. Surname, gender and education were considered and left out because no scenario needs them; an awareness app should not ask for data it does not use. Do not add fields without a concrete use, and never send the profile off the device.
- The password tools must stay local: no network call, no persistence, no logging of the typed or generated value.

## Tests

`test/widget_test.dart` loads the real bundled content. Widget tests run at 320×640 so layout overflow fails the test; list items below the fold are not built, so tests scroll to a widget (`gor`) before asserting on it.
