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

The xboxrecomp new-game template contains an NV2A MMIO decoder and register
model, but the template host did not initialize or route faults to it. The
project-specific integration is kept separately in
[`patches/steel-battalion-nv2a-host-hook.patch`](../patches/steel-battalion-nv2a-host-hook.patch).
It initializes the existing model, protects the guest MMIO aperture to route
accesses through the vectored exception handler, and reports unsupported
register-access instructions through the normal crash diagnostics. The patch
applies to the upstream template at the pinned version; build and runtime
verification are still pending.

This hookup does not make the component a complete GPU implementation. At the
pinned revision, `nv2a_core.c` labels PFIFO as a phase-one stub, and the block
table routes PFIFO cache and NV_USER windows to stub handlers. The component's
own README describes push-buffer parsing as a separate processing path. Treat
the hook as first-step register integration only; title-screen rendering and
GPU command execution remain unverified and may require completing or replacing
those specific device functions with compatible, license-reviewed upstream
code.

The upstream `NOTICE` identifies xemu-derived APU and NV2A components under
LGPL-2.1-or-later. The local executable links xboxrecomp runtime libraries,
including those components. No game executable or runtime libraries are
prepared for redistribution. Before distributing binaries, retain all upstream
notices and license texts and satisfy the LGPL relinking/source requirements.
The project license remains undecided pending the full dependency review.
