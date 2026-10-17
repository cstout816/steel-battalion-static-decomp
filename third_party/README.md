# Third-party code and local modifications

The project currently uses sp00nznet/xboxrecomp `v0.13.1` (upstream commit
`193e2995ffaec871bb3be43a43bd66aa5fccfeb1`) as an external local checkout. The
upstream source is not vendored in this repository. Its MIT license is retained
at [`licenses/xboxrecomp-MIT.txt`](licenses/xboxrecomp-MIT.txt).

The initial Steel Battalion translation exposed a shift-count mismatch in that
version's lifter: x86 masks shift counts to five bits, while the generated C
used the unmasked count. The local build used the isolated patch
[`patches/xboxrecomp-v0.13.1-shift-count.patch`](../patches/xboxrecomp-v0.13.1-shift-count.patch).
It masks counts, preserves zero-count no-op behavior, and avoids out-of-range C
shifts when recovering carry. Keep this change separate from upstream source
and revalidate it when changing xboxrecomp versions.

The upstream `NOTICE` identifies xemu-derived APU and NV2A components under
LGPL-2.1-or-later. The local executable links xboxrecomp runtime libraries,
including those components. No game executable or runtime libraries are
prepared for redistribution. Before distributing binaries, retain all upstream
notices and license texts and satisfy the LGPL relinking/source requirements.
The project license remains undecided pending the full dependency review.
