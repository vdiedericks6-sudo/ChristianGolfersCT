# Round flow reference — 30 October 2026

Reviewed the supplied 88-second video. It shows an activity launcher, course search, tee selection, settings review, a full-screen rendered hole, zoomed green, map-layer choices and scorecard/leaderboard shortcuts.

Implemented for CGCT: larger photo-led start-round card; dedicated course selection mode; separate tee selection and settings review; host-only initial lobby; immersive hole image viewer with pan/zoom, reset, previous/next hole previews, scorecard, leaderboard and score-entry controls. Navigation regression test covers this complete path. Hole previews do not advance the group's scoring hole or discard unsaved scores.

Current settings remain supported stroke play, 18 holes, starting hole 1. The screen does not pretend that 9-hole setup, arbitrary starting holes, per-player tees or stats-exclusion switches have been implemented.

Course and hole pictures use their own supplied image URLs. The start-round card uses the existing golf-ball/tee brand asset, not a claimed image of any specific course. Missing hole imagery is explicitly labelled. No video screenshots, competitor map assets or invented geometry were loaded as real course data.

Still needed to match the mapped visuals: licensed fairway/green/hazard polygons or imagery for each hole; verified tee and green coordinates; satellite provider rights and credentials; green elevation/contour data. The viewer is a photographic viewing surface, not a navigable GPS map, contour renderer or live distance engine. GolfAPI access remains unavailable. Do not advertise those capabilities as complete.

Validation: all 53 Flutter tests passed on 30 October 2026. The updated debug APK built successfully. Static analysis reported informational lint/deprecation notices only, with no errors.

Device delivery: installation succeeded on the connected Samsung SM-S926B; Christian Golfers Debug was launched for review.
