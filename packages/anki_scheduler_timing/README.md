# Anki scheduler timing

This platform-neutral AGPL-3.0-or-later package ports Anki Core's
`sched_timing_today_v2_new` day timing calculation. Callers supply Unix
seconds and the UTC offset in minutes west of UTC that applied at creation and
at the current time. The calculation does not inspect the machine timezone.

The pinned Rust source and its SHA-256 digest are recorded in `SOURCE.sha256`.
The source is from Anki Core commit `e64c6b1aee3e8d668fb8bbe084beada8e070d985`.
