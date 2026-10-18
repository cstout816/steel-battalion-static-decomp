# MCPX GP/EP DSP integration plan

**Status (2026-10-18):** the optional FFI lifecycle, scratch-bootstrap, and bounded-frame patches apply in sequence. The pinned Windows x64 library, APU target, focused C harness, and full Windows game target build. The harness covers SGE page crossing, 24-bit masking, malformed-table rejection, callback register behavior, and bounded synthetic execution. A corrected no-ack, watchdog-bounded Steel Battalion run now verifies that the guest GP/EP programs bootstrap from guest scratch and execute real DSP56300 instructions. A targeted trace shows the GP polling its frame-status peripheral, receiving and clearing a host-scheduled frame bit, and running scratch DMA actions. An earlier run that logged DSP cycles used an incorrect readiness marker and remains excluded. The game command transaction, full DMA/FIFO and mixbin behavior, audible output, and title-screen arrival remain unverified. The FFI remains opt-in and disabled by default.

## Execution architecture

The Xbox x86 game remains statically translated by XboxRecomp and runs against its Windows compatibility runtime. The MCPX Global Processor (GP) and Encode Processor (EP) are separate DSP56300 coprocessors. Using a DSP56300 JIT for those two processors would emulate the audio coprocessors only; it would not replace the game's static x86 translation with full-system Xbox emulation. The runtime and its documentation must describe those paths separately.

## Reuse and licensing findings

- The local XboxRecomp APU is extracted from xemu and marks its APU files LGPL-2.1-or-later. Its existing notice and license files must continue to ship with any redistributed build.
- [xemu's GP/EP APU implementation](https://github.com/xemu-project/xemu/blob/master/hw/xbox/mcpx/apu/dsp/gp_ep.c) supplies useful behavioral reference for MMIO windows, reset transitions, scatter-gather transfers, FIFOs, mixbin flow, and frame scheduling. The file is LGPL-2.1-or-later. Keep any direct reuse isolated, attributed, and under its applicable license.
- xemu's current [Rust JIT bridge](https://github.com/xemu-project/xemu/blob/master/hw/xbox/mcpx/apu/dsp/dsp_jit.c) already connects the DSP56300 C FFI to xemu's APU. It demonstrates persistent host-owned X/Y/P buffers, a callback-backed peripheral region, scratch-to-program-memory bootstrap with 24-bit masking and cache invalidation, and batched state synchronization. That bridge is GPL-2.0-or-later and depends on xemu's private `DSPState` and DMA types; it is a behavioral and architectural reference, not a drop-in file for XboxRecomp. Reuse would require preserving its GPL terms and reviewing the project's combined license obligations.
- The DSP56300 emulator depends on Cranelift. Bytecode Alliance documents x86-64 code generation, the Windows x64 calling convention, and Windows as a supported host OS for JIT use. This makes the requested Windows x64 target plausible, but it does not replace a local Windows x64 build and smoke check of this specific crate combination.
- [xemu-project/dsp56300](https://github.com/xemu-project/dsp56300) is MIT-licensed and publishes a C FFI crate as a Rust static library. Its pinned workspace declares Rust 1.99 and edition 2024. The official [FFI header](https://github.com/xemu-project/dsp56300/blob/main/crates/emu-ffi/include/dsp56300.h), [quickstart](https://github.com/xemu-project/dsp56300/blob/main/crates/emu-ffi/examples/quickstart.c), and [crate manifest](https://github.com/xemu-project/dsp56300/blob/main/crates/emu-ffi/Cargo.toml) describe the interface. A project-local Rust/Cargo 1.99.1 installation is available under ignored `local-tools/rust-dsp/`; it was used for the first successful FFI build. A later incremental configure accidentally selected the machine's default rustup shim, which installed its declared 1.99.0 toolchain in the user environment and rebuilt successfully. This must be corrected in the documented developer setup so CMake consistently selects the project-local toolchain.
- Candidate source revision for follow-up review: [`82fb25a6917a36ac66212ae31f02aab62211f979`](https://github.com/xemu-project/dsp56300/commit/82fb25a6917a36ac66212ae31f02aab62211f979), the upstream `main` commit observed on 2026-10-17. This is a review pin, not an integrated or build-verified dependency.
- Read-only Cargo tree and metadata resolution for the Windows x86_64 MSVC FFI path completed with the lockfile. The pinned FFI was subsequently compiled from its clean reviewed checkout. Cargo generated its checked-in C header as a build side effect; that header was restored and the dependency checkout is clean again.
- The active normal/build dependency tree resolves to 86 unique package/version pairs, each with a Cargo-declared license expression. Nineteen packages declare Apache-2.0 WITH LLVM-exception, 47 declare MIT OR Apache-2.0, nine declare MIT, five declare Apache-2.0 OR MIT, and the remaining six use `MIT/Apache-2.0`, `Apache-2.0 / MIT`, `(MIT OR Apache-2.0) AND Unicode-3.0`, `Unlicense OR MIT`, Zlib, or MPL-2.0. The exact package/version/metadata inventory is in [the DSP56300 Cargo dependency license record](dsp56300-cargo-dependency-licenses.md).
- Direct crate roles from the pinned manifests:

- **Runtime path:** `dsp56300-core` and `dsp56300-emu` are MIT; the direct Cranelift crates and `target-lexicon` are Apache-2.0 WITH LLVM-exception.
- **Build path:** `cc` is MIT OR Apache-2.0; `cbindgen` is MPL-2.0. `cbindgen` appears as a build dependency, not part of the game runtime. Its build script generates `include/dsp56300.h` and compiles the quickstart C source into a helper archive.
- Inspected the pinned DSP repository's MIT license and representative crate license texts for Apache-2.0 WITH LLVM-exception, MPL-2.0, Zlib, Unlicense OR MIT, and Unicode-3.0. Cranelift's license file includes the LLVM exception; `unicode-ident` carries a separate Unicode license notice. Cargo declares no missing license expressions in the selected graph. This spot-check informs the later notice package but does not replace review of all distributed source files or the final linked binary.
- This is a complete Cargo-declared license-expression inventory for the resolved Windows normal/build graph, not yet a complete redistribution review. The candidate workspace lockfile has 144 entries, including workspace, test, and optional packages outside this selected graph. Before integration, inspect and preserve the relevant license texts/notices for shipped runtime components and verify the actual static-library output. The project-wide license remains undecided.
- An MIT DSP core does not remove the XboxRecomp APU's LGPL obligations. Dependency and notice review is still required before selecting the final project-wide license or distributing binaries.

## Required runtime integration

### Adapter decision

Use the MIT-licensed DSP56300 C FFI as the processor core and write a small XboxRecomp-specific C bridge around it. Reuse xemu for the LGPL APU code already present in XboxRecomp and for behavioral reference; do not copy xemu's GPL `dsp_jit.c` into this bridge. The existing wrapper is tied to xemu's private structures, and directly importing it would add GPL-covered source without making the XboxRecomp integration drop-in. This choice preserves the static x86 game path and avoids introducing a new GPL component. It does not settle the project's overall license; the existing LGPL components and every future dependency still need a full distribution review.

### Unverified engine-lifecycle scaffold

The patch file above adds an off-by-default CMake option that builds the pinned FFI and creates/resets/destroys GP and EP JIT instances over the APU's existing state-owned X/Y/P and mixbin buffers. It checks the dependency revision and clean checkout at configure time. The patch applies to a fresh XboxRecomp v0.13.1 worktree and passes `git diff --check`, but has not been compiled or linked. It does not connect guest MMIO, load/bootstrap firmware, schedule cycles, transfer FIFO/DMA data, or run the core. The existing pass-through remains the runtime behavior; this patch is groundwork only and must not advance audio or FFI lifecycle verification bars.

### Guest-visible memory windows

The local runtime currently routes main APU and Voice Processor MMIO, while GP (`APU base + 0x30000`) and EP (`APU base + 0x50000`) are ignored. Add separate GP and EP dispatch paths for those 64 KiB windows. Keep the current XboxRecomp API's exact access widths and offsets visible in traces while mapping the windows.

The pinned APU register definitions express these subwindow addresses in **bytes**, while the DSP FFI and backing arrays use **24-bit words**. The upstream xemu LGPL APU handler maps the following byte ranges to DSP word addresses; use these boundaries in the future host-access tests:

| Processor | Register window (APU-relative bytes) | Bytes | DSP word addresses |
| --- | --- | ---: | --- |
| GP X memory | `0x0000–0x3FFF` | `0x4000` | X `[0, 0x1000)` |
| GP mixbuffer | `0x5000–0x5FFF` | `0x1000` | X `[0x1400, 0x1800)` |
| GP Y memory | `0x6000–0x7FFF` | `0x2000` | Y `[0, 0x800)` |
| GP P memory | `0xA000–0xDFFF` | `0x4000` | P `[0, 0x1000)` |
| GP reset | `0xFFFC–0xFFFF` | `4` | register, not DSP RAM |
| EP X memory | `0x0000–0x2FFF` | `0x3000` | X `[0, 0xC00)` |
| EP Y memory | `0x6000–0x63FF` | `0x400` | Y `[0, 0x100)` |
| EP P memory | `0xA000–0xDFFF` | `0x4000` | P `[0, 0x1000)` |
| EP reset | `0xFFFC–0xFFFF` | `4` | register, not DSP RAM |

The range ends above are exclusive. Each mapped RAM access is a four-byte aligned register transaction in the upstream handler; XboxRecomp's VEH path supplies a size, so the first tests must establish the game's actual access widths before enforcing the upstream assertion. DSP P writes must go through `dsp56300_write_memory` (or its run variant) when the optional core exists so JIT code is invalidated; directly modifying `core.pram` is only valid for the pass-through fallback. The xemu LGPL `gp_ep.c` is an implementation reference and is not copied by the current patch. Its reset handler resets while either required bit is low and bootstraps on the low-to-high transition of both bits. That bootstrap transition remains deferred until firmware and scratch-transfer behavior are implemented.

Source reference: [xemu GP/EP APU handler](https://github.com/xemu-project/xemu/blob/master/hw/xbox/mcpx/apu/dsp/gp_ep.c) and the pinned XboxRecomp `src/apu/apu_regs.h`. These are upstream semantics; Steel Battalion's complete transaction sequence still needs runtime traces.

The xemu model provides the first address-space map to reconcile with the pinned DSP core:

| Processor | DSP memory exposed through APU MMIO | Initial size indicated by xemu |
| --- | --- | ---: |
| GP | X memory, Y memory, P program memory, and the X mixbin window | X 0x1000 words, Y 0x800 words, P 0x1000 words; mixbin window starts at X address 0x1400 |
| EP | X memory, Y memory, and P program memory | X 0xC00 words, Y 0x100 words, P 0x1000 words |

The v0.13.1 XboxRecomp `DSPState` already allocates GP/EP-compatible backing arrays: XRAM 0x1000, YRAM 0x800, PRAM 0x1000, and a separate 0x400-word mix buffer. A direct FFI memory map can therefore use stable state-owned buffers instead of allocating parallel memory:

| DSP address space | FFI buffer view |
| --- | --- |
| GP X `[0, 0x1000)` | `DSPState.core.xram` |
| GP X `[0x1400, 0x1800)` | `DSPState.core.mixbuffer` |
| GP Y `[0, 0x800)` | `DSPState.core.yram` |
| GP P `[0, 0x1000)` | `DSPState.core.pram` |
| EP X `[0, 0xC00)` | `DSPState.core.xram` |
| EP Y `[0, 0x100)` | `DSPState.core.yram` |
| EP P `[0, 0x1000)` | `DSPState.core.pram` |

These are candidate FFI regions derived from the pinned crate's half-open range contract and XboxRecomp's allocation sizes, reconciled with the existing xemu register definitions; they have not been validated by a C build or guest memory trace. The FFI copies region descriptors during instance creation, but its buffer pointers must remain valid until the instance is destroyed. Route guest P-memory writes through the core's write API or batch-write API so the translated-code cache is invalidated correctly. Confirm the upstream APU's address units, 24-bit masking, unmapped ranges, and overlapping mixbin semantics before runtime use.

### Reset and bootstrap behavior

Static analysis of the user's XBE found GP and EP setup sequences that write reset/control value 1 followed by 3. The xemu reference resets a DSP while either required reset bit is low and bootstraps it on reset release. XboxRecomp now implements a bounded SGE reader through the existing `mcpx_apu_phys()` resolver, so physical addresses select the correct contiguous host mapping. It copies 0x800 words from the guest scratch pages to P memory, masks words to 24 bits, and invalidates the FFI code cache. Direct-RAM reset release is observed by the APU frame path, which retries until the SGE data can be read; the MMIO path handles the transition when invoked there. A synthetic harness verifies page-crossing, masking, and malformed-table rejection. A real title startup log confirmed GP and EP bootstrap success in one watchdog-bounded run. It did not establish that the loaded code is valid or ran. xemu's 512-byte MCPX boot ROM is loaded into the Xbox CPU BIOS address space; its APU initializer receives RAM and not this image. Its presence is therefore not evidence of DSP firmware availability. Do not treat a command-doorbell clear as DSP execution.

### Peripheral callbacks, DMA, and frame scheduling

xemu's GP/EP path performs scratch DMA and circular FIFO transfers through scatter-gather tables, advances FIFO current pointers, writes VP mixbins into GP X memory, runs GP per APU frame, and runs EP on an 8-frame divider. These are reference semantics, not independently verified hardware timing.

The bridge exposes host-owned peripheral callbacks for frame status and DMA registers, plus a bounded scratch-DMA path through the title's guest scatter-gather tables. Synthetic tests verify status reads/clears, register round-tripping, SGE page crossing, 24-bit masking, and malformed-table rejection. A no-ack game trace observed the GP read and clear the start-frame bit at `X:$FFFFC5`, execute DSP routines, and process scratch-DMA nodes without a logged transfer error. This confirms those startup behaviors only; it does not establish the effects-image command result or complete the DSP audio path. The frame path starts a bounded 1,000-cycle FFI run for GP each APU frame and EP every eight frames. The callback stores a halt request for application after the run returns, respecting the FFI's warning not to alter internal execution state mid-block. Readiness to execute is stored separately from the DSP's architectural interrupt flags; an earlier draft conflated them, and its game-run log is discarded as compatibility evidence. The FFI may complete a translated block beyond the requested budget, so the value is a run budget and not a strict maximum. Circular FIFO DMA, the full peripheral model, scheduling limits, and guest-visible command completion remain incomplete. The FFI's interrupt-pipeline fields must not be mutated as a shortcut for peripheral events.

Preserve the existing APU worker's locking, frame pacing, and shutdown lifecycle. Do not call DSP callbacks while holding a lock that their DMA path also needs. Track GP and EP cycle counts separately and bound each work slice so a bad guest program cannot stall the statically translated game indefinitely.

## Work sequence before claiming audio support

1. Keep the reviewed MIT `dsp56300` revision pinned, finish source-text/notice review for the selected static-library output, and record the required Rust toolchain. The adapter decision is to write a narrow XboxRecomp-specific bridge against the MIT API, not copy xemu's GPL bridge.
2. Build only the FFI static library when a safe build window is available; do not install Rust system-wide. Confirm the C header and Windows x64 linker output with a small independent smoke program.
3. Implement GP/EP storage and MMIO routing behind the project's diagnostics while preserving the existing APU register path.
4. Implement and test circular FIFO DMA, mixbin flow, and remaining peripheral semantics, then compare cycle scheduling and output against observed game behavior.
5. Compare observed guest writes, DSP memory, cycle counters, and DMA effects against xemu's behavior; keep xemu-specific assumptions labeled as such.
6. Run a Steel Battalion startup test only when the user is not playing and a test window is permitted. Capture runtime/audio logs and demonstrate real DSP processing and audible game output before advancing those progress bars.

The last step does not prove campaign audio or full campaign compatibility. Those still require mission-by-mission verification.

## Latest implementation checkpoint (2026-10-18)

The lifecycle, scratch-bootstrap, and bounded-frame patches apply in sequence. The focused Windows x64 test and full game executable build. The synthetic harness passes. A later bounded startup run with synthetic AC'97 readiness and no `RECOMP_APU_DSP_ACK` bootstrapped both guest programs, executed GP/EP instructions, and showed the GP frame-status handshake and scratch-DMA callbacks in operation. The P-memory code around the observed wait address was disassembled with the local DSP56300 disassembler; it loops on the frame-status bit while awaiting another APU frame. This corrects the earlier diagnosis that GP zero-cycle slices alone meant the DSP could not make progress. The command-mailbox result, complete FIFO/mixbin behavior, audible output, and title screen are not verified. Next trace the guest command word and DMA writes through the guest alias without a synthetic acknowledgement; preserve the no-ack requirement for compatibility claims.
