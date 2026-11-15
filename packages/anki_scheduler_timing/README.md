# Anki scheduler timing

This platform-neutral AGPL-3.0-or-later package ports Anki Core's v1, v2
legacy, and v2-new scheduler day timing calculations, including the official
version-selection rule. Callers supply Unix seconds and offsets in minutes
west of UTC. The calculation does not inspect the machine timezone; callers
must inject the appropriate current and creation offsets from their platform
adapter when needed.

`schedTimingTodayV1` counts fixed 86,400-second intervals. When rollover is
configured without a collection creation offset, `schedTimingToday` selects
`schedTimingTodayV2Legacy`, which interprets creation time in the current
offset. Supplying both rollover and creation offset selects `schedTimingTodayV2New`.
`v1CreationDate` also takes an explicit local offset, and
`fixedOffsetFromMinutes` preserves the source's ±23-hour clamping behavior.

`currentDueDay` applies a signed day delta with Anki Core's `u32` to `i32`
reinterpretation and floor-at-zero behavior. `isUnixEpochTimestamp` identifies
seconds-based due values using the strict `due > 1_000_000_000` threshold.

The pinned Rust source and its SHA-256 digest are recorded in `SOURCE.sha256`.
The sources are from Anki Core commit
`e64c6b1aee3e8d668fb8bbe084beada8e070d985`; the helper implementations come
from `rslib/src/scheduler/mod.rs` and `rslib/src/scheduler/timing.rs`.
