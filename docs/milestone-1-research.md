# Milestone 1: Research and Architecture

Updated 2026-10-17. Status: title XBE identified and parsed; architecture evaluated, but runtime selection remains unresolved. No project build or game boot has been attempted.

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

## Architecture status and recommendation

Keep the execution requirement as **ahead-of-time x86 static recompilation plus native compatibility layers**. Do not describe full-system emulation as recompilation. Do not select a runtime solely on the basis of the D3D12 feature: the title's XDK build 4627 is not currently demonstrated to work in that candidate, while the other toolkit's documented Windows renderer is D3D11.

Before implementation, complete a targeted feasibility comparison: confirm whether XboxXBERecomp can add valid XDK 4627 signatures/layout using only redistributable, non-proprietary data; compare function-discovery/lifting coverage against the XBE's 78 sections; and establish whether the D3D11 route could satisfy the required output API without replacing the CPU recompilation model. Preserve the architectural choice for user review before committing to runtime-specific code.

## Input and launcher requirements added by the user

- Add an explicit launcher action to register the installed game as a non-Steam game in the user's Steam library. Keep this opt-in; do not install or change Steam data without the user choosing the action. Steam officially describes adding a non-Steam game as adding a client shortcut, not a Steam store entitlement or Steam-delivered updater ([Steam Support](https://help.steampowered.com/en/faqs/view/4B8B-9697-2338-40EC)). The official path is a user-controlled client flow. Directly editing Steam shortcut data would need separate evaluation because no supported launcher API was identified.
- Support the original Steel Battalion controller. Treat this as a dedicated device/input backend requirement; do not assume it presents itself as a standard XInput gamepad. The controller is reported as an unknown USB device on Windows and is not HID-compliant. A community driver converts its 32-byte input report to HID, but it is a GPL-3.0 kernel-mode driver ([SteelBattalionDriver](https://github.com/caosdoar/SteelBattalionDriver)); its 2019 Windows setup guide requires test-signing mode and a restart ([driver article](https://medium.com/@oscarsc/writing-a-driver-for-the-steel-battalion-controller-e1e4311f1a40), [setup steps](https://medium.com/@oscarsc/how-to-use-the-steel-battalion-controller-on-windows-10-2e21aa8ccd28)). It is not suitable as an automatically installed dependency. A native application cannot assume ordinary HID/SDL APIs can access this device without an installed device driver or a hardware adapter that presents it as standard HID. Any project-owned driver would require separate architecture, signing, installation-consent, and license review. Physical-device validation remains required. Mouse/keyboard and modern controller support remain additional input requirements.

## Environment and verification limits

- Windows 11 Pro x64, Git 2.55.0 and .NET SDK 10.0.204 are available. Python, `py`, CMake, MSVC, and a local ISO extraction utility were not found on PATH. No dependencies were installed.
- ISO root and XDVDFS partition were examined by reading the existing image. `default.xbe` was extracted only to an ignored local-analysis path, then the image metadata, header, section table, library versions, and kernel ordinal table were inspected.
- No code was generated, no compiler or test was run, and no rendering, audio, input, performance, or title-screen behavior has been verified.
- The repository has been initialized on `main`. `README.md` and `.gitignore` are staged. No initial commit exists because Git has no author identity configured; do not invent or globally alter identity.

## Next steps

1. Finish the runtime feasibility comparison for XDK 4627, including an exact full ordinal/API inventory and per-section function discovery feasibility.
2. Research original Steel Battalion controller user-mode HID support and Steam shortcut registration, preserving opt-in behavior.
3. Resolve the static recompilation runtime choice before implementation, then proceed through milestones under the active project goal. Keep all game data/generated code out of Git and do not claim a boot until verified.


