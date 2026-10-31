# Notices

This repository contains a partial, modified Dart port of code from
[AnkiDroid](https://github.com/ankidroid/Anki-Android), release 2.25.3, commit
`d9bf072f814a0c37d30a694192593b31ff2df875`. It is an independent project and
does not imply endorsement by the AnkiDroid or Anki projects.

## Adapted source

- `AnkiDroid/src/main/java/com/ichi2/anki/CardTemplateEditor.kt:1550–1574` (`CardTemplateFragment.deleteTemplate`) is Copyright © 2014 Timothy Rae and © 2018 Mike Hardy and marked `GPL-3.0-or-later` upstream. Its source-ordered collection filtering, per-match log and temporary-note-type removal, assignment/update, and pager effects are adapted in `lib/src/card_template_fragment_delete_template.dart`; focused source-derived cases are in `test/card_template_fragment_delete_template_test.dart`. The host retains `NotetypeJson`, `CardTemplates`/JSONArray, the null assertion, Timber, ordinal updater, adapter, pager, animation, and UI. Pinned `CardTemplateEditorTest.testDeleteTemplate` and `testDeleteTemplateWithSelectivelyGeneratedCards` cover integration behavior.

- `AnkiDroid/src/main/java/com/ichi2/anki/CardTemplateEditor.kt`
  (`CardTemplateFragment.saveNoteType`, lines 1091–1119) is marked
  `GPL-3.0-or-later` upstream and names no separate copyright holder. Its
  callback order and `Exception` boundary are adapted in
  `lib/src/card_template_fragment_save_note_type.dart`, with focused cases in
  `test/card_template_fragment_save_note_type_test.dart`. Android views,
  Activity/lifecycle, resources, task/progress UI, temporary-model `!!` read,
  model/database, logging, and success effects remain host-side. The pinned
  `CardTemplateEditorTest` covers successful confirm/save flows in context;
  the focused branch and error cases are source-derived.

- `AnkiDroid/src/main/java/com/ichi2/anki/CardTemplateEditor.kt:1127–1160`
  (`CardTemplateFragment.setupCommonMenu`; pinned AnkiDroid 2.25.3 commit
  `d9bf072f814a0c37d30a694192593b31ff2df875`) is adapted in
  `lib/src/card_template_fragment_common_menu.dart` as
  `CardTemplateCommonMenuSetupCallbacks` and
  `setupCardTemplateCommonMenu()`, with source-derived cases in
  `test/card_template_fragment_setup_common_menu_test.dart`. The ordered menu
  title and visibility projection preserves lazy dynamic-note, current-template,
  JSON `did`, count, and view reads. Android menu/resource/model access and
  mutations remain host-side. Pinned `CardTemplateEditorTest` exercises visible
  add/delete/preview actions but does not isolate these setup branches.

- `AnkiDroid/src/main/java/com/ichi2/anki/NoteFieldsCheckResult.kt` is Copyright (c) 2024 Ashish Yadav and declares `GPL-3.0-or-later`. Its status-to-success/failure decision is adapted in `lib/src/note_fields_check_result.dart`; host validation, generated response types, note/collection access, localization, and Android remain host-side. No generated protocol code is copied. The pinned source has no direct focused test; source-derived cases are in `test/note_fields_check_result_test.dart`.

- `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/FullScreenMode.kt` declares `GPL-3.0-or-later` and does not name a separate copyright holder. Its exact mode strings, default/null/unknown decoding, fullscreen predicate, legacy boolean migration decision, and ordered string-write/key-removal plan are adapted in `lib/src/reviewer_full_screen_mode.dart`; source-derived cases are in `test/reviewer_full_screen_mode_test.dart`. The host reads SharedPreferences and applies the ordered actions inside its Android edit transaction. SharedPreferences, Android window/insets/UI effects, and unrelated Reviewer behavior remain host-side.

- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt` is marked `GPL-3.0-or-later` upstream and names no separate copyright holder. Its `onPageFinished(isAfterRecreation)` branch and request order are adapted in `lib/src/reviewer_page_finished_effects.dart`; source-derived cases are in `test/reviewer_page_finished_effects_test.dart`. Its `typeAnsQuestionFilter` HTML transformation is adapted in `lib/src/type_answer_question.dart`, with focused source-derived cases in `test/type_answer_question_test.dart`. The host retains the lifecycle callback, IO coroutine scheduling, actual current-card refresh and rendering, mutation signal/JavaScript, coroutine cancellation/errors, Flow delivery, WebView, Android input lifecycle, Reviewer dispatch/state, and TypeAnswer lookup/comparison. The upstream TODO about "Don't keep activities" is not extended.

- The same `ReviewerViewModel.kt` `updateCurrentCard()` method is adapted as the ordered host callback executor `executeReviewerCurrentCardUpdate()` in `lib/src/reviewer_current_card_update_effects.dart`, with source-derived cases in `test/reviewer_current_card_update_effects_test.dart`. Scheduler/collection access, current-card deferred state, timer, Auto Advance, Flow publication, rendering, media/player work, availability/count calculation, coroutine/lifecycle behavior, and UI remain host-side.

- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt` (`typeAnsFilter`, lines 612–625; pinned AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`) is marked `GPL-3.0-or-later` upstream and names no separate copyright holder. Its branch and host callback order are adapted in `lib/src/reviewer_type_answer_filter_effects.dart`, with focused cases in `test/reviewer_type_answer_filter_effects_test.dart`. The host retains card lookup/await, TypeAnswer construction and state, Flow emission, answer comparison, existing Reviewer filters and tag removal, rendering, and coroutine/Android lifecycle.

- `AnkiDroid/src/main/java/com/ichi2/anki/instantnoteeditor/InstantEditorViewModel.kt` is Copyright © 2024 Ashish Yadav <mailtoashish693@gmail.com> and marked `GPL-3.0-or-later` upstream. Its cloze field-text state, word extraction, ordinal extraction, mode and counter changes, cloze wrapping/removal text, and punctuation behavior are adapted in `lib/src/instant_editor_cloze_state.dart`. Note/collection mutation, undoable save, editor selection/fields, Android StateFlow/lifecycle, and UI remain host-side. The pinned `InstantEditorViewModelTest.kt` and `InstantEditorViewModelParameterizedTest.kt` provide source cases; focused Dart tests also cover JVM whitespace behavior, source-regex boundaries, integer bounds and unmatched input.

- `AnkiDroid/src/main/java/com/ichi2/anki/account/LoginViewModel.kt` is Copyright (c) 2025 Ashish Yadav <mailtoashish693@gmail.com> and marked `GPL-3.0-or-later` upstream. Its local input focus validation, button-enabled predicate, error values, and Idle/Success/Error state variants are adapted in `lib/src/login_input_state.dart`. The host retains authentication/network requests, preference persistence, PII-sensitive exception handling, Android string resources, StateFlow/coroutines, lifecycle, and UI. The pinned source has no direct tests for these input/state paths; focused Dart cases are source-derived.

- `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/EditDeckDescriptionDialogViewModel.kt` is marked `GPL-3.0-or-later` upstream. Its portable description/Markdown state, initialization and change comparison, back/close decisions, and save-before-dismissal actions are adapted in `lib/src/edit_deck_description_state.dart`. The host supplies persisted values and applies the returned actions; SavedStateHandle, collection access and updates, coroutine/Flow delivery, Android lifecycle, and dialog UI remain host-side. The pinned `EditDeckDescriptionDialogViewModelTest.kt` is also marked `GPL-3.0-or-later`. The upstream files state no separate copyright holder.

- `AnkiDroid/src/main/java/com/ichi2/anki/preferences/profiles/SwitchProfilesViewModel.kt` is Copyright © 2026 Ashish Yadav <mailtoashish693@gmail.com> and marked `GPL-3.0-or-later` upstream. Its empty profile-list state and add-dialog visibility transitions are adapted in `lib/src/switch_profiles_dialog_state.dart`; profile creation remains TODO, matching the pinned source. ProfileManager/profile IO, logging, StateFlow, lifecycle, and Android UI remain host-side; ProfileName validation is separately adapted below. The pinned `SwitchProfilesViewModelTest.kt` is also Copyright © 2026 Ashish Yadav and marked `GPL-3.0-or-later`.

- `AnkiDroid/src/main/java/com/ichi2/anki/multiprofile/ProfileName.kt` is Copyright © 2026 Ashish Yadav <mailtoashish693@gmail.com>, and `ProfileId.kt` is Copyright © 2025 Ashish Yadav; both are marked `GPL-3.0-or-later` upstream. Their portable value, validation, and generation behavior is adapted in `lib/src/profile_name.dart` and `lib/src/profile_id.dart`. The pinned `ProfileNameTest.kt` and `ProfileIdTest.kt` are Copyright © 2026 Ashish Yadav and marked `GPL-3.0-or-later`; focused Dart cases are in `test/profile_name_test.dart` and `test/profile_id_test.dart`. ProfileManager, persistence, uniqueness checks, profile switching, lifecycle, and UI remain host-side.

- `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/viewmodel/ExportReadyViewModel.kt` is Copyright © 2026 lukstbit <52494258+lukstbit@users.noreply.github.com> and marked `GPL-3.0-or-later` upstream. Its immutable export-ready parameters and request register/clear state are adapted in `lib/src/export_ready_request_state.dart`. SavedStateHandle/StateFlow/Parcelable, Android lifecycle, Timber logging, dialog/navigation, filesystem, and export execution remain host-side. The pinned source has no tests for these methods; focused Dart cases are source-derived.

- `AnkiDroid/src/main/java/com/ichi2/anki/multimedia/MultimediaViewModel.kt` is Copyright © 2024 Ashish Yadav <mailtoashish693@gmail.com> and marked `GPL-3.0-or-later` upstream. Its nullable URI/path state, saved values for revert, selected media length, and direct updates are adapted in `lib/src/multimedia_view_model_state.dart` using opaque host value types. `MutableSharedFlow` action emission/coroutines, String-to-File conversion, Android media/file/URI operations, lifecycle, and UI remain host-side. The pinned source has no tests for these methods; focused Dart cases are source-derived.

- `AnkiDroid/src/main/java/com/ichi2/anki/pages/viewmodel/ImageOcclusionViewModel.kt` is Copyright © 2025 Ashish Yadav <mailtoashish693@gmail.com> and marked `GPL-3.0-or-later` upstream. Its Add/Edit arguments, Image Occlusion mode map, Add-mode selected deck, and conditional original-deck restore decision are adapted in `lib/src/image_occlusion_view_model_state.dart`. The host retains Parcelable/SavedStateHandle, deck-name lookup, collection current-deck writes, coroutine/StateFlow behavior, rendering/navigation, and UI.

- `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/ImportViewModel.kt` is Copyright © 2026 Georgios Michelakis <michelakisgio@gmail.com> and marked `GPL-3.0-or-later` upstream. Its add/replace action selection and unchanged path request are adapted in `lib/src/import_action_routing.dart`. SharedFlow delivery, coroutine/Job scheduling, importer/backend work, and Android UI remain host-side. The pinned source has no tests for these methods; focused Dart cases are source-derived.

- `AnkiDroid/src/main/java/com/ichi2/anki/shareddeck/SharedDecksDownloadViewModel.kt` is Copyright © 2026 Ashish Yadav <mailtoashish693@gmail.com> and marked `GPL-3.0-or-later` upstream. Its portable download state and progress transitions are adapted in `lib/src/shared_decks_download_state.dart`; process-default locale formatting is delegated to the host. DownloadManager/network/file work, Android lifecycle, StateFlow, localization, and UI remain host-side. The pinned `SharedDecksDownloadViewModelTest.kt` is also Copyright © 2026 Ashish Yadav and marked `GPL-3.0-or-later`; focused Dart cases are source-derived.

- `AnkiDroid/src/main/java/com/ichi2/anki/notetype/ManageNoteTypesState.kt`
  and `ManageNoteTypesViewModel.kt` are Copyright © 2025 lukstbit and marked
  `GPL-3.0-or-later` upstream. Their portable row/state values, filter and
  selection transitions, selected-row projection, and editor destination
  requests are adapted in `lib/src/manage_note_types_state.dart`. The host
  supplies note-type rows and retains collection loading/refresh, use-count
  queries, note-type mutations, exception classification/construction,
  StateFlow/coroutines, and Android UI/lifecycle. Selected deletion choreography
  is adapted in `lib/src/manage_note_types_delete_plan.dart`; the host retains
  `safeRemoveNoteType`, undoable database operations, `OpChanges`, Kotlin
  exception wrappers, mutable state/StateFlow, coroutine scheduling, Timber,
  and Android UI/lifecycle. Focused Dart cases are source-derived from
  `ManageNoteTypesViewModelTest.kt`, Copyright © 2025 lukstbit and marked
  `GPL-3.0-or-later`. The single-note-type delete decision and outcome are
  adapted in `lib/src/manage_note_type_delete_plan.dart`; the host retains the
  undoable operation, safe removal, generated result, reportable exception,
  coroutine/state-flow, logging, and Android/UI lifecycle. No direct pinned
  test covers this method; focused Dart cases are source-derived. Rename
  choreography is adapted in `lib/src/manage_note_type_rename_plan.dart`; the
  host retains `safeRenameNoteType`, undoable execution, generated changes,
  backend-exception classification, reportable-error construction, coroutine
  scheduling, logging, and Android/UI lifecycle. No direct pinned test covers
  rename; focused Dart cases are source-derived. Refresh result publication is
  adapted in `lib/src/manage_note_type_refresh_plan.dart`; the host retains the
  collection query/use-count lookup, safe-query `Exception` capture,
  `ReportableException`, `MutableStateFlow`, coroutine scheduling, Timber, and
  Android lifecycle/UI. Its state/error branch and callback-boundary cases are
  source-derived; no direct pinned refresh test was found. Independent
  transient message/error clearing is adapted in
  `ManageNoteTypesState.clearMessage()` and `clearError()`; the host retains
  MutableStateFlow publication, logging, and lifecycle. Focused cases are
  source-derived; the pinned ViewModel tests do not cover these clear methods.

- `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/InsertFieldDialogViewModel.kt`,
  `AnkiDroid/src/main/java/com/ichi2/anki/model/FieldName.kt`,
  `AnkiDroid/src/main/java/com/ichi2/anki/model/SpecialField.kt`, and
  `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/SingleCardSide.kt` are
  marked `GPL-3.0-or-later` upstream. Their portable field values, ordered
  side-specific availability, tab positions, and selection state are adapted in
  `lib/src/insert_field_dialog_selection.dart`. SavedStateHandle, StateFlow,
  metadata queries, database reads, descriptions/localization, and dialog UI
  remain host-side. The pinned ViewModel tests directly cover field selection
  and special-field ordering; invalid-selection retention and wrapper/selected
  value identity cases are source-derived.

- `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/tags/TagsList.kt`,
  `AnkiDroid/src/main/java/com/ichi2/utils/TagsUtil.kt`, and
  `UniqueArrayList.kt` are marked `GPL-3.0-or-later` upstream; `TagsList.kt`
  attributes copyright to Tarek Mohamed Abdalla. Their portable tag selection
  model and hierarchy comparison helpers are adapted in
  `lib/src/tags_list.dart`. Collection loading, dialog and adapter UI,
  localization, and saving remain host-side. The portable initialization
  projection from `TagsDialogViewModel.kt` is in
  `lib/src/tags_dialog_initialization.dart`; it consumes host-fetched note tags
  and returns the TagsList plus source-ordered progress values. Collection and
  note reads, coroutine/flow publication, lifecycle, dialog UI, and saving stay
  host-side. The pinned `TagsDialogViewModelTest.kt` is Copyright © 2025
  Divyansh Kushwaha and marked `GPL-3.0-or-later`.

- `AnkiDroid/src/main/java/com/ichi2/anki/tags/ManageTagsViewModel.kt` and
  `AnkiDroid/src/test/java/com/ichi2/anki/tags/ManageTagsViewModelTest.kt` are
  marked `GPL-3.0-or-later` upstream and state no separate copyright holder.
  The source-ordered remove, rename, and clear-unused operation orchestration,
  event values, query snapshot, and failure behavior are adapted in
  `lib/src/manage_tags_operation_plan.dart`. The host retains the collection
  mutations, undoable operation, tag-tree loading, coroutine/job scheduling,
  StateFlow, event channel, logging, lifecycle, and UI. The pinned tests cover
  operation effects and affected-note counts; Dart cases for orchestration and
  failure ordering are source-derived.

- `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/EmptyCardsViewModel.kt` is
  Copyright (c) 2025 lukstbit <52494258+lukstbit@users.noreply.github.com> and
  marked `GPL-3.0-or-later` upstream. The portable Empty Cards state and query
  publication behavior are adapted in `lib/src/empty_cards_search_state.dart`.
  The host retains collection access, the generated report type, query
  execution, coroutine/job, StateFlow, lifecycle, and UI.

- `AnkiDroid/src/main/java/com/ichi2/anki/filtered/FilteredDeckOptionsState.kt`
  and `FilteredDeckOptionsViewModel.kt` are marked `GPL-3.0-or-later` upstream;
  both headers attribute copyright to lukstbit (2025). Their portable
  option/filter values, name/limit validation, search/card-order/reschedule/
  allow-empty transitions, clear actions, dirty-state comparison, build
  eligibility, and second-filter toggle projections are adapted in
  `lib/src/filtered_deck_options.dart`; transition wrappers also expose the
  dirty updates for name, limit, and second-filter changes without changing the
  existing state-only projections. Focused cases in
  `test/filtered_deck_options_validation_test.dart` derive from
  `AnkiDroid/src/test/java/com/ichi2/anki/filtered/FilteredDeckOptionsViewModelTest.kt`,
  including changed input, unobserved properties, and restored state. The
  transition model reports whether each action recomputes dirty status while
  leaving StateFlow delivery and SavedStateHandle persistence to the host. The
  same ViewModel's `FilteredDeckForUpdate.asInitialState` and
  `FilteredDeckOptions.asBackendData` projections are adapted with portable
  input/update DTOs in `lib/src/filtered_deck_options.dart`; focused cases in
  `test/filtered_deck_backend_conversion_test.dart` cover zero/nonzero IDs,
  null versus empty default search overrides, term-count and second-filter
  rules, malformed missing-first-term failure, integer parsing/defaults, and
  host order-index inputs. The source files are marked `GPL-3.0-or-later` and
  attribute copyright to lukstbit (2025). The generated backend model, enum
  `forNumber` resolution and protobuf serialization, collection queries and
  mutations, lifecycle, asynchronous flows, query validation/execution, Android
  UI, and filtered-deck building remain host-side; Dart does not recreate the
  generated backend or collection behavior. The same ViewModel’s
  `onSearchInBrowser` request/result projection is adapted by
  `FilteredDeckBrowserSearchRequest`, `FilteredDeckInvalidSearchException`,
  and its success/failure functions in `lib/src/filtered_deck_options.dart`;
  `test/filtered_deck_browser_search_result_test.dart` covers exact request
  search strings, absent second filters, and result field preservation. The
  pinned method is tested by `FilteredDeckOptionsViewModelTest.kt` cases
  “filter search in browser produces expected state” and “invalid search in
  browser produces state with error”. The ViewModel and test headers mark
  `GPL-3.0-or-later` and attribute copyright to lukstbit (2025); the host
  supplies `safeBuildSearchString` outcomes and localized messages, while
  collection access, coroutine/StateFlow delivery, and Android UI remain
  host-side. The same `build()` outcome boundary is adapted by
  `FilteredDeckBuildStart`, `FilteredDeckBuildOutcome`, and singleton `DeckBuilt`
  in `lib/src/filtered_deck_options.dart`; focused cases in
  `test/filtered_deck_build_outcome_test.dart` cover the immediate build flag
  and request snapshot, success marker, and failure against current state. The
  host retains the undoable operation, scheduler call, generated request/result
  types, and state/effect publication. `AnkiDroid/src/main/java/com/ichi2/anki/exception/InvalidSearchException.kt` is Copyright (c) 2026 lukstbit and distributed under GPL-3.0-or-later; the Dart wrapper does not implement backend parsing or localization.
  `FilteredDeckOptionsViewModel.kt` also supplies `onShowExcludedCards()` and
  `filteredSearchNode()` (the latter is annotated `@NeedsTest("Ensure this
  method produces the expected filter")` and has no direct pinned unit test).
  Their portable plan is `FilteredDeckExcludedCardsSearchPlan` and its node
  DTOs in `lib/src/filtered_deck_options.dart`; source-derived cases in
  `test/filtered_deck_excluded_search_plan_test.dart` preserve exact manual
  searches, optional second-filter gating, OR grouping and singleton collapse,
  suspended/buried/deck implicit order, the new/edit filtered-deck node shape,
  and the final AND structure. Success stores the exact browser query while
  retaining the existing throwable; a caught `Exception` is assigned directly
  while retaining the browser query. Collection `groupSearches`, generated
  `SearchNode` construction, `buildSearchString` serialization/validation,
  asynchronous query execution, state delivery, and Android lifecycle remain
  host-side. The source path is
  `AnkiDroid/src/main/java/com/ichi2/anki/filtered/FilteredDeckOptionsViewModel.kt`,
  pinned at `d9bf072f814a0c37d30a694192593b31ff2df875`; the source header marks
  it `GPL-3.0-or-later` and attributes copyright to lukstbit (2025).

- `AnkiDroid/src/main/java/com/ichi2/anki/StudyOptionsViewModel.kt` is
  Copyright © 2026 Ashish Yadav <mailtoashish693@gmail.com> and marked
  `GPL-3.0-or-later` upstream. Its `DeckStudyData`, buried-count derivation,
  and Loading/Empty/Congrats/StudyOptions projections are adapted in
  `lib/src/study_options_view_model.dart`. The `rebuildCram()` and `emptyCram()`
  action order is adapted in `lib/src/study_options_filtered_deck_actions.dart`:
  each keeps its diagnostic, selected-deck scheduler call inside one undoable
  operation, and collection-state refresh afterward. Collection access, flow
  publication, scheduler execution, Android lifecycle, description rendering,
  media resolution, and UI remain host-side.
- `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/customstudy/CustomStudyViewModel.kt`
  is Copyright © 2025 lukstbit and marked `GPL-3.0-or-later` upstream;
  `CustomStudyDialog.kt`, which declares the card-state enum, is Copyright © 2015
  Timothy Rae and marked `GPL-3.0-or-later`. Their portable selected-index to
  scheduler-kind mapping is adapted in `lib/src/custom_study_card_state.dart`.
  SavedStateHandle persistence, Android spinner, labels/localization, and
  scheduler execution remain host-side.
- `AnkiDroid/src/main/java/com/ichi2/anki/scheduling/SetDueDateViewModel.kt`
  is marked `GPL-3.0-or-later` upstream. Its portable due-date validation,
  parameter formatting, scheduler-setting guard, interval-match behavior, card
  count, and review-only current-interval visibility are adapted in
  `lib/src/set_due_date_view_model.dart`. Collection access, scheduler mutation,
  undo handling, and Android UI remain host-side.
- `AnkiDroid/src/main/java/com/ichi2/anki/scheduling/Fsrs.kt` is marked
  `GPL-3.0-or-later` upstream and names no separate copyright holder. Its
  exact FSRS library-version label mapping is adapted in
  `lib/src/fsrs_version.dart`, with focused cases in
  `test/fsrs_version_test.dart`. Backend `BuildConfig`, scheduler calculations,
  and scheduler execution remain host-side.
- `AnkiDroid/src/main/java/com/ichi2/anki/CardTemplateEditorState.kt` and
  `CardTemplateEditorViewModel.kt` are Copyright © 2025 Snowiee
  <xenonnn4w@gmail.com> and marked `GPL-3.0-or-later` upstream. Their portable
  Initializing / Loaded / Finished state variants, editor-view and message
  enums, opaque reportable-exception data, and Loaded-only transitions are
  adapted in `lib/src/card_template_editor_state.dart`. The exception source
  is preserved with its reportable flag; host error conversion, StateFlow,
  logging, Android lifecycle, template loading/saving, rendering, and UI remain
  host-side. `AnkiDroid/src/main/java/com/ichi2/anki/exception/ReportableException.kt`
  is Copyright © 2025 lukstbit
  <52494258+lukstbit@users.noreply.github.com> and marked `GPL-3.0-or-later`;
  its opaque source value and `isReportable` flag are represented in the Dart
  data wrapper. The pinned source has no tests for these methods; Dart cases
  are source-derived.
- `AnkiDroid/src/main/java/com/ichi2/anki/mediacheck/MediaCheckViewModel.kt`
  is Copyright (c) 2025 Ashish Yadav <mailtoashish693@gmail.com> and marked
  `GPL-3.0-or-later` upstream. Its portable unused-file deletion and
  missing-media tagging plans are adapted in
  `lib/src/media_check_unused_deletion.dart` and
  `lib/src/media_check_missing_tagging.dart`; the check-result publication
  sequence is adapted in `lib/src/media_check_result_publication.dart`. Trash
  deletion/restoration operation selection and source order are adapted in
  `lib/src/media_check_trash_actions.dart`, with no progress message. These
  preserve opaque result publication only after the check succeeds, null-result
  fallbacks, exact host inputs, `CHECKING_MEDIA` / `DELETING_MEDIA` /
  `ADDING_TAGS` progress, and count publication only after successful host
  operations. The tagging plan uses the host bulk-add result count. Media
  scanning, backend operations, coroutine launch, progress execution,
  StateFlow/coroutines, lifecycle, and UI remain host-side. The pinned
  `MediaCheckViewModelTest.kt` is Copyright (c) 2026 Ashish Yadav <mailtoashish693@gmail.com> and marked
  `GPL-3.0-or-later`.
- `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DeckFilters.kt` is
  Copyright © 2026 Arthur Milchior <arthur@milchior.fr>. Its Dart adaptation is
  `lib/src/deck_filters.dart`, with locale-sensitive case handling in
  `lib/src/locale_lowercase.dart`.
- `AnkiDroid/src/main/java/com/ichi2/anki/deckpicker/DisplayDeckNode.kt` is
  Copyright © 2025 Gautam Bhetanabhotla <gautamarcturus@gmail.com>. Its Dart
  adaptation is `lib/src/display_deck_node.dart`.
- `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/ChangeNoteTypeViewModel.kt`
  is marked `GPL-3.0-or-later` and attributes source copyright to Hari
  Srinivasan. Its pure regular/cloze conversion-direction mapping and default
  field-map and discarded-field projections are adapted in
  `lib/src/change_note_type_conversion.dart`,
  `lib/src/change_note_type_default_field_map.dart`, and
  `lib/src/change_note_type_discarded_fields.dart`; the template-mapping
  default template mapping is in `lib/src/change_note_type_default_template_map.dart`; user
  update projections are in `lib/src/change_note_type_template_mapping_update.dart`
  and `lib/src/change_note_type_field_mapping_update.dart`. The pure `hasChanges`
  decision is in `lib/src/change_note_type_has_changes.dart`; discarded-template
  projection, settled eligibility predicate, tab-position mapping, and the
  `SelectedIndex` model are in `lib/src/change_note_type_discarded_templates.dart`,
  `lib/src/change_note_type_template_change_eligibility.dart`,
  `lib/src/change_note_type_tab.dart`, and `lib/src/selected_index.dart`. Collection/type
  lookup, state flow, template UI, note conversion, and sync behavior are not
  included.
- `libanki/src/main/java/com/ichi2/anki/libanki/sched/DeckNode.kt` is Copyright
  © 2020 Arthur Milchior <arthur@milchior.fr>. Its Dart input projection and
  `totalCardsDue()` behavior are in `lib/src/deck_node.dart`; the total sums
  immediate child aggregates as used by `DeckPickerViewModel.kt`, preserving
  Kotlin signed 32-bit `Int` overflow behavior. When omitted, the synthetic
  flag is derived from projected depth (`depth < 0`), matching the source's
  `node.level <= 0`; explicit Dart overrides remain available.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt`
  is marked `GPL-3.0-or-later` in its upstream header. Its reviewer action and
  queue lifecycle, including the current-card mutation readiness barrier and
  retaining a non-null post-hook queue state before answer reveal, grading from
  the post-hook state, and the last-published StudyCounts snapshot across
  timebox/loading/completion, is adapted by `lib/src/review_session.dart`; the
  upstream file does not state an individual copyright holder.
- `libanki/src/main/java/com/ichi2/anki/libanki/sched/Scheduler.kt` is Copyright
  © 2022 Ankitects Pty Ltd. The Dart adapter contract in
  `lib/src/review_session.dart` reflects its queue and answer entry points, and
  `lib/src/review_presentation.dart` reflects its `describeNextStates()` entry
  point; the Rust scheduler implementation is not included.
- `libanki/src/main/java/com/ichi2/anki/libanki/sched/Counts.kt` is Copyright
  © 2020 Arthur Milchior <arthur@milchior.fr>. Its three scheduler counts and
  queue enum are projected into `ReviewQueueCounts` and `ReviewQueueKind` in
  `lib/src/review_session.dart`.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/StudyCounts.kt`,
  `StudyCountsView.kt`, and `AnswerButtonsNextTime.kt` are marked
  `GPL-3.0-or-later` in the upstream source. Their count strings, active-queue
  condition, and four backend label assignments are adapted by
  `lib/src/review_presentation.dart`. The source's default count/active-queue
  values and last-published snapshot behavior are modeled in
  `lib/src/review_session.dart`; the Android view widgets are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt`
  is marked `GPL-3.0-or-later` upstream. Its answer-button next-time
  visibility/null-state publication decision is adapted by
  `lib/src/reviewer_answer_buttons_next_time_update.dart`; host settings and
  queue reads, scheduler calculation, coroutine and Flow delivery, call sites,
  and answer-button layout remain outside.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt`
  is marked `GPL-3.0-or-later` upstream. Its source-ordered operation-change
  callback requests are projected by `lib/src/reviewer_op_executed_effect_plan.dart`;
  the host retains `OpChanges` and handler reads, collection/card/media access,
  coroutine and Flow handling, labels, rendering, and lifecycle.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/AnswerTimer.kt`
  and `AnswerTimerState.kt` are marked `GPL-3.0-or-later` upstream. Their
  hidden/running/paused/stopped state machine is adapted in
  `lib/src/answer_timer.dart`; host lifecycle registration and timer rendering
  are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt`
  and `autoadvance/AutoAdvance.kt`, `AutoAdvanceSettings.kt`,
  `AutoAdvanceAction.kt`, `QuestionAction.kt`, and
  `AnswerAction.kt` are marked `GPL-3.0-or-later` upstream. Their settings
  contract, action codes, delay dispatch, and cooperative in-flight cancellation
  signal are adapted
  in `lib/src/auto_advance.dart`; the Android collection settings lookup and
  reviewer action routing are not included. `toggleAutoAdvance()` state/effect
  ordering is separately projected in
  `lib/src/reviewer_auto_advance_toggle.dart`; settings, localization, media
  state, timer operations, and StateFlow remain host-side. The
  `answerCardInternal()` operation order is projected in
  `lib/src/reviewer_answer_card_effect_plan.dart`; mutation/queue/card Flows,
  scheduler computation, collection access, undoable persistence, leech
  detection, card reload/queue lookup, localization, feedback delivery,
  logging and lifecycle remain host-side. The source's negative-queue-code
  suspension decision is projected in that helper. Leech feedback text
  composition is projected in `lib/src/reviewer_leech_feedback.dart`;
  localization and flow delivery remain host-side. Whiteboard toggle
  state/preference ordering is
  projected in `lib/src/reviewer_whiteboard_toggle.dart`; StateFlow mutation,
  repository access/write, action dispatch and UI remain host-side.
  Record-voice toggle state/preference ordering is projected in
  `lib/src/reviewer_record_voice_toggle.dart`; StateFlow mutation, repository
  access/write, action dispatch and recorder lifecycle remain host-side.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/whiteboard/WhiteboardViewModel.kt`
  declares `SPDX-License-Identifier: GPL-3.0-or-later`; its header contains no
  separate copyright line. Completed-add, clear, undo, redo and reset history
  transitions are adapted in `lib/src/whiteboard_drawing_history.dart`. The
  Dart model is Copyright © 2026 John Tsui and marked `GPL-3.0-or-later`. Path
  values remain opaque; Android `Path` geometry, erase gestures, StateFlow,
  ViewModel lifecycle, repository behavior, rendering and UI stay host-side.
  Brush and eraser tool state decisions from that same source, including
  source-ordered persistence requests, are adapted in
  `lib/src/whiteboard_tool_state.dart`; `BrushInfo` and default width values
  are drawn from `WhiteboardRepository.kt`, which also declares
  `SPDX-License-Identifier: GPL-3.0-or-later` and no separate copyright line.
  The host supplies loaded preferences and the current eraser display width and
  performs repository IO; Android SharedPreferences, StateFlow, lifecycle,
  flows, gestures, rendering and UI remain host-side. The Dart tool-state model
  is Copyright © 2026 John Tsui and marked `GPL-3.0-or-later`.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/GestureParser.kt`
  and `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/Gesture.kt` declare
  `GPL-3.0-or-later`. Their gesture enums, decoded-input decisions, viewport
  mapping, tap timing, and cancellation of pending delayed taps are adapted in
  `lib/src/gesture_parser.dart`; Android Uri/WebView/preferences integration is
  not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/GestureProcessor.kt`,
  `Gesture.kt`, and `ViewerCommand.kt`, together with
  `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/ReviewerBinding.kt` and
  `Binding.kt`, declare `GPL-3.0-or-later`. Their gesture-to-command mapping,
  command identifiers/order, corner gating, and execution-result behavior are
  adapted in `lib/src/gesture_command_router.dart`; Android preference lookup,
  input events, and command handlers are not included.
  The `ViewerCommand.defaultValue` lists are adapted in
  `lib/src/reviewer_command_defaults.dart`, preserving symbolic key names,
  Unicode values, sides, modifiers, order, and empty entries. The host supplies
  numeric Android key-code mappings. `ReviewerBindingPreferenceResolver` in
  `lib/src/reviewer_binding_preference_resolver.dart` uses defaults only when
  the host supplies a null preference; every configured string replaces them
  through the codec, including empty and malformed values. Preference lookup
  remains with the host.
- `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/AnswerButtons.kt` and
  `AutomaticAnswer.kt` declare `GPL-3.0-or-later`. Their answer-rating to
  `ViewerCommand` mapping, automatic-action config values, unknown-value
  fallback, and optional command result are adapted in
  `lib/src/reviewer_answer_action.dart`. The upstream REUSE annotation attributes
  Kotlin source copyright to Contributors to the AnkiDroid project. Deck-config
  access, command execution, logging, and localized reminder UI remain with the
  host.
- `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/MappableBinding.kt`,
  `ReviewerBinding.kt`, `Binding.kt`, `Axis.kt`, and `CardSide.kt` declare
  `GPL-3.0-or-later`. Their serialized reviewer-binding codec and gesture
  preference adapter are adapted in `lib/src/reviewer_binding_codec.dart` and
  `lib/src/gesture_command_router.dart`. Serialized key-code and Unicode
  bindings, modifiers, validity, card-side behavior, and source equality/hash
  quirks are represented as typed values; axis IDs, Java float parsing, and
  source-style Float serialization are retained. Android preference lookup,
  `KeyEvent` extraction, platform `getUnicodeChar()` calculation,
  MotionEvent extraction and device handling, display strings, Android `BindingProcessor`
  wiring, and command execution are not included. The
  headless key/gesture registration and lookup behavior from
  `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/BindingMap.kt` is adapted in
  `lib/src/reviewer_binding_map.dart`; axis registrations are retained there.
  Their threshold and debounce behavior over host-provided Float32 values is
  adapted in `lib/src/reviewer_axis_dispatch.dart`. Projected key candidate
  construction and sequential dispatch are adapted in
  `lib/src/reviewer_key_dispatch.dart`; the host must supply the Unicode result
  computed with the Shift/NumLock meta-state mask.
- `compat/src/main/java/com/ichi2/anki/compat/BaseCompat.kt` is Copyright
  © 2017 Profpatsch <mail@profpatsch.de>. Its fallback gesture-axis IDs are
  referenced by the codec's syntax check; the compatibility layer itself is
  not ported.
- `libanki/src/main/java/com/ichi2/anki/libanki/DeckConfig.kt` is Copyright
  © 2020 David Allison <davidallisongithub@gmail.com> and Arthur Milchior
  <Arthur@Milchior.fr>. Its Auto Advance fields and defaults remain behind the
  `AutoAdvanceSettingsAdapter`; the Dart port does not copy its storage access
  or property wrappers.
- `libanki/src/main/java/com/ichi2/anki/libanki/Collection.kt` contains
  `Collection.TimeboxReached`, Copyright © 2026 Mike Hardy
  <github@mikehardy.net>. Its `secs` and `reps` payload is adapted by
  `ReviewTimeboxReached` in
  `lib/src/review_session.dart`. The source timebox counter and its automatic
  restart are adapted in `lib/src/review_timebox.dart`; clock, scheduler limit,
  and answer-count values remain adapter inputs.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerFragment.kt`
  declares `GPL-3.0-or-later`. Its `secs / 60f` rounded-minute projection is
  adapted in `lib/src/review_timebox.dart`; localized text and the Android
  dialog are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/previewer/PreviewerViewModel.kt` and
  `CardViewerViewModel.kt` declare `GPL-3.0-or-later`. The portable
  `CardViewerViewModel.setSoundPlayerEnabled()` and `playSoundFromUrl()` callback
  order is adapted in `lib/src/card_viewer_sound_actions.dart`, with
  source-derived cases in `test/card_viewer_sound_actions_test.dart`. The host
  retains task scheduling, AV URL parsing and collection callbacks, player
  implementation, and asynchronous error handling. `servicelayer/NoteService.kt`
  is Copyright © 2013 Bibek Shrestha, Zaur Molotnikov, Nicolas Raoul, and Flavio
  Lerda and declares `GPL-3.0-or-later`. Previewer navigation
  formulas and side/card transitions are adapted in
  `lib/src/previewer_navigation.dart`. Its flag codes and set/toggle choice with
  ordered write-then-publish-on-success effects are adapted in
  `lib/src/previewer_flag_effects.dart`; collection/undo execution, current-card
  lookup and StateFlow publication remain outside.
  The `toggleMark()` operation order is adapted as host effects in
  `lib/src/previewer_mark_effects.dart`; current note resolution, tag mutation,
  undoable persistence, marked-state lookup, error handling, and StateFlow
  delivery remain outside. `CardViewerViewModel.showQuestion()` order is adapted
  in `lib/src/card_viewer_show_question_effects.dart`, with source-derived tests
  in `test/card_viewer_show_question_effects_test.dart`; collection/card access,
  media operations, type-answer filtering, JSON encoding, body-class lookup,
  eval delivery, coroutines, media/lifecycle, and UI remain with the host.
  `CardViewerViewModel.handlePostRequest()` routing is adapted in
  `lib/src/card_viewer_post_routing.dart`, with source-derived cases in
  `test/card_viewer_post_routing_test.dart`; the exact `i18nResources` response
  is returned unchanged. URI parsing/rendering, byte transport, resource lookup,
  Android/coroutine/API exceptions, and HTTP handling remain with the host.
  `AnkiDroid/src/main/java/com/ichi2/anki/servicelayer/NoteService.kt`
  is Copyright © 2013 Bibek Shrestha <bibekshrestha@gmail.com>, Zaur
  Molotnikov <qutorial@gmail.com>, Nicolas Raoul <nicolas.raoul@gmail.com>, and
  Flavio Lerda <flerda@gmail.com>. Its pure mark-tag action and
  tag-before-undoable-update plan is in
  `lib/src/note_mark_toggle.dart`; tag mutation, collection-aware lookup,
  `updateNote`, and `undoableOp` remain host-side.
- `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/CardAppearance.kt` and
  `AnkiDroid/src/main/java/com/ichi2/anki/reviewer/ReviewerCustomFonts.kt`
  are part of the GPL-3.0-or-later AnkiDroid source. Their CSS zoom appending,
  exact OpenSans CSS prefix composition, bold-weight string replacement, and
  class suffix/card-class projections are adapted in
  `lib/src/card_appearance_css.dart`, reusing the internal Java Float formatter
  in `lib/src/java_float_format.dart`. The host supplies font scale, zoom
  preferences, current-theme projection, and centering state. Font resource
  installation/selection, theme selection/preferences/CSS, vertical-centering
  styles, AndroidCardRenderContext audio and MathJax rendering, WebView
  textZoom, and full rendering remain outside. The pinned test tree has no direct
  assertions for `ReviewerCustomFonts.updateCssStyle()`,
  `CardAppearance.fixBoldStyle()`, `getCssClasses()`, or `getCardClass()`; those
  Dart cases are source-derived. The upstream `ReviewerCustomFonts.kt` header
  attributes Copyright © 2013 Flavio Lerda <flerda@gmail.com>.
- `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/CardTemplate.kt`
  declares `GPL-3.0-or-later`. Its first-marker section segmentation and ordered
  HTML-string composition, including the `RenderedCard` value, are adapted in
  `lib/src/card_template.dart`. A missing style marker retains the uncaught
  negative-`take` argument failure as Dart `ArgumentError`; invalid later
  boundaries map to `StateError` with the pinned source message. The pinned
  `CardTemplateTest.kt` directly covers canonical replacement and a 1,000-
  character insertion; malformed-marker cases are source-derived. The host
  supplies the template string; Android asset loading, full card rendering and
  media-reference expansion, and WebView integration remain outside this
  slice. Resolved sound markup is separately listed below.
- `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/AndroidCardRenderContext.kt`
  declares `GPL-3.0-or-later`. Its private `enrichWithQADiv()` string wrapper is
  adapted as `wrapCardContentInQaDiv()` in `lib/src/card_template.dart`; content
  is inserted verbatim between the exact source tags. The pinned tests do not
  directly cover this private helper, so Dart assertions are source-derived.
  Android-side filtering, full media-reference expansion, bold rewriting,
  rendering, and caller orchestration remain outside this slice. Resolved
  sound markup is separately listed below.
- `AnkiDroid/src/main/java/com/ichi2/anki/multimedia/SoundUtils.kt` is
  Copyright © 2009 Edu Zamora <edu.zasu@gmail.com> and © 2014 Timothy rae
  <perceptualchaos2@gmail.com>, and is marked GPL-3.0-or-later. Its source
  audio-button and video-element string projections for already-resolved media
  references are adapted in `lib/src/card_media_markup.dart`. The host supplies
  the audio/video kind, play side/index, video URI, and HTML-escaped filename;
  reference parsing/replacement, media-type and file resolution, playback, and
  WebView integration remain host-side. `libanki/Sound.kt` contains separately
  AGPL-incorporated parser code and is not adapted by this module.
- `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/TypeAnswerModifiers.kt`
  declares `GPL-3.0-or-later`. Its source-prefix parsing and four-field value
  semantics are adapted in `lib/src/type_answer_modifiers.dart`; field lookup,
  cloze-content invocation, answer comparison, template rendering, and Android
  input integration are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/previewer/TypeAnswer.kt` declares
  `GPL-3.0-or-later`. Its `removeTags` regex behavior is adapted as the pure
  question-side `removeTypeAnswerTags` function in `lib/src/type_answer_tags.dart`.
  Previewer integration, field lookup, answer comparison,
  rendering, and Android input remain outside this port.
- `AnkiDroid/src/main/java/com/ichi2/anki/previewer/TemplatePreviewerViewModel.kt`
  declares `GPL-3.0-or-later`. Its question-side `typeAnsFilter` marker
  replacement is adapted as `filterTemplatePreviewerTypeAnswerQuestion` in
  `lib/src/type_answer_question.dart`; Previewer state, warning localization,
  and rendering remain host-side.
- `AnkiDroid/src/main/java/com/ichi2/anki/cardviewer/TypeAnswer.kt` declares
  `GPL-3.0-or-later`. Its question-prompt transformation in `filterQuestion`
  is adapted as `filterTypeAnswerQuestion` in
  `lib/src/type_answer_question.dart`. The host supplies the extracted prompt
  state. Its `filterAnswer` placeholder replacement is adapted as
  `filterTypeAnswerAnswer` in `lib/src/type_answer_answer.dart`; the host
  supplies already-computed comparison HTML. Its pure `contentForCloze`
  extraction is adapted as `typeAnswerContentForCloze` in
  `lib/src/type_answer_cloze.dart`; its `updateInfo` marker-to-index projection
  is also adapted there as `typeAnswerDeclarationForQuestion` and
  `typeAnswerClozeIndexForQuestion`. The host supplies the rendered question,
  card ordinal, and field text. The Rust comparator,
  card/template and answer lookup, Android state delivery, cloze-content
  invocation, Android input lifecycle and JavaScript integration, and card
  rendering remain outside this port. The `updateInfo` field/result decision is
  adapted as `resolveTypeAnswerFieldResult` in
  `lib/src/type_answer_field_result.dart`; the host supplies ordered field
  metadata, note values, cloze index, and already-localized warnings. The
  projection preserves first exact-name match, copied font/size/language hint,
  no-match metadata retention, and the source's distinct warning behavior for
  null, empty, and nonempty results. Field lookup, warning localization, and
  state delivery remain host-side. The full pure `updateInfo` branch/effect
  order is projected as `planTypeAnswerInfoUpdate` in
  `lib/src/type_answer_info_update.dart`; the host applies the assignments in
  order and handles Android/collection/resource access and source-equivalent
  failure delivery. The pinned test tree has no direct `updateInfo` test.
  The pure `validForEditText` and `autoFocusEditText` checks are adapted as
  `typeAnswerValidForEditText` and `typeAnswerAutoFocusEditText` in
  `lib/src/type_answer_eligibility.dart`. They preserve the non-null check
  (including an empty string) and exact `useInputTag`/`autoFocus` gates; the
  host handles field visibility and Android focus/input lifecycle. No direct
  pinned tests cover these predicates.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserColumnCollection.kt`
  and `CardBrowserColumn.kt` declare `GPL-3.0-or-later`. Column-key parsing,
  load-time fallback/de-duplication, nullable updates and replacement are
  adapted in `lib/src/browser_column_collection.dart`; successful updates can
  retain duplicates until a later load removes them, as in the source. The host
  supplies the current Cards/Notes mode, and the same file maps all column types
  from `CardBrowserColumn.kt`, including `template` as TEXT for Cards and
  NUMERIC for Notes and `cardDue` as UNSPECIFIED. Mode/config lookup, mode-specific
  defaults from `BrowserConfig.kt` (whose constants incorporate upstream AGPL
  code and are not copied), SharedPreferences, labels/tooltips, backend column
  values and browser UI remain outside.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserColumnSelectionAdapter.kt`
  and `AnkiDroid/src/main/java/com/ichi2/anki/utils/ext/MutableList.kt` declare
  `GPL-3.0-or-later`; their row movement-capability and adjacent-swap plan are
  adapted in `lib/src/browser_column_selection_move.dart`. It preserves the
  literal target-position-zero guard and accepted same-position no-op; the host
  applies swaps and handles RecyclerView notifications, drag lifecycle and the
  column-selection UI.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserColumnSelectionAdapter.kt`
  and `BrowserColumnSelectionFragment.kt` declare `GPL-3.0-or-later`. The pure
  click-toggle target/side projection is adapted in
  `lib/src/browser_column_selection_toggle.dart`: it locates the first
  AVAILABLE heading in the host-projected row kinds, preserves the source's
  `< heading` side test, and applies the original-index remove-then-insert move
  without validation. If the heading is missing, insertion uses `-1` and can
  fail after removal, as in the source. Android click wiring, RecyclerView
  notifications, and dialog lifecycle remain host-side.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserColumnSelectionFragment.kt`
  and `CardBrowserViewModel.kt` declare `GPL-3.0-or-later`. Their pure save
  decision is adapted in `lib/src/browser_column_selection_save.dart`: it
  preserves the ordered-list comparison, the pre-update dismissal when there
  are no changes, the unconditional update call, and the later success-dismiss
  or failure-message result. Thus the source's no-change fall-through can
  produce an initial dismissal followed by the no-columns message. Preference
  and backend updates, Android dialog lifecycle, and localized snackbar
  delivery remain host-side. No direct pinned save-handler test was found;
  Dart coverage is source-derived.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserColumnSelectionFragment.kt`
  and `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/DiscardChangesDialog.kt`
  declare `GPL-3.0-or-later`. The pure Back/discard projection is adapted in
  `lib/src/browser_column_selection_discard.dart`: the host supplies the current
  discard-callback enabled state, and the plan distinguishes default Back
  handling from opening the discard dialog. A positive confirmation emits
  disable-guard then redispatch-back effects in source order; cancellation
  emits none. The Android dispatcher, dialog callback/lifecycle and delivery
  remain host-side. No direct pinned Back-flow test was found; Dart coverage is
  source-derived.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserColumnSelectionAdapter.kt`
  declares `GPL-3.0-or-later`. Its pure displayed/available/selected row
  projection is adapted in `lib/src/browser_column_selection_projection.dart`:
  the first Available heading determines the strict index split, heading rows
  are excluded, and a missing heading preserves the source `-1` behavior.
  Labels/samples, RecyclerView state and notifications, saving, and state
  restoration remain host-side. The pinned screenshot and touch-helper tests do
  not directly assert these getters; Dart coverage is source-derived.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/CardOrNoteId.kt`,
  `AnkiDroid/src/main/java/com/ichi2/anki/browser/BrowserRowCollection.kt`, and
  `AnkiDroid/src/main/java/com/ichi2/anki/model/CardsOrNotes.kt` declare
  `GPL-3.0-or-later`. Their Cards/Notes-associated row ID and collection
  projections are adapted in `lib/src/browser_row_collection.dart`. The host
  supplies collection callbacks for card-to-note and note-to-card lookups. The
  port preserves the source's note-ID snapshot before asynchronous note-to-card
  expansion even if the aliased row list changes while lookups are pending.
  Empty Notes-row queries return an empty list without invoking or requiring the
  lookup callback, as the pinned source's list transforms do not invoke their
  lambdas for an empty row list; nonempty row lookups remain host-side. Android
  collection access, backend row data, and sorting are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/CardBrowserViewModel.kt` and
  `common/src/main/java/com/ichi2/anki/common/utils/ext/List.kt` declare
  `GPL-3.0-or-later`. `browserRowPositionOfId()` in
  `lib/src/browser_row_collection.dart` adapts the first-match index-or-null
  lookup; Android scrolling, notifications, and layout offsets remain host-side.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/CardBrowserFragment.kt`
  declares `GPL-3.0-or-later`. `browserPaneRowNotificationPositions()` in
  `lib/src/browser_row_collection.dart` adapts its ordered, distinct pane-row
  lookup to current adapter positions; pane-state mutation and Android adapter
  notifications remain host-side.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/CardBrowserFragmentViewModel.kt`
  declares `GPL-3.0-or-later` and has no separate copyright holder in its source
  header. Its `openDeckSelectionDialog()` request, annotated
  `@NeedsTest("default usage")`, is represented by the payload-free
  `BrowserOpenDeckSelectionDialogRequest` in
  `lib/src/browser_open_deck_selection_dialog_request.dart`. No direct unit test
  for this request was found upstream; the Dart declaration is source-derived.
  The host retains SharedFlow delivery, coroutine/Job scheduling, dialog
  construction, Fragment lifecycle, and UI; no Android flow runtime is ported.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/CardBrowserViewModel.kt`
  declares `GPL-3.0-or-later`. Its `RowSelection` value and selected-row toggle
  state projection are adapted in `lib/src/browser_row_selection.dart`, which
  retains source insertion order, mode-change causes, last-selected ID, and
  refresh behavior. Upstream `CardBrowserViewModelTest.kt` directly exercises
  multi-select tap outcomes; the pure value-projection cases are source-derived.
  Its `onTap` branch and `setNoteEditorRow` effect order are projected by
  `lib/src/browser_row_activation.dart`: normal taps route to a pane or
  activity, while only deselecting an already selected row in fragmented mode
  adds a pane reload after the selection toggle. Upstream
  `CardBrowserViewModelTest.kt:1395–1472` directly covers the major tap
  branches. The host applies Android flows, selection widgets, pane/mode state,
  collection-backed destination lookup, and note-editor commands.
  Its initial `getInitialDeck()` selection is projected in
  `lib/src/browser_initial_deck.dart`, preserving launch-intent consumption,
  intent/persisted/all-decks precedence, and host-selected fallback. Android
  state persistence, intent/deck lookup, collection reads, and `setSelectedDeck`
  remain host-side. The direct ViewModel tests cover intent and persisted ID
  behavior and user-choice persistence; unasserted branches are source-derived.
  Its `toggleMark()` all-or-none target decision is projected by
  `planBrowserBulkMarkToggle()` in `lib/src/browser_bulk_mark.dart`: no selected
  card IDs means no operation; otherwise any unmarked note selects adding the
  `marked` tag, while all marked notes select removal. The source's empty-note
  `all()` behavior is retained. `CardBrowserViewModelTest.kt:792–804` directly
  covers adding the mark to unmarked notes with selection retained; other
  branch/edge cases are source-derived. Note/tag lookup, undoable collection
  mutation, and post-success card-state flow publication remain host-side.
  Its `toggleBury()` decision and `BuryResult` values are projected by
  `planBrowserBulkBuryToggle()` and `BrowserBulkBuryPlan` in
  `lib/src/browser_bulk_bury.dart`. The source tests cover the main single/mixed
  branches, no-selection behavior, and manual-buried queue change; sibling
  burial, empty resolved IDs and projection-value checks are source-derived.
  The host checks selection before resolving card IDs, maps queue states,
  performs the undoable scheduler operation, and exposes the result only after
  success.
  Its `toggleSuspendCards()` all-or-none decision is projected by
  `planBrowserBulkSuspendToggle()` and `BrowserBulkSuspendOperation` in
  `lib/src/browser_bulk_suspend.dart`: all selected card queues must be
  `Suspended` to select unsuspending; a mixed or unsuspended set selects
  suspending. The source's empty `all()` behavior is retained. Direct
  `CardBrowserViewModelTest.kt:662–749` cases directly exercise no-selection,
  all-suspended, mixed, and none-suspended behavior in Cards mode and
  no-selection/all-suspended/mixed behavior in Notes mode; the later
  none-suspended Notes helper is not annotated as a test. Queue-projection
  order and empty resolved IDs are source-derived. The host
  checks row selection before resolving card IDs, performs queue lookup and the
  selected scheduler call inside its undoable operation, and owns execution.
  Its `prepareToRepositionCards()` partition and `canRepositionCard()` rule are
  represented by `planBrowserRepositionCards()` and `BrowserRepositionPlan` in
  `lib/src/browser_reposition_plan.dart`. Host-resolved type-New or queue-New
  cards remain eligible; both eligible and skipped IDs preserve selected-row
  order, and skipped count is exact after a full scan. The pinned tests directly
  cover mixed New/Review count, all-New, suspended-New eligibility, and the
  all-ineligible error (`CardBrowserViewModelTest.kt:1063–1147`); order and
  queue-only eligibility cases are source-derived. The host resolves selected
  card IDs and queue/type state, scans the collection, computes queue bounds,
  applies scheduler defaults, and performs or reports repositioning.
  `projectBrowserRepositionPresentation()` and its typed resource/directive
  values in `lib/src/browser_reposition_presentation.dart` map the fragment's
  error, missing-bound, and valid-bound result branches. The upstream ViewModel
  tests cover source request results and bounds, but no pinned test directly
  asserts the fragment's presentation branches; the Dart mapping tests are
  source-derived. Resource resolution, task launching, actual UI construction
  and delivery, and repositioning remain host-side.
  `RepositionData` min/max normalization is represented by
  `BrowserRepositionQueueBounds` and `projectBrowserRepositionQueueBounds()` in
  `lib/src/browser_reposition_queue_bounds.dart`: two present values are
  ordered into top/bottom, while either missing value clears both; equal and
  negative values are retained. ViewModel integration tests cover normal bounds
  for regular and suspended-new cards, but not the constructor directly;
  reversed/equal/negative/null cases are source-derived. SQL lookup and the
  source `max(0,minDue)` behavior remain host-side.
  The host-read due extrema mapping at `CardBrowserViewModel.kt:1125–1138` is
  projected by `projectBrowserRepositionDueExtrema()` in
  `lib/src/browser_reposition_due_extrema.dart`: only minDue is clamped to zero,
  maxDue is preserved, and the result reuses the queue-bounds projection. SQL
  and cursor work, scheduler defaults and execution remain host-side. The pinned
  ViewModel test covers ordinary positive values; negative min/max cases are
  source-derived.
  `requestChangeNoteType()` at `CardBrowserViewModel.kt:383–394` is represented
  by `planBrowserChangeNoteType()` and `BrowserChangeNoteTypePlan` in
  `lib/src/browser_change_note_type_plan.dart`. It checks host-supplied note IDs
  against the first selected note type's membership set, then deduplicates
  compatible IDs in selected order. Upstream tests directly cover no selection,
  mixed types, and same-type single/multiple notes; duplicate order and explicit
  membership cases are source-derived. Note-type resolution, collection queries,
  flow publication, snackbar/dialog delivery and the change itself remain
  host-side.
  `CardBrowserFragment.onChangeNoteType()` at `CardBrowserFragment.kt:1225–1230`
  is represented by `projectBrowserChangeNoteTypePresentation()` in
  `lib/src/browser_change_note_type_presentation.dart`: NoSelection has no
  user-visible action, MixedSelection carries the source snackbar resource, and
  ChangeNoteType carries the response IDs unchanged to a dialog directive. No
  pinned test directly invokes the Fragment presenter; the ViewModel tests cover
  response values, while these mappings are source-derived. Logging, flow
  collection, resource/UI work and subsequent note-type change remain host-side.
  `toHumanReadableContent()` at `CardBrowserViewModel.kt:1794–1798` is adapted
  by `projectBrowserRepositionSummary()` in
  `lib/src/browser_reposition_summary.dart`: host-supplied localized top and
  bottom lines are joined with one newline, or null is returned if either bound
  is missing. The pinned ViewModel test directly asserts normal summary text;
  missing-bound tests are source-derived. Resource resolution and localization
  remain host-side; this helper has no production caller in the pinned source.
  Its `updateSelectedCardsFlag()` write/event/return sequence is represented by
  `planBrowserSelectedCardsFlagUpdate()` and `BrowserSelectedCardsFlagPlan` in
  `lib/src/browser_selected_flag_plan.dart`. The host supplies selected card
  IDs and the source flag value; the plan preserves that list and flag, orders
  the write before card-state-changed publication, and retains the source's
  no-guard behavior for an empty list. No pinned test directly covers this
  method, so these Dart cases are source-derived. The host resolves IDs,
  performs the undoable write, delivers the event only after success, and
  returns the IDs after the sequence completes.
  `selectAll()`, `selectNone()` and `toggleSelectAllOrNone()` are projected by
  `BrowserBulkSelectionTransition` and the `planBrowserSelect*` functions in
  `lib/src/browser_row_selection.dart`. Select-all appends new distinct rows in
  linked-set order and emits the source multi-select `Other` cause before row
  refresh; select-none copies previous IDs, clears the rows, and refreshes while
  retaining multi-select mode. The toggle follows the current cached
  SELECT_ALL/SELECT_NONE state supplied by the host. The pure
  `projectBrowserSelectAllOrNoneState()` also applies the source visible-row
  rule, direct `>= rowCount` comparison, and initial SELECT_NONE value. The
  pinned `CardBrowserViewModelTest.kt:1316–1329,1361–1375` covers initial,
  partial, full and mode-integrated outcomes; hidden-selection, duplicate-ID,
  zero/negative-count projection cases and immutable projection/no-op/effect-
  order assertions are source-derived. The source mutates its synchronized set
  in place; the pure Dart results are ordered immutable snapshots. Row loading,
  StateFlow scheduling/coroutine delivery, and selection widgets remain
  host-side.
  `selectedNoteCount()` at `CardBrowserViewModel.kt:931` applies
  `distinct().size` to note IDs from `BrowserRowCollection.queryNoteIds()`,
  represented by `browserSelectedNoteCount()` in
  `lib/src/browser_row_selection.dart`. The host supplies IDs after the
  Cards/Notes collection lookup. No pinned test directly exercises the count;
  the Dart empty/duplicate/unique-ID cases are source-derived. The localized
  delete-menu plural and UI remain host-side.
  `hasSelectedAllDecks()` at `CardBrowserViewModel.kt:933–935` is represented by
  `browserHasSelectedAllDecks()` in `lib/src/browser_search_request.dart`; it
  returns true only when the deck-filter list is empty and ignores other filter
  fields and available rows. Direct ViewModel tests at
  `CardBrowserViewModelTest.kt:274–290,1531–1574` cover its selected-deck and
  search-result use; the Dart unrelated-filter case is source-derived. Current
  search-flow values, result-message delivery, localization, and UI stay
  host-side.
  `querySelectionExportData()` is projected by `planBrowserSelectionExport()`
  and `BrowserSelectionExportPlan` in `lib/src/browser_selection_export.dart`.
  It returns no plan for an empty selected set; otherwise it chooses Cards or
  Notes export type from the supplied mode and copies raw row IDs in linked-set
  iteration order. Direct `CardBrowserViewModelTest.kt:761–790` covers the
  empty, one-card, and one-note cases; ordering and list-copy checks are
  source-derived. The host handles the export dialog, cache/file preparation,
  and actual export; this port does not implement export formats or execution.
  `setFlagFilter()` at `CardBrowserViewModel.kt:1236–1245` builds a legacy
  `flag:<code>` query from the current search terms; the pure transformation is
  represented by `browserSearchTermsWithFlag()` in
  `lib/src/browser_flag_filter_query.dart`. `BrowserFlagFilterSearchPlan` in
  `lib/src/browser_flag_filter_search_plan.dart` adds the ordered query-emission,
  request-update, and default-refresh-search effects while preserving request
  filters. The transformation preserves the source's case-sensitive substring
  check, first unanchored `flag:.` replacement, one-character consumption,
  nonempty-query prepend, and unmatched incomplete-marker behavior. `Flag.kt`
  source values supply the integer code to the host. `CardBrowserViewModelTest.kt:293–307`
  tests RED filtering end-to-end but does not assert the constructed text or
  ordered effects, so these Dart cases are source-derived. The host owns flag
  resolution/UI, flow and request-state mutation, and backend search.
  `libanki/src/main/java/com/ichi2/anki/libanki/Consts.kt` is Copyright (c) 2014
  Houssam Salem and is licensed GPL-3.0-or-later; the host maps its
  `QueueType.Suspended` identity to the headless enum.
- `AnkiDroid/src/main/java/com/ichi2/anki/model/SortType.kt`,
  `libanki/src/main/java/com/ichi2/anki/libanki/SortOrder.kt`, and typed config
  decoding in `libanki/src/main/java/com/ichi2/anki/libanki/Config.kt` declare
  `GPL-3.0-or-later`. Sort-type resolution and ordered save plans are adapted in
  `lib/src/browser_sort_type.dart`; the model receives the active mode's config
  keys, values, and backend column keys from its host. It preserves the shared
  defaults missing or incorrectly typed config values to the source defaults
  and preserves the shared no-sorting flag behavior, including its effect
  across both modes. It does not
  access Android preferences, collection config, or perform backend sorting.
  `BrowserConfig.kt` constants and lookup code are not copied.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/CardBrowserLaunchOptions.kt`
  and the related extra names in `CardBrowserViewModel.kt` are declared
  `GPL-3.0-or-later`. Their ordered deep-link, JavaScript-search, card-ID, and
  process-text option projection is adapted in
  `lib/src/browser_launch_options.dart`. The host supplies already-decoded
  values; Android Intent/Uri access and navigation remain outside.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/SearchHistory.kt`,
  `AnkiDroid/src/main/java/com/ichi2/anki/Flag.kt`, and
  `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/CardState.kt` declare
  `GPL-3.0-or-later`; `libanki/src/main/java/com/ichi2/anki/libanki/PythonTypes.kt`
  (Copyright © 2021 David Allison, GPL-3.0-or-later) defines the signed-long
  `DeckId` and `NoteTypeId`. Search-history equality,
  blank detection, recency/eviction, and compact JSON encoding/decoding are
  adapted in `lib/src/browser_search_history.dart` and
  `lib/src/browser_search_history_json.dart`. The codec preserves source field
  names/order and invalid-whole-list fallback; the host handles SharedPreferences
  and entries may contain user-provided search text and filters.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/CardBrowserSearchViewModel.kt`
  and `SearchString.kt` declare `GPL-3.0-or-later`. The view-model's
  Loading/Loaded recent-history display projection, collapsed five-entry limit,
  expansion state, and toggle threshold are adapted in
  `lib/src/browser_search_history_display.dart`; SavedStateHandle, StateFlow,
  search-string conversion, and Android widgets remain outside.
  The history and saved-search availability projections from
  `searchHistoryAvailableFlow` and `canManageSavedSearchesFlow` are adapted in
  `lib/src/browser_availability.dart`; the host supplies the current values and
  owns flow updates and widgets.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/CardBrowserSearchViewModel.kt`,
  `SearchFilters.kt`, and `SearchRequest.kt` declare `GPL-3.0-or-later`. Their
  structured history/request transformations are adapted in
  `lib/src/browser_search_request.dart`. The host supplies deck and note-type
  name/ID values; only those mapping fields are represented from `Decks.kt` and
  `Notetypes.kt`. `Decks.kt` is Copyright © 2025 David Allison; `Notetypes.kt`
  credits Daniel Svärd, Rick Gruber-Riemer, Norbert Nagold, Kostas Spyropoulos,
  and David Allison. Both files also identify separately incorporated AGPL
  material; none of that backend implementation is copied here. Collection
  access, backend query generation, and execution are not included. The Dart
  `BrowserNoteTypeNameId` constructor is intentionally non-const so equal-field
  instances retain identity semantics rather than Dart const canonicalization;
  callers should construct ordinary mapping instances. No pinned test directly
  checks this equality rule; the added assertion is source-derived. The view
  model's `FilterUpdate` origin and one-snapshot request projection are adapted
  in `lib/src/browser_filter_update.dart`; StateFlow/coroutine timing and
  application of field-specific setter updates remain with the host. The four
  Card Browser filter setter projections in that file preserve the source
  `SearchFilters.copy(field = incomingList)` behavior: each returns a User
  update without equality suppression, retains the incoming list reference,
  and reuses other field lists. `SearchFiltersTest.kt` does not directly test
  the ViewModel setters, so the new setter cases are source-derived. The
  Basic/Advanced text buffers and transition methods are adapted in
  `lib/src/browser_search_text_state.dart`; SavedStateHandle persistence,
  flow scheduling, and Android text widgets remain with the host.
  The ordered `onSearchTextChanged` effects are projected in
  `lib/src/browser_search_state_effects.dart`: a shallow-copied User filter
  update precedes text replacement in the active buffer. LF is replaced while
  CR and other characters remain unchanged; no request or close event is
  emitted. The pinned text tests do not assert this combined effect order, so
  the corresponding Dart cases are source-derived.
  The ordered effects for `selectSearchHistoryEntry` and its LF-only text edit
  are projected in `lib/src/browser_search_state_effects.dart`, reusing the
  host-mapped history restoration; the host applies flows and performs search
  submission. The pinned test named “selecting search history entry” calls the
  `submitSearch` helper rather than this method, so the selection sequence is
  covered by source-derived Dart cases rather than a direct upstream test. No
  pinned test directly covers host-map restoration through `SearchFilters.from`.
  The source `syncState` and `resetSearchState` method call order is projected
  as typed effects in `lib/src/browser_search_state_effects.dart`. The reset
  preserves the exact query and omits `historyExpanded` from the three ordered
  key removals. The host performs the StateFlow and SavedStateHandle operations;
  the source marks reset `@NeedsTest("reset")` and has no direct reset or sync
  test. The `submitCurrentSearch(SearchRequest)` overload is also projected in
  `lib/src/browser_search_state_effects.dart`: it records the trimmed ID-based
  history entry using the existing recency rules, publishes the updated history
  as Loading, then emits the close-view event and exact submitted request. It
  does not set screen-open state or execute the search. The pinned view-model
  test helper calls the no-argument submit overload instead, so its ordered
  effects are covered by source-derived Dart tests, not a direct upstream test.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/SearchRequest.kt`,
  `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/SearchFilters.kt`,
  `AnkiDroid/src/main/java/com/ichi2/anki/Flag.kt`, and
  `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/CardState.kt` declare
  `GPL-3.0-or-later`. Their pre-backend
  query and filter-node construction behavior is represented in
  `lib/src/browser_search_node_plan.dart`; Kotlin-compatible whitespace
  trimming is shared through `lib/src/kotlin_whitespace.dart`. The plan keeps
  stored flag/card-state codes separate from semantic search values and models
  query inclusion and boolean grouping. `Collection.kt` is GPL-3.0-or-later,
  Copyright © 2011 Norbert Nagold, 2012 Kostas Spyropoulos, and 2022 Ankitects;
  only its `groupSearches()` singleton-collapse behavior is referenced. That
  file also incorporates separate AGPL-3.0-or-later code, which is not copied
  into this port. The backend protobuf SearchNode, parser/validation,
  SearchString serialization, and execution are not included.
- `AnkiDroid/src/main/java/com/ichi2/anki/browser/search/SavedSearches.kt`
  declares `GPL-3.0-or-later`. Its named saved-search value behavior,
  case-sensitive ordering and lookup, duplicate rejection, query normalization,
  and map/list conversion are adapted in `lib/src/browser_saved_searches.dart`.
  `SavedSearches.kt` defines the `Config.savedFilters` extension, while
  `Config.kt` supplies the generic typed get/set operations it uses. Collection
  config access and saved-search UI are not included. The outcome mapping from
  `CardBrowserSearchViewModel.kt`'s `addSavedSearch`/`deleteSavedSearch` methods
  and `UserMessage` enum is adapted in `lib/src/browser_saved_search_messages.dart`;
  only message identifiers are returned, while localization, UI and message-flow
  delivery remain with the host. `submitSavedSearch`'s direct filter/text/close
  effect sequence is adapted in `lib/src/browser_search_state_effects.dart`;
  the downstream closed-screen search flow, request generation, and history
  effects remain separate host-applied behavior.
- Behavioral cases in `test/deck_filters_test.dart` are adapted from
  `DeckFiltersTest.kt`, Copyright © 2026 Arthur Milchior.
- Behavioral cases in `test/deck_list_test.dart` are adapted from
  `DeckNodeTest.kt`, Copyright © 2025 Shridhar Goel.
- The same Dart tests include source-derived empty-child and signed
  overflow/underflow cases; the pinned `DeckNodeTest.kt` does not directly test
  those boundaries or directly assert `depth`/`isSyntheticDeck`. Synthetic
  constructor parity cases are source-derived from `DeckNode.kt`'s level
  projection.
- `test/review_session_test.dart` checks the reviewer flow recorded in
  `ReviewerViewModel.kt`, `Scheduler.kt`, and `Collection.kt`; it is not a port
  of the Android test harness. The post-hook queue-state-on-reveal and
  count-snapshot retention cases are source-derived because the pinned tests do
  not directly assert those behaviors.
- `test/review_timebox_test.dart` checks the strict threshold, zero disablement,
  result payload, answer delta, restart reads, negative-limit behavior, and
  rounded-minute conversion from `Collection.kt` and `ReviewerFragment.kt`;
  there is no direct upstream `timeboxReached()` unit test, and this is not a
  port of the Android test harness.
- `test/previewer_navigation_test.dart` adapts the navigation cases in
  `PreviewerViewModelTest.kt`; it does not port the Android test harness,
  collection, or card-rendering setup.
- `test/previewer_flag_effects_test.dart` adapts the Previewer flag toggle case
  and adds source-derived checks for all flag codes, toggle decisions, and
  write/publish ordering. The pinned test covers RED set/toggle only; no direct
  test covers every code or failed collection writes.
- `test/previewer_mark_effects_test.dart` covers the source-ordered mark toggle,
  post-toggle read, and publication plan. The pinned ViewModel test verifies the
  resulting mark state and tag but does not directly test effect ordering or
  failure short-circuiting; those cases are source-derived.
- `test/note_mark_toggle_test.dart` covers both host-resolved mark branches and
  tag-change-before-undoable-update order. The pinned Previewer and Card Browser
  integration tests verify successful outcomes, not the isolated NoteService
  effect order; these focused cases are source-derived.
- `test/type_answer_modifiers_test.dart` adapts all direct parser cases in
  `TypeAnswerModifiersTest.kt` and adds source-derived checks for unknown-prefix
  stopping, verbatim remainder handling, empty input, and structural equality.
  It does not port card/note lookup or rendered TypeAnswer behavior.
- `test/type_answer_tags_test.dart` contains source-derived checks for the
  `TypeAnswer.removeTags` regex. `TypeAnswerTest.kt` has related answer-side
  placeholder cases but no direct `removeTags` test; answer-side behavior is not
  claimed as ported here.
- `test/type_answer_question_test.dart` contains source-derived checks for
  `TypeAnswer.filterQuestion`, including prompt formatting and Java Matcher
  replacement strings. The pinned `TypeAnswerTest.kt` has no direct
  `filterQuestion` tests; its answer-filter cases are only adjacent evidence.
- The same file contains focused source-derived checks for the separate
  Reviewer `ReviewerViewModel.typeAnsQuestionFilter` HTML transformation,
  including exact prompt whitespace, multiple/nonmatching markers, and direct
  font interpolation with Kotlin replacement-string semantics. The pinned
  `ReviewerViewModelTest.kt` has no direct assertion for this private helper.
- The same file contains source-derived checks for the question branch of
  `TemplatePreviewerViewModel.typeAnsFilter`, which has no direct pinned test;
  it verifies first-input/later-warning order, replacement-string behavior,
  and unchanged malformed markers.
- `test/type_answer_answer_test.dart` contains source-derived checks for the
  placeholder-substitution stage of `TypeAnswer.filterAnswer`. The pinned
  `TypeAnswerTest.kt` directly tests full answer filtering with
  `CollectionManager.compareAnswer`; it does not isolate this substitution
  stage. Dart accepts the comparator's HTML as input and does not port the
  comparator or Android integration.
- `test/type_answer_cloze_test.dart` adapts the two direct assertions in
  `TypeAnswerTest.kt` for repeated and distinct cloze answers, and adds
  source-derived cases for hints, no matches, requested index, order,
  duplicates, malformed payloads, and line boundaries. The pinned suite has no
  direct `updateInfo` cloze-index test; source-derived cases cover modifier
  parsing, first-marker/absent-marker behavior, Java line terminators,
  signed-32-bit ordinal overflow, and the -1-to-zero edge. Card/template
  lookup, ordinal extraction, state updates and cloze-content invocation remain
  host-side.
- `test/type_answer_field_result_test.dart` contains source-derived checks for
  `TypeAnswer.updateInfo` field selection/result behavior; the pinned test tree
  has no direct test for this method. Host lookup, localization and state
  application remain excluded.
- `test/type_answer_info_update_test.dart` contains source-derived checks for
  the ordered `TypeAnswer.updateInfo` branch/effect plan, including early
  return, metadata and warning transitions, and the lookup-failure boundary.
  The pinned test tree has no direct `updateInfo` test; Android state delivery,
  resources, collection access and exception application remain host-side.
- `test/type_answer_eligibility_test.dart` contains source-derived checks for
  the exact `validForEditText`/`autoFocusEditText` boolean decisions, including
  the source's empty-but-non-null answer case. The pinned suite has no direct
  predicate tests; Android visibility and focus integration remain host-side.
- `test/browser_column_collection_test.dart` adapts the active-column collection
  cases in `BrowserColumnCollectionTest.kt`, including constructor aliasing
  and cached count, and adds a source-derived snapshot key-projection check; it
  does not port SharedPreferences, backend column setup, or the Android harness.
- `test/browser_column_selection_move_test.dart` contains source-derived
  movement eligibility, target-zero rejection, adjacent-swap order, same-position
  and index pass-through assertions based on `BrowserColumnSelectionAdapter.kt`
  and `MutableList.kt`. `BrowserColumnSelectionTouchHelperCallbackTest.kt` tests
  RecyclerView drop-refresh timing, not the move guard or swap order.
- `test/browser_column_selection_toggle_test.dart` contains source-derived tests
  for active/available side selection, first-heading target selection,
  remove-then-insert ordering, the missing-heading partial-mutation edge, and
  invalid source positions. No pinned test directly asserts click toggling;
  the upstream touch-helper test covers drag refresh and the screenshot tests
  cover layout only.
- `test/browser_column_selection_save_test.dart` contains source-derived tests
  for the staged save/dismiss decision, including the unchanged-selection
  fall-through and update-result mapping. The pinned fragment marks saving as
  needing a test; screenshot coverage is not a save-handler test.
- `test/browser_column_selection_discard_test.dart` contains source-derived
  checks for default Back when the discard guard is disabled, confirmation
  when enabled, ordered guard-disable/back-redispatch after confirmation, and
  no callback effects after cancellation. The pinned screenshot test covers
  layout only.
- `test/browser_column_selection_projection_test.dart` contains source-derived
  checks for strict displayed/available boundaries, first matching Available
  heading behavior, usage-row dropping, selected/displayed correspondence, and
  the missing-heading `-1` case. The pinned tests cover screenshots and drag
  callbacks but do not directly assert these adapter getters.
- `test/browser_row_collection_test.dart` contains source-derived checks for
  Cards/Notes row-ID conversion, aliased list replacement/reset, ordered host
  lookups, duplicate-preserving note expansion, and first-card/per-position
  projections. It also checks that empty Notes-row queries do not require a
  host lookup callback; the pinned tests do not directly cover this empty case.
  The upstream `CardBrowserViewModelTest.kt` directly verifies
  expansion of a Notes row to all its cards, and
  `BrowserMultiColumnAdapterRowsTest.kt` exercises reset/replacement through
  the UI adapter; there is no dedicated upstream `BrowserRowCollection` test.
- `test/browser_row_position_test.dart` contains source-derived checks for the
  first duplicate match, `BrowserRowId` value equality, missing IDs, and empty
  rows. The generic pinned `ListTest.kt:11–14` directly covers first-match and
  missing-ID helper behavior, but no upstream test invokes `getPositionOfId`.
- `test/browser_pane_row_notification_test.dart` contains source-derived checks
  for previous/new position order, null and duplicate ID handling, missing-row
  omission, and first matching positions for duplicate rows. Pane-state tests
  exist upstream, but no pinned test asserts the callback's notified positions.
- `test/browser_row_range_test.dart` contains source-derived checks for the
  inclusive row slice, first-match behavior with repeated endpoint IDs, reversed
  endpoints, equal endpoints, and missing-ID index failures. The pinned
  `CardBrowserViewModelTest.kt:489–518` directly
  tests range-selection effects and no repeated emission, but not the ID-based
  range projection.
- `test/browser_preview_starting_index_test.dart` covers no/multi/single
  selection, stale single IDs, and first-match behavior for duplicate browser
  rows. Pinned `CardBrowserViewModelTest.kt:990–1041` directly covers Notes
  preview at zero, Cards with no selection at zero, and single selected Cards at
  positions zero and one; the remaining projection cases are source-derived.
- The same row-collection tests include source-derived concurrent-mutation cases:
  note IDs captured for `queryCardIds` and `queryOneCardIdPerRow` remain fixed
  while the host lookup awaits, matching `BrowserRowCollection.kt` materializing
  `requireNoteIdList()` before expansion. Collection lookups remain host-side.
- `test/browser_row_selection_test.dart` contains source-derived checks for
  selection-toggle order, mode causes, final-row deselection, retained active
  mode after select-none, refresh/last-selected values, and `RowSelection`
  equality. Pinned ViewModel tests cover row selection through UI integration,
  not the pure Dart projection; Android flow delivery and editor/pane actions
  remain outside.
- `test/browser_row_to_edit_test.dart` contains source-derived checks for empty
  row precedence, first-selected-row choice without stale-ID validation,
  multi-select with no selection, and normal-mode first-row choice. Pinned
  `CardBrowserTest.kt:1548–1563,1576–1590` verifies successful editor entry and
  persisted edits, but not the helper's row-choice results.
- `test/browser_toggle_selection_state_test.dart` adapts the initial, partial,
  and fully-selected flow outcomes from `CardBrowserViewModelTest.kt`; its
  hidden-selection, duplicate-ID, and zero/negative-row-count cases are
  source-derived. StateFlow scheduling and UI remain host-side.
- `test/browser_selected_note_count_test.dart` uses source-derived cases for
  empty, repeated, and distinct host-resolved note IDs. No upstream test
  directly asserts `CardBrowserViewModel.selectedNoteCount()`; collection
  lookup and delete-menu plural rendering remain host-side.
- `test/browser_has_selected_all_decks_test.dart` adapts direct ViewModel cases
  for initial/specific-deck false and AllDecks true, plus the search-result
  action branch. The check that non-deck filter fields are ignored is
  source-derived; flow delivery, localization, and UI remain host-side.
- `test/browser_sort_type_test.dart` adapts the sort resolution and save cases in
  `SortTypeTest.kt`, plus typed config fallback behavior from `Config.kt`,
  including the source's global no-sorting behavior; it does not port
  preference/config storage or the Android test harness.
- `test/browser_sort_notification_test.dart` covers the no-ordering variant,
  resolved and fallback label/type values, and both reverse values. The pinned
  `CardBrowserViewModelTest.kt:1951–2003` tests sort query and reverse-direction
  behavior but does not assert notification values; the Dart projection cases
  are source-derived.
- `test/browser_search_history_test.dart` adapts recency, duplicate, truncation,
  removal, clear, canonical serialized JSON, and malformed/invalid-code fallback
  behavior in `SearchHistoryTest.kt`, `FlagSerializerTest.kt`, and
  `CardStateSerializerTest.kt`; it does not test Android preferences or
  collection-backed search query generation.
- `test/browser_search_history_display_test.dart` adapts collapsed/expanded
  recent-history presentation, five-entry truncation/toggle behavior, and
  Loading's construction-time entry/null-pair projection and Loaded shape from
  `CardBrowserSearchViewModelTest.kt`, with an added source-derived Loading
  snapshot check; it does not test Android flows, search-string conversion, or
  widgets.
- `test/browser_search_restore_test.dart` uses source-derived request/history
  conversion cases, with `SearchHistoryTest.kt` as the history-format reference
  and `CardBrowserSearchViewModel.kt` as the host-map restoration implementation.
  It covers first-match ID mapping, duplicate/order preservation, Kotlin query
  trimming, and missing-ID failure. The pinned history tests cover invalid IDs
  during search-string generation, not direct restoration through host maps.
  Collection lookup and backend query generation remain outside this model.
- `test/browser_search_text_state_test.dart` adapts Basic/Advanced mode and text
  transitions from `CardBrowserSearchViewModelTest.kt`, including append spacing,
  LF replacement, saved-query application, and independent buffers; it does not
  test SavedStateHandle, flow scheduling, or Android text widgets.
- `test/browser_search_text_effects_test.dart` adds source-derived cases for
  Basic/Advanced branch selection, LF-only replacement with CR preservation,
  shallow-copy filter/list identity, User-update-before-text order, and absence
  of request/close effects. Pinned tests cover text edits but do not assert this
  combined effect sequence; Android flow execution remains host-side.
- `test/browser_search_state_effects_test.dart` adds source-derived cases for
  `syncState`/`resetSearchState` effect order, verbatim request/filter values,
  and the exact three SavedState keys removed. The pinned source marks reset
  `@NeedsTest("reset")` but has no direct test for either method; host execution
  and coroutine scheduling remain outside this test.
- The same `test/browser_search_state_effects_test.dart` also checks the
  source-derived internal effect order for `submitSavedSearch`. Pinned
  `CardBrowserSearchViewModelTest.kt` directly covers the resulting query text,
  history entry, close event, and submitted search, but does not assert this
  internal order. StateFlow scheduling and downstream request/history effects
  remain host-side.
- `test/browser_search_submit_effects_test.dart` adds source-derived cases for
  the `SearchRequest` submit overload: trimmed ID-based history conversion,
  history Loading before close-view and request events, blank-query history
  suppression/inclusion, and exact submitted-request identity. The similarly
  named pinned view-model test helper exercises the no-argument overload, not
  this ordered event sequence. Persistence, event delivery, and search execution
  remain host responsibilities.
- `test/browser_search_history_selection_test.dart` adds source-derived cases
  for history-selection effect order, active Basic/Advanced text replacement,
  LF/CR behavior, restored filters, and empty-filter fallback on missing IDs.
  The similarly named pinned test calls `submitSearch`, not
  `selectSearchHistoryEntry`; this model does not execute Android flows or
  search submission.
- `test/browser_saved_searches_test.dart` adapts name ordering and lookup,
  duplicate handling, query normalization, remove/clear, and map conversion
  behavior from `SavedSearchesTest.kt`; it does not test collection config IO,
  query execution, or the Android test harness.
- `test/browser_saved_search_messages_test.dart` adapts the four direct
  `CardBrowserSearchViewModelTest.kt` cases for successful/duplicate add and
  successful/missing delete. It checks source message identifiers only; it does
  not test localization, Android message-flow delivery, or UI rendering.
- `test/browser_availability_test.dart` adapts the direct empty-history and
  saved-search false/true/false availability cases from
  `CardBrowserSearchViewModelTest.kt`, with added Loading/Loaded list-shape
  checks. Android flow scheduling and widgets remain outside.
- `test/review_presentation_test.dart` checks the count and answer-label
  projection recorded in `StudyCounts.kt`, `StudyCountsViewTest.kt`,
  `AnswerButtonsNextTime.kt`, and `Scheduler.kt`; it is not a port of the
  Android test harness.
- `test/reviewer_answer_buttons_next_time_update_test.dart` checks hidden,
  missing-value, and publication outcomes derived from
  `ReviewerViewModel.kt:651–658`; no direct pinned Reviewer ViewModel test
  covers this decision, and the existing Android reviewer test checks only an
  end-to-end button update.
- `test/answer_timer_test.dart` checks the timer behavior and boundary cases
  from `AnswerTimerTest.kt`; it is not a port of the Android test harness.
- `test/auto_advance_test.dart` checks the delay, cancellation, deck-setting,
  action-code, and same-side behavior recorded in `AutoAdvanceTest.kt`; it is
  not a port of the Android test harness.
- `test/reviewer_auto_advance_toggle_test.dart` adds source-derived toggle
  state/message/effect ordering, audio wait, and shown-side scheduling cases.
  No direct ReviewerViewModel toggle test was found; AutoAdvance's delegated
  scheduling remains covered separately by `AutoAdvanceTest.kt`.
- `test/reviewer_leech_feedback_test.dart` adds source-derived base/suspended
  message composition, separator, whitespace and empty-string cases. No direct
  pinned test for `onLeech()` or its message resources was found.
- `test/reviewer_answer_card_effect_plan_test.dart` adds source-derived cases
  for the null-queue early return and the answer persistence, feedback, saved
  card, conditional leech handling, negative queue-code suspension check and
  refresh order. The pinned
  `ReviewerViewModelTest.kt` directly covers scheduler mutation waiting and
  process-death restoration, not this complete effect sequence.
- `test/reviewer_whiteboard_toggle_test.dart` adds source-derived enabled and
  disabled state/preference effect-order cases. Pinned UI tests enable the
  whiteboard but do not directly assert ReviewerViewModel state/preference
  ordering.
- `test/whiteboard_drawing_history_test.dart` adds source-derived completed-add,
  empty-operation, identity, removal ordering/clamping, clear/redo equality, and
  Kotlin `Float` equality (Float32 rounding, NaN, and signed zero), and reset
  cases. No direct pinned `WhiteboardViewModel` history test was found; Android
  fragment/repository whiteboard tests provide context only.
- `test/whiteboard_tool_state_test.dart` adds source-derived brush and eraser
  selection, effect ordering, preference, invalid-index, Float32 width, and
  brush add/remove cases. No direct pinned `WhiteboardViewModel` tool-state
  test was found; Android fragment/repository whiteboard tests provide context
  only.
- `test/reviewer_record_voice_toggle_test.dart` adds source-derived enabled and
  disabled state/preference effect-order cases. No direct ReviewerViewModel
  record-voice toggle assertion was found; `AudioRecordViewTest.kt` checks only
  the record button content description.
- `test/reviewer_edit_note_destination_test.dart` adds source-derived current
  card ID pass-through cases for the Reviewer's EDIT destination; no direct
  pinned Reviewer EDIT destination assertion was found.
- `test/gesture_parser_test.dart` checks the input, target, swipe, scroll,
  malformed-data, and asynchronous timing behavior recorded in
  `GestureParserTest.kt`; it is not a port of the Android test harness.
- `test/gesture_command_router_test.dart` checks command ordering, the source
  center-tap dispatch, corner and multitap filtering, enabled-state behavior,
  and executor results recorded in `GestureProcessorTest.kt`; it is not a port
  of the Android test harness.
- `test/reviewer_command_defaults_test.dart` checks that every command has a
  table entry and the exact empty-default set, plus representative answer,
  Unicode and modifier bindings, key-name resolution, duplicate numeric
  values, and the aggregate membership cases from `MappableBindingTest.kt`; it
  is not a port of the Android test harness.
- `test/reviewer_binding_preference_resolver_test.dart` checks null-only
  default selection, source-order defaults, configured override behavior,
  empty/unsupported/malformed values, and the configured path's independence
  from host key-name resolution.
- `test/reviewer_binding_codec_test.dart` and
  `test/reviewer_binding_types_test.dart` check serialized binding framing,
  typed key/Unicode parsing, modifiers, UTF-16 behavior, source equality/hash,
  gesture names and sides, permissive prefix and fallback behavior, invalid
  omission, and router-adapter filtering recorded in `BindingTest.kt`,
  `MappableBindingTest.kt`, and applicable `BindingAndroidTest.kt` cases; they
  are not ports of the Android test harness.
- `test/reviewer_binding_map_test.dart` checks ordered duplicate registration,
  side-independent lookup with the original side retained, separate axis
  registrations, and skipping unknown bindings, based on `BindingMap.kt` and
  `BindingMapTest.kt`; Android event decoding and command execution are not
  included.
- `test/reviewer_key_dispatch_test.dart` checks projected key candidate order,
  modifier matching, repeat suppression, Unicode code-unit truncation and
  separator omission, and callback order/short-circuit behavior from
  `Binding.kt` and `BindingMap.kt`; it does not test Android `KeyEvent` access
  or keyboard-layout Unicode generation.
- `test/reviewer_axis_dispatch_test.dart` checks inclusive threshold comparisons,
  per-registration debounce/rearm, Float32 value handling, ordered multiple
  triggers, processor-result independence, and null-event/no-registration cases
  derived from `SingleAxisDetector.kt` and `BindingMap.kt`. AnkiDroid 2.25.3 has
  no direct `SingleAxisDetector` unit test; Android `MotionEvent` extraction is
  outside this model.
- Dart adaptations, including the Switch Profiles dialog state, the review-session
  controller, timer, Auto Advance, leech, whiteboard and record-voice toggle
  models, gesture models, and new test code are Copyright © 2026 John Tsui.

- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt`
  (`runStateMutationHook`, lines 481–495; pinned AnkiDroid 2.25.3 commit
  `d9bf072f814a0c37d30a694192593b31ff2df875`) is marked `GPL-3.0-or-later`
  and states no separate copyright holder. Its empty-JavaScript signal decision
  and exact raw-interpolation script template are adapted in
  `lib/src/reviewer_state_mutation_hook.dart`; focused source-derived cases are
  in `test/reviewer_state_mutation_hook_test.dart`. The pinned
  `ReviewerViewModelTest.kt:81–112` covers restoring an answer while waiting
  for the custom scheduler and not rerunning it for a retained ViewModel, but
  does not directly test the empty branch or template formatting. The host
  retains awaiting, flow emission/delivery, deferred mutation-signal completion
  from the callback, scheduler execution, callback error propagation, logging,
  WebView, and lifecycle.

- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt`
  (`showQuestion`, lines 465–478; pinned AnkiDroid 2.25.3 commit
  `d9bf072f814a0c37d30a694192593b31ff2df875`) is marked `GPL-3.0-or-later`
  and states no separate copyright holder. Its ordered show-question host
  requests are adapted in `lib/src/reviewer_show_question_effects.dart`, with
  focused cases in `test/reviewer_show_question_effects_test.dart`. The pinned
  `ReviewerViewModelTest.kt:45–112` covers restoration and custom-scheduler
  behavior, but not completed/pending mutation-signal selection, callback
  order, or the wait-for-audio gate. The host retains signal lifecycle,
  rendering, hook execution, mark/flag collection reads and Flow publication,
  Auto Advance, coroutine/error boundaries, media callbacks, and UI.

- `AnkiDroid/src/main/java/com/ichi2/anki/CardUtils.kt` contains the pure
  `getDeckIdForCard()` rule adapted in `lib/src/card_utils.dart`, with focused
  cases in `test/card_utils_test.dart`. The Kotlin file has no copyright or
  SPDX header; its only header comment suppresses the missing-copyright-header
  inspection. The pinned `CardUtilsTest.kt` is Copyright (c) 2026 Ayush
  <ayushdevraj9@gmail.com> and marked `GPL-3.0-or-later`. AnkiDroid's root
  `COPYING` is GNU GPL version 3. The Dart adaptation and focused tests are
  Copyright © 2026 John Tsui and marked `GPL-3.0-or-later`; card and collection
  access remain host-side.

- `AnkiDroid/src/main/java/com/ichi2/anki/CardTemplateEditor.kt:1320–1337` (`CardTemplateFragment.performPreview`; pinned AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`) is adapted as the ordered host callback boundary `CardTemplateFragmentPerformPreviewCallbacks` and `cardTemplateFragmentPerformPreview()` in `lib/src/card_template_fragment_perform_preview.dart`, with focused source-derived cases in `test/card_template_fragment_perform_preview_test.dart`. The host retains Android context, `NotetypeFile`, note type and note models, collection access, preview argument creation, Intent, Activity, and `launchCatchingTask` error handling. No Android Activity implementation or model copies are provided. Pinned integration tests at `CardTemplateEditorTest.kt:160–170, 251–289, 1118–1126` cover preview launch and current-tab ordinal selection.

- `AnkiDroid/src/main/java/com/ichi2/anki/CardTemplateEditor.kt:1068–1072` (`CardTemplateFragment.openBrowserAppearance`) and `1363–1367` (`launchCardBrowserAppearance`; AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`) are adapted as `openCardTemplateBrowserAppearance()` in `lib/src/card_template_fragment_open_browser_appearance.dart`, with focused source-derived cases in `test/card_template_fragment_open_browser_appearance_test.dart`. A null current template skips context, Intent construction, and result launch; otherwise the exact host context and template pass through in source order, and successful paths return true. Current-template backend access, its exception boundary, Android context/Intent construction, ActivityResult launch, and result parsing/application remain host-side. Pinned `CardTemplateEditorTest.kt:898–914` verifies the discard dialog after a successful browser-appearance result but does not directly test the opener's null-template path or every callback boundary.

- `AnkiDroid/src/main/java/com/ichi2/anki/CardTemplateEditor.kt:1339–1353` (`CardTemplateFragment.displayDeckOverrideDialog`; AnkiDroid 2.25.3 commit `d9bf072f814a0c37d30a694192593b31ff2df875`) is adapted as `CardTemplateFragmentDisplayDeckOverrideDialogCallbacks` and `cardTemplateFragmentDisplayDeckOverrideDialog()` in `lib/src/card_template_fragment_display_deck_override_dialog.dart`, with focused source-derived cases in `test/card_template_fragment_display_deck_override_dialog_test.dart`. The source order, cloze short-Snackbar return, reuse of the existing current-template-name helper, and false allow-all/filtered flags are preserved. Android Activity/model access, task handling, localization, Snackbar, and dialog UI remain host-side; this does not port Android UI. Pinned `CardTemplateEditorTest.testDeckOverride` covers subsequent valid/null deck override mutation, not this dialog method.

- `AnkiDroid/src/main/java/com/ichi2/anki/CardTemplateEditor.kt:1026–1048` (`CardTemplateFragment.deleteCardTemplate`) is Copyright © 2014 Timothy Rae and © 2018 Mike Hardy and marked `GPL-3.0-or-later` upstream. Its ordered model/ordinal/template reads, single-template and orphan guards, pending-add zero confirmation, and ordinary template-use-count confirmation are adapted in `lib/src/card_template_fragment_delete_card_template.dart`; focused source-derived cases are in `test/card_template_fragment_delete_card_template_test.dart`. The host retains lifecycle, resources, model/notetype and collection access, logging, dialogs, and confirmation UI. Pinned `CardTemplateEditorTest` cases cover the single-template guard, orphan prevention, and deletion confirmation.

- `AnkiDroid/src/main/java/com/ichi2/anki/CardTemplateEditor.kt:1453–1480` (`CardTemplateFragment.confirmDeleteCards`) is Copyright © 2014 Timothy Rae and © 2018 Mike Hardy and marked `GPL-3.0-or-later` upstream. Its ordered dialog argument projection and lazy sync-checked confirmation are adapted in `lib/src/card_template_fragment_confirm_delete_cards.dart`; focused source-derived cases are in `test/card_template_fragment_confirm_delete_cards_test.dart`. The host retains Android `ConfirmationDialog`, resources/localization, generated template JSON/name access, sync/schema behavior, actual deletion, lifecycle, and UI. Pinned `CardTemplateEditorTest.kt:213–220` checks the rendered message and continuation.

- `AnkiDroid/src/main/java/com/ichi2/anki/CardTemplateEditor.kt:1522–1543` (`CardTemplateFragment.executeWithSyncCheck`) is Copyright © 2014 Timothy Rae and © 2018 Mike Hardy and marked `GPL-3.0-or-later` upstream. Its checked schema/action sequence, narrowly classified full-sync confirmation, lazy confirm/cancel callbacks, and fragmented-only preview reload are adapted in `lib/src/card_template_fragment_execute_with_sync_check.dart`; focused source-derived cases are in `test/card_template_fragment_execute_with_sync_check_test.dart`. The Dart catch preserves the source Exception boundary and lets Error values propagate. The host retains collection/schema operations, `ConfirmModSchemaException` classification and logging, Android `ConfirmationDialog` and resources, lifecycle, previewer, and UI. Pinned `CardTemplateEditorTest.testDeleteTemplate` and `testTemplateAdd` cover the full-sync confirmation integration.

- `AnkiDroid/src/main/java/com/ichi2/anki/CardTemplateEditor.kt` (`CardTemplateFragment.addCardTemplate`, lines 1074–1089) is Copyright © 2014 Timothy Rae and © 2018 Mike Hardy and marked `GPL-3.0-or-later` upstream. Its cloze early return, pending-add zero count, ordered lazy model/ordinal reads, and template-use-count forwarding are adapted in `lib/src/card_template_fragment_add_card_template.dart`; focused source-derived cases are in `test/card_template_fragment_add_card_template_test.dart`. The pinned `CardTemplateEditorTest.testTemplateAdd` checks the resulting template count and preview, and its helper checks the confirmation quantity. Timber, Android models/assertions, collection access and query, and confirmation UI remain host-side.

## Unicode property data

The locale-casing property ranges and full lowercase mappings in
`lib/src/unicode_15_case_data.dart`, and simple BMP case mappings in
`lib/src/unicode_15_simple_case_mappings.dart`, are derived from Unicode 15.0.0
`UnicodeData.txt`, `PropList.txt`, `DerivedCoreProperties.txt`, and
`SpecialCasing.txt`; the BMP decimal-digit block starts in the same file are
derived from Unicode 15.0.0 `UnicodeData.txt`. Copyright © 2022 Unicode, Inc.
This data is distributed under Unicode License V3. Its local SPDX identifier is
`LicenseRef-Unicode-License-V3`; the license text is included at
`LICENSES/Unicode-License-V3.txt`.

The adapted AnkiDroid source is licensed under GNU GPL version 3 or any later
version (`GPL-3.0-or-later`). The pinned scheduler binary is an external
dependency and is not redistributed here. See the notices in each source file
and the full license text in `COPYING` and `LICENSES/GPL-3.0-or-later.txt`.

The Set Due Date tests were written against `SetDueDateViewModelTest.kt` and
exercise its scheduler-loading guard, day/range validation, parameter format,
FSRS setter semantics, and current-interval visibility. They are not a port of
the Android test harness.

The other tests were written against the behavior documented and exercised by
AnkiDroid's `DeckFiltersTest.kt`, `DeckNodeTest.kt`, reviewer flow,
`AnswerTimerTest.kt`, `GestureParserTest.kt`, `GestureProcessorTest.kt`,
`BindingTest.kt`, `MappableBindingTest.kt`, `BindingMap.kt`,
`BindingMapTest.kt`, and applicable `BindingAndroidTest.kt` cases, including
the projected key dispatch behavior in `Binding.kt` and `BindingMap.kt`.
They are not a port of the Android test harness.

The Study Options projection tests were written against
`StudyOptionsViewModelTest.kt` and cover buried-count arithmetic, state precedence,
and Loading accessors. The filtered-deck action tests are source-derived from
`StudyOptionsViewModel.kt` and cover diagnostic distinction, scheduler/refresh
ordering, and failure propagation. They are not a port of the Android test
harness.

The portable review-reminder form state in `lib/src/review_reminder_form_state.dart`
is derived from AnkiDroid's `AddEditReminderDialogViewModel.kt`, `ReviewReminder.kt`,
and `AddEditReminderDialog.kt`, Copyright © 2025 Eric Li
<ericli3690@gmail.com>, licensed `GPL-3.0-or-later` upstream. The host retains
runtime reminder creation and all Android, collection, persistence, scheduling,
and notification behavior.

The scheduled-delivery comparison in `lib/src/review_reminder_delivery.dart` is
derived from `ReviewReminder.kt` and `ReviewReminderTest.kt`, Copyright © 2025
Eric Li <ericli3690@gmail.com>, licensed `GPL-3.0-or-later` upstream. The host
supplies the local clock and timezone and retains reminder persistence,
TimeManager, and Android alarm/notification scheduling. The Dart tests are
source-derived behavior tests, not a port of the Android test harness.

The `ReviewReminderId`, `ReviewReminderIdAllocation`, and
`ReviewReminderCardTriggerThreshold` values in
`lib/src/review_reminder_id.dart` are derived from AnkiDroid's
`ReviewReminder.kt` and `ReviewReminderTest.kt`, Copyright © 2025 Eric Li
<ericli3690@gmail.com>, licensed `GPL-3.0-or-later` upstream. The host supplies
the current next-ID preference and applies the returned increment; preference
access, persistence, runtime reminder creation, and Android behavior remain
host-side. The focused Dart cases are source-derived behavior tests, not a port
of the Android test harness.

The current `ReviewReminder` model in `lib/src/review_reminder.dart` and its
source-compatible nested time/scope string forms are derived from AnkiDroid's
`ReviewReminder.kt` and `ReviewReminderTest.kt`, Copyright © 2025 Eric Li
<ericli3690@gmail.com>, licensed `GPL-3.0-or-later` upstream. The host supplies
the allocated reminder ID and epoch-millisecond timestamps and retains clock,
preference access, Parcelable, persistence, collection access,
and notification scheduling. The focused Dart cases are source-derived behavior
tests, not a port of the Android test harness.

`ReviewReminderGroup` and `List<ReviewReminderGroup>.mergeAll()` in
`lib/src/review_reminder_group.dart` are derived from AnkiDroid's
`ReviewReminderGroup.kt`, Copyright © 2026 Eric Li
<ericli3690@gmail.com>, licensed `GPL-3.0-or-later` upstream. The map wrapper
and merge operations are represented in memory. The current-schema JSON codec
is derived from `ReviewReminder.kt`, Copyright © 2025 Eric Li
<ericli3690@gmail.com>, and the golden fixture in
`ReviewRemindersDatabaseTest.kt`, Copyright © 2025 Eric Li
<ericli3690@gmail.com>; both are licensed `GPL-3.0-or-later` upstream. It
preserves the reminder-ID-keyed map, source field order and names, and the
polymorphic scope discriminator and payload. SharedPreferences,
schema/database handling, mutexes/coroutines, scheduling, and Android UI remain
host-side. Value iteration order is not a contract. The focused Dart cases are
source-derived behavior tests, not a port of an Android group test harness.

The schema version values, V1/V2 reminder schemas, current-schema migration
projection, and in-memory step-by-step map migration in
`lib/src/review_reminder_schema_migration.dart` are derived from AnkiDroid's
`ReviewReminderSchema.kt`, `ReviewReminder.kt`, `ReviewRemindersDatabase.kt`,
and `ReviewRemindersDatabaseTest.kt`, Copyright © 2026 Eric Li
<ericli3690@gmail.com> (schema source) and Copyright © 2025 Eric Li
<ericli3690@gmail.com> (migration tests), licensed `GPL-3.0-or-later`
upstream. The Dart migration runner and focused tests are Copyright © 2026 John
Tsui <110079544+JohnXu22786@users.noreply.github.com>, licensed
`GPL-3.0-or-later`. The host supplies each allocated reminder ID and current
epoch-millisecond timestamp. `ReviewReminderSchemaV1MapCodec` and
`ReviewReminderSchemaV2MapCodec` in `lib/src/review_reminder_group.dart` encode
and decode the typed legacy maps with source-compatible decimal keys, value
IDs, scope JSON, strict fields/types, and V1's omitted false default. The Dart
codecs and focused cases in `test/review_reminder_schema_codec_test.dart` are
Copyright © 2026 John Tsui and marked `GPL-3.0-or-later`. Schema
registry/database migration, preference access, persistence, clock access, and
other runtime integration remain host-side. The focused Dart cases are
source-derived behavior tests, not a port of the Android test harness.

- `AnkiDroid/src/main/java/com/ichi2/anki/reviewreminders/ReminderTroubleshootingViewModel.kt` is marked `GPL-3.0-or-later` upstream and does not name a separate copyright holder in its source header. Its portable result variants, check values/defaults, summary precedence, and battery optimization result mapping are adapted in `lib/src/reminder_troubleshooting_state.dart`. Android Context and notification APIs, repository-backed checks, ViewModel lifecycle/StateFlow/coroutines, localization, and UI remain host-side. The pinned `ReminderTroubleshootingViewModelTest.kt` is also marked `GPL-3.0-or-later` and is the behavioral reference; the Dart cases add only focused coverage for source cases it does not directly test.

- `AnkiDroid/src/main/java/com/ichi2/anki/dialogs/viewmodel/TtsVoicesViewModel.kt` declares `GPL-3.0-or-later`; its available-voice status precedence and pure filter projection are adapted in `lib/src/tts_voice_filter_projection.dart`, and `playVoice()` / `playTts()` ordered playback decisions and returned-error projection are adapted in `lib/src/tts_voice_playback_effects.dart`. `AnkiDroid/src/main/java/com/ichi2/anki/TtsVoices.kt` supplies the `AndroidTtsVoice.unavailable()` and network-required facts used by the projections; `libanki/src/main/java/com/ichi2/anki/libanki/Tts.kt` supplies the base `TtsVoice` availability contract. Voice enumeration, sorting, Android/platform classes, engine/player, player execution, and playback event delivery are not copied. `TtsVoices.kt` and `Tts.kt` also identify separately licensed Anki backend code, which this Dart slice does not include. The pinned source has no direct `TtsVoicesViewModel` tests; the focused Dart cases are source-derived. The new Dart projection and test are Copyright © 2026 John Tsui and marked `GPL-3.0-or-later`.
- `AnkiDroid/src/main/java/com/ichi2/anki/TtsParser.kt` is pinned at `d9bf072f814a0c37d30a694192593b31ff2df875`; its source has a MissingCopyrightHeader suppression and names no separate copyright holder. Its portable ordered `<tts service="android">` text/voice selection, marker replacement, and body-text fallback are adapted in `lib/src/tts_text_selection.dart`, with focused cases in `test/tts_text_selection_test.dart`. The pinned `TtsParserTest.kt` directly covers fallback and marker replacement; remaining cases are source-derived. The host supplies parsed DOM facts and TTSTag construction; Jsoup parsing/text semantics, protobuf fields, and playback are not included. The root `COPYING` gives the AnkiDroid project license as GNU GPL version 3. The Dart adaptation and focused tests are Copyright © 2026 John Tsui and marked `GPL-3.0-or-later`.
- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/audiorecord/CheckPronunciationViewModel.kt` and `AnkiDroid/src/test/java/com/ichi2/anki/ui/windows/reviewer/audiorecord/CheckPronunciationViewModelTest.kt` both declare `GPL-3.0-or-later` and name no separate copyright holder. The ordered `onPlayOrReplay()` branch/effect projection is adapted in `lib/src/check_pronunciation_playback_plan.dart`; the Dart tests are focused behavior cases, not a copy of the Android test harness. The host retains Flow delivery, coroutine scheduling and Job lifecycle, duration/prepared/completion callbacks, progress sampling, audio player/recorder behavior, file access, and UI.

- `AnkiDroid/src/main/java/com/ichi2/anki/CardTemplateNotetype.kt` and its
  `CardTemplateNotetypeTest.kt` are marked `GPL-3.0-or-later` and identify
  Copyright (c) 2020 Mike Hardy <mike@mikehardy.net>. The deterministic pending
  template-change history and ordinal projections are adapted in
  `lib/src/card_template_change_tracking.dart`; focused source-derived cases are
  in `test/card_template_change_tracking_test.dart`. The Dart adaptation and new
  tests are Copyright © 2026 John Tsui and marked `GPL-3.0-or-later`. Only the
  add/delete tracking algorithms are represented. Java `Serializable`, Android
  Bundle/Parcelable behavior, NotetypeJson mutation, temporary-file persistence,
  logging, CollectionManager/Rust backend operations, undoable database writes,
  and editor UI remain host-side and are not reimplemented here.

- `AnkiDroid/src/main/java/com/ichi2/anki/reviewreminders/ReminderLogTree.kt` and `common/src/main/java/com/ichi2/anki/common/utils/ext/ByteArray.kt` are Copyright © 2026 Eric Li <ericli3690@gmail.com> and marked `GPL-3.0-or-later` upstream. The exact reminder log prefix/header, level and line projection, newline search, and trim projection are adapted in `lib/src/reminder_log_projection.dart`; focused source-reference cases are in `test/reminder_log_projection_test.dart`. The implementation accepts a host-formatted timestamp and host grapheme ellipsizer. Timber routing, Android logging, coroutine scheduling, log-file IO/rotation, atomic rename, and error handling remain host-side. The supporting `StringUtils.kt` source is also GPL-3.0-or-later; its Unicode grapheme behavior is delegated to the host. The pinned direct tests are `ReminderLogTreeTest.kt` and `ByteArrayTest.kt`.

The scope-to-SharedPreferences-key projection in
`lib/src/review_reminder_scope_storage_key.dart` and focused cases in
`test/review_reminder_scope_storage_key_test.dart` are derived from AnkiDroid's
`ReviewRemindersDatabase.kt` and `ReviewRemindersDatabaseTest.kt`, Copyright © 2025 Eric Li
<ericli3690@gmail.com>, licensed `GPL-3.0-or-later`. The host retains
SharedPreferences access and reminder persistence. The focused Dart cases are
source-derived behavior tests, not a port of the Android test harness.

The notification refresh decision in `lib/src/review_reminder_refresh_decision.dart`
and its focused cases are derived from AnkiDroid's `ReviewRemindersDatabase.kt`,
`ReviewReminder.kt`, and `ReviewRemindersDatabaseTest.kt`, Copyright © 2025 Eric
Li <ericli3690@gmail.com>, licensed `GPL-3.0-or-later`. The host supplies local
check time and a separately sampled update timestamp and retains database
lookup, locking, serialization, editor/persistence execution, logging,
coroutines, scheduling, alarms, and UI behavior. The focused Dart cases are
source-derived behavior tests, not a port of the Android test harness.

`StoredReviewReminderGroup` in `lib/src/review_reminder_stored_group.dart` and
its focused cases in `test/stored_review_reminder_group_test.dart` are derived
from AnkiDroid's `ReviewRemindersDatabase.kt` and
`ReviewRemindersDatabaseTest.kt`, Copyright © 2025 Eric Li
<ericli3690@gmail.com>, licensed `GPL-3.0-or-later`. The host retains storage,
schema migration, and recovery behavior.
The Dart adaptation and focused tests are Copyright © 2026 John Tsui and marked
`GPL-3.0-or-later`.

- `AnkiDroid/src/main/java/com/ichi2/anki/ui/windows/reviewer/ReviewerViewModel.kt`
  (pinned at `d9bf072f814a0c37d30a694192593b31ff2df875`) is marked
  `GPL-3.0-or-later` and names no separate copyright holder. Its
  `showAnswerInternal()` effect order is adapted in
  `lib/src/reviewer_show_answer_effects.dart`, with source-derived cases in
  `test/reviewer_show_answer_effects_test.dart`. The host retains deferred and
  coroutine execution, scheduler/deck/config reads, media playback, timer
  operation, StateFlow/lifecycle, and UI.
