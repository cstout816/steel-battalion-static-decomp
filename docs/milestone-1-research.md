# Milestone 1: Research and Architecture

Updated 2026-10-17. Architecture: user selected sp00nznet/xboxrecomp. Milestone 2 is complete; Milestone 3 boot work is in progress but currently blocked before the title screen. The game has not been successfully booted.

## Disc and executable evidence

- Local image: `iso/Steel Battalion (USA).iso` (7,825,162,240 bytes). The original ISO was only read; no bytes were written back to it.
- The ISO 9660 compatibility volume exposes `VIDEO_TS`; the game is in an XDVDFS partition. The XDVDFS header magic was verified at byte offset `0x18310000` (partition base `0x18300000` plus `0x10000`). This matches the documented XGD1 Redump layout. The ISO/XDVDFS format and offsets are described by the [xboxrecomp disc image notes](https://github.com/sp00nznet/xboxrecomp/blob/main/docs/formats/disc-image.md) and the [XDVDFS technical reference](https://purelogiccode.github.io/XISOStudio/XDVDFS-Technical-Documentation.html).
- The XDVDFS root names `default.xbe`, 6,635,520 bytes. A local analysis copy is at `iso/local-analysis/default.xbe`; the entire `iso/` tree is ignored by Git.
- Parsed header magic is `XBEH`; title certificate says `STEEL BATTALION`, title ID `0x43430002`, base address `0x00010000`, 78 sections, 6,740-byte header, and 10,546,272-byte image.
- Retail-decoded entry point is `0x00192C47`, inside `.text` (`0x00012000`, 2,073,036 bytes). Retail-decoded kernel thunk table VA is `0x0025D0E0`, mapped to the start of `.rdata`.
- XDK library versions are all build 4627: `XAPILIB`, `D3D8`, `XGRAPHC`, `DSOUND`, `DMUSIC`, `XBOXKRNL`, and `LIBCMT`. The executable has no non-kernel import directory. Its XBE kernel thunk table contains 123 ordinal imports.
- Other notable sections include `D3D`, `XGRPH`, `DSOUND`, `DOLBY`, `XPP`, Bink code/data, `.text`, `.rdata`, and `.data`. Many `seg00`–`seg50` sections are executable. This indicates the XBE includes statically linked XDK/middleware code and that recompiler coverage cannot be assessed from `.text` alone.
- All 123 kernel thunk ordinals were mapped against the Xbox kernel ordinal table; the local `iso/local-analysis/kernel-imports.csv` is ignored by Git and records slot, ordinal, and export name. Examples include `NtAllocateVirtualMemory` (184), `NtClose` (187), `NtFreeVirtualMemory` (199), `NtSetInformationFile` (226), `NtQueryVirtualMemory` (217), `RtlEnterCriticalSection` (277), and `RtlLeaveCriticalSection` (294).
- A SHA-256 fingerprint was computed locally for the extracted XBE; it is intentionally not reproduced here. This XBE is copyrighted user-supplied material and must remain ignored/unpublished.

The XBE header format and retail/debug XOR decoding used here are cross-checked against the [XBE layout in Cxbx-Reloaded](https://github.com/Cxbx-Reloaded/Cxbx-Reloaded/blob/master/src/common/xbe/Xbe.h), [xemu's packed XBE header](https://github.com/xemu-project/xemu/blob/master/xemu-xbe.h), and the [XboxDevWiki XBE reference](https://xboxdevwiki.net/Xbe). This verifies format and key metadata; it does not verify runtime compatibility, complete control flow, or game behavior.

## Candidate execution architectures

Static recompilation is feasible in principle for this XBE: it is a retail x86 XBE with a conventional image header, section map, and kernel ordinal thunk table. A native port still needs comprehensive function discovery/lifting and an Xbox compatibility runtime. This remains a feasibility assessment, not proof that the title can boot.

### XboxXBERecomp

The MIT-licensed [XboxXBERecomp](https://github.com/TGP482/XboxXBERecomp) translates XBE x86 code ahead of time to C++ and documents a Windows x64 executable with an Xbox API layer, Direct3D 8 translation to native Direct3D 12, XAudio2, and SDL3 input. This most closely matches the requested graphics API.

**Title-specific gap:** the public repository tree reviewed for this milestone exposes `xdk/5849`, while this XBE identifies its XDK libraries as build 4627. Its tool documentation says symbol identification selects signatures for the XBE's XDK build and stops if no corresponding signatures exist. Therefore it cannot be assumed to process this title unchanged. Supporting build 4627 may require generating/validating a new layout and signature set or modifying the analysis tool; neither has been done.

### sp00nznet/xboxrecomp

The MIT-licensed [xboxrecomp](https://github.com/sp00nznet/xboxrecomp) is an alternative static XBE-to-C toolkit. Its Windows graphics layer is documented as D3D8-to-D3D11, so it does not meet the requested D3D12 target as documented. It includes runtime compatibility components, some derived from xemu and separately licensed; any dependency combination and distribution obligations need a component-by-component license review. It may still be useful for cross-checking XBE parsing, function boundaries, or APIs. A read-only comparison of the current `kernel_thunks.c` source against this XBE found case entries for all 123 imported ordinals. `DbgPrint` (ordinal 8) routes to `xbox_Unknown_8`. This proves dispatch-table coverage only; the presence of a case does not prove correct behavior for Steel Battalion.

### Cxbx-Reloaded and xemu

[Cxbx-Reloaded](https://github.com/Cxbx-Reloaded/Cxbx-Reloaded) and [xemu](https://github.com/xemu-project/xemu) are original Xbox emulators, not static recompilers. They remain useful behavioral references for kernel, D3D8/NV2A, audio, and input semantics. They are not proposed as the game's execution core. No emulator code has been incorporated.

## Architecture decision

On 2026-10-17, the user selected **sp00nznet/xboxrecomp** as the static-recompilation runtime. The intended execution model remains ahead-of-time x86 translation plus Xbox compatibility layers. Full-system emulation is not an approved substitute. Begin Milestone 2 with local XBE analysis and a first runtime-specific translation assessment.

The selected toolkit's documented Windows renderer is D3D8-to-D3D11, not D3D12. This is an acknowledged mismatch with the original graphics API request, not a claim that D3D12 is supported. First establish whether this title can be statically translated and reach a baseline boot using the selected runtime. Any later D3D12 renderer replacement or port requires technical feasibility analysis and must preserve the approved static-recompilation CPU architecture. xboxrecomp has not been shown to support this title or XDK build 4627; no successful boot or rendering is claimed.

## Input and launcher requirements added by the user

- Add an explicit launcher action to register the installed game as a non-Steam game in the user's Steam library. Keep this opt-in; do not install or change Steam data without the user choosing the action. Steam officially describes adding a non-Steam game as adding a client shortcut, not a Steam store entitlement or Steam-delivered updater ([Steam Support](https://help.steampowered.com/en/faqs/view/4B8B-9697-2338-40EC)). The official path is a user-controlled client flow. Directly editing Steam shortcut data would need separate evaluation because no supported launcher API was identified.
- Support the original Steel Battalion controller. Treat this as a dedicated device/input backend requirement; do not assume it presents itself as a standard XInput gamepad. The controller is reported as an unknown USB device on Windows and is not HID-compliant. A community driver converts its 32-byte input report to HID, but it is a GPL-3.0 kernel-mode driver ([SteelBattalionDriver](https://github.com/caosdoar/SteelBattalionDriver)); its 2019 Windows setup guide requires test-signing mode and a restart ([driver article](https://medium.com/@oscarsc/writing-a-driver-for-the-steel-battalion-controller-e1e4311f1a40), [setup steps](https://medium.com/@oscarsc/how-to-use-the-steel-battalion-controller-on-windows-10-2e21aa8ccd28)). It is not suitable as an automatically installed dependency. A native application cannot assume ordinary HID/SDL APIs can access this device without an installed device driver or a hardware adapter that presents it as standard HID. Any project-owned driver would require separate architecture, signing, installation-consent, and license review. Physical-device validation remains required. Mouse/keyboard and modern controller support remain additional input requirements.

## Environment and verification limits

- At the Milestone 1 research checkpoint, Windows 11 Pro x64, Git 2.55.0 and .NET SDK 10.0.204 were available. Visual Studio Build Tools 2022 had MSVC x86/x64 and Windows SDK 19041, but `cl.exe` was not on PATH. CMake, Ninja, and Clang were not found on PATH or among checked Visual Studio components. A Codex-managed Python 3.12.14 runtime lacked Capstone. Local-only tool setup is recorded below.
- ISO root and XDVDFS partition were examined by reading the existing image. `default.xbe` was extracted only to an ignored local-analysis path, then the image metadata, header, section table, library versions, and kernel ordinal table were inspected.
- At the Milestone 1 checkpoint, no code had been generated and no compiler or test was run. See the Milestone 2 progress record below for later analysis/codegen. No native executable, boot, rendering, audio, input, or performance result has been verified.
- The repository is on `main`; the initial setup is committed, and the architecture research was committed locally as `bc3a034`. That commit is one commit ahead of `origin/main` and has not been pushed. The repository-local author identity is `cstout816 <cstout816@live.com>`.

## Milestone 2 result

- Full static translation completed for 9,125 functions: 2,331,961 lines of C across 37 chunks (about 97.7 MiB), with zero function-level translation failures. The upstream summary reported 351 unresolved call targets stubbed and 287 unsupported instruction sites (38 mnemonics) emitted as no-op comments. These gaps can alter game behavior; successful translation/build does not establish correctness.
- The first build exposed a shift-count bug in xboxrecomp v0.13.1: x86 masks shift counts to five bits, but its C output used an immediate count such as `0xA7` directly, producing MSVC C4293 warnings and undefined C behavior. The isolated patch [`patches/xboxrecomp-v0.13.1-shift-count.patch`](../patches/xboxrecomp-v0.13.1-shift-count.patch) masks counts, preserves the zero-count no-op, and avoids out-of-range carry shifts. Its MIT notice is retained under [`third_party/licenses/xboxrecomp-MIT.txt`](../third_party/licenses/xboxrecomp-MIT.txt); see [`third_party/README.md`](../third_party/README.md).
- After applying the patch, a targeted generated-C test compiled and ran on MSVC, checking `SHL EAX, 0xA7` against the masked result and checking a count of `0x20` preserves value/flag snapshots; both checks passed. The full generated C was regenerated and rebuilt.
- CMake configured and MSVC built the local xboxrecomp game template successfully. The result is a 103,068,160-byte x64 Windows PE (`0x8664`) at ignored path `local-tools/steel-battalion-game/build/Release/your_game_recomp.exe`. The first build showed two C4293 warnings; the corrected build completed successfully with no such warnings observed. The local executable and game-derived source remain ignored. No smoke-test executable was run.
- This is a native host executable containing statically translated x86 code and xboxrecomp compatibility libraries, not a full-system emulator. It remains a build artifact, not a verified game launch: the template still needs a real user XBE/assets path, the XBE data set has not been fully extracted, and no boot/title-screen/render/audio/input check has run. The runtime renderer is D3D11, not the requested D3D12.

### Milestone 2 verification limits and known issues

- Function boundaries, ABI classifications, and control flow are heuristic. The 9,125 generated functions are not proof of complete or accurate execution coverage.
- 351 unresolved targets route through generated stubs. The 287 unsupported instructions become no-op comments. Either can prevent startup or corrupt game behavior.
- Original controller support, kernel/D3D8/audio fidelity, the 4627-specific runtime paths, asset loading, title-screen boot, Steam integration, and performance are unverified.
- Generated C, the XBE, ISO, temporary build harness, and executable are all ignored by Git. The original ISO remains untouched. Local branch changes have not been pushed.

## Next milestone

Milestone 3 is to configure the real XBE/data paths, implement only the compatibility fixes needed for startup, and attempt a boot to the title screen. It must begin only after the user approves moving beyond Milestone 2. The project is not ready for graphics enhancements.



## Milestone 1 feasibility update (2026-10-17)

### Recompiler comparison

The XBE metadata continues to support the feasibility of static recompilation: it is a retail x86 XBE with a conventional image header, entry point, section table, and kernel thunk table. Its XDK build is 4627. It has 78 sections, including many executable `segXX` sections and statically linked D3D/XAPI/audio code, so a `.text`-only scan is inadequate. Exact function and control-flow coverage is still unmeasured.

## Milestone 2 progress (2026-10-17)

- The user selected sp00nznet/xboxrecomp. Its upstream `v0.13.1` tag resolves locally to commit `193e2995ffaec871bb3be43a43bd66aa5fccfeb1`. The source checkout is under ignored `local-tools/xboxrecomp`; Capstone 5.0.9 is installed under ignored `local-tools/python-packages`. No machine-wide dependency was installed.
- The upstream XBE parser successfully re-parsed the local XBE: retail `XBEH`, build-4627 libraries, entry point `0x00192C47`, 78 sections, and 123 kernel imports. Its JSON report stays in ignored `iso/local-analysis/`.
- xboxrecomp disassembled all 76 sections marked executable (including D3D, DSOUND, Bink, XPP, `seg00`–`seg50`, DOLBY, and BINKDATA): 2,282,732 instructions, 237,767 cross-references, and 9,058 initial function candidates. The run completed in 122.92 seconds. The heuristic then classified 15,346 functions after vtable scanning (10,677 categorized as game; 4,657 unknown). The large gap between initial and classified counts includes 6,288 discovered vtable thunks; these are heuristic candidates, not verified functions.
- ABI analysis produced 9,058 entries, including 963 detected as `thiscall`. This remains static heuristic output; calling conventions and function boundaries need runtime or manual validation.
- A targeted translation of entry point `0x00192C47` succeeded. The generated C represents 114 bytes / 42 instructions and calls other untranslated title functions. It is saved locally at `iso/local-analysis/xboxrecomp-generated/entry_point.c` and is ignored by Git. The upstream translation setup loaded/adjusted the full function database and took about 92 seconds even for one function.
- No title-wide generated program or native Windows executable has been produced. CMake 4.4.4 and Ninja 1.13.2 are now installed only under ignored `local-tools/python-packages`. CMake successfully configured the xboxrecomp runtime using Visual Studio Build Tools 2022 (MSVC 19.44.35229.0) and Windows SDK 10.0.26100.0; no compile/build was run. No game boot, rendering/audio/input test, or performance run was performed.
- Analysis and codegen artifacts are explicitly ignored (`iso/` and `local-tools/`). The original ISO remains untouched. These files contain title-derived metadata/code and must not be staged or uploaded.

### Milestone 2 next work

Finish the initial translation and determine whether a title-specific Windows executable can be built with the configured local CMake/Ninja setup and installed MSVC tools. Before any resource-intensive full-title code generation or build, confirm that the user is not currently playing a game, per the user's instruction. Do not install system-wide tools. If a full-title executable requires a major architectural change, stop and get the user's decision.

- **Xbox XBE Recomp** (MIT) remains the closest existing D3D12 architecture. Its current upstream README says XDK matching selects `xdk/<build>/signatures.toml` and stops if the pack is absent; the public tree currently lists only `xdk/5849`. Supporting this XBE would therefore require a build-4627 layout/signature pack, then title-specific verification. The docs say packs are generated from fully configured title images using masked function lengths/hashes and include no library code. This suggests a route that avoids redistributing proprietary SDK files, but generation, title coverage, and whether the metadata should ship remain unverified. Source: [Xbox XBE Recomp README](https://github.com/TGP482/Xbox-XBERecomp).
- **sp00nznet/xboxrecomp v0.13.1** (MIT core with separately licensed LGPL-2.1-or-later xemu-derived APU/NV2A components) is more immediately useful for XBE analysis: its parser and disassembler derive section layout from the XBE and can analyze all code sections; its docs explicitly warn that `.text`-only misses executable library sections. Its documented Windows runtime translates D3D8 to D3D11, which does not match the requested D3D12 target. The public `xboxdashboard` project shows a static recompilation on XDK build 3944 reaching substantial startup/kernel work, but its current notes still say it has not rendered a scene. This is evidence that the pipeline is real and useful, not that Steel Battalion boots or that build 4627 is fully supported. Sources: [xboxrecomp README](https://github.com/sp00nznet/xboxrecomp), [Getting Started](https://github.com/sp00nznet/xboxrecomp/blob/main/docs/GETTING_STARTED.md), [xboxdashboard status](https://github.com/sp00nznet/xboxdashboard).
- **Cxbx-Reloaded** and **xemu** remain emulator references only. Their execution cores are not proposed for the native game's runtime.

At this earlier research checkpoint, the D3D12-oriented Xbox XBE Recomp candidate appeared closest to the graphics request, while xboxrecomp's Windows renderer was D3D11. The user's subsequent explicit selection of xboxrecomp supersedes the provisional Xbox XBE Recomp recommendation. The selected runtime preserves the static-recompilation CPU architecture; its D3D11 renderer limitation remains recorded above.

### Input feasibility

The original controller has many independent switches/buttons, several analog controls and pedals; a generic XInput gamepad mapping cannot preserve the full layout. The local XBE import table contains kernel device/I/O functions but no obvious XInput import names; XAPI is statically linked, so the actual controller query path must be found in code analysis before claiming compatibility.

Cxbx-Reloaded documents a WinUSB-compliant driver as an optional prerequisite for USB pass-through of original Xbox and Steel Battalion controllers. Its emulator cannot be adopted as the game's runtime, but this establishes WinUSB pass-through as a concrete input research lead. A separate Windows driver project exposes the Steel Battalion controller as HID but is GPL-3.0 and its installation instructions require privileged driver setup. No driver should be bundled or installed automatically. A candidate design is an opt-in native WinUSB/XID backend or a separately installed HID driver, selected only after validating actual reports and mapping the full original control surface. This remains unverified without code-level XID analysis and physical-controller testing. Sources: [Cxbx-Reloaded prerequisites](https://github.com/Cxbx-Reloaded/Cxbx-Reloaded), [SteelBattalionDriver](https://github.com/caosdoar/SteelBattalionDriver), [Microsoft HID/Raw Input overview](https://learn.microsoft.com/en-us/windows/win32/inputdev/about-raw-input).

### Environment and gate

The GitHub repo is private at `https://github.com/cstout816/steel-battalion-static-decomp`; only code/docs are tracked and the ISO/XBE remain ignored. The local worktree has `main` tracking `origin/main`, with the current README and research updates still uncommitted. Visual Studio Build Tools 2022 provides MSVC x86/x64 and Windows SDK 19041, but CMake, Ninja, and Clang are missing. The bundled Python 3.12.14 has no Capstone or pytest. No game build or test has been run and no dependency was installed.

Milestone 1 has enough evidence to make the architecture choice concrete, but implementation is gated on user approval. Next: approve the recommended Xbox XBE Recomp + build-4627 feasibility path, or choose a different architecture. After approval, Milestone 2 can generate local-only function/control-flow analysis and a first recompiled build. Do not push these latest note corrections to GitHub without renewed authorization.

### Build-4627 bootstrap risk refinement

A direct read of Xbox XBE Recomp's current `xdk/5849/layout.toml` and `signatures.toml` clarifies the build-port work. The 5849 layout contains internal D3D8 device offsets, DSOUND structure offsets, and XAPI XPP device-record offsets. Its comments say these values were proven from specific 5849 XBE code (`default.xbe` for Splinter Cell: Double Agent and `sc4_adv.xbe`). The signatures file contains per-function hashes/call fingerprints and explicitly says it stores no library bytes. Sources: [5849 layout](https://raw.githubusercontent.com/TGP482/Xbox-XBERecomp/main/xdk/5849/layout.toml), [5849 signatures](https://raw.githubusercontent.com/TGP482/Xbox-XBERecomp/main/xdk/5849/signatures.toml).

Therefore the 4627 candidate requires more than adding a version folder: a new layout must be recovered and validated from 4627 code, and a signature database requires a completed title configuration. No evidence shows that the tool can bootstrap these from an unsupported XBE automatically. This may be possible using this locally owned XBE plus manual code analysis and the independent xboxrecomp analysis pipeline, without proprietary SDK files, but it is a material engineering risk. Keep all generated symbol/signature metadata local until its origin, licensing, and redistribution are reviewed. Do not begin the tool-specific XBE analysis/recompilation step until the user approves the architecture gate.

### Redistribution and controller dependency review

- Xbox XBE Recomp's current `THIRD_PARTY.txt` lists toml++ and Dear ImGui under MIT and SDL3 under its permissive zlib-style license. This is compatible with the candidate's MIT license with notices preserved. Source: [Xbox XBE Recomp third-party notices](https://raw.githubusercontent.com/TGP482/Xbox-XBERecomp/main/THIRD_PARTY.txt).
- xboxrecomp's core is MIT, while its NOTICE identifies specific xemu-derived APU and NV2A register files under LGPL-2.1-or-later. The NOTICE says distribution must retain notices, provide LGPL source, and let users relink modified library code. That does not make MIT reuse inherently incompatible, but it adds distribution and packaging work. Source: [xboxrecomp NOTICE](https://raw.githubusercontent.com/sp00nznet/xboxrecomp/main/NOTICE), [license](https://raw.githubusercontent.com/sp00nznet/xboxrecomp/main/LICENSE).
- For the physical controller, prefer investigating Microsoft's WinUSB user-mode path before adopting a bundled third-party driver. Cxbx-Reloaded lists WinUSB as necessary for USB pass-through; the SteelBattalionDriver is GPL-3.0 and exposes HID via a kernel driver. Neither path has been validated with this controller on the user's Windows 11 machine. Do not include driver binaries or automate driver binding; make any required device-driver setup explicit and opt-in. The app-side adapter and control mapping remain unimplemented.
- These checks are preliminary license reviews, not legal advice. The actual dependency revisions and build linkage must be reviewed again before choosing the repository license or preparing a release. No license file has been added yet.

## Milestone 3 boot attempt (2026-10-17)

- Extracted the full XDVDFS game partition (1,230 files, 1,808,157,592 bytes) from the user's ISO into ignored `iso/local-analysis/game_files/`. The ISO remained read-only. The local harness now points at that extracted `default.xbe` and game-data directory; these absolute paths are local-only and are not tracked.
- Built and launched the local AMD64 executable. It loaded the XBE, initialized the Xbox memory layout and kernel replacement, resolved all 123 imported kernel thunks, and entered `0x00192C47`. The first run repeatedly called ungenerated addresses in the executable D3D section and reached the 45-second watchdog with no window.
- Used xboxrecomp's `seed_from_log` validation against the execution log: 23 runtime-seen addresses (including the thread start routine and D3D call targets) passed executable-section and function-body checks. Re-disassembled with those seeds and translated 9,147 functions (0 failures; 2,333,179 C lines; 351 unresolved stubs; 287 unsupported instruction sites emitted as no-op comments). The local MSVC Release rebuild succeeded.
- Second launch no longer logged unresolved D3D indirect-call targets. It reached `KeConnectInterrupt` setup and executed unsupported `out dx, al` and `wbinvd` instructions as configured no-ops, then stalled through the 45-second watchdog. Diagnostics showed NV2A USER PUT and GET both at `0x495C` and no visible window. The process exited with code 3 after the watchdog. This supports a D3D/NV2A initialization or progress gap, but does not identify its exact root cause.
- Verified: image extraction, executable launch and XBE entry, kernel thunk resolution, two watchdog-bounded startup attempts, seed validation, translation and native rebuild. Not verified: title screen, working graphics/rendering, audio, input, Steam integration, physical Steel Battalion controller, or performance. No smoke tests were run.
- Known issues remain substantial: 351 unresolved call stubs, 287 no-op instruction sites, unsupported `out`/`wbinvd` paths reached at runtime, and the D3D11 backend. The stalled GPU command path and controller remain unverified. All game-derived files/logs are ignored; no ISO modifications, GitHub publication, or dependency installs occurred.
- Milestone 3 is **not complete**. This is a hard compatibility roadblock, so stop before Milestone 4. Next decision: continue targeted D3D/NV2A/kernel investigation within xboxrecomp, or pause for an architecture re-evaluation. Do not substitute emulation or switch recompilers without explicit user approval.


### Milestone 3 continuation: vector 3 ISR investigation (2026-10-17)

- After the user's instruction to continue, inspected vector 3 setup. `KeConnectInterrupt` registers `0x002169F0`, but runtime vblank diagnostics said the ISR could not be called because that entry was absent from generated dispatch.
- Validated `0x002169F0` with xboxrecomp's disassembler: it is in executable section `D3D`, and `probes_as_function_body()` succeeds. Added the observed target to ignored `iso/local-analysis/seeds_m3.json`, regenerated disassembly and ABI metadata, and translated 9,148 functions with zero translation failures (2,333,469 lines across 37 source chunks). The translation reported 288 unsupported instruction sites emitted as no-op comments (38 mnemonics) and 351 unresolved call targets.
- Confirmed generated C contains the ISR entry and updated the vblank trace list. A full MSVC rebuild began, but was stopped when process inspection showed the user was running a game. Do not resume the build or runtime test until the user is done playing. The new executable and ISR behavior are therefore unverified.
- Current milestone status: still incomplete before the title screen. Next action after the user is no longer playing: rebuild the local executable and run the bounded vblank-enabled startup check, then inspect ISR traces and unsupported `in al, dx` behavior in the ISR. Do not start later milestones or enhancements until the game reaches the required title-screen baseline and the milestone gate is satisfied.

### Milestone 3 continuation: static inspection of the ISR I/O path (2026-10-17)

- Current process inspection still shows the user's `Bloodborne` game running. Resource-intensive build and runtime checks remain paused.
- Static disassembly confirms the seeded ISR `sub_002169F0` conditionally executes `in al, dx` from port `0x80C0`, uses bit 5 to update its D3D interrupt state, then may queue a DPC. Its D3D initialization routine `sub_00217A16` writes `AL=0` to the same port before querying PCI configuration with `HalReadWritePCISpace` and registering the vector 3 ISR.
- The XboxDevWiki I/O map places `0x80C0` within the LPC power-management range `0x8000–0x80FF`, but the map is explicitly marked incomplete and gives no per-register semantics. This narrows the hardware block without establishing what bit 5 means or what value a read should return. Source: [XboxDevWiki memory and I/O map](https://xboxdevwiki.net/Memory).
- The generated ISR currently leaves the `IN` instruction as `RECOMP_UNIMPL`; inventing a return value could falsely claim an interrupt and corrupt event state. No matching `0x80C0` behavior was found in the reviewed local runtime or targeted public Cxbx-Reloaded/xemu source searches. Resolve this mapping from reliable Xbox hardware/runtime evidence before implementing port behavior.
- No updated executable was produced and no ISR call has been runtime-verified. Next safe step remains a rebuilt, vblank-enabled diagnostic after the user is done playing, preceded by a reviewed port-I/O model if evidence identifies the hardware semantics.

### Boot-trace diagnosis refinement (2026-10-17)

- The saved `runtime-m3-vblank.stderr.log` shows `KeConnectInterrupt` registering vector 3 to `0x002169F0`, followed by repeated `[NV2A] vblank -> ISR not callable` messages. The same run reports the NV2A MMIO aperture was zeroed with no register semantics and only six busy-bit acknowledgements were enabled; later it times out in the early D3D path with PFIFO `PUT=0`, `GET=0`.
- This trace predates the latest ISR-inclusive generated sources: the executable timestamp is 15:20:25, while `recomp_0031.c` and `recomp_dispatch.c` were generated at 15:33:21. Therefore the old “ISR not callable” result does not test the newly seeded ISR, and the `IN` at `0x80C0` is not yet shown to be the startup blocker. The broader confirmed limitation is that this run had no functional NV2A register model. Rebuild and rerun after the game process is closed, then determine whether the current ISR is dispatched before diagnosing the port read.
