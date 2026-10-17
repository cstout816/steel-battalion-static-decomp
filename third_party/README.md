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
It initializes the existing model and routes selected register pages through
the vectored exception handler. The RAMHT register page, PRAMIN, and NV_USER
remain shared memory so the kernel's pushbuffer worker and semaphore path see
the guest's writes. The model's RAMIN pointer aliases that shared PRAMIN via
[`patches/xboxrecomp-v0.13.1-shared-pramin.patch`](../patches/xboxrecomp-v0.13.1-shared-pramin.patch).
An optional rate-limited diagnostic is isolated in
[`patches/steel-battalion-mmio-fault-trace.patch`](../patches/steel-battalion-mmio-fault-trace.patch).

The allocator stall exposed a static-lifter bug in locked XADD handling. Capstone
reports `lock xadd`, but the flag tracker previously discarded its EFLAGS
result. The emitted `jne` then read an uninitialized fallback flag, which made
the reference-count destructor path run for every decrement. The isolated fix
[`patches/xboxrecomp-v0.13.1-locked-xadd-flags.patch`](../patches/xboxrecomp-v0.13.1-locked-xadd-flags.patch)
normalizes the lock prefix for flag tracking and snapshots the atomic addition
result for ZF. Its focused lifter tests pass, and a local single-function
translation confirms the actual Steel Battalion release routine now branches
on that result. A bounded runtime run passed the former allocator loop and
advanced farther, then crashed in an audio cleanup path with a null list
object. This does not establish audio compatibility or a successful boot.

An earlier local RelWithDebInfo run verified that Steel Battalion advances
USER DMA_PUT/DMA_GET to `0x495C`, resolves its handle 8 semaphore DMA
descriptor, and releases the guest fence from 3 to 9, then stalls in a guest
allocator free-list loop. After the locked-XADD fix below, the allocator loop
no longer recurs in the bounded run; audio cleanup now crashes on a null list
object. The pushbuffer executor still reports one surface clear and one flip
setup but zero geometry draws and zero pixels; a title screen, audio, and
controller input have not been verified.

This hookup does not make the component a complete GPU implementation. At the
pinned revision, `nv2a_core.c` labels PFIFO as a phase-one stub, and the block
table routes PFIFO cache and NV_USER windows to stub handlers. The same pinned
checkout also includes a separate, opt-in scanner and partial pushbuffer
executor in `src/kernel/nv2a_pb_scan.c` and `nv2a_pb_exec.c`, linked into the
`xbox_kernel` target. It is gated by `RECOMP_PB_EXEC=1` and can process a
subset of surface, clear, and geometry methods into the guest framebuffer.
It is not a complete PFIFO, shader, or texture implementation. Its safety
guards and method coverage still need validation against Steel Battalion's
full command stream. The observed clear/flip is partial command execution, not
a rendered title-screen frame.

There is also a separate `src/nv2a/nv2a_pgraph_d3d11.c` translator for a limited
subset of NV097 methods. It is dispatched by the toolkit's `pgraph_method()`
path and by its pushbuffer replay harness. That path should not be confused
with the game-specific executor above: the toolkit labels PFIFO a phase-one
stub, so the title's normal guest pushbuffer has not been shown to reach this
translator. Static source inspection finds no call from the game's
`nv2a_pb_exec_method()` to `pgraph_d3d11_method()`; the game-specific executor
instead rasterizes its supported subset into the guest framebuffer. This
separation is important when interpreting a future window or frame trace.

An isolated follow-on patch,
[`patches/xboxrecomp-v0.13.1-nv2a-semaphore-release.patch`](../patches/xboxrecomp-v0.13.1-nv2a-semaphore-release.patch),
adds the Xbox BIOS RAMHT defaults and a bounded NV097 semaphore release path
to that partial executor. It resolves the configured handle through RAMHT and
the guest DMA descriptor, checks class, target, limit, and physical-memory
bounds, then writes through the contiguous physical alias. It is informed by
xemu's LGPL-2.1-or-later DMA descriptor interpretation and Cxbx-Reloaded
commit `d3bf46e` as behavioral prior art; no Cxbx code was copied. Runtime
coverage is not established, and the patch is not a complete PFIFO or GPU
implementation. Keep the Cxbx GPL-2.0 license restriction in mind before any
future direct code reuse.

The port-I/O bridge is isolated in
[`patches/xboxrecomp-v0.13.1-port-io.patch`](../patches/xboxrecomp-v0.13.1-port-io.patch)
and the host callback lives in the NV2A host patch above. It translates x86
`IN`/`OUT` operations through a host callback and models the observed `0x80C0`
LPC GPIO behavior from the open xemu PR as a candidate. The currently generated
Steel Battalion C still contains `RECOMP_UNIMPL` for these instructions; it
must be regenerated before the bridge can be exercised. Neither compilation
nor runtime behavior has been verified.

An isolated watchdog diagnostic,
[`patches/xboxrecomp-v0.13.1-watchdog-native-pc.patch`](../patches/xboxrecomp-v0.13.1-watchdog-native-pc.patch),
captures the native instruction pointer of the thread running guest code when
the watchdog expires. It briefly suspends that thread to read its Windows
context, resumes it before logging, then asks DbgHelp for symbol and source-line
information when a local PDB is available. This is separate from the translated
guest registers and does not claim to recover a guest EIP directly. The patch
has passed a reverse-apply/whitespace check only; it has not been compiled or
exercised.

The upstream `NOTICE` identifies xemu-derived APU and NV2A components under
LGPL-2.1-or-later. The local executable links xboxrecomp runtime libraries,
including those components. No game executable or runtime libraries are
prepared for redistribution. Before distributing binaries, retain all upstream
notices and license texts and satisfy the LGPL relinking/source requirements.
The project license remains undecided pending the full dependency review.
