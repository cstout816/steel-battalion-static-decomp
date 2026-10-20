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

Startup tracing found several call and tail-jump targets inside detected
functions. The default fallback stubs made the Windows build link but returned
without executing those guest blocks. The separate patch
[`patches/xboxrecomp-v0.13.1-interior-tail-continuations.patch`](../patches/xboxrecomp-v0.13.1-interior-tail-continuations.patch)
adds instruction-boundary and reachable-CFG checks, then emits a translated
continuation only when the block can safely stand alone. Full regeneration
emitted 251 such entries and reduced unresolved stubs from 351 to 100; the
Windows target built and a bounded run continued through the affected audio
setup into title-media reads. This is not proof of a title-screen boot, audio
output, or correctness of every recovered continuation. The patch contains
generic recompiler logic only; generated game code remains local and ignored.

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

A bounded startup trace found that the guest's PCRTC hardware interrupt was
pending with the PMC hardware-enable bit set, then the guest ISR cleared that
enable before the trace's later state snapshot. The standalone NV2A core's old
`pending_interrupts && enabled_interrupts` check could also cross-enable
hardware and software interrupt classes. The minimal, reproducible PMC gate
correction is isolated in
[`patches/xboxrecomp-v0.13.1-pmc-irq-gating.patch`](../patches/xboxrecomp-v0.13.1-pmc-irq-gating.patch).
It distinguishes the global hardware and software enable bits described in
the [envytools PMC register reference](https://envytools.readthedocs.io/en/latest/hw/bus/pmc.html).
A local instrumented run observed a PCRTC hardware pending bit with hardware
enable `1` asserting the line, followed by enable `0` deasserting it. This
confirms the gate behavior in that trace; it does not establish a title-screen
boot or complete interrupt correctness. The project runtime also has a host IRQ
callback for wiring this line to the guest kernel; that callback wiring is a
separate local integration change and is not included in this minimal patch.

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
is supplemented by
[`patches/xboxrecomp-v0.13.1-watchdog-bounded-default.patch`](../patches/xboxrecomp-v0.13.1-watchdog-bounded-default.patch),
which makes native-PC symbolization opt-in through
`RECOMP_WATCHDOG_NATIVE_PC`. This keeps DbgHelp out of the watchdog's default
timeout path because a bounded startup run stopped producing diagnostics after
the symbol-capture path was entered. The follow-up patch passed a forward and
reverse application check, rebuilt the Windows x64 target, and restored the
expected 15-second watchdog exit (code 3) with symbolization disabled. DbgHelp
symbol capture remains opt-in and has not been revalidated.

The upstream `NOTICE` identifies xemu-derived APU and NV2A components under
LGPL-2.1-or-later. The local executable links xboxrecomp runtime libraries,
including those components. No game executable or runtime libraries are
prepared for redistribution. Before distributing binaries, retain all upstream
notices and license texts and satisfy the LGPL relinking/source requirements.
The project license remains undecided pending the full dependency review.

The opt-in Steel Battalion XID input profile has a separate report-layout
correction in
[`patches/xboxrecomp-v0.13.1-steel-battalion-xid-report-offsets.patch`](../patches/xboxrecomp-v0.13.1-steel-battalion-xid-report-offsets.patch).
Apply it after the project Steel Battalion XID profile patch. It places the
analog fields according to the packed 26-byte report layout exercised by the
public [Xbox-side XID test](https://gist.github.com/Ryzee119/5b74e94eb765bcc54e68afde9ddc7623).
The corrected layout and synthetic report transport were observed locally;
guest-side acceptance and gameplay behavior are not yet verified.

## Pinned Vulkan presentation dependencies

The Windows Vulkan framebuffer presenter fetches two pinned dependencies
through CMake FetchContent. No Vulkan SDK installation is required, and
neither dependency source tree is vendored in this repository.

| Dependency | Pinned revision | License used | Archive SHA-256 |
|---|---|---|---|
| [Volk](https://github.com/zeux/volk) | `3ca312a4f38baa63d8006b6905abbeeb89c8087d` | MIT | `8C938B390B234DDEE57C01D47933E708E5BF6F51CE8601B9E93154173C6AD5A1` |
| [Vulkan-Headers](https://github.com/KhronosGroup/Vulkan-Headers) | `acbb9391c0a597272800cd3f4363661c00a27c77` | MIT option under upstream `Apache-2.0 OR MIT` licensing | `4F1526F54E1DEB260BF5BD534AE47F01ABF93155B4FCCD2609EC605207CF4428` |

Retained notices and license texts are in `licenses/volk-MIT.txt`,
`licenses/Vulkan-Headers-LICENSE.md`, and `licenses/Vulkan-Headers-MIT.txt`.
The Vulkan-Headers notice says `parse_dependency.py` is excepted from its
dual-license statement; this project fetches the Vulkan declarations and does
not use that Python utility.

The Vulkan adapter presents the existing guest framebuffer through a Vulkan
swapchain. It does not yet render NV2A commands. No xemu renderer source has
been copied. See [`../docs/VULKAN_REUSE_AUDIT.md`](../docs/VULKAN_REUSE_AUDIT.md)
for the separate xemu shader/PGRAPH reuse and licensing review.

The follow-up
[`patches/xboxrecomp-v0.13.1-vulkan-aspect-fit.patch`](../patches/xboxrecomp-v0.13.1-vulkan-aspect-fit.patch)
preserves the guest image's aspect ratio in the swapchain and clears the
letterbox bars. Apply it after the presenter patch.

## NV2A D3D fence and interrupt references

The XboxRecomp maintainer's merged [pushbuffer executor PR #162](https://github.com/sp00nznet/xboxrecomp/pull/162)
documents two separate D3D completion paths: the semaphore release at method
`0x1D70`, and XDK D3D's software notification/fence methods. It notes that the
optional DMA-style walk can stall on a software-method interrupt that the
runtime does not yet deliver. Steel Battalion's local startup trace confirms
that vector 3's guest ISR is called and claims modeled NV2A interrupts in the
complete XPP-seeded build. The trace did not observe method `0x0310` on
subchannel 5, so its PGRAPH `0x400B10` fence latch remains an unverified
compatibility candidate in
[`patches/xboxrecomp-v0.13.1-pattern-fence-latch.patch`](../patches/xboxrecomp-v0.13.1-pattern-fence-latch.patch).

The separate [Project Clanker](https://github.com/megabitt01/project-clanker)
repository is MIT licensed and describes an original-Xbox Battlefront II
recompilation with a dedicated GPU pusher and interrupt worker. It is useful
as an architectural reference for independent guest ISR delivery. Its C++
runtime is not integrated here, and no code was copied. A shallow checkout at
`565532df3854ddc861373bb037acbe3da511844a` is ignored under `local-tools/`
for local research; it is not part of this repository.

## Steel Battalion runtime integration candidates

[`patches/steel-battalion-frame-counter-registration.patch`](../patches/steel-battalion-frame-counter-registration.patch)
registers the title's statically identified D3D device counter (`0x0021AFE0`,
offset `0x2580`) with xboxrecomp's existing NV2A flip/idle counter service.
The corrected Windows build succeeded, and bounded runs showed the counter
advancing where it had remained at `1`. Those runs still stalled before the
title prompt, so this is a diagnostic compatibility candidate rather than a
verified boot fix. It relies on this XBE's device layout and must not be applied
to other games without analyzing their binaries.

[`patches/xboxrecomp-v0.13.1-path-trace-gate.patch`](../patches/xboxrecomp-v0.13.1-path-trace-gate.patch)
makes verbose guest path traces opt-in through `RECOMP_TRACE_PATHS`; normal
file opens no longer contend on repeated path messages. This changes logging
only, not path translation or file semantics.
