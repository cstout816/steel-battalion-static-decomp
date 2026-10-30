# r401 source preservation manifest

The dirty XboxRecomp checkout must remain intact. Its base revision is `193e2995ffaec871bb3be43a43bd66aa5fccfeb1`; the current source contains pre-existing APU tracing and FET interrupt edits as well as the r399 invalid-voice bounds guard. No generated game source is included here.

`preservation-apu-vp-r401.patch` is the binary-safe Git diff for `local-tools/xboxrecomp/src/apu/apu_vp.c` against that base. It is 7,004 bytes, SHA-256 `A1223E3869449C4127FDF451D15CBB232CC12C7E0EFCBECACD247B42D9C74BA8`. Current source SHA-256: `3160C94C57BCF0E7416467C9DCFEDB88B63E4B42DD01717D9D91723B7B4D6792`.

The patch intentionally captures the entire current diff for this one dirty source file, including earlier local edits, so it must be reviewed and applied only to the matching base revision. Other dirty and untracked XboxRecomp files remain in the checkout and are covered by earlier preservation artifacts; this small patch is not a full-worktree backup. It contains runtime project code only, not proprietary generated Steel Battalion code or game assets.
