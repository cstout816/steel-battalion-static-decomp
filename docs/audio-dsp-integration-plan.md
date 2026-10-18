# MCPX GP/EP DSP integration plan

**Status:** research and interface analysis only. No DSP core has been integrated, and no audio behavior is verified.

## Execution architecture

The Xbox x86 game remains statically translated by XboxRecomp and runs against its Windows compatibility runtime. The MCPX Global Processor (GP) and Encode Processor (EP) are separate DSP56300 coprocessors. Using a DSP56300 JIT for those two processors would emulate the audio coprocessors only; it would not replace the game's static x86 translation with full-system Xbox emulation. The runtime and its documentation must describe those paths separately.

## Reuse and licensing findings

- The local XboxRecomp APU is extracted from xemu and marks its APU files LGPL-2.1-or-later. Its existing notice and license files must continue to ship with any redistributed build.
- [xemu's GP/EP APU implementation](https://github.com/xemu-project/xemu/blob/master/hw/xbox/mcpx/apu/dsp/gp_ep.c) supplies useful behavioral reference for MMIO windows, reset transitions, scatter-gather transfers, FIFOs, mixbin flow, and frame scheduling. The file is LGPL-2.1-or-later. Keep any direct reuse isolated, attributed, and under its applicable license.
- xemu's current [Rust JIT bridge](https://github.com/xemu-project/xemu/blob/master/hw/xbox/mcpx/apu/dsp/dsp_jit.c) already connects the DSP56300 C FFI to xemu's APU. It demonstrates persistent host-owned X/Y/P buffers, a callback-backed peripheral region, scratch-to-program-memory bootstrap with 24-bit masking and cache invalidation, and batched state synchronization. That bridge is GPL-2.0-or-later and depends on xemu's private `DSPState` and DMA types; it is a behavioral and architectural reference, not a drop-in file for XboxRecomp. Reuse would require preserving its GPL terms and reviewing the project's combined license obligations.
- The DSP56300 emulator depends on Cranelift. Bytecode Alliance documents x86-64 code generation, the Windows x64 calling convention, and Windows as a supported host OS for JIT use. This makes the requested Windows x64 target plausible, but it does not replace a local Windows x64 build and smoke check of this specific crate combination.
- [xemu-project/dsp56300](https://github.com/xemu-project/dsp56300) is MIT-licensed and publishes a C FFI crate as a Rust static library. Its pinned workspace declares Rust 1.99 and edition 2024. The official [FFI header](https://github.com/xemu-project/dsp56300/blob/main/crates/emu-ffi/include/dsp56300.h), [quickstart](https://github.com/xemu-project/dsp56300/blob/main/crates/emu-ffi/examples/quickstart.c), and [crate manifest](https://github.com/xemu-project/dsp56300/blob/main/crates/emu-ffi/Cargo.toml) describe the interface. Rust/Cargo 1.99.1 are available project-locally under ignored `local-tools/rust-dsp/`; the FFI library has not been built or tested here.
- Candidate source revision for follow-up review: [`82fb25a6917a36ac66212ae31f02aab62211f979`](https://github.com/xemu-project/dsp56300/commit/82fb25a6917a36ac66212ae31f02aab62211f979), the upstream `main` commit observed on 2026-10-17. This is a review pin, not an integrated or build-verified dependency.
- A project-local Rust 1.99.1/Cargo 1.99.1 installation was added under ignored `local-tools/rust-dsp/`; no system-wide toolchain was installed. Read-only Cargo tree and metadata resolution for the Windows x86_64 MSVC FFI path completed with the lockfile. This did not compile the library or run tests.
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

### Guest-visible memory windows

The local runtime currently routes main APU and Voice Processor MMIO, while GP (`APU base + 0x30000`) and EP (`APU base + 0x50000`) are ignored. Add separate GP and EP dispatch paths for those 64 KiB windows. Keep the current XboxRecomp API's exact access widths and offsets visible in traces while mapping the windows.

The xemu model provides the first address-space map to reconcile with the pinned DSP core:

| Processor | DSP memory exposed through APU MMIO | Initial size indicated by xemu |
| --- | --- | ---: |
| GP | X memory, Y memory, P program memory, and the X mixbin window | X 0x1000 words, Y 0x800 words, P 0x1000 words; mixbin window starts at X address 0x1400 |
| EP | X memory, Y memory, and P program memory | X 0xC00 words, Y 0x100 words, P 0x1000 words |

Use independently owned word buffers or stable callback state for each DSP instance. The C FFI requires mapped buffers and callback context to remain valid for the instance lifetime. Route guest P-memory writes through the core's write API or batch-write API so its translated-code cache is invalidated correctly. Confirm the upstream APU's address units, 24-bit masking, unmapped ranges, and overlapping mixbin semantics before adopting these sizes verbatim.

### Reset and bootstrap behavior

Static analysis of the user's XBE found GP and EP setup sequences that write reset/control value 1 followed by 3. The xemu reference resets a DSP while either required reset bit is low and bootstraps it on the transition to both bits high. The C FFI does not provide a named bootstrap operation. xemu's bridge implements bootstrap in host code by loading scratch memory into P memory, masking words to 24 bits, and invalidating the JIT cache. Adapt this behavior to XboxRecomp's memory layout only after confirming its scratch DMA and bootstrap contract. Do not treat a command-doorbell clear as DSP execution.

### Peripheral callbacks, DMA, and frame scheduling

xemu's GP/EP path performs scratch DMA and circular FIFO transfers through scatter-gather tables, advances FIFO current pointers, writes VP mixbins into GP X memory, runs GP per APU frame, and runs EP on an 8-frame divider. These are reference semantics, not independently verified hardware timing.

The C FFI provides memory callbacks and run-cycle functions, but its callback documentation says callbacks must not modify the DSP's internal registers, stack, or PC while compiled code is running. Build host-owned callback state for scratch/FIFO DMA and peripheral registers. xemu handles start-frame and DMA status in host-side peripheral state read and written through DSP callbacks; its shared frame hook sets a peripheral flag rather than requiring a new FFI interrupt API. Reproduce only after validating the XboxRecomp callback ordering and guest-visible read/clear semantics. The FFI's interrupt-pipeline fields are for core state synchronization and should not be mutated as a shortcut for peripheral events.

Preserve the existing APU worker's locking, frame pacing, and shutdown lifecycle. Do not call DSP callbacks while holding a lock that their DMA path also needs. Track GP and EP cycle counts separately and bound each work slice so a bad guest program cannot stall the statically translated game indefinitely.

## Work sequence before claiming audio support

1. Keep the reviewed MIT `dsp56300` revision pinned, finish source-text/notice review for the selected static-library output, and record the required Rust toolchain. The adapter decision is to write a narrow XboxRecomp-specific bridge against the MIT API, not copy xemu's GPL bridge.
2. Build only the FFI static library when a safe build window is available; do not install Rust system-wide. Confirm the C header and Windows x64 linker output with a small independent smoke program.
3. Implement GP/EP storage and MMIO routing behind the project's diagnostics while preserving the existing APU register path.
4. Add reset/bootstrap, peripheral callback, scratch/FIFO, start-frame, and bounded cycle-scheduling behavior, each with isolated synthetic tests.
5. Compare observed guest writes, DSP memory, cycle counters, and DMA effects against xemu's behavior; keep xemu-specific assumptions labeled as such.
6. Run a Steel Battalion startup test only when the user is not playing and a test window is permitted. Capture runtime/audio logs and demonstrate real DSP processing and audible game output before advancing those progress bars.

The last step does not prove campaign audio or full campaign compatibility. Those still require mission-by-mission verification.
