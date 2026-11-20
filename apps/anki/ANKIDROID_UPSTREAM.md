# Forgotten Cards behavior provenance

The Deck Picker's **Review forgotten cards** option follows AnkiDroid 2.25.3
at commit `d9bf072f814a0c37d30a694192593b31ff2df875` and Anki Core at the
matching pinned source in `/workspace/anki-core-official`.

AnkiDroid `CustomStudyDialog.kt` supplies the forgotten-days value to the
`forgotDays` request field, defaults it to 1, and persists the last value in
`forgottenDays`. Its text is parsed as a positive signed 32-bit integer, so
the accepted range is 1 through 2,147,483,647. `DeckPicker.kt` provides the
exact search used to check whether matching cards exist before enabling
Create. The chosen deck search follows Core's normal `deck:` semantics,
including its subdecks.

Anki Core `rslib/src/scheduler/filtered/custom_study.rs` defines the actual
session: `rated:<days>:1` AND the selected deck, random order, limit 99,999,
and `reschedule: false`; it reuses the filtered deck named “Custom Study
Session”, rejects a normal deck with that name, and rejects empty matches.
The availability query excludes suspended, buried, and filtered-deck cards,
matching the cards that filtered-deck construction can move. Search terms are
written with the shared structured search writer, preserving deck-name
escaping.

The app code is original AGPL-3.0-or-later code. The behavior above was
independently implemented from the following source files; no upstream code
was copied:

| Source | SHA-256 |
| --- | --- |
| AnkiDroid `AnkiDroid/src/main/java/com/ichi2/anki/DeckPicker.kt` | `9859b3f9a604b52a67193027fcdec2b2e67e6a50a1ea04f760425822a23ac242` |
| AnkiDroid `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/customstudy/CustomStudyDialog.kt` | `f05c630547dd440016e6a7b613e3bc7200d99b52fd5cb526983cc3fcc3a2459d` |
| AnkiDroid `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/customstudy/CustomStudyViewModel.kt` | `331d8bab14d22e5f1365bd6c8cff237cf0cd8c5cbc8cd2f37793c6891ce25822` |
| AnkiDroid `AnkiDroid/src/test/java/com/ichi2/anki/dialogs/CustomStudyDialogTest.kt` | `2a236b521058e09e2c96ac147db70995629de2c6c4d4f079ff01a0a413e26306` |
| Anki Core `rslib/src/scheduler/filtered/custom_study.rs` | `8701f9bbd428ab3651e6343af9a6567a4ed28c094269b4b2dab20b5810e1732a` |
| Anki Core `proto/anki/scheduler.proto` | `9ebdd150185cdaccef2a7957481361b869344e573cce4dc0be77489cac7b71e3` |

AnkiDroid's source is GPL-3.0-or-later and Anki Core's source is AGPL-3.0-or-later.
