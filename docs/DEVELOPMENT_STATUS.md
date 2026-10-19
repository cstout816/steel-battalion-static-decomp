# Development status

This page is for people who want the detailed engineering tracker. The project is experimental. A local diagnostic run has visually reached the title screen, but this does not mean the game is playable. Progress bars describe tracked work; they do not mean that a game feature is playable.

For the plain-language overview, see the [README](../README.md) or the [player guide](PLAYER_GUIDE.md).

### Latest bounded title and Steel Battalion USB input probe (2026-10-18)

A 180-second Vulkan launch with the virtual Steel Battalion USB profile reached the dark title screen and displayed “PRESS MAIN WEAPON BUTTON”. After that prompt appeared, the live input file sent `a:500`. The OHCI report trace captured a 26-byte XID report with byte 2 bit 0 set (`00 1A 01 ...`) and then cleared (`00 1A 00 ...`); OHCI continued periodic transfers, reaching 12,795 before the watchdog. This verifies that the virtual USB device emitted the intended press and release packets. It does **not** verify that the guest recognized the control: title captures before, during, and after the pulse were byte-identical (SHA-256 `604A1D53DDD97989B4688868E7ECFB5E0F2F1ED88DE1CAF6FC7A6C72F1F83F4E`).

The watchdog ended the process at 180 seconds with the guest waiting at event `0x0021DCF4`, 955,910 indirect calls, and NV2A USER `PUT=GET=0x6D11C`. This is an idle/wait snapshot, not proof of a deadlock. Temporary XID-report and guest file-helper trace hooks were removed, then the normal Release target rebuilt successfully. The XInput A-to-`RightJoyMainWeapon` mapping remains unverified at the game level and is still an uncommitted local patch. The ISO, generated source, logs, and screenshots remain local/ignored. No progress bars advance; Milestone 3 remains active, and Vulkan remains the sole host renderer.

**Fixed and only host renderer: Vulkan. Migration is incomplete.** `nv2a_pb_exec` sends one tightly checked textured splash-logo draw to a project-owned Vulkan pipeline; six nonblack fade frames match CPU-reference captures byte-for-byte. Other pushbuffer draws still use the CPU reference rasterizer. A 190-second run without USB repeatedly displayed very dark Steel Battalion title art. A separate 160-second run with the Steel Battalion USB profile enabled and no scripted input also reached that screen and captured the faint “PRESS MAIN WEAPON BUTTON” prompt. The USB-enabled run stayed there until its watchdog, whose guest snapshot was waiting on event `0x0021DCF4` with NV2A `PUT=GET=0x80F1C`. An earlier trace-free run also captured the prompt. This is evidence of title display, not verified input response or playability. Runs with `RECOMP_PAD_LIVE` or `RECOMP_PAD_SCRIPT` enabled stopped producing frames at the Nude Maker logo; watchdogs sampled the same guest font-loading call path. A 90-second scripted A probe did log the press at 5,000 ms while periodic USB reports were being served, but the capture remained on the Nude Maker logo and the run does not verify game-side input response. Scripted press times are measured from the first USB report, not process launch. The cause of the stalled runs is not established, so do not attribute it to USB or the A-button mapping yet. An opt-in native-PC watchdog capture also failed to produce a report before its bound; its isolated test process was stopped, and this symbol-capture path is not currently usable. General NV2A rendering, audio, and gameplay remain unverified. **All project-owned host rendering work stays on Vulkan.** Milestone 3 remains active.

The latest bounded diagnostic launch rebuilt successfully with the Vulkan path and isolated watchdog logging. It exited at 45 seconds with code 3 after 171 flips; sampled NV2A `PUT` and `GET` were equal at `0x6AAB8`. Startup read `STRM00.WAV` and `STRM01.WAV`; the guest stack contained the return address from a `KeWaitForSingleObject` wrapper. This does not establish why the guest was waiting, verify audible output, or reach the Steel Battalion title screen. The watchdog's separate log path is a local diagnostic change and has not been added to the dependency patch stack.

A follow-up 60-second run added timer-thread stage markers. They continued through `before/after-vblank`, `before/after-irq`, and `before/after-dpc` at loop 3000; the isolated watchdog ended the process at 60 seconds. This rules out a timer-thread stall in those three stages for that run. The guest still had not reached the title screen, and the run does not establish why game-thread progress stopped. Diagnostics remain local and ignored. Vulkan remains the fixed renderer choice; this result does not reopen API selection.

A further 60-second bounded launch traced the guest-built event at `0x0021DCE4`. All 128 logged `KeWaitForSingleObject` calls returned `STATUS_SUCCESS`; the title repeatedly reset the notification event and another runtime thread signaled it. The NV2A queue continued to drain and reached `PUT=GET=0x4E81C`; the run logged 400 draw batches and 200 clears before the watchdog. The watchdog stack happened to sample the event wrapper, which does not prove a deadlock. No title-screen, audio-output, or gameplay verification was made, and no progress bars advance. Tracing, logs, and the rebuilt binary are local under the ignored `iso/local-analysis/` and `local-tools/` paths.

A separate 45-second capture run enabled per-draw timing and saved the first 16 vertex-program draw results locally. The 16th capture visibly shows the dim CAPCOM logo and is byte-identical to three earlier Vulkan captures; it is not an exact match to a CPU-reference capture from a different fade timing. This does not change the prior six-state CPU/Vulkan parity result. The diagnostic timing recorded 63 Vulkan logo submissions averaging 16.31 ms and 16 black-depth operations averaging 1.35 ms; these are instrumented timings, not performance benchmarks. The run reached 51 flips and stopped at the guest queue fence with 12 commands outstanding. It produced no generic `cpu-raster` batches, so the sample did not reach the unsupported draw state targeted for profiling. No title-screen or gameplay progress is established. Captures and logs remain local under `iso/local-analysis/logs/m3-vulkan-program-draw-capture-45s-20261018/`.

See [the Vulkan migration map](VULKAN_MIGRATION_MAP.md) for source call paths, verified runtime boundaries, and the remaining implementation steps.

### Detailed field progress

These smaller bars expose progress across the individual work areas requested for the project. Each denominator is a short list of verifiable outcomes, not an estimate of effort. A 0% bar means no outcome in that field has been verified yet; it does not mean the work is impossible.

#### XBE analysis and static recompilation

These bars separate file analysis and generated output from semantic coverage. In particular, the function-output percentage only measures emitted functions; unsupported instructions and unresolved calls remain visible as separate gaps.

```text
XBE format, sections, libraries, and image map  [####################] 1 / 1 (100%)
Kernel import ordinals named in analysis         [####################] 123 / 123 (100%)
Function translation output emitted              [####################] 9,400 / 9,400 (100%)
Unsupported instruction sites resolved           [--------------------] 0 / 243 (0%)
Unresolved call targets implemented              [##############------] 251 / 351 (72%)
Generated Windows executable builds              [####################] 1 / 1 (100%)
Verified title-screen startup                    [--------------------] 0 / 1 (0%)
```

The ordinal bar records names mapped to the kernel import table, not implementations verified against live game behavior. The build bar records a local executable build only. Startup still fails before a verified title screen; the 9,400 emitted functions do not imply complete or correct decompilation.

```text
Static recompilation: functions emitted       [####################] 9,400 / 9,400 (100%)
Static recompilation: unsupported ops resolved [--------------------] 0 / 243 (0%)
Static recompilation: unresolved calls resolved [##############------] 251 / 351 (72%)
Windows target: build completes locally         [#-------------------] 1 / 1 (100%)
Xbox runtime: guest entry and asset read         [##------------------] 2 / 4 (50%)
Xbox runtime: title screen and gameplay frame    [--------------------] 0 / 2 (0%)
Xbox kernel and synchronization                  [--------------------] 0 / 3 (0%)
Filesystem and ISO validation                    [--------------------] 0 / 3 (0%)
Vulkan/NV2A: full scene rendering                 [--------------------] 0 / 3 (0%)
Vulkan host presentation: device/swapchain/present  [####################] 3 / 3 (100%)
Windows graphics migration: guest draws rendered by Vulkan [--------------------] 0 / 1 (0%)
Audio: guest DSP execution and audible output     [##########----------] 1 / 2 (50%)

Original SB controller: input, mapping, lights   [--------------------] 0 / 3 (0%)
Modern controller and accessibility profiles     [--------------------] 0 / 4 (0%)
Graphics: resolution, ratios, display modes      [--------------------] 0 / 4 (0%)
Graphics: HUD, FOV, image controls, presets      [--------------------] 0 / 4 (0%)
Frame rate: original timing and 30/60 FPS        [--------------------] 0 / 3 (0%)
Frame rate: 120/144/uncapped safety and pacing   [--------------------] 0 / 3 (0%)
Campaign: mission-by-mission completion          [--------------------] 0 / 1 (0%)
Campaign: saves, cinematics, progression checks  [--------------------] 0 / 4 (0%)

Diagnostics: crash logs and performance records  [#-------------------] 1 / 2 (50%)
Diagnostics: deterministic input replay          [--------------------] 0 / 1 (0%)
Launcher: game library and ISO path              [--------------------] 0 / 3 (0%)
Launcher: graphics and controller settings       [--------------------] 0 / 2 (0%)
Launcher: Steam shortcut and app entry           [--------------------] 0 / 1 (0%)
Launcher: consent-based verified updates          [--------------------] 0 / 3 (0%)
Community: portable install, profiles, support   [--------------------] 0 / 4 (0%)
Line of Contact: network and separate profile     [--------------------] 0 / 3 (0%)
Distribution: clean package, licenses, docs      [#-------------------] 1 / 3 (33%)
```

For example, “guest entry and asset read” records observed startup checkpoints, while “title screen and gameplay frame” remains at zero. A corrected run now verifies that guest-loaded GP/EP programs execute in bounded DSP slices without the fake doorbell acknowledgment; this does not verify command completion or audible output. Diagnostic logging and local project documentation exist, but deterministic replay, a clean playable package, and completed license review do not. Counts move only when the corresponding outcome is verified. These detailed bars supplement the milestone and top-level field bars above; they do not change the milestone gate or imply campaign compatibility.

### Requirement-by-requirement progress

These additional bars break the requested features into smaller player-facing checks. They count working, verified outcomes; planning, source inspection, and diagnostic-only behavior do not count as delivered features.

```text
Original controller: adapter, detection, input, output  [--------------------] 0 / 4 (0%)
Controller editor: labeled layout and reassignment     [--------------------] 0 / 4 (0%)
Controller behavior: toggles, gears, analog calibration [--------------------] 0 / 3 (0%)
Controller feedback: indicator lights and vibration    [--------------------] 0 / 2 (0%)
Input devices: keyboard/mouse and Xbox/PlayStation      [--------------------] 0 / 3 (0%)
Input devices: HOTAS, pedals, multi-device/custom HID   [--------------------] 0 / 3 (0%)
Controller profiles: defaults, import, export           [--------------------] 0 / 3 (0%)

Campaign checks: mission load and stable gameplay      [--------------------] 0 / 2 (0%)
Campaign checks: cinematics and mission audio           [--------------------] 0 / 2 (0%)
Campaign checks: save/load and mission completion      [--------------------] 0 / 2 (0%)
Campaign checks: progression through the full campaign  [--------------------] 0 / 1 (0%)

Display: 1080p, 1440p, 4K, and window/fullscreen modes  [--------------------] 0 / 4 (0%)
Display: widescreen, 4:3, HUD placement, FOV            [--------------------] 0 / 4 (0%)
Rendering: original look and enhanced preset           [--------------------] 0 / 2 (0%)
Rendering: filtering, AA, VSync, noise/grain options    [--------------------] 0 / 4 (0%)
Rendering: shader/pipeline cache and scaling            [--------------------] 0 / 2 (0%)
Frame pacing: original, 30, 60, 120, 144 FPS modes      [--------------------] 0 / 5 (0%)
Frame pacing: timing safety, uncapped mode, measurements [--------------------] 0 / 3 (0%)

Launcher: import, validate, identify, and change ISO    [--------------------] 0 / 4 (0%)
Launcher: settings, diagnostics, logs, reset, shortcut  [--------------------] 0 / 5 (0%)
Launcher: add the game to Steam                         [--------------------] 0 / 1 (0%)
Launcher updates: check, notes, download consent        [--------------------] 0 / 3 (0%)
Launcher updates: verify files and preserve settings    [--------------------] 0 / 2 (0%)
Community tools: portable mode and troubleshooting      [--------------------] 0 / 2 (0%)
Community tools: consent-based crash report and docs    [--------------------] 0 / 2 (0%)
Line of Contact: separate game profile and network study [--------------------] 0 / 2 (0%)
```

These feature bars complement the engineering checkpoint bars above. They are intentionally zero until the feature is implemented and verified; a planned feature or research note alone does not advance them.

### Runtime and campaign field bars

This final breakdown shows the lower-level compatibility fields and the campaign matrix separately. Analysis, generated output, local builds, diagnostic observations, and working runtime behavior are tracked only in bars labeled for that evidence. Diagnostic traces do not count as a working game feature.

```text
XBE analysis: entry point and section map                  [####################] 1 / 1 (100%)
XBE analysis: function boundaries and control flow         [--------------------] 0 / 2 (0%)
XBE analysis: guest memory map and runtime behavior         [--------------------] 0 / 2 (0%)
Translation: emitted functions                            [####################] 9,400 / 9,400 (100%)
Translation: unsupported instruction sites resolved        [--------------------] 0 / 243 (0%)
Translation: unresolved call targets implemented           [##############------] 251 / 351 (72%)
Windows build: generated executable links                  [####################] 1 / 1 (100%)

Kernel: threads and scheduling                             [--------------------] 0 / 1 (0%)
Kernel: events, semaphores, and synchronization             [--------------------] 0 / 1 (0%)
Kernel: memory, exceptions, and timing                      [--------------------] 0 / 1 (0%)
Filesystem: ISO import and XBE discovery                    [--------------------] 0 / 1 (0%)
Filesystem: title-asset read diagnostic                    [####################] 1 / 1 (100%)
Filesystem: saves and persistent settings                   [--------------------] 0 / 1 (0%)
Graphics: pushbuffer and GPU command handling               [#-------------------] 1 / 4 (25%)
Graphics: textures and shader output                       [--------------------] 0 / 2 (0%)
Graphics: correct presented game image                     [--------------------] 0 / 1 (0%)
Graphics diagnostics: Vulkan splash pixel parity             [#-------------------] 1 / 1 diagnostic (100%)
NV2A analysis: PMC interrupt-enable write mapped            [#-------------------] 1 / 1 (100%)
NV2A startup: PCRTC vblank clear/enable sequence observed    [#-------------------] 1 / 1 (100%)
NV2A runtime: opt-in modeled periodic vblank observed         [#-------------------] 1 / 1 diagnostic (100%)
NV2A bridge: opt-in modeled IRQ reached ISR and DPC           [#-------------------] 1 / 1 diagnostic (100%)
NV2A bridge: startup event setter called by guest DPC          [#-------------------] 1 / 1 diagnostic (100%)
NV2A bridge: startup wait release verified                    [#-------------------] 1 / 1 diagnostic (100%)
NV2A runtime: default, hardware-valid delivery verified       [--------------------] 0 / 1 (0%)
NV2A executor: semaphore target resolved in guest trace        [#-------------------] 1 / 1 diagnostic (100%)
Audio cleanup: same access violation with vblank on and off    [####################] 2 / 2 diagnostic runs (100%)
Audio cleanup: iterator and callback path mapped               [#-------------------] 1 / 1 static analysis (100%)
Audio code: destructor's generic unlink helper mapped           [#-------------------] 1 / 1 static analysis (100%)
Audio cleanup: null owner traced to failed DSOUND init           [#-------------------] 1 / 1 diagnostic (100%)
Audio cleanup: safe initialization and cleanup verified         [--------------------] 0 / 1 (0%)
Audio: device initialization                               [#-------------------] 1 / 3 (33%)
Audio: compatible DSP backend candidate researched           [#-------------------] 1 / 1 research (100%)
Audio: XBE GP/EP startup sequence mapped                     [#-------------------] 1 / 1 static analysis (100%)
Audio: `DSSTDFX.BIN` read and passed to DSOUND             [#-------------------] 1 / 1 diagnostic (100%)
Audio: effects-image mapping and command shape traced       [#-------------------] 1 / 1 static analysis (100%)
Audio: upstream xemu GP/EP behavior mapped                   [#-------------------] 1 / 1 research (100%)
Audio: DSP56300 C FFI capabilities and gaps reviewed          [#-------------------] 1 / 1 research (100%)
Audio: existing xemu Rust-JIT adapter audited                 [#-------------------] 1 / 1 research (100%)
Audio: MIT FFI / project-owned bridge selected                 [#-------------------] 1 / 1 architecture (100%)
Audio: Windows DSP FFI dependency licenses inventoried         [#-------------------] 1 / 1 research (100%)
Audio: GP/EP DSP MMIO windows routed                        [--------------------] 0 / 1 (0%)
Audio: GP/EP X/Y/P memory mapped                             [####################] 1 / 1 (100%)
Audio: GP/EP scratch DMA and reset bootstrap integrated       [####################] 1 / 1 (100%)
Audio: DSP status callbacks and bounded run tested           [#-------------------] 1 / 1 (synthetic)
Audio: game DSP instruction execution verified              [#-------------------] 1 / 1 (bounded diagnostic)
Audio: GP/EP scratch DMA and EOL status observed              [#-------------------] 1 / 1 (bounded diagnostic)
Audio: DSP56300 bounded run path built and linked           [#-------------------] 1 / 1 (100%)
Audio: DSP cycles, interrupts, and DMA verified               [--------------------] 0 / 1 (0%)
Audio: game sound output verified                            [--------------------] 0 / 1 (0%)
Input: original Steel Battalion hardware                   [--------------------] 0 / 3 (0%)
Input: keyboard/mouse, gamepad, and HOTAS                   [--------------------] 0 / 3 (0%)

Campaign matrix: mission loading                           [--------------------] 0 / 1 (0%)
Campaign matrix: stable gameplay                            [--------------------] 0 / 1 (0%)
Campaign matrix: cinematics                                 [--------------------] 0 / 1 (0%)
Campaign matrix: audio                                      [--------------------] 0 / 1 (0%)
Campaign matrix: controller behavior                        [--------------------] 0 / 1 (0%)
Campaign matrix: save/load                                  [--------------------] 0 / 1 (0%)
Campaign matrix: frame pacing                               [--------------------] 0 / 1 (0%)
Campaign matrix: mission completion and progression         [--------------------] 0 / 1 (0%)
```

The XBE entry point and section map are documented; that is static analysis, not verified runtime behavior. The title-asset bar records a diagnostic read of the three title XPR files only, not complete filesystem compatibility. Pushbuffer handling records command processing and draw calls, not a correct rendered scene. A fresh local build completed and the XBE reached its entry point. An opt-in NV2A trace then observed display-mode setup and GPU semaphore releases before the process exited on an access violation in the XBE's audio cleanup path. It again recorded `DSERR_NODRIVER`, a null audio vtable, and invalid audio virtual calls. This corroborates the already traced failed-DirectSound cleanup path; it does not establish that the GPU caused the crash or that untraced startup now has deterministic behavior. With diagnostic AC'97 readiness and a fake DSP doorbell acknowledgement, the guest read additional resources and flipped three frames, but the captured output was black and the renderer found no usable textured batches. The fake acknowledgement clears commands without DSP computation, so this run does not verify DSP or audio behavior. The host DirectSound COM wrapper is a no-output stub and the generated game code uses its XBE-resident DirectSound implementation; neither is a verified audio path. The APU has a Windows XAudio2 output backend, but its GP/EP DSP is stubbed. The optional DSP56300 FFI bridge and its synthetic memory-map/lifecycle harness now compile in an isolated worktree, and the harness passes. The patch does not route GP/EP MMIO or execute DSP firmware, and it does not change the audio status bars. AC'97 readiness, DSP processing, safe audio cleanup, audible output, and a verified title screen remain unverified. These diagnostic hooks remain opt-in. The campaign bars remain at zero because no mission has been verified from loading through completion and progression.

#### Latest bounded rebuild and pixel trace (2026-10-17)

The isolated `RelWithDebInfo` game target rebuilt successfully with the installed Visual Studio CMake. A 15-second watchdog-bounded launch using the existing diagnostic AC'97-ready and fake DSP-ack options reached guest entry `0x00192C47`, read game resources, and produced a framebuffer capture. The capture was not a recognizable title screen; the trace still logged unusable texture batches and a mostly black output. Pixel tracing sampled the full-screen textured quad: texture samples and RGB output were nonzero, while diffuse alpha and final combiner alpha were zero. A vertex-program dump showed that the XBE's inline data supplied diffuse alpha `0` and its vertex program directly copied that attribute to the color output. With source-alpha blending enabled (`0x302/0x303`), the transparent quad correctly leaves the black destination unchanged. This rules out the current vertex interpreter inventing alpha zero for this draw, but it does not establish whether the game should advance to a later screen or change the submitted fade alpha. No renderer fix was applied. Diagnostic audio shortcuts remain in effect, so DSP execution and audible output are still unverified. No progress bars advance, and no title-screen or campaign compatibility is claimed.

#### Latest bounded DSP effects-image trace (2026-10-17)

The Windows target built successfully with a temporary local-only trace inside the translated DSOUND-section function. A watchdog-bounded launch read all 24,936 bytes of `Media\SndEff\DSSTDFX.BIN`; the function received the buffer and returned `S_OK`. Static tracing shows that the XBE-resident DSOUND path builds 32-byte mapping records, relocates GP-memory references, copies mapped image data, then writes and polls a command word. This identifies the guest-side transaction shape, but not the meaning of every record or whether the DSP accepted or processed it. A corrected 8-second launch observed GP scratch registers `GPSADDR=0x003C4000`/`GPSMAXSGE=206`, EP `EPSADDR=0x003DC000`/`EPSMAXSGE=19`, and nonzero frame-table registers. The actual GP/EP SGE tables and first mapped payload are in the `0x80000000` contiguous alias: a write watch caught the first GP entry and the watchdog sample showed a physical page address there. Earlier low-alias-only zero reads and addresses `0xFE832040`/`0xFE8320D4`, `0xFE852048`/`0xFE8520DC` were invalid. Synthetic AC'97 readiness and fake DSP doorbell acknowledgement were enabled, so `S_OK` does not verify DSP execution, effects, audible output, or the title screen. xemu's GP/EP reference uses the descriptor registers for scatter/gather DMA and bootstraps P memory on reset release. The project APU's physical resolver already selects the contiguous alias, but the DSP scratch/bootstrap callback is missing. xemu's 512-byte MCPX boot ROM is mapped in the CPU BIOS region and not passed to its APU initializer, so it is not established as DSP firmware. Next implement and synthesize-test the callback and reset bootstrap. Audio and all playable-feature bars remain unchanged.

### Full project field tracker

The bars below give every major work area and sub-field an individual, evidence-based status. Each bar counts verified results, not time spent, planned work, code presence, or diagnostic activity. A zero means the capability has not yet been verified.

```text
RESEARCH AND ARCHITECTURE
XBE format and executable identified                   [#-------------------] 1 / 1 (100%)
Static-recompilation architecture selected             [#-------------------] 1 / 1 (100%)
Technical limits and legal boundaries documented       [#-------------------] 1 / 1 (100%)
Dependency license review complete                     [--------------------] 0 / 1 (0%)

STATIC RECOMPILATION
XBE sections and entry map documented                  [#-------------------] 1 / 1 (100%)
Kernel imports named                                   [####################] 123 / 123 (100%)
Functions emitted                                      [####################] 9,400 / 9,400 (100%)
Unsupported instruction sites resolved                 [--------------------] 0 / 243 (0%)
Unresolved call targets implemented                    [##############------] 251 / 351 (72%)
Windows executable builds locally                      [#-------------------] 1 / 1 (100%)
Title-screen boot verified                             [--------------------] 0 / 1 (0%)

BOOT AND RUNTIME COMPATIBILITY
Guest startup progression                              [#############-------] 2 / 3 (67%)
ISO and game-file access                               [#-------------------] 1 / 3 (33%)
Title screen rendered correctly                        [--------------------] 0 / 1 (0%)
Kernel threads, scheduling, and TLS                    [--------------------] 0 / 3 (0%)
Kernel events, semaphores, and synchronization         [--------------------] 0 / 3 (0%)
Kernel memory, exceptions, and timers                  [--------------------] 0 / 3 (0%)
ISO mounting and XBE validation                        [--------------------] 0 / 2 (0%)
Title asset read path                                  [#-------------------] 1 / 1 (100%)
Save files and persistent settings                    [--------------------] 0 / 1 (0%)
GPU pushbuffer and command handling                    [#-------------------] 1 / 3 (33%)
Texture upload and sampling                            [--------------------] 0 / 2 (0%)
Shaders and register combiners                         [--------------------] 0 / 2 (0%)
Correct game image presented                           [--------------------] 0 / 1 (0%)
Audio device and APU initialization                    [#-------------------] 1 / 2 (50%)
Steel Battalion XBE GP/EP startup sequence mapped       [#-------------------] 1 / 1 static analysis (100%)
Upstream xemu GP/EP semantics mapped                    [#-------------------] 1 / 1 research (100%)
GP/EP DSP MMIO routing                                 [--------------------] 0 / 1 (0%)
GP/EP DSP X/Y/P memory and register mapping            [--------------------] 0 / 1 (0%)
DSP56300 FFI memory-map/lifecycle harness passed         [#-------------------] 1 / 1 (100%)
GP/EP guest firmware loading and execution             [#-------------------] 1 / 1 (bounded diagnostic)
DSP cycle, interrupt, FIFO, and DMA behavior           [--------------------] 0 / 1 (0%)
DSP processing and audible game sound                  [--------------------] 0 / 2 (0%)
Basic in-game input                                    [--------------------] 0 / 1 (0%)

The optional C harness for GP/EP memory boundaries, engine initialization, reset, and destruction compiled, linked, and passed in an isolated verification worktree. A later corrected game run bootstrapped 2,048 program words to GP and EP from guest scratch DMA and executed bounded DSP instruction slices without the synthetic doorbell acknowledgment. This verifies guest-loaded DSP code execution only; complete GP/EP MMIO, command completion, interrupts, DMA behavior, DSP output, and game audio remain unimplemented or unverified.

ORIGINAL STEEL BATTALION CONTROLLER AND ACCESSIBILITY
Original controller adapter/device detection          [--------------------] 0 / 1 (0%)
Original buttons, toggle switches, and gear controls   [--------------------] 0 / 1 (0%)
Original analog controls and calibration               [--------------------] 0 / 1 (0%)
Original indicators and output feedback                [--------------------] 0 / 1 (0%)
Automatic detection across connected input devices     [--------------------] 0 / 1 (0%)
Labeled controller editor and remapping                [--------------------] 0 / 2 (0%)
Keyboard/mouse profile and in-game input               [--------------------] 0 / 2 (0%)
Xbox/PlayStation controller profile and input          [--------------------] 0 / 2 (0%)
HOTAS, pedals, and custom HID support                  [--------------------] 0 / 2 (0%)
Multiple USB devices and combinations                  [--------------------] 0 / 1 (0%)
Profiles: defaults, import, export, and sharing         [--------------------] 0 / 4 (0%)

CAMPAIGN RELIABILITY
Mission loading                                       [--------------------] 0 / 1 (0%)
Stable gameplay                                       [--------------------] 0 / 1 (0%)
Cinematics                                            [--------------------] 0 / 1 (0%)
Mission audio                                         [--------------------] 0 / 1 (0%)
Controller behavior                                   [--------------------] 0 / 1 (0%)
Save and load                                         [--------------------] 0 / 1 (0%)
Frame pacing                                          [--------------------] 0 / 1 (0%)
Mission completion and campaign progression           [--------------------] 0 / 1 (0%)
Full campaign completed and verified                  [--------------------] 0 / 1 (0%)

GRAPHICS AND PERFORMANCE
Original rendering preset                             [--------------------] 0 / 1 (0%)
1080p and 1440p output                                 [--------------------] 0 / 2 (0%)
4K output                                             [--------------------] 0 / 1 (0%)
4:3, widescreen, and 16:10 presentation               [--------------------] 0 / 3 (0%)
HUD, menus, cinematics, and field-of-view handling    [--------------------] 0 / 4 (0%)
Windowed, borderless, and exclusive display modes     [--------------------] 0 / 3 (0%)
Filtering, anti-aliasing, VSync, and scaling          [--------------------] 0 / 4 (0%)
Noise, film grain, and enhanced graphics options      [--------------------] 0 / 3 (0%)
Shader and pipeline caching                           [--------------------] 0 / 1 (0%)
Original-rate and 30/60 FPS modes                     [--------------------] 0 / 3 (0%)
120/144 FPS and safe uncapped mode                    [--------------------] 0 / 3 (0%)
Frame times, 1% lows, and pacing measured             [--------------------] 0 / 3 (0%)

DEBUGGING AND REPLAY
Runtime/kernel, graphics, audio, and input logs        [#-------------------] 1 / 4 (25%)
Crash capture and repeatable diagnostics              [#-------------------] 1 / 2 (50%)
Deterministic input recording and replay              [--------------------] 0 / 1 (0%)
Before/after performance comparisons                  [--------------------] 0 / 1 (0%)

LAUNCHER, COMMUNITY, AND DISTRIBUTION
ISO selection, validation, and game-version detection [--------------------] 0 / 3 (0%)
Change ISO path and explain invalid images             [--------------------] 0 / 2 (0%)
Graphics settings and controller settings UI          [--------------------] 0 / 2 (0%)
Launch button, version information, and repo link     [--------------------] 0 / 3 (0%)
Logs folder, reset, and desktop shortcut              [--------------------] 0 / 3 (0%)
Add game to Steam as a non-Steam shortcut              [--------------------] 0 / 1 (0%)
GitHub update checks and release notes                [--------------------] 0 / 2 (0%)
Consent-based download and installation               [--------------------] 0 / 2 (0%)
Update file verification and settings preservation    [--------------------] 0 / 2 (0%)
Portable mode and launcher without configured ISO      [--------------------] 0 / 2 (0%)
Community profiles, troubleshooting, and docs          [--------------------] 0 / 3 (0%)
Crash reporting with user consent                     [--------------------] 0 / 1 (0%)
Screenshots and video-friendly presentation            [--------------------] 0 / 2 (0%)
Dependency review and clean package                   [--------------------] 0 / 2 (0%)
Player-ready release and installation guide           [--------------------] 0 / 2 (0%)

LINE OF CONTACT FUTURE RESEARCH
Community and network protocol research               [#-------------------] 1 / 3 (33%)
Insignia/XLink Kai compatibility assessed              [--------------------] 0 / 1 (0%)
Separate game profile and multiplayer verified        [--------------------] 0 / 2 (0%)
```

### Individual requirement progress

These additional bars break combined requirements into separate outcomes. An outcome advances only after it is implemented and verified; planning, code presence, and diagnostic activity alone do not count.

```text
STATIC RECOMPILATION AND RUNTIME
Function output generated                         [####################] 9,400 / 9,400 (100%)
Unsupported instruction sites handled             [--------------------] 0 / 243 (0%)
Unresolved call targets implemented               [##############------] 251 / 351 (72%)
Native Windows build produced                     [#-------------------] 1 / 1 (100%)
Game runs without a separate emulator             [--------------------] 0 / 1 (0%)
Title screen reached and visually verified        [--------------------] 0 / 1 (0%)
Correct in-game image rendered                    [--------------------] 0 / 1 (0%)
Game audio heard                                   [--------------------] 0 / 1 (0%)

STEEL BATTALION CONTROLLER AND ACCESSIBILITY
Original USB controller detected through adapter  [--------------------] 0 / 1 (0%)
Original buttons and toggles mapped               [--------------------] 0 / 1 (0%)
Original gear selection works                     [--------------------] 0 / 1 (0%)
Original analog controls calibrated               [--------------------] 0 / 1 (0%)
Original indicator lights receive output          [--------------------] 0 / 1 (0%)
Keyboard and mouse work in game                   [--------------------] 0 / 1 (0%)
Xbox controller works                             [--------------------] 0 / 1 (0%)
PlayStation controller works                      [--------------------] 0 / 1 (0%)
HOTAS and pedals work                             [--------------------] 0 / 1 (0%)
Dual-stick and custom HID devices work            [--------------------] 0 / 1 (0%)
Multiple USB devices work together                [--------------------] 0 / 1 (0%)
Labeled controller editor and remapping work      [--------------------] 0 / 1 (0%)
Default profiles and profile import/export work   [--------------------] 0 / 1 (0%)

CAMPAIGN RELIABILITY
Mission loading verified                          [--------------------] 0 / 1 (0%)
Gameplay stability verified                       [--------------------] 0 / 1 (0%)
Cinematics verified                               [--------------------] 0 / 1 (0%)
Mission audio verified                            [--------------------] 0 / 1 (0%)
Controller behavior verified                      [--------------------] 0 / 1 (0%)
Save and load verified                            [--------------------] 0 / 1 (0%)
Frame pacing verified                             [--------------------] 0 / 1 (0%)
Mission completion verified                       [--------------------] 0 / 1 (0%)
Campaign progression verified                     [--------------------] 0 / 1 (0%)
Full campaign completed end to end                [--------------------] 0 / 1 (0%)

GRAPHICS AND PERFORMANCE
Original appearance preset verified              [--------------------] 0 / 1 (0%)
1080p output verified                             [--------------------] 0 / 1 (0%)
1440p output verified                             [--------------------] 0 / 1 (0%)
4K output verified                                [--------------------] 0 / 1 (0%)
4:3 presentation verified                         [--------------------] 0 / 1 (0%)
16:9 presentation verified                        [--------------------] 0 / 1 (0%)
16:10 presentation verified                       [--------------------] 0 / 1 (0%)
HUD, menus, and cinematics preserve layout         [--------------------] 0 / 1 (0%)
Field-of-view adjustment works                    [--------------------] 0 / 1 (0%)
Windowed, borderless, and exclusive modes work    [--------------------] 0 / 1 (0%)
Texture filtering and anisotropic filtering work  [--------------------] 0 / 1 (0%)
Anti-aliasing, VSync, and scaling work            [--------------------] 0 / 1 (0%)
Original, 30, and 60 FPS modes verified           [--------------------] 0 / 1 (0%)
120, 144, and safe uncapped modes verified        [--------------------] 0 / 1 (0%)
Frame times, 1% lows, and pacing measured         [--------------------] 0 / 1 (0%)

LAUNCHER, COMMUNITY, UPDATES, AND PRESERVATION
ISO selection and validation work                 [--------------------] 0 / 1 (0%)
Supported game version identification works      [--------------------] 0 / 1 (0%)
Graphics and controller settings work             [--------------------] 0 / 1 (0%)
Launch, version, logs, reset, and shortcut options [--------------------] 0 / 1 (0%)
Add game to Steam library option works            [--------------------] 0 / 1 (0%)
GitHub update check and release notes work        [--------------------] 0 / 1 (0%)
Update install requires consent                    [--------------------] 0 / 1 (0%)
Update verification and settings preservation work [--------------------] 0 / 1 (0%)
Portable mode and no-ISO launcher work             [--------------------] 0 / 1 (0%)
Community profiles and troubleshooting available  [--------------------] 0 / 1 (0%)
Crash report sharing requires consent              [--------------------] 0 / 1 (0%)
Repository excludes user game data                   [#-------------------] 1 / 1 (100%)
Dependency licenses reviewed                     [--------------------] 0 / 1 (0%)
Line of Contact network compatibility researched  [#-------------------] 1 / 1 (100%)
ChatGPT Codex majority authorship disclosed       [#-------------------] 1 / 1 (100%)
```

The platform build and translation-output bars are not evidence of a playable game. The project remains in Milestone 3, before a verified title screen; no unverified feature or partial campaign run advances these counts. This detailed tracker supplements the milestone and summary bars.

| Area | Status |
| --- | --- |
| Research and architecture | Complete; static recompilation remains the chosen approach. |
| Initial Windows translation | Built locally; translation gaps mean this is not yet proof of correct game behavior. |
| Game startup | In progress; ordinary startup still fails during audio setup. Diagnostic AC'97/DSP shortcuts let a traced run render a dim CAPCOM logo quad, but no Steel Battalion title screen has been reached and DSP/audio are not verified. |
| Playable release and launcher | Not available. |
| Full campaign compatibility | Not verified. No mission-completion or campaign-progression testing has been completed. |

**The latest verified state is not a playable game.** The title screen, graphics, sound, controller input, saves, cinematics, mission completion, and campaign progression remain unverified. We will report compatibility only after the complete campaign has been tested mission by mission.

### Prior bounded startup and DSP mapping check (2026-10-17)

The optional DSP56300 bridge aliases the GP/EP DSP memory descriptors to the ordinary guest RAM windows. A focused synthetic test passed for those aliases and their boundaries. With the pushbuffer executor enabled, the guest semaphore advances and both GP and EP reset-release transitions are visible. The next guest wait posts DSP commands at 0x803B8810; real firmware bootstrap and DSP cycles remain absent. The diagnostic fake ACK can advance file and GPU work but does not calculate DSP output. No recognizable Steel Battalion title screen, audio, controller, save, or campaign behavior is verified. The bounded process exited, and a subsequent check found no project game/emulator process active. At that checkpoint, the timer/event wait release and real DSP bootstrap remained unresolved. The later opt-in event/GPU check below verifies only the diagnostic wait release; real DSP firmware/cycles remain absent. Milestone 3 remains active.

### Latest opt-in event and GPU executor check (2026-10-17)

The title-built event wait returned success and advanced its guest signal/counter state under the opt-in event bridge. A separate 45-second watchdog-bounded run continued consuming NV2A commands through GET `0x9ED0` while PUT reached `0xA968`, counting 28 vertex-program batches and 56 triangles. It did not produce a recognizable Steel Battalion title screen. That earlier run reported degenerate coordinates and no usable textured batches; a later first-frame trace refines this finding below. The event/vblank paths and AC'97/DSP shortcuts were diagnostic only; default synchronization, real DSP/audio, correct rendering, input, and campaign remain unverified. The specific opt-in wait-release diagnostic bar is now 1/1; all playable-feature and default-compatibility bars remain unchanged.

### Vertex and complete startup-frame trace (2026-10-17)

A later bounded trace of the first startup frame refined the earlier GPU diagnosis. Its immediate-mode vertices form a 640×480 full-screen quad. The passthrough vertex program outputs those same corners, and the textured draw has UVs spanning `(0,0)` to `(1,1)` with a valid 512×512 DXT texture. The frame records two draws and four rasterized triangles; an earlier periodic capture shows only a dim CAPCOM logo. Thus the earlier degenerate-coordinate/no-texture summary does not describe this first traced startup frame. The image is still not the Steel Battalion title screen, and the dim appearance's cause is not established. No renderer changes or feature progress-bar increments were made. Separate 25-second vertex-input and 20-second full-frame traces exited at their guest watchdogs; a process check found no project game runtime active. Synthetic AC'97 readiness and fake DSP acknowledgement remain in use, so neither DSP execution nor audible output is verified.

A subsequent pixel trace sampled the texture and combiner output at two logo coordinates. RGB was about `0.28` and `0.61`, but alpha was zero at both points because the guest supplied diffuse alpha zero. With source-alpha / one-minus-source-alpha blending, the textured draw leaves the destination unchanged at those pixels. The local combiner's signed-identity mapping and final-combiner expression match [xemu's reference shader generator](https://github.com/xemu-project/xemu/blob/master/hw/xbox/nv2a/pgraph/glsl/psh.c), so this does not establish a combiner bug. Six flip captures progress from black to a dim CAPCOM logo: the first three are black, then the logo brightness grows across three samples. This suggests a guest-driven intro fade, but it has not been compared with an Xbox reference capture. The responsible draw/surface is not yet identified. No rendering changes or progress-bar increments were made; next compare surface and draw transitions across flips.

To inspect later logo draws, the opt-in vertex trace limit was increased to eight batches in the local XboxRecomp checkout and the Windows target rebuilt successfully (existing MSVC warnings remain). In a 25-second watchdog-bounded run, guest-provided diffuse RGB stayed at `0.690196` while alpha rose from `0` in batches 2 and 4 to `0.0470588` in batch 6 and `0.0980392` in batch 8; intervening batches were black/opaque. This is consistent with a guest-driven logo fade and argues against forcing combiner/blend output. It is not verified against Xbox hardware and does not reach the Steel Battalion title screen. No feature bars advance. Diagnostic AC'97 and DSP shortcuts remain active, leaving real audio unverified. Next inspect guest timer/event execution after the CAPCOM intro and the real DSP initialization path.

### Latest Milestone 3 startup trace (2026-10-17)

An 8-second watchdog-bounded launch exited with code 3. The guest call path reaches translated `sub_00211E10`, whose code polls for free space in a ring buffer at guest `0x00211F10`; the buffer's consumer and the reason it does not advance are still unknown. A separate lock trace observed worker thread 40308 waiting on guest critical section `0x00F86F88` while thread 32904 held and repeatedly released/reacquired it. The capture did not show whether the worker later acquired the lock, so starvation and causality remain unverified. Another diagnostic trace showed the guest timer advancing in 0.05 increments and finite 30 ms waits returning `STATUS_TIMEOUT`. The test used synthetic AC'97/DSP acknowledgements; it does not verify real audio. The Steel Battalion title screen and all gameplay features remain unverified, and no progress bar advances. Next identify the ring-buffer consumer and correlate it with the lock contention before changing runtime behavior.

### Follow-up: semaphore release advances startup (2026-10-17)

With the opt-in pushbuffer executor enabled, the trace observed NV2A semaphore releases of 5, 7, and 9 to guest word `0x80003000`; the watchdog sampled value 9 and the guest queue cursor at 11. NV2A GET and PUT both reached `0x495C`. The guest then reached a timed `KeDelayExecutionThread` call at the 8-second sample. This refines the previous ring-buffer observation: that polling came from a diagnostic run with pushbuffer execution disabled and is not established as a separate runtime defect. This run still used fake DSP acknowledgement and AC'97 readiness, and did not verify the title screen, real DSP execution, or audio. Progress bars remain unchanged.

### DSP scratch-to-P bootstrap verified (2026-10-18)

Implemented a bounded 0x800-word reset bootstrap using the corrected SGE registers and the guest's `0x80000000` contiguous alias. The focused Windows x64 harness passed across a two-page table, confirmed 24-bit masking and boundary copying, and rejected an incomplete SGE table. The full `your_game_recomp` target built with the optional DSP56300 FFI enabled. An 8-second watchdog-bounded run with pushbuffer execution and synthetic AC'97 readiness, but without `RECOMP_APU_DSP_ACK`, logged successful GP and EP bootstraps from guest scratch DMA and exited with expected watchdog code 3; no project game process remained. This verifies bootstrap reads real guest SGE data and writes the DSP program windows, not that the loaded program is correct or executed. The DSP cycle scheduler still bypasses GP/EP, so DSP output, audible sound, and the Steel Battalion title screen remain unverified. The X/Y/P mapping and reset-bootstrap engineering bars above now show 1/1; player-facing DSP execution and audio bars stay at 0. Next implement and test bounded GP/EP cycles, command completion, DMA/peripheral behavior, and resulting audio.

### Bounded GP/EP execution scaffold (2026-10-18)

The XboxRecomp-specific bridge maps the DSP peripheral-status region through callbacks, keeps program-bootstrap readiness separate from the architectural interrupt bits, and schedules a 1,000-cycle FFI run for GP each APU frame and EP every eight frames. The JIT can consume whole translated blocks, so this value is a run budget rather than a strict maximum. Synthetic Windows x64 coverage verifies GP/EP status reads and clears, DMA-register round-tripping, scratch bootstrap, and bounded loop execution. The harness, APU library, and full game target build. The first corrected startup attempt exposed a stale generated dispatcher: five valid functions present in the refreshed XBE analysis were absent from the output. Regenerating the current 9,148-function translation added those entries with zero translation failures. A follow-up found the DSP reader was rejecting the guest's contiguous alias because it compared a 2 GB alias offset against the 64 MB physical RAM size; the resolver now validates the physical page against the contiguous allocation and reads the alias. A rebuilt 15-second launch, with pushbuffer execution and synthetic AC'97 readiness but without fake `RECOMP_APU_DSP_ACK`, loaded and executed the real guest GP/EP programs. It had zero unresolved indirect-call failures and reached one NV2A surface clear; USER DMA PUT/GET were both `0x495C`. The watchdog exited with code 3 while the guest polled command word `0x803B8810`; GPU diagnostics reported 235 unhandled methods. No verified Steel Battalion title screen appeared. This verifies guest-loaded DSP instruction execution only; DMA/control behavior, command completion, usable output, audible sound, title screen, and campaign remain unverified. The optional FFI remains disabled by default. Synthetic bridge, full build, alias resolution, and bounded guest-DSP execution are verified; player-facing audio stays unverified.

### Follow-up: guest DSP alias resolution and execution verified (2026-10-18)

The initial physical-address resolver checked the `0x80000000` contiguous alias against `xbox_GetMappedSize()`, which reports physical RAM size, not the reserved guest address span. This rejected the valid alias even though the backing allocation contained the guest's populated SGE tables. Removing that incorrect alias-size check while retaining physical-address and contiguous-allocation bounds let the actual GP and EP descriptor/payload pages load. The Windows x64 target rebuilt successfully. In a 15-second watchdog-bounded launch with `RECOMP_PB_EXEC=1`, synthetic `RECOMP_AC97_READY=1`, and no `RECOMP_APU_DSP_ACK`, both 2,048-word guest programs bootstrapped and GP/EP instruction slices ran; the GP state and loaded P words changed during execution. The run reached one NV2A surface clear, then polled `0x803B8810`; GPU logs still counted 235 unhandled methods. It did not reach the title screen or produce verified audible output. The game process was stopped at the watchdog bound and no process remained. No image assets are tracked in the repository; runtime diagnostics and any screenshots stay local under `iso/local-analysis/`. No progress bar for audio output, gameplay, or campaign completion advances.

### Follow-up: first guest DSP DMA chain runs (2026-10-18)

Disassembly of the live guest GP program identified a freeze-status wait at P:$010E and a second wait at P:$011E. The bridge had treated DSP DMA control writes as literal register values; it now maps the guest action values to frozen, running, and stopped status bits. A small bounded subset of scratch DMA now reads the guest SGE pages, moves supported 8/16/24-bit non-interleaved data between guest scratch and DSP X/Y/P memory, handles circular scratch buffers, and reports end-of-list status. Unsupported interleaved/FIFO modes fail closed rather than reporting completion. The public [xemu GP/EP APU reference](https://github.com/xemu-project/xemu/blob/master/hw/xbox/mcpx/apu/dsp/gp_ep.c) and [xemu DSP DMA reference](https://github.com/xemu-project/xemu/blob/master/hw/xbox/mcpx/apu/dsp/dsp_dma.c) informed the behavior; no xemu code was copied.

The Windows x64 target rebuilt successfully. A 15-second watchdog-bounded launch used pushbuffer execution and synthetic AC'97 readiness, with no fake DSP command acknowledgement. The guest GP ran several scratch descriptors, observed and cleared DMA end-of-list status, and reached a GP wait loop for the next frame interrupt; logs showed no scratch-transfer error. One NV2A surface clear was observed, while 235 NV2A methods remained unhandled. The guest CPU still polled `0x803B8810`, and the title screen, audible output, and gameplay were not verified. The project process was stopped at the watchdog limit. The engineering bar above records only bounded guest scratch DMA/EOL handling; it does not imply working game audio.

### Follow-up: command-mailbox snapshot and event-call churn (2026-10-18)

A watchdog-bounded run with synthetic AC'97 readiness and no DSP acknowledgement shim reached a later guest state than the earlier command-word spin. At the 8-second snapshot, `0x803B8810` read as zero and the guest register sample had changed; this does not prove a complete DSP-command transaction because the mailbox write/clear transition was not captured in that run. It did not reach a verified title screen. The GP DSP continued to wait at P:$0160 for its next frame interrupt, one NV2A surface clear remained the only visual result, and the renderer still reported 235 unhandled methods.

A separate 4-second diagnostic logged 10,995 guest-kernel calls and 14,779 indirect calls. The capped trace showed 64 `NtCreateEvent` calls from guest return site `0x00191642` (inside `sub_0019160B`); the kernel summary was dominated by critical-section and IRQL calls, with repeated delay calls. This is an observed call pattern, not yet a diagnosed cause. The temporary caller logger was removed and the normal Windows x64 target rebuilt successfully. No player-facing progress bars advance from this evidence; command completion, title screen, audio output, and gameplay remain unverified.

### Correction: event creation is part of audio-object setup (2026-10-18)

A bounded, opt-in guest-frame trace captured 61 successful `NtCreateEvent` calls during startup. The guest return address was consistently `0x0010739A`, inside translated `sub_001072E0`; that routine stores the returned event handle at offset `0x54` of the object it is initializing. The calls returned distinct host event handles. This evidence is consistent with per-object audio initialization, so the earlier event-call churn is not established as a startup defect. Whether these objects later complete initialization and close their events remains unverified.

The same externally bounded 8-second run used pushbuffer execution and synthetic AC'97 readiness, with no DSP acknowledgement shim. It reached the already observed single NV2A surface clear and logged GP/EP bootstrap/execution, but no title screen or audible output was verified. The watchdog did not terminate this launch; the diagnostic process was stopped at the external time bound. The ordinary Windows x64 Release target was rebuilt after removing the temporary trace. This refines the diagnosis only; progress bars remain unchanged.

### Watchdog wait-path diagnostic (2026-10-18)

Temporary stage markers confirmed `RECOMP_WATCHDOG_SECS=3` reached `xbox_WatchdogStart`, and `CreateThread` returned a valid handle. The worker entered, but a direct `WriteFile` marker placed immediately after its three-second Windows `Sleep` never appeared in a five-second externally bounded run. Raising that watchdog thread to time-critical priority for one diagnostic attempt did not change the observation. This points to the worker remaining in or before the return from its wait; it does not establish why. The process was stopped externally. All temporary watchdog markers and priority changes were removed, and the normal Windows x64 Release target rebuilt successfully. Future diagnostics must use an external process bound until the watchdog wait path is understood. This does not advance game compatibility bars.

### Audio lock-call-site trace (2026-10-18)

A 7-second external-bound trace sampled the frequent IRQL calls. Guest return sites `0x00223EC8` and `0x00223EE0` map to the acquire/release wrappers `sub_00223E9C` and `sub_00223ECF`; both call sites are in the translated audio subsystem. An earlier 8-second run counted 729 `KfRaiseIrql` and 731 `KfLowerIrql` calls among 3,729 kernel calls. The sampled pairs are balanced lock activity, not evidence of the startup hang. The run still reached one NV2A clear and no title screen. No compatibility bars advance; continue tracing the guest wait/mailbox or the next graphics submission.

### Critical-section contention follow-up and clean rebuild (2026-10-18)

A bounded direct trace of guest lock `0x00F86F88` showed one thread repeatedly entering and leaving it through translated `sub_001AA151`, while a second thread attempted entry from `0x001AA22B`. The trace did not record the waiter acquiring the lock before the external 10-second stop. This is consistent with possible starvation, but does not prove starvation, a deadlock, or that this lock blocks startup; the owner continued making recursive lock transitions. No lock behavior was changed. The temporary direct-trace instrumentation was removed, then the Windows x64 Release executable rebuilt successfully. A fresh 8-second externally bounded launch with pushbuffer execution and synthetic AC'97 readiness again executed GP/EP DSP slices and reached one NV2A clear, but did not reach the Steel Battalion title screen. The process was stopped and no game process remained. All game-compatibility progress bars stay unchanged.

The repository image cleanup removed the only tracked photo (the controller reference image) and its now-unused attribution page. README and player-guide references were removed; the controller plan remains documented in text. There are currently no tracked project images. This supersedes the earlier note that the controller photo was being retained.

### First-frame and timed-worker trace (2026-10-18)

A correctly armed `RECOMP_FRAME_TRACE` captured the first frame boundary. It showed the early flip/stall, a surface-offset change, semaphore releases, and clear-value writes; the subsequent GPU report still counted zero draws, zero indices, and zero pixels. This trace does not prove that later title frames never draw, but no recognizable game image was captured. A four-second lock probe ended before the watched lock was touched. A 10-second rerun captured a thread waiting on guest lock `0x00F86F88`; its guest stack passes through the title's timed event worker (`sub_001ABA10`), which waits on two events and then calls into guest object code at `sub_001ABAC0`/`sub_001ABB03`. The owner still enters through `sub_001AA151`. This narrows the contention to the event worker's object callback while the startup thread owns the same lock, but does not prove that the callback produces the state awaited by startup.

A separate 20-second diagnostic used asynchronous file-I/O mode, pushbuffer execution, synthetic AC'97 readiness, and no DSP doorbell acknowledgement. GP/EP guest programs bootstrapped and executed bounded slices; GP repeatedly reached its frame-wait path and emitted repeated scratch-DMA activity. The renderer still reported zero draws and zero written pixels, and no title screen or audible audio was verified. A DMA diagnostic was much noisier than expected (572 records in the captured log), so later runs should cap that trace before extending runtime duration. No runtime semantics or progress bars changed. Milestone 3 remains active; next capture the event-worker callback result and the guest state the renderer is waiting on, with the DMA trace capped.

### Audio worker callback and lock wait (2026-10-18)

Two externally bounded runs (12 and 20 seconds) with the DMA trace cap confirmed the event worker's indirect target as guest `0x001AA1FC`, in the translated audio code. The worker object was `0x006E9730`; its callback field points to `0x00F86FA8`, whose vtable is `0x00271014`. In the 20-second run, the callback thread reached the critical-section enter at guest `0x001AA22B` and remained waiting on lock `0x00F86F88`; the sampled owner was in `sub_001AA151` at `0x001AA166`, with recorded recursive depth 7. This ties the observed wait to an audio callback, but does not prove a deadlock, starvation, or that the lock blocks title startup. No synchronization behavior was changed.

The 20-second GPU summary advanced to four draw calls and 16 indices but reported no usable draw coordinates; no recognizable Steel Battalion image or title screen was verified. The run used synthetic AC'97 readiness and no DSP doorbell acknowledgement, so audible output remains unverified. Both diagnostic processes were stopped at their external bounds; a process check found no project game runtime. Temporary callback instrumentation was removed, and the ordinary Windows x64 target rebuilt successfully. Logs are ignored at `iso/local-analysis/logs/m3-worker-callback/` and `iso/local-analysis/logs/m3-worker-callback-20s/`. Feature bars remain unchanged; owner-stack follow-up is recorded below.

### DSP frame-status and scratch-DMA trace (2026-10-18)

After removing temporary renderer probes, the Windows x64 target rebuilt. An 8-second externally bounded launch used asynchronous file I/O, the diagnostic pushbuffer executor, synthetic AC'97 readiness, and `RECOMP_APU_DSP_TRACE=1`; `RECOMP_APU_DSP_ACK` was unset. The run exited with the expected watchdog code 3, and no project game process remained.

The guest GP and EP programs each bootstrapped 2,048 words from the title's scratch SGE tables. The local DSP56300 disassembler identifies the GP wait at P:$0160 as `JCLR #1,x:$FFFFC5,$0160`. A temporary callback trace observed the host frame bit (`0x2`) read and cleared at X:$FFFFC5, followed by repeated reads with the bit clear while the DSP waited for the next frame. The GP then performed scratch-DMA control actions and accessed SGE entries through the contiguous guest alias without a reported transfer error. This corrects the earlier inference that zero-cycle slices alone meant DSP execution was stalled; the wait instruction is part of the guest program's frame loop. The EP's bootstrapped P window was zero in this run, so its initial 1,020-cycle slice is not evidence of useful EP audio work.

The trace did not verify completion of the DirectSound effects-image command at the guest mailbox, DSP-produced audio, or a Steel Battalion title image; the GPU summary reported no draws at the watchdog point. The `0x803B8810` command transaction and the guest-visible effects-image completion remain open. Temporary peripheral callback logging was removed from ignored XboxRecomp source and is not part of the repository patch set. The audio execution bar remains at 1/2, while audible output and all game-playability bars remain unchanged. Next trace guest command-mailbox and DMA writes with no synthetic acknowledgement, then compare the transaction against the XBE's polling loop.

### Follow-up: observed DSP completion of command `3` (2026-10-18)

A second 8-second watchdog-bounded launch traced the XBE mailbox loop and the guest-memory writes made by GP scratch DMA. The launch again used async file I/O, pushbuffer execution, and synthetic AC'97 readiness; it did not configure `RECOMP_APU_DSP_ACK`. The translated XBE stored command `3` at `0x803B8810`, then repeatedly read `3` while polling. The GP scratch-DMA output copied a zero word to physical `0x003B8810` from the mapped 24-byte block at `0x003B8800`; the subsequent XBE poll observed zero and returned. This is direct evidence that one command was completed through the guest DSP DMA path rather than the diagnostic host acknowledgement. The test exited at the watchdog bound; it still had zero GPU draws, and no audible output or title screen was verified. The trace proves command `3` only; command `2` and the rest of the effects-image/audio path remain unverified. These probes were removed from ignored generated/runtime source, and the release target was rebuilt without them. The audio execution bar remains 1/2 and the game-compatibility bars stay unchanged. Next trace the command `2` submission and verify its response and resulting DSP output without a synthetic acknowledgement.

### Lock-owner guest stacks (2026-10-18)

A further 20-second externally bounded run temporarily recorded guest stacks on acquisitions of lock `0x00F86F88` (48 records maximum). The repeated owner snapshots include the callback return site `0x001AA62D` and nested paths through `0x0020B886`, `0x001BC30A`, `0x001BD34C`, `0x001BD1E6`, `0x001CEB18`, `0x001CFF9E`, `0x001EE71B`, `0x001CE4B9`, and `0x001D02A1`. This shows repeated acquisitions along the same nested guest callback/object path while the audio worker waits; it does not establish whether the path is a legitimate long operation, reentrant guest behavior, or a missing release. No lock behavior changed. The temporary runtime trace was removed, the standard Windows x64 target rebuilt successfully, and no project runtime remains. Log: `iso/local-analysis/logs/m3-lock-owner-stacks/stderr.log` (ignored). The indirect-target follow-up is recorded below; lock release remains unproven.

### Guest indirect target at `0x001D029E` (2026-10-18)

A temporary, 64-record trace at the indirect call in `sub_001CFFC0` showed a valid guest target each time: object `0x00F86EE0`, vtable `0x00271030`, target `sub_001AA151`. The first 64 calls sweep 16 entries for each of outer values 1 through 4. This call site is not itself dispatching a null or host-address target in the captured portion. The caller-site follow-up is recorded below.

### Startup initializer non-code callsites (2026-10-18)

Added temporary opt-in logging of call-site addresses for indirect targets rejected as non-code. In the 15-second bounded run, three calls from `sub_00106C10` were rejected: site `0x00106C67` targeted process-space address `0x758B1E74`, site `0x00106C73` targeted `0x01C10FF0`, and site `0x00106C7F` targeted null. `sub_00106C10` is called by startup initializer `sub_0010FC40` at `0x0010FD70` after it sets up object `0x006C9750`. A second initializer, `sub_00106C90`, repeatedly calls a null target at `0x00106CC2` (10 logged hits by call count 13,521). This is now the concrete unresolved startup lead; object/vtable ownership and whether these entries should dispatch to Xbox compatibility shims or are optional remain unverified. No call or lock behavior was changed.

The same bounded run still showed the waiter on `0x00F86F88`, four GPU draw calls without usable coordinates, and no Steel Battalion title screen. It used synthetic AC'97 readiness and no DSP acknowledgement, so audible output remains unverified. The diagnostic build succeeded, the test process was stopped at its external limit, and no project runtime remains. The site logger is opt-in (`RECOMP_ICALL_SITE_TRACE=1`) and exists only in ignored local build/generated files; it is not committed. Log: `iso/local-analysis/logs/m3-icall-site-attribution/stderr.log` (ignored). Next trace the startup objects and vtable entries around `0x00106C10`/`0x00106C90`, compare intended Xbox interface dispatch with the currently populated values, and then decide on the smallest compatibility layer fix. All player-facing progress bars remain unchanged.

### Startup audio-call register and stack trace (2026-10-18)

A bounded 15-second run with pushbuffer execution and synthetic AC'97 readiness captured the startup factory objects (`0x00F82860`/vtable `0x00272E80` and `0x00F82BA0`/vtable `0x002715B0`). At `0x00106C53`, the second object's virtual slot `+0x60` correctly targets translated `sub_001BBFF0`. Its nested `sub_001BC070` call later reaches vtable target `sub_001AA5EE`, whose method slot resolves to `sub_001AA305` on object `0x00F86EE0`/vtable `0x00271030`. After that nested method returns, guest ESI/EDI contain `0x00F86EE0` rather than the startup output-slot addresses `0x006C9750`/`0x006C9754`; those bad values then produce rejected targets at `0x00106C67` and `0x00106C73` and a null dereference path at `0x00106C7F`.

A one-translation-unit ABI diagnostic measured the call to `sub_001AA305` returning with guest ESP `0x00F7FE0C`, versus `0x00F7FE40` before the call. That function tail-jumps to `0x001AA35D` or `0x001AA4B0`; both addresses have real XBE instructions, but the generated unresolved-stub file currently implements each as only `g_esp += 4`. The `0x001AA35D` instruction is `or dword ptr [ebp-4], -1`; `0x001AA4B0` begins `add esi, 0xA8`. This makes missing interior-block translation a strong candidate for the stack/register corruption. The exact taken tail path and safe lifter-level repair are not yet verified. The ABI diagnostic also flagged `0x00203C1C`, a special SEH-prolog helper that intentionally changes guest ESP, so that warning alone is not evidence of a defect.

No runtime compatibility code was changed. The target rebuilt successfully; the diagnostic process stopped at its 15-second watchdog with code 3. GPU output remained one clear/no verified title image. The generated-code instrumentation and logs remain ignored local analysis only. Next record the condition selecting `0x001AA35D` versus `0x001AA4B0`, then fix the translation of interior tail targets rather than patching this game call or suppressing the bad indirect calls. Progress bars remain unchanged; Milestone 3 is active.

### Taken audio cleanup branch and local validation (2026-10-18)

The branch condition at `sub_001AA305` is now directly observed: argument 2 and `[ESI+0xA4]` are both zero, so execution takes `0x001AA4B0`. A temporary edit to the ignored generated stub implemented that XBE block's critical-section leave, saved-register restore, SEH restore, and `ret 8` cleanup. The rebuilt target then returned from `sub_001AA5EE` with guest ESP restored to `0x00F7FE4C`; at caller return site `0x001BC2A2`, ESI/EDI were again `0x006C9750`/`0x006C9754`. Startup callsite `0x00106C67` now reads object `0x00F82860`, vtable `0x00272E80`, and valid slot target `0x001DF902`. This confirms the old `0x001AA4B0` no-op stub caused that specific stack/register failure.

Startup still fails later. Callsite `0x001BC307` dispatches `sub_001BD290` on object `0x00F82BA0`/vtable `0x002715B0`; after it returns, ESI is again `0x00F86EE0`, so `0x00106C73` still targets non-code `0x01C10FF0`, and `0x00106C7F` remains null. The 15-second watchdog run still showed no title screen. The local stub repair and all added trace statements are ignored generated output; no game code or generated game-derived code was committed. The ordinary source tree was not changed beyond this status record. Next trace the return paths inside `sub_001BD290`, then implement a general, boundary-checked translation of reachable interior tail blocks instead of accumulating title-specific stub edits. Progress bars remain unchanged; Milestone 3 is active.

### Interior tail-block continuation probe (2026-10-18)

A second bounded run isolated the later register failure to another unresolved interior target. `sub_001AA305` allocates a per-index audio object and tail-jumps to `0x001AA35D`; the generated unresolved stub had returned early instead of executing the block. In a local-only diagnostic build, that stub was temporarily made to continue through the already translated body beginning at `0x001AA35A`. The six nested calls then advanced the object's count from zero through six and returned success (`EAX=1`) from `sub_001BD290`, while preserving the caller's ESI/EDI (`0x006C9750`/`0x006C9754`). Startup objects at `0x00106C73` and `0x00106C7F` consequently resolved to valid guest objects and vtables. This confirms the `0x001AA35D` no-op stub caused the second observed register-corruption path.

The 15-second bounded run continued reading the title's `.sgt`, `.wav`, and `capcom.xpr` resources and executed DSP slices, but GPU diagnostics still showed only one clear and zero written pixels. No Steel Battalion title screen or audible sound was verified. Synthetic AC'97 readiness and pushbuffer execution were enabled; no fake DSP acknowledgement was used. The local generated-code workaround and opt-in traces are ignored under `iso/`; they are diagnostic only and are not a general recompiler fix. No progress bars advance. Next inspect the recompiler's function-boundary and tail-jump handling so reachable interior blocks can be translated generally, then retest ordinary startup without one-off game stub bodies. Milestone 3 remains active.


### Interior-tail continuation recovery and runtime retest (2026-10-18)

The isolated XboxRecomp patch `patches/xboxrecomp-v0.13.1-interior-tail-continuations.patch` now checks unresolved call/tail targets against containing code ranges. It emits an additional translated entry only when the target is an instruction boundary and the reachable control-flow graph forms a complete standalone continuation; unsafe or unowned targets remain unresolved. A full regeneration emitted 9,399 function bodies, including 251 recovered interior entries, with zero translation failures. The generated unresolved-stub count fell from 351 to 100, so the engineering bars now record 251/351 recovered targets. The patch applies to the pinned checkout and the refreshed Windows x64 executable builds.

A 15-second bounded startup run, with pushbuffer execution and synthetic AC'97 readiness but no fake DSP acknowledgement, returned valid guest objects through the previously corrupted audio setup path and read title `.sgt`, `.wav`, and `capcom.xpr` resources. It still produced only one NV2A clear and zero written pixels; there was no recognizable Steel Battalion title screen or verified audio output. The next logged unresolved address is `0x0010D100`, associated with the third worker's context value. XBE disassembly shows executable bytes at that address between the detected routines at `0x0010D0FA` and `0x0010D1F0`, but its ownership and call convention remain to be established. Logs and generated code are ignored under `iso/local-analysis/`; only the generic recompiler patch and this status note are tracked. Milestone 3 remains active.

### Seeded worker callbacks and refreshed translation (2026-10-18)

- The existing runtime-seed workflow validated two observed XBE addresses as decodable function bodies: `0x0010D100` and `0x001ABA10`. A fresh seeded disassembly recovered 9,082 functions; fresh function identification and ABI analysis were generated from that same database.
- Full ahead-of-time translation completed with 9,400 emitted function bodies, zero translation failures, 100 unresolved target stubs, and 243 unsupported instruction sites. The trampoline `0x001914F8` and both seeded targets have generated bodies and dispatcher entries. Generated code, analysis, and logs remain ignored under `iso/local-analysis/`.
- The Release Windows x64 target rebuilt successfully against the fresh generated directory. In the subsequent startup log, `PsCreateSystemThreadEx` created a worker using routine `0x001914F8` and context `0x001ABA10`; the run also loaded guest DSP programs, executed bounded GP/EP slices, consumed GPU commands through DMA PUT/GET `0x495C`, and reached one surface clear. The run still reported 235 unhandled NV2A methods and zero written pixels. It did not show a title screen or verify audible audio. This run did not itself show `0x0010D100` as a thread context, so its runtime reachability is still unconfirmed.
- `RECOMP_WATCHDOG_SECS=15` did not produce a watchdog record or stop this windowed process. I stopped only the project test process after collecting its log; no project process remains. Treat internal watchdog behavior as an open debugging issue and use an independently checked process bound for the next launch.
- All function-output bars now count 9,400 emitted bodies. No player-facing compatibility bar advances. Milestone 3 remains active.
- Next inspect why the watchdog thread fails to fire in this build, then continue from the startup state after the worker creation. Keep static recompilation intact and avoid changing GPU/audio semantics based only on the current no-pixel result.

### Watchdog bounded-path fix and callback retest (2026-10-18)

The watchdog's native-PC helper suspended the guest thread and entered DbgHelp before printing its timeout record. In a 15-second startup run with that path enabled by default, the game log stopped advancing near the timeout, no watchdog record appeared, and the windowed process remained alive. I made native-PC symbolization opt-in with `RECOMP_WATCHDOG_NATIVE_PC`; the default watchdog now skips DbgHelp, prints the guest register/stack snapshot, and exits on schedule. The isolated follow-on patch forward/reverse applied against the local XboxRecomp source, and the Windows x64 target rebuilt. A fresh 15-second run then exited with code 3 and emitted `[WATCHDOG] no exit after 15s`.

The bounded startup behavior was otherwise unchanged: one surface clear, GP and EP bounded DSP slices, worker creation at `0x001914F8` with context `0x001ABA10`, 235 unhandled NV2A methods, and zero pixels written. The title screen and audible sound remain unverified. The run did not observe `0x0010D100` as a thread context, so that seeded function still needs runtime reachability evidence. No player-facing bars advance; Milestone 3 remains active.

### No-ack follow-up: second effects command not observed (2026-10-18)

A fresh 15-second watchdog-bounded run used pushbuffer execution, async I/O, synthetic AC'97 readiness, and DSP tracing, with `RECOMP_APU_DSP_ACK` explicitly unset. Temporary XBE and GP-DMA probes again recorded command `3` stored at `0x803B8810`, followed by a GP scratch-DMA transfer that copied zero to physical `0x003B8810`; the translated guest poll then returned. No command `2` mailbox store occurred in this startup window. The run continued loading title `.sgt` and `.wav` resources, but GPU diagnostics still reported zero draws and zero pixels, so neither title-screen rendering nor audible output is verified. It exited with watchdog code 3. Temporary probes were removed and the clean Release target rebuilt; no game process remains. The trace does not establish why command `2` was absent or whether it is issued on a later path. Audio and player-facing progress bars remain unchanged; Milestone 3 remains active.

### Longer no-ack DSP mailbox run (2026-10-18)

A 45-second watchdog-bounded startup run extended the observation through title audio-resource loading. Command `3` again reached zero through a GP scratch-DMA transfer. Later, another 24-byte GP transfer covering physical `0x003B8800` observed mailbox value `2` at offset `0x10` and copied zero over it. `RECOMP_APU_DSP_ACK` was unset. This verifies a second mailbox value was cleared through guest GP DMA, but this run did not capture the corresponding XBE store or its polling loop, so it does not establish that the guest observed completion or that the command's full effects-image work completed. The title path then read `capcom.xpr`, `nude.xpr`, and `dolby.xpr`; GPU diagnostics reported four draws and about 1.23 million pixel writes but zero draws with usable coordinates, so no recognizable title image is verified. Audible output is also unverified. The process exited with expected watchdog code 3. Temporary probes were removed and the clean Release target rebuilt; no runtime process remains. The generated files and logs remain local and ignored. Milestone 3 and player-facing progress bars remain unchanged.

### Command-2 sender traced to the guest routine (2026-10-18)

A targeted repeat instrumented only the translated `sub_00223C25` mailbox path and GP scratch-DMA callback. With `RECOMP_APU_DSP_ACK` unset, the guest routine observed mailbox zero at base `0x803B8800`, then reached its `MEM32(base + 0x10) = 2` store. The following 24-byte GP scratch-DMA transfer read `2` at physical `0x003B8810` and copied zero over it. This links the guest's command-2 store to the real GP-DMA response; it does not prove the effects image produced correct DSP output or audible sound. Afterward the guest continued through `capcom.xpr`, `nude.xpr`, `dolby.xpr`, and `BGM00.WAV` reads. The run still did not verify a recognizable title image or audio output and exited at the 45-second watchdog. All targeted probes were removed, the clean Release target rebuilt successfully, and no runtime process remains. Milestone 3 and player-facing progress bars remain unchanged.

### Title framebuffer and combiner trace (2026-10-18)

The temporary first-four-batches vertex-shader trace was restored to its normal 20,000-batch sampling interval, and the Windows x64 Release target rebuilt. A 45-second no-ack run armed `RECOMP_FRAME_TRACE` before launch and captured frame methods plus after-draw BMPs. The guest reached four programmable draw calls (eight triangles, about 1.23 million pixel writes) on the 640x480 surface; direct framebuffer captures were black. The watchdog exited with code 3. This is draw execution evidence, not a title-screen boot.

A follow-up pixel trace captured two representative pixels. In the first full-screen pass, texture stage 0 was invalid/off and the register combiner produced `(0,0,0,1)`, writing black. The second pass sampled the 512x512 DXT texture at `0x803DF800` and produced nonzero RGB (for example `0.2795,0.2809,0.2795`) with alpha 0. Its observed blend factors were `SRC_ALPHA / ONE_MINUS_SRC_ALPHA` (`0x302 / 0x303`), so the resulting framebuffer pixels remained black. This narrows the issue to guest draw state, shader/combiner inputs, or their interpretation; it does not establish which state is wrong or whether these passes are expected before the title screen. No rendering semantic was changed.

The temporary pixel-trace condition was restored and the Release target rebuilt successfully. Logs and BMPs remain ignored local analysis data under `iso/local-analysis/logs/m3-title-frame-trace-rearmed-20261018`, `m3-title-draw-capture-20261018`, and `m3-title-first-pass-pixels-20261018`. No project process remains. No title screen, audible output, or gameplay was verified; Milestone 3 and player-facing bars remain unchanged. Next trace the guest texture and combiner setup immediately before these passes, then compare the captured inputs and outputs with the pinned NV2A reference behavior before changing emulation semantics.

### Vertex DMA context gap (2026-10-18)

A 45-second externally bounded startup trace enabled complete pushbuffer-method accounting and vertex input diagnostics; it used the diagnostic pushbuffer executor, async file I/O, synthetic AC'97 readiness, and no DSP acknowledgement shim. It exited by external termination at the 45-second limit, with no game process left running. The log is local and ignored at `iso/local-analysis/logs/m3-vertex-dma-trace-20261018/stderr.log`.

The game's pushbuffer sets `NV097_SET_CONTEXT_DMA_VERTEX_A` (`0x019C`) twice and `NV097_SET_CONTEXT_DMA_VERTEX_B` (`0x01A0`) once, each with handle `3`. The partial executor currently reports both methods as unhandled and does not retain those context handles. The upstream NV2A implementation stores these handles, then maps each vertex-array offset through the selected vertex DMA object; it also treats the high offset bit as the A/B selector ([upstream source](https://github.com/xqemu/xqemu/blob/master/hw/xbox/nv2a/nv2a_pgraph.c)). The four observed batches in this Steel Battalion trace are immediate-mode vertex submissions, so this missing array-DMA path does not explain the black framebuffer captured in those batches. It is a separate compatibility gap that could affect later non-inline geometry. No renderer semantics or progress bars changed.

Next inspect handle `3` in the game's RAMHT/PRAMIN state and compare its DMA descriptor with the pushbuffer offsets before implementing a bounded, generic vertex-array mapping. Keep the current black-frame diagnosis separate until another trace ties these vertex contexts to a failing draw. The run still did not verify a title screen, sound, or gameplay; Milestone 3 remains active.

### Vertex DMA descriptor resolved (2026-10-18)

A temporary, read-only probe followed the observed handle `3` through the game's live RAMHT and PRAMIN state. Vertex A (`0x019C`) and vertex B (`0x01A0`) both resolve to RAMHT context `0x80000112`, PRAMIN instance `0x01120`, descriptor flags `0x0000B03D` (class `0x03D`, target NVM), limit `0x07FFAFFF`, frame `0x00000003`, and computed base address `0x00000000`. The probe did not alter guest memory or renderer state. Its bounded run was externally stopped after about 12 seconds; the log is ignored at `iso/local-analysis/logs/m3-vertex-dma-descriptor-20261018/stderr.log`.

Because the mapped base is zero and the four observed splash batches use immediate-mode vertices, the descriptor base does not explain the current black framebuffer. The partial executor still does not retain A/B handles, mask the selector bit from vertex-array offsets, or enforce descriptor limits, so non-inline array draws remain an unverified compatibility path. I removed the temporary probe, verified its source file exactly matched the pre-probe backup, and rebuilt the ordinary Windows x64 Release target successfully. No game process remains. No title screen, sound, or gameplay was verified; Milestone 3 and progress bars remain unchanged.

Next trace the guest's actual vertex-array offset/format methods and locate a non-inline draw before implementing DMA mapping. Keep this issue separate from the black immediate-mode passes until a trace connects them.

The same 45-second pushbuffer inventory contained no `SET_VERTEX_DATA_ARRAY_OFFSET` (`0x1720` range), `SET_VERTEX_DATA_ARRAY_FORMAT` (`0x1760` range), or `DRAW_ARRAYS` (`0x1810`) methods; only `SET_BEGIN_END` was present among these vertex submission methods. Thus the game configured vertex DMA handles during startup, but this capture never used the non-inline array path. This reinforces that the A/B mapping gap is not the cause of the four observed draws.

### Immediate-mode diffuse alpha traced to guest data (2026-10-18)

A temporary environment-gated trace recorded raw `NV097_SET_VERTEX_DATA4UB` writes for attribute 1 during a 15-second bounded startup. The textured startup pass wrote `0x00B0B0B0` (RGB bytes `0xB0`, high alpha byte `0x00`); a black vertex wrote `0xFF000000`. The runtime-decoded diffuse attribute therefore matches the guest command stream for the observed zero-alpha vertex, rather than an incorrect byte-order decode. This explains why the traced blended pixel from that startup pass retained black destination color when its source alpha was zero. It does not establish that the pass is the title image, prove all combiner/blend behavior, or establish why the guest authored that vertex color. No alpha workaround was applied.

The temporary probe was removed by restoring the ignored XboxRecomp source byte-for-byte from its pre-probe backup; the SHA-256 hashes matched (`06EC1DC9…60B3B1C`). The diagnostic Release build and subsequent clean Release build both succeeded. The process was externally stopped at the 15-second capture bound; no title screen, audible output, or gameplay was verified. Logs remain local and ignored at `iso/local-analysis/logs/m3-raw-vertex-trace-20261018/`. Next investigate guest-side setup/state for the immediate-mode diffuse value and compare the full vertex/combiner/blend sequence against upstream behavior before changing rendering semantics. Graphics feature bars remain unchanged; Milestone 3 is active.

A fresh 15-second run of the restored Release build enabled the existing immediate-mode vertex dump. Its first textured quad had four vertices with diffuse RGB `0.690196` and alpha `0`; the short run reported four draw calls and a brightest written pixel of `0x00AAAAAA`. It emitted no guest timer trace, so this run does not show whether that fade value changes over a longer interval. The process was stopped at the external bound; no recognizable title image was verified. Log: `iso/local-analysis/logs/m3-fade-sequence-20261018/stderr.log` (ignored). This check confirms the guest-supplied vertex state reaches the existing immediate-mode draw path but does not show a rendering fix or title-screen boot.

### PMC interrupt enable gating (2026-10-18)


The original trace appeared to show a pending PCRTC hardware interrupt after its enable mask had become zero. A targeted assertion-time probe clarified the order: the hardware interrupt asserted with PMC pending `0x01000000` and enable `0x00000001`, then the guest ISR cleared the enable before the later status snapshot. The NV2A core's generic `pending && enabled` condition could also incorrectly allow a hardware interrupt under only the software enable bit, or vice versa. A small helper now gates hardware and software pending state with their corresponding PMC enable bits, following the [PMC register reference](https://envytools.readthedocs.io/en/latest/hw/bus/pmc.html). The standalone reproducibility patch is `patches/xboxrecomp-v0.13.1-pmc-irq-gating.patch`; its forward application was checked against the pinned xboxrecomp index. The separate host callback still carries the resulting IRQ line into the guest runtime.

The restored source had no obsolete trace print, but an incremental build initially left its string in the executable. I forced `nv2a_core.c` to recompile; the build output included that translation unit, the NV2A library and executable timestamps advanced, and a binary scan confirmed the marker was absent. A fresh 15-second bounded run then showed the guest NV2A IRQ being claimed, GP and EP DSP bootstrap plus execution slices, and title-media reads. The partial executor still reported 235 unhandled GPU methods, one surface clear, zero draw calls, and zero written pixels. The process was stopped at the external bound and its exit was confirmed. This verifies the refreshed binary and these startup paths only; no title screen, audible output, or gameplay was verified. Progress bars and Milestone 3 remain unchanged.

### Startup fade combiner interpretation corrected (2026-10-18)

The earlier pixel trace's zero alpha is consistent with the captured guest registers and does not by itself indicate a combiner bug. In the textured quad, the alpha inputs are `0xD4` and `0xD8` (V0.a and T0.a with signed-negate mapping); alpha output `0x000000C0` writes their AB product into R0.a. The guest supplies V0.a = 0, so this product is zero. The final-combiner G input `0x1C` reads R0.a, and the blend state is SRC_ALPHA / ONE_MINUS_SRC_ALPHA. This matches the local evaluator and the corresponding behavior in [xemu's pixel-shader generator](https://github.com/xemu-project/xemu/blob/master/hw/xbox/nv2a/pgraph/glsl/psh.c); no rendering semantic change is justified by this trace.

Separate bounded captures show the guest later submitting the same logo quad with alpha rising from 0 to 12/255 and 25/255, alongside a gradually brighter CAPCOM image. That is consistent with a guest-driven fade, though there is no Xbox reference comparison. The latest 45-second no-ack trace still produced no recognizable Steel Battalion title screen; real DSP/audio, controls, and gameplay remain unverified. This supersedes the earlier hypothesis that the traced zero-alpha pixel itself demonstrated an unknown combiner/texture fault. No feature bars advance; Milestone 3 remains active. Next trace why guest startup remains at the CAPCOM sequence and correlate its event/timing and DSP state before changing renderer behavior.

### Opt-in title event signal observed with DSP-enabled build (2026-10-18)

A 15-second watchdog-bounded run used the current DSP-enabled Windows build with pushbuffer execution/scanning, asynchronous file I/O, diagnostic AC'97 readiness, modeled vblank, and the opt-in title-event bridge. `RECOMP_APU_DSP_ACK` was unset. A kernel watch on the title-built notification event at `0x0021DCE4` recorded its signal-state word changing from 0 to 1 during `KeSetEvent` (ordinal 145); the surrounding trace also shows the event being waited on (ordinal 159). At the watchdog sample the state was 1, so this run progressed past that wait rather than remaining in the previously observed counter poll.

The DSP-enabled target bootstrapped 2,048 GP and EP program words and executed bounded slices of 4,120 GP cycles and 1,020 EP cycles. Its watchdog guest stack was in the asset parser reading `Media\\title\\snk_002.wav` and a `wavh` chunk, with 27,302 indirect calls recorded. The watchdog exited with code 3 and no project runtime remains. This proves only the opt-in event transition, early DSP instruction execution, and file-parser progress; modeled vblank and event bridging are diagnostics, audible audio is unverified, and no Steel Battalion title screen was reached. It supersedes the older sampled-window claim that no signal was observed for this event, but does not establish default or hardware-valid interrupt delivery. Progress bars remain unchanged; next trace the WAV parse/read completion and subsequent guest startup path with no DSP acknowledgement shim.

### WAV parsing completed and worker moved into guest state loop (2026-10-18)

A review of the existing 45-second no-DSP-ACK trace (`iso/local-analysis/logs/m3-current-noack-frame-20261018/stderr.log`, ignored) supersedes the 15-second watchdog snapshot that caught the worker while it was parsing `snk_002.wav`. The file path is followed by successful reads of its RIFF/WAVE header and chunks (`wavh`, `smpl`, `wsmp`, `data`, and INFO metadata); the guest then opens `snk_003.sgt` and proceeds through later `snk_00x` title assets. Later in the same run it reads streamed `BGM00.WAV` data and `ADVANCE.BIN`. The reads and subsequent opens show that WAV parsing is not the persistent startup blocker. They do not prove decoding or audible sound.

A fresh 35-second run of the existing DSP-enabled executable left `RECOMP_APU_DSP_ACK` unset. It used pushbuffer execution/scanning, async I/O, diagnostic AC'97 readiness, modeled vblank, the opt-in title-event bridge, and the bounded watchdog. It exited by watchdog code 3 with no runtime process remaining. The snapshot reported 112,612 indirect calls and NV2A USER PUT `0x648C` versus GET `0x54A8`; the GPU queue had not drained at that sample. The worker stack returned through `sub_00192BD8` at `0x00192C34`, the call site after `sub_000467A0`; static inspection shows `sub_000467A0` enters a guest state-dispatch loop. This is evidence of continued guest execution, not proof of a title screen or the exact active instruction.

An attempted incremental rebuild for additional I/O tracing did not start: this machine's Visual Studio installation is missing `MSBuild\\Microsoft\\VC\\v170\\Microsoft.Cpp.Default.props`. The opt-in I/O trace patch was reverse-applied after the failed build, and the existing executable was left unchanged. Next inspect the guest state-dispatch path and queued NV2A work at the watchdog boundary, then restore a usable C++ build toolchain before making runtime fixes. Audio output, title-screen appearance, input, saves, and gameplay remain unverified; progress bars remain unchanged and Milestone 3 remains active.

### Sixty-second no-ack boot reaches repeated render work (2026-10-18)

A fresh 60-second run of the existing DSP-enabled executable used pushbuffer execution/scanning, async I/O, diagnostic AC'97 readiness, modeled vblank, the opt-in title-event bridge, DSP tracing, and `RECOMP_APU_DSP_ACK` unset. The internal watchdog exited with code 3 and the project process was gone afterward. Log: `iso/local-analysis/logs/m3-startup-60s-noack-20261018/stderr.log` (ignored).

The guest progressed past title asset loading: the log includes `snk_007.sgt`, `BGM00.WAV`, and `ADVANCE.BIN`. Watchdog memory shows transition float `0x6874BC = 0x3F266668` (~0.65), step `0x26042C = 0.05`, and a changed guest tick source; the clock is advancing. The saved worker stack remains in the guest boot-transition draw path: return sites `0x000E0231` (after `sub_000DFBC0`) and `0x000DFE75` (after the D3D helper `sub_0020E520`). The renderer reported 24 draws/96 indices, 13 clears, 528 unhandled methods (155 distinct), and 7,365,568 pixel writes; no draws had usable screen coordinates and the brightest pixel was `0x00AAAAAA`. This remains no verified title image, audio, input, or gameplay. The sample is consistent with active transition rendering; it does not prove a specific cause for the missing visible image.

The 10-second comparison was earlier in title RIFF parsing, with timer still zero; the 35- and 60-second samples show later progress. Do not treat the earlier WAV stack or a stopped clock as the persistent blocker. Next trace the guest draw/flush path and why the partial renderer receives no usable coordinates, while preserving guest alpha/blend behavior absent stronger evidence. The local incremental build remains unavailable because Visual Studio is missing its C++ targets; existing diagnostic binaries were used without modification. No progress bars advance; Milestone 3 remains active.

### Vertex-program draw counters corrected (2026-10-18)

A fresh 60-second no-DSP-ack startup with the existing vertex-program dump and draw-verbose flags recorded two simple splash vertex programs: `oPos = v0`, `oD0 = v1`, and (for the textured pass) `oT0 = v2`. The first splash quad's input positions included `(0,0,0,1)`, `(0,480,0,1)`, and `(640,0,0,1)`, and the software rasterizer reported 16 triangles drawn with roughly 2.46 million pixel writes at its first post-splash report. This establishes that this startup pass supplies screen-sized positions and reaches the rasterizer; it does not establish that the image is recognizable or correct.

Correct the interpretation in the preceding 60-second snapshot: `[GPU] draws ... (0 with coordinates)` is not a count of all draws with coordinates. The counter inspects only attribute 0's first vertex before transformation, so it omits program-mode batches (and also misses a batch whose first vertex is the origin). The program-mode X range is likewise misleading: `xf_min`/`xf_max` update from only the first vertex of each triangle, which is x=0 for the observed full-screen triangles. Therefore the earlier inference that the renderer received no usable screen coordinates is withdrawn. Log: `iso/local-analysis/logs/m3-first-vertex-input-20261018/stderr.log` (ignored); run exited with expected watchdog code 3 and no runtime remains.

No title screen, audible output, input, saves, or gameplay was verified. Keep Milestone 3 and progress bars unchanged. Next capture an actual framebuffer image from this diagnostic path and verify later startup transition/title behavior; keep that evidence separate from original-Xbox comparison until a reference capture is available. Runtime changes still require a usable local C++ build toolchain.

### Guest framebuffer dump shows Capcom splash (2026-10-18)

A fresh 60-second no-DSP-ack diagnostic run enabled `RECOMP_FB_DUMP` and produced five ignored local 640×480 framebuffer dumps in `iso/local-analysis/logs/m3-framebuffer-dump-20261018/`. The first images are black; later images visibly show the centered Capcom logo on black. This confirms that the partial renderer's guest-memory surface contains a recognizable startup splash image. The last image still shows Capcom rather than Steel Battalion, and the watchdog ended in the startup draw path. These are user-copy-derived captures and remain local; no image asset was added to Git.

This verifies one image through the diagnostic framebuffer dump path only. It does not prove presentation in the Windows window, original-Xbox visual accuracy, title-screen arrival, audio, input, saves, or gameplay. Milestone 3 remains active and progress bars do not advance. Next follow the transition after the Capcom splash and verify the Steel Battalion title screen; a runtime change still needs the missing Visual Studio C++ targets restored.

### Startup advances into the next guest logo helper (2026-10-18)

A 120-second no-DSP-ack run kept pushbuffer execution enabled but disabled the separate method-inventory trace. It ended with watchdog code 3 and no runtime process. The guest fade value advanced through 0.9 and 1.0, then cycled back below 1; the watchdog stack now returns through `sub_000DFF40` at `0x000DFF7A`, with a caller return at `0x000E035B`, rather than the earlier `sub_000E0200`/`0x000E0231` splash draw loop. During the run it accessed `st00_0.rep`, the expected `UDATA\43430002\` save path, and `engdat11.eng`. The 640×480 framebuffer dumps still show Capcom at the last capture. This is evidence of guest startup progression into a subsequent logo/helper phase, not arrival at the Steel Battalion title.

The final partial-render report counted 72 draws, 288 indices, 37 clears, and 1,104 unhandled method instances (155 IDs). The no-inventory run produced more draw work within the watchdog interval than the previous capture, but this comparison is not a performance benchmark and cannot isolate the cause. No title screen, window presentation, audio, input, save/load behavior, or gameplay was verified. Keep Milestone 3 and progress bars unchanged. Next identify what `sub_000DFF40` waits for/draws and follow the new resource reads until a Steel Battalion title image is captured.

### Nude Maker splash reached during extended startup (2026-10-18)

A 180-second no-DSP-ack run with pushbuffer execution, modeled vblank/title-event diagnostics, framebuffer dumps, and the extra inventory scan disabled exited at watchdog code 3; no process remains. The guest read English tables through `engdat22.eng`, the fade timer cycled, and the final watchdog stack returned through `sub_000DFF40` / `sub_000DFBC0`. The local 640×480 framebuffer sequence moves from black/Capcom to a visible Nude Maker logo (`iso/local-analysis/logs/m3-startup-180s-20261018/frame_00012.bmp`). This confirms the startup sequence advances across distinct splash images, but the dump is guest framebuffer memory, not proof of display-window presentation or original-hardware accuracy.

At the watchdog snapshot the partial renderer counted 132 draws/528 indices, 67 clears, and 1,824 unhandled method instances across 155 IDs. It still did not reach the Steel Battalion title screen. No audio, controller input, save/load behavior, or gameplay was verified. ISO-derived BMPs remain in ignored local analysis storage and are not committed. No feature bars advance; Milestone 3 remains active. Next follow the remaining splash sequence and capture the actual Steel Battalion title image.

### Dolby startup splash reached in a bounded capture (2026-10-18)

A 300-second diagnostic launch of the existing Windows x64 executable used the same no-DSP-ack startup setup and guest-framebuffer dump as the prior splash captures. The last saved 640×480 frame (`iso/local-analysis/logs/m3-startup-300s-20261018/frame_00020.bmp`, ignored) visibly contains the Dolby Digital logo, after earlier CAPCOM and Nude Maker frames. This confirms additional guest startup splash progression in captured framebuffer memory only; it does not verify the actual window presentation, correct Xbox rendering, the Steel Battalion title screen, audio output, or gameplay.

The watchdog logged its 300-second diagnostic snapshot, including the guest fade timer at 0.6; a final later sample shows it had cycled back to 0. The process was no longer present after the capture, and a process check confirmed no `your_game_recomp` remains. No reliable performance benchmark was taken. Feature bars remain unchanged and Milestone 3 is still active. Next inspect the startup path after the Dolby splash and determine whether the missing MSVC C++ build targets can be restored without a system-wide install before attempting runtime fixes.

### Local Release rebuild and post-build startup check (2026-10-18)

The existing `your_game_recomp.sln` Release|x64 solution now builds successfully using the already-installed Visual Studio 2022 Build Tools MSBuild path. This resolves the earlier missing-import issue without installing system-wide components. The build emitted compiler warnings in the Xbox kernel bridge, but all solution targets, including `your_game_recomp.exe`, completed successfully.

A fresh 180-second bounded launch of that rebuilt executable used pushbuffer execution, asynchronous file I/O, diagnostic AC'97 readiness, modeled vblank/title-event signals, and no DSP acknowledgement shim. It wrote 15 local framebuffer captures. The last saved 640×480 capture (`iso/local-analysis/logs/m3-postbuild-180s-20261018/frame00014.bmp`, ignored) shows the Nude Maker splash. The watchdog log reports no guest exit at 180 seconds; a subsequent process check found no `your_game_recomp` process. The new capture did not reach or verify the Steel Battalion title screen.

This verifies local buildability and progress through the guest splash sequence only. It does not verify accurate window output, real DSP/audio, controls, saves, or gameplay. No performance benchmark was collected; all progress bars remain unchanged and Milestone 3 remains active. Next continue tracing the startup transition after Nude Maker and work toward title-screen boot before any Milestone 4 tasks.

### Reproduced Dolby splash in a rebuilt 300-second run (2026-10-18)

A second 300-second diagnostic launch of the freshly rebuilt Release executable reproduced the CAPCOM, Nude Maker, and Dolby Digital guest-framebuffer sequence. The final saved 640×480 capture (`iso/local-analysis/logs/m3-postbuild-300s-20261018/frame00020.bmp`, ignored) shows the Dolby Digital logo. This is repeatable guest framebuffer output, not a title screen or verified native-window presentation.

At the 300-second watchdog snapshot, the guest had not exited and the stack again ran through `sub_000DFF40` / `sub_000DFBC0`, with the outer return at `0x000E0362`; the fade timer was about 0.9. NV2A USER GET (`0x2C628`) trailed PUT (`0x2D60C`) at that instant, but this alone does not show that queued work causes the persistent splash loop. The process was stopped at the diagnostic bound and a follow-up process check found none. The partial renderer counted 232 draws, 928 indices, 117 clears, and 3,024 unhandled method instances across 155 IDs. No reliable performance result follows from these counters.

The rebuilt binary therefore reaches later splash content consistently but still does not reach the Steel Battalion title. Real audio/DSP, controller input, save/load, and gameplay remain unverified. No progress bars advance; Milestone 3 remains active. Next trace how the guest splash-state helper advances after Dolby and correlate that with the pending NV2A work before altering either the runtime or rendering behavior.

### Standard USB Start-pulse diagnostic (2026-10-18)

A bounded 180-second launch enabled the local opt-in `RECOMP_PAD_PRESS=0x10` diagnostic, which pulses only the Start button on the generic emulated Xbox USB gamepad. The run ended at the Nude Maker framebuffer splash; it did not reach the title screen. The log contains no `PAD:` report message, and its watchdog peeks show guest words `0x00687484` and `0x0066658C` remained zero. This indicates that the generic USB report path was not visibly exercised in this run; it does not prove the game requires a Steel Battalion controller or that all input paths are broken. No save/menu-confirm input was sent. The partial renderer counted 136 draws / 544 indices, 69 clears, and 1,872 unhandled method instances across 155 IDs. No performance benchmark is implied.

No `your_game_recomp` process remains. The test log and ISO-derived BMPs are ignored under `iso/local-analysis/logs/m3-start-pulse-180s-20261018/`. Controller response, title screen, window presentation, audio, saving, and gameplay remain unverified. Milestone 3 and all feature bars remain unchanged. Next trace which guest controller/USB APIs `default.xbe` actually polls and compare that path with the original controller's reported XID protocol before implementing an input bridge.

### USB host wiring and first XAPI enumeration trace (2026-10-18)

The earlier Start-pulse run had not enabled or initialized the optional OHCI device model, so its lack of a `PAD:` report was inconclusive about the emulated USB path. The local game harness now starts the existing OHCI module when `RECOMP_USB` is enabled, routes MCPX OHCI access violations to that model, and stops the worker during normal cleanup. The changes are isolated in `patches/steel-battalion-usb-host-wiring.patch` and `patches/xboxrecomp-v0.13.1-ohci-lifecycle.patch`.

The Release|x64 build succeeded. A 40-second watchdog-bounded launch with OHCI tracing and one synthetic Start pulse observed the game's XAPI stack operate HC0, receive the virtual device on port 1, request the 8-byte device descriptor, assign address 1, read the 32-byte configuration descriptor, and issue `SET_CONFIGURATION`. At the watchdog sample the OHCI counters showed four setup requests, two zero-length OUT status stages, no interrupt reports, and no periodic transfers. The trace did not show an XID descriptor request or input polling during this run; it does not establish whether those happen later in startup or after the title screen. The watchdog exited with code 3, and a process check found no runtime left active.

This verifies that the optional OHCI layer is now reachable and that the guest performs the first standard USB enumeration steps. It does not verify original Steel Battalion controller behavior, any guest-visible input response, the title screen, audio output, or gameplay. Controller feature bars remain at zero; Milestone 3 remains active. Next inspect the guest's path after `SET_CONFIGURATION` and continue toward a verified title-screen boot before assessing the custom controller protocol.

### A/B input probe and static splash-input path (2026-10-18)

A second bounded run held synthetic A+B through startup and pulsed Start later, with the wired OHCI model enabled. It again performed the same four setup requests and ended with zero periodic transfers and zero input reports. The pad script is applied only when the guest asks the OHCI model for a report, so no `PAD:` script-application line appeared; this run did not deliver those buttons to the game. At the 55-second watchdog sample, the guest stack return was `0x000E0231`, inside the first startup draw loop in `sub_000E0200`, after a call to `sub_000DFBC0`. This run did not reach the later logo helper seen in longer earlier runs, so startup progression is not consistent across these bounded samples. It did not reach the Steel Battalion title screen. The process exited at watchdog code 3 and no runtime remained.

Static disassembly shows the splash helper calls `sub_000C8050` and `sub_000C8080`, which query the embedded input accessor `sub_00048B80` with `(1, 6, 9)` and `(1, 6, 8)`. These are input-query arguments; their control names and the source that populates the accessor's state tables are not yet established. This supplies a concrete next trace target, but does not show that the input query caused the startup stall. No feature bars advance. Next trace the producers of the guest input state and the XAPI path after `SET_CONFIGURATION`, then continue the title-screen boot investigation.

### Controller input data-flow trace (2026-10-18)

Static inspection clarifies that `sub_00048B80` is an embedded input-state accessor, not an XAPI import. It selects among several per-slot state fields using its three arguments and reads the game-owned records beginning at `0x004AFBC0`; the records use a `0x154`-byte stride, and the initialization path clears four such records. Separate routines copy and transform those records and map bit fields into a game-side event/state table around `0x003B94AC`. The splash helper's `(1, 6, 9)` and `(1, 6, 8)` queries therefore read from this internal state path, but their labels and the upstream hardware producer are still unknown.

This narrows the next analysis target to the producers feeding the per-slot records and the bridge between Xbox device enumeration and those records. It does not establish that input is blocking startup, that the game is polling XID reports, or that the original Steel Battalion controller is recognized. The bounded USB trace still shows only standard descriptor enumeration and `SET_CONFIGURATION`, with no interrupt report requests. The original-controller input/mapping/lights bars remain at zero; title-screen, audio-output, and gameplay verification remain incomplete. No feature bars advance and Milestone 3 remains active.

### XPP-to-game input producer trace (2026-10-18)

Follow-up disassembly identifies the game-side producer path. `sub_00049910` initializes the input records and device state. `sub_00049970` iterates four slots, checks the XPP device-change state, creates or releases per-slot objects, and invokes embedded XPP helpers that return device data. It then copies button/axis-shaped fields into the slot record. `sub_00049DD0`, called by the surrounding input update routine, also operates on those records and calls XPP helpers. The disassembly therefore connects XPP-managed device state to the records read by the splash/game input accessors.

This does not identify the exact descriptor or report format accepted for the Steel Battalion controller, nor does the USB trace yet show report polling. It also does not establish that the splash waits on a controller input. Next compare the XPP device request path, OHCI's standard enumeration, and public Steel Battalion adapter documentation to determine what descriptor/endpoint behavior the runtime must support before implementing a controller-specific translation. Controller and title-screen progress remain unverified; no feature bars advance.

### Steel Battalion XID protocol comparison (2026-10-18)

Static inspection of the embedded XPP helper `sub_00256F26` shows it builds interface control requests with `bmRequestType=0xC1`, `bRequest=1`, and `wValue=0x0200` and `0x0100` to retrieve output and input capabilities. Those values match the XID `GET_CAPABILITIES` requests documented by [XboxDevWiki's Xbox Input Devices reference](https://xboxdevwiki.net/Xbox_Input_Devices). That reference records the Steel Battalion XID type/subtype as `0x80/0x01`, with 26-byte input and 22-byte output reports; its interface uses Xbox class/subclass `0x58/0x42`, interrupt IN endpoint `0x82`, and interrupt OUT endpoint `0x01`.

The local virtual USB gamepad currently advertises a standard Xbox Controller-S XID profile instead (type/subtype `0x01/0x02`, 20-byte input and 6-byte output). This generic profile is not a Steel Battalion controller profile. The prior OHCI log contains no XID descriptor or `GET_CAPABILITIES` request, so the guest did not reach that part of device negotiation in the bounded sample; the cause remains unresolved. This is a concrete protocol gap, not proof that it caused the startup stall.

The community Windows driver [SteelBattalionDriver](https://github.com/caosdoar/SteelBattalionDriver) exposes the controller as USB-HID and is GPL-3.0. It is a reference for Windows device access, not a dependency selected for this project; no code was copied, and no project-wide license decision is implied. Next reproduce the guest's XID descriptor/capability negotiation in a bounded run, then compare any requests with this documented Steel Battalion profile before adding it to the virtual device. Do not claim controller input, output lights, title-screen boot, or gameplay from this static comparison. Progress bars remain unchanged and Milestone 3 remains active.

### Startup-window input update trace (2026-10-18)

A 40-second bounded launch of the Release|x64 build enabled environment-gated traces at the outer input-update routine `sub_0004AA80` and the previously traced producer `sub_00049970`. The run again completed four standard USB setup requests (`GET_DESCRIPTOR` device/configuration, `SET_ADDRESS`, and `SET_CONFIGURATION`), with two zero-length OUT status stages and zero periodic transfers/reports. Neither input routine emitted an entry trace during this sample. The process was externally stopped at the 40-second bound; no title screen was verified.

This narrows the observation: the guest did not enter these particular game input-update routines during this startup interval, so the absence of XID capability requests cannot yet be attributed to a rejected Steel Battalion descriptor or report format. It does not show that the routines are never used later or that controller support is unnecessary. The temporary instrumentation was removed from the ignored generated source and the clean Release|x64 target rebuilt successfully. The log remains local and ignored at `iso/local-analysis/logs/m3-input-update-caller-trace-20261018/`. No feature bars advance; Milestone 3 remains active. Next continue tracing the startup state transition after the splash sequence toward a verified Steel Battalion title screen, and revisit the input path when the guest reaches a state that invokes it.

### Missing XPP function-boundary probe (2026-10-18)

Static disassembly found valid XPP code at `0x0025A3D7` (340 bytes, 91 instructions) immediately after the previously recognized function boundary. The local recompiler's function map omitted it, and runtime logs repeatedly reported failed indirect calls to that address. A temporary local translation and dispatcher entry made the warning disappear during a bounded 120-second test. In that test, standard OHCI setup transactions increased from four to five, but the game still showed no periodic transfers, no input reports, and no guest-visible device-change flag; both splash input queries remained zero. This experiment is diagnostic only: it did not establish a working controller path or title-screen boot.

The temporary generated callback and all startup/input traces were removed. The baseline Release|x64 build then completed successfully. A clean 40-second watchdog run reproduced the unresolved `0x0025A3D7` indirect call and exited on the watchdog with code 3. This pairs the missing boundary with a change in XPP/OHCI activity in the temporary test, but does not yet prove causality or resolve why the XPP path stops before requesting periodic reports. No game process remains. Title screen, native presentation, audio, controller functionality, saving, and gameplay remain unverified. Progress bars stay unchanged and Milestone 3 remains active. Next determine why the candidate callback enables one more setup transaction and whether the guest can proceed to XID capabilities and interrupt reports, using an isolated, reviewable source-level boundary fix if confirmed.

### Steel Battalion XID profile and enumeration follow-up (2026-10-18)

The public Xbox XID reference documents Steel Battalion as type/subtype `0x80/0x01`, with 26-byte input and 22-byte output reports. The opt-in virtual USB profile in `patches/xboxrecomp-v0.13.1-steel-battalion-xid-profile.patch` advertises the matching USB identity and endpoint layout, responds to the guest's 16-byte XID descriptor request, and provides a 26-byte input report. This profile is only a guest-side test device; it is not physical-controller support.

One earlier 30-second run recorded the guest requesting `C1 06` / `wValue=0x4200`, then `A1 01` / `wValue=0x0100` for a 26-byte report, with 25 periodic reports served. That result has not been reproducible: matching 30- and 60-second reruns of both the normal seeded build and manual-injection build reached the XID descriptor request but stopped at five control setups, zero periodic transfers, and zero reports. A narrow traced run confirmed that the guest's descriptor callback finds the virtual device's `0x80` type entry and continues through the callback success path with expected sizes 26/22, but no subsequent `GET_CAPABILITIES` or input-report request appeared before the watchdog. Treat the one polling run as an unreproduced observation, not verified controller polling.

The latest captured 60-second run exited on watchdog code 3; no title screen, audio, gameplay, real controller input, output-report handling, or indicator lights were verified. Trace instrumentation slowed execution, so its timing is diagnostic only. No feature bars advance; Milestone 3 remains active. Next trace the XPP device-change delivery from the successful descriptor callback through the game-owned input records, then rerun without function tracing to verify whether the normal startup reaches a report request.

A separate low-overhead 60-second run placed one-shot entry markers in the game-side `sub_00049970`, `sub_00049DD0`, and `sub_0004AA80` routines. None ran during the startup sample, even though the USB path reached the XID callback. This means the absent report request cannot yet be attributed to a rejected controller descriptor: these game-level input update routines were not reached. The temporary markers were removed and the local Release target rebuilt successfully. The cause of the earlier startup stall remains unresolved, and the title screen is still unverified.

The watchdog's native-PC capture and a local linker map put one sampled host address nearest the symbol for `sub_00194BA5` in the generated object. That function is a matrix-rotation routine, but a separate traced rebuild with an entry marker in that function emitted no marker, and another traced sample stopped inside XPP callback code. The map-to-function assignment is therefore not corroborated well enough to identify the startup stall. The watchdog's native stack walk is also incomplete without matching symbols. Keep the root cause open; next add same-build symbols or narrowly targeted PC/call-site tracing before attributing the stall to graphics or input. The map and logs remain local under ignored build/analysis directories.

### 2026-10-18 follow-up: symbolized queue fence and XID input polling

A diagnostic Release build with matching `/Zi` and `/DEBUG:FULL` produced an executable, linker map, and PDB. With pushbuffer execution disabled, the watchdog native PC resolved through that exact PDB to `sub_00211E10` at `recomp_0015.c:35137`. A temporary loop probe recorded `EAX=2`, queue producer `ESI=11`, completion pointer `EDX=0x80003000`, and completion value `3`; `producer - completion` was 8, so the guest repeatedly waited for the queue fence. This is expected in the deliberately executor-disabled diagnostic and is not evidence of the current startup blocker. The probe was removed and the clean generated source rebuilt successfully. This exact symbol evidence supersedes the prior map-only tentative attribution to `sub_00194BA5`.

A 35-second bounded run with pushbuffer execution, async file I/O, diagnostic AC'97 readiness, modeled vblank, the opt-in title-event bridge, and the virtual Steel Battalion USB profile passed that queue fence. It loaded title assets and served 45 periodic input reports. A separate 45-second USB-traced run reproduced XID descriptor request `C1 06` / `wValue=0x4200` (16 bytes), followed by `A1 01` / `wValue=0x0100` (26 bytes); the virtual device served 85 periodic reports before watchdog exit code 3. These are virtual-device request/response observations under experimental switches, not physical controller input, validated report semantics, game-side input-state updates, or a playable game. The Steel Battalion title screen, audio output, saves, and gameplay remain unverified; all player-facing bars and Milestone 3 remain unchanged.

The 35-second run repeatedly logged unresolved indirect target `0x0025D059`. Local disassembly shows valid x86 instructions from that address to `0x0025D098` (63 bytes); the current function map starts the next recognized function at `0x0025D098`, leaving the callable entry untranslated. Next establish a bounded function boundary and generate this small function in ignored local analysis output, then verify dispatch and inspect its effect on XPP/controller state before retaining any compatibility change. Never commit the generated game-derived C code.

### 2026-10-18 follow-up: local translation of XPP entry `0x0025D059`

The project translator lifted the 63-byte XPP routine at `0x0025D059` from the user-supplied XBE after a temporary local function-boundary entry was added to ignored analysis data. The generated function was inserted into the ignored local source chunk, declaration, and sorted dispatcher, then the Windows target built successfully. In a 35-second bounded run with the same opt-in runtime profile, no unresolved-call warning for `0x0025D059` appeared; the guest repeated the Steel Battalion XID descriptor request and 26-byte report request and the virtual device served 60 reports. This does not show that the translated routine changed the observed report behavior: report polling already occurred in the prior run, and game-side state changes remain unverified. Keep the helper and boundary metadata out of Git because the body is generated from copyrighted game code.

The watchdog now samples the guest back in the queue fence at `sub_00211E10` / `recomp_0015.c:35137`: producer `0x1D` (29), completion counter `0x11` (17), and a difference of 12 where the loop waits until the difference is at most 8. NV2A USER DMA has `PUT=0x5F40`, `GET=0x54A8`, so submitted work remains beyond the executor's consumed position. The title screen is still not visible or verified. Next capture and decode the pushbuffer words at the stalled GET position, identify the first command the executor does not consume, then make and validate the smallest runtime correction. The run still used experimental AC'97, vblank, event, async-I/O, pushbuffer-executor, and virtual USB settings; no audio output, real controller input, saves, or gameplay is verified. Milestone 3 and all player-facing bars remain unchanged.

### 2026-10-18 follow-up: queue advances; startup remains on splash sequence

This follow-up supersedes the preceding interpretation of `GET=0x54A8` as a stalled cursor. A later cursor trace walked the full `0x800054A8..0x80005F40` segment (678 words, no jumps or unknown methods) and logged completion. At its 45-second watchdog sample, USER DMA had advanced to `PUT=0x79BC`, `GET=0x69D8`; a separate 90-second sample reached `PUT=0xCE94`, `GET=0xBEB0`. These snapshots show queue consumption progressing, although the producer remains ahead. The captured range therefore does not establish a stuck or faulty command as the startup root cause.

A subsequent 60-second diagnostic run captured four local 640×480 guest-framebuffer images: black frames followed by a dim CAPCOM splash. Its watchdog reports producer fence `0x49`, completion `0x3D`, and USER DMA `PUT=0x9984`, `GET=0x89A0`; the guest stack returns through `sub_000DFE75` / `sub_000E0231`. The OHCI model served 1,118 periodic transfers/reports in this run. This is guest-memory splash output and virtual report service only; it does not verify native-window presentation, Steel Battalion title screen, physical-controller input semantics, audio output, saves, or gameplay. The bounded run ended without reaching the title screen, and no runtime process remains.

Keep all bars unchanged and Milestone 3 active. Next trace the guest startup state after the CAPCOM/Nude Maker/Dolby logo helpers and the XBE-derived asset/resource handoff; continue correlating guest state with framebuffer captures. Do not treat the earlier queue snapshot as the root cause. Local captures and generated game-derived code remain ignored and must stay out of Git.

### 2026-10-18 follow-up: splash sequence call-path review

Static review of the translated guest code maps the watchdog return addresses to the startup logo path: `sub_0004683E` invokes `sub_000E0200`, which advances a guest fade timer using the game time value and frame delta, draws through `sub_000DFBC0`, and then invokes two `sub_000DFF40` logo helpers before returning to the main loop. This is consistent with the observed CAPCOM/Nude Maker/Dolby splash frames. It does not prove that the timer, logo assets, or graphics translation are the cause of the missing title screen.

A temporary trace was added only to ignored generated source to sample the guest clock/timer at those call sites. The Release build succeeded, but the bounded 40-second run emitted no trace markers and ended in the watchdog path before a useful clock sample was captured. The temporary instrumentation was removed byte-for-byte from the generated source and the baseline Release target rebuilt successfully. Treat this probe as inconclusive; no gameplay behavior changed or was verified. No runtime process remains. Keep Milestone 3 and every progress bar unchanged. Next make a trace that can confirm entry and guest time values without relying on the unsuccessful generated-source marker, then follow the same splash-to-title state transition.

A separate 35-second symbolized watchdog run captured a guest thread in the XPP/OHCI event path: the bridge created an event, OHCI raised an interrupt, and the thread entered the host `ZwWaitForAlertByThreadId` wait path. The watchdog's sampled guest globals still showed the splash timer fields at zero, but this sample was from the USB/event thread and was trace-instrumented; those zeroes do not establish the main game thread's timer state. This observation does not prove the wait is incorrect or blocks title startup. Keep the root cause open and compare the main game thread's call path in an uninstrumented run with event wakeups and splash asset loads.

### 2026-10-18 follow-up: untraced main-thread sample and flip rate

The recompiled output contains function-trace hooks whose default budget is 400,000 entries. Earlier “symbolized” runs that omitted `RECOMP_TRACE_BUDGET` still emitted traces and ran slowly; the 35-second USB/event sample is useful for call-path evidence, but is not an uninstrumented timing sample. Setting `RECOMP_TRACE_BUDGET=0` disables those trace messages. This corrects the comparison method and makes the earlier zero splash-timer values from a USB/event stack sample non-diagnostic for the main thread.

With tracing disabled, a fresh 90-second watchdog run sampled the main guest thread inside the splash draw/fade path (`sub_000DFE75` / `sub_000E0231`). Guest clock advanced by about 66.3 seconds during the 90-second host interval; the fade timer was about 0.5 with a 0.05 increment. USER DMA `PUT=0xF3A8`, `GET=0xE910` confirms the queue continued advancing. The guest had loaded CAPCOM, Nude Maker, and Dolby logo assets, BGM and `ADVANCE.BIN`; the framebuffer captures still showed CAPCOM. The renderer reported 27 flips and about 0.44 guest FPS near the end, with 52 draw batches, 104 triangles, and about 16 million pixel writes. These figures show very poor startup presentation cadence in this partial renderer; they are not a stable performance benchmark, and they do not prove the rasterizer is the sole bottleneck. The OHCI model served virtual reports, but controller response remains unverified. No title screen, audible output, saves, or gameplay was verified.

A separate 45-second probe used the renderer's maximum 16-worker setting and reported 0.38 guest FPS at its last periodic report, with nine flips at that point; the saved final framebuffer still showed CAPCOM. This short run is not a controlled enough comparison to conclude whether the worker setting changes throughput. No title screen was reached. Keep all progress bars and Milestone 3 unchanged. Next profile time spent in the guest draw/flip path versus the CPU software rasterizer, then use a matched-duration comparison before selecting a performance fix. Do not advance frame-rate or graphics-feature progress from these startup diagnostics.

### 2026-10-18 follow-up: software-rasterizer timing sample

Temporary QPC instrumentation around `raster_batch()` was added to the ignored local XboxRecomp source for a watchdog-bounded 45-second run, then removed by restoring the pre-instrumentation file byte-for-byte. With `RECOMP_TRACE_BUDGET=0`, pushbuffer execution, async I/O, synthetic AC'97 readiness, modeled vblank, title-event handling, and the virtual Steel Battalion USB device, the first frame contained two raster batches and subsequent sampled splash frames each spent about 2.18–2.40 seconds inside `raster_batch()`. The renderer reported 0.38 guest FPS at nine flips. This directly identifies the partial CPU software rasterizer as a major measured cost in this run; it does not prove it is the only bottleneck or that this timing represents a playable scene.

The run remained on the CAPCOM splash and did not verify the Steel Battalion title screen, audible output, physical-controller input, saves, or gameplay. The `nv2a_pb_exec.c` source was restored to its recorded SHA-256 (`06EC1DC9EE2A3056242746E7A3F1BF0DBE204D27A21EC4CC20E46B61B60B3B1C`), and the clean Release target rebuilt successfully. The timing logs and temporary instrumentation remain local under ignored analysis output. Milestone 3 and all progress bars remain unchanged. Next inspect whether the existing D3D8-to-D3D11 interception path can handle Steel Battalion's translated rendering workload; do not switch rendering architecture until that local path and its limits are established.

### 2026-10-18 follow-up: graphics-path wiring audit

The local runtime contains a Windows D3D8 COM compatibility layer backed by D3D11, and the umbrella `xboxrecomp` target links it. However, the observed title NV2A pushbuffer path is separate: `nv2a_pb_scan.c` decodes commands and, when `RECOMP_PB_EXEC` is enabled, dispatches them to `nv2a_pb_exec_method()` in `kernel/nv2a_pb_exec.c`, whose current visible-pixel path uses the CPU software rasterizer. The D3D8 bridge does not automatically receive this pushbuffer workload.

There is also an NV2A PGRAPH-to-D3D11 method translator in `src/nv2a/nv2a_pgraph_d3d11.c`. The current source documents it as a 5-dword inline-vertex, textured 2D menu profile; `pgraph_d3d11_init()` is called by the pushbuffer replay harness, while the normal scan path described above routes to the separate executor. A method-coverage audit is needed before judging whether this translator can be extended for Steel Battalion or whether a broader PGRAPH backend is required. Do not equate the existence of the D3D11 library with GPU-accelerated rendering of the game's current pushbuffer stream, and do not select or implement a replacement architecture yet. The exact `raster_batch()` timing above remains the measured performance evidence. Milestone 3 and all progress bars remain unchanged.

A source-to-trace comparison shows why the PGRAPH translator is not a drop-in renderer for the observed Steel Battalion startup workload. The 90-second guest run reported 52 vertex-program batches / 208 vertices with vertex attributes `v0` through `v15` in the observed attribute format. The executor also saw texture state at guest offset `0x803DF800` in 51 batches, but reported zero batches with a usable texture stage, so this is texture-state evidence rather than proof of successful texture sampling. The translator hardcodes five dwords per vertex (`X, Y, U, V, Color`) and its generic build path disables texturing and uses diffuse vertex color; a source search found no `GAME_HAS_FONT_ATLAS` definition in the local runtime checkout. Its optional texture mapping is a fixed reference-title lookup. The current executor separately interprets guest vertex programs and reports 155 distinct methods unhandled during startup; that count does not mean all 155 are visually significant. Any GPU path must preserve the game's vertex-program, texture, blend, and surface behavior, rather than forwarding this workload to the narrow menu translator. Next compare reuse options for the existing NV2A PGRAPH execution/shader code and define a semantics-preserving GPU raster backend; no backend switch or implementation is made by this audit.

### 2026-10-18 follow-up: renderer reuse and license boundary

The checked-out local XboxRecomp tree (`v0.13.1-dirty`) identifies the toolkit as MIT, with explicit LGPL-2.1-or-later exceptions for `src/apu/` and `src/nv2a/nv2a_regs.h`. Its contribution guidance specifically says not to port GPL code from Cxbx-Reloaded or the GPL portions of xemu. Cxbx-Reloaded publishes under GPL-2.0, and xemu's top-level `COPYING` is GPL version 2. Therefore, directly porting either project's PGRAPH renderer is not compatible with the current upstream contribution policy and would require a deliberate licensing review before any reuse. No code was copied and no project license was changed.

The viable research paths are to implement a semantics-preserving hardware raster backend against the existing decoded NV2A state using original code, or to pursue an explicitly approved GPL-compatible integration after reviewing project-wide distribution obligations and the XboxRecomp upstream policy. Continue with original-code feasibility and method-coverage analysis first; do not begin a GPL-derived port or change the license implicitly. Milestone 3 and all progress bars remain unchanged.

At this earlier checkpoint, the option comparison in [`GRAPHICS_BACKEND_OPTIONS.md`](GRAPHICS_BACKEND_OPTIONS.md) recommended D3D12 and listed Vulkan as an alternative. That recommendation has since been superseded by the final Vulkan-only decision at the top of this status page and in the current backend decision record.

### USB input and startup follow-up (2026-10-18)

A bounded 45-second diagnostic of the local `build-xpp-seeded` Windows x64 executable enabled the Steel Battalion virtual USB profile, synthetic Start pulses, USB transfer statistics, asynchronous file I/O, pushbuffer execution, and the existing watchdog. The Xbox OHCI bridge initialized with one device on HC0 port 1; after initial setup traffic, the guest scheduled its periodic endpoint. The bridge served 870 periodic transfers/reports during the sample. The synthetic Start source was active, and the profile code maps its standard Start bit to Steel Battalion input-report byte 2 bit 6. This verifies host-side report generation and delivery through the virtual interrupt endpoint; it does not show that game logic consumed Start or reacted to it.

The local 640×480 guest-framebuffer capture sequence advanced to a dim CAPCOM splash. The watchdog ended the run after 45 seconds with the guest still active. No Steel Battalion title screen, native-window presentation, audio output, physical controller behavior, save/load, or gameplay was verified. The earlier five-minute capture run showed only one flip and black frames; that differing result is not reconciled by this follow-up and should not be combined as a matched comparison. Logs and captures remain local under `iso/local-analysis/logs/m3-usb-stats-45s-20261018/`. All progress bars remain unchanged and Milestone 3 remains active. The exact XID trace results are recorded below; preserve the graphics-backend approval gate before renderer implementation.

A second bounded run with `RECOMP_USB_TRACE=1` captured the guest's exact requests: XID `GET_DESCRIPTOR` (`C1 06`, value `0x4200`, length 16), followed by interrupt input request `A1 01`, value `0x0100`, length 26. The bridge served 451 periodic transfers by the 45-second watchdog sample, and the synthetic Start source was active. No XID `GET_CAPABILITIES` request appeared in this trace, and there is still no evidence that the game logic acted on Start. This verifies that the virtual endpoint matches the requested Steel Battalion report size and is being polled, but not complete controller compatibility, output/light behavior, or gameplay. Captures and trace remain local under `iso/local-analysis/logs/m3-usb-xid-trace-45s-20261018/`; no progress bars change. Next determine why the guest proceeds from XID descriptor retrieval to input polling without requesting capabilities, while continuing the splash-to-title trace.

A matched 90-second run with the same build and Steel Battalion input profile again ended at the watchdog with a CAPCOM logo in the last sampled guest framebuffer. The latest GPU sample reported 0.43 guest FPS at 27 flips; this is an early startup measurement, not a gameplay benchmark. OHCI counted 2,444 periodic transfers, including 2,434 input reports and 10 non-control OUT transfers. Source inspection shows the current OHCI bridge counts non-control OUT transfers but accepts and discards their payloads; the initial stats-only trace did not record those bytes, so their function was then unknown. This is a concrete gap for future device-output work, not proof that those packets control indicator lights. The Steel Battalion title screen remains unverified. Local logs and captures are under `iso/local-analysis/logs/m3-usb-startup-90s-20261018/`; progress bars remain unchanged. The payload trace follow-up is recorded below.

A temporary, local-only OHCI trace then captured non-control OUT payloads during another bounded 90-second run. The guest sent 22-byte packets on endpoint 1. Nonzero fields changed in byte 3's high nibble and byte 18's low nibble; the public [XboxDevWiki Steel Battalion XID table](https://xboxdevwiki.net/Xbox_Input_Devices) labels those positions `Start` and `GearN`. This is consistent with the game updating controller status/indicator channels, but their hardware meaning has not been confirmed on a physical controller. The current bridge discards these writes, so original-controller output functionality remains absent. The temporary trace change was restored byte-for-byte to source SHA-256 `21E55855E52C34CBAB1755B72981324CC51D31C62BDA8B2B0F513327369ED3A7`, and the normal Release target rebuilt successfully. Raw packet captures remain local and ignored under `iso/local-analysis/logs/m3-usb-out-payload-90s-20261018/`. Progress bars remain unchanged. Next validate output channels with a physical Steel Battalion controller/adapter or an independently documented test, then implement a narrow output-forwarding path.

A matched 180-second run with the virtual Steel Battalion profile, synthetic Start pulses, USB stats, async file I/O, and pushbuffer execution advanced the 640×480 guest framebuffer from CAPCOM to the Nude Maker logo by capture 12. The watchdog stack still sampled `sub_000DFE75`, the startup logo draw/fade path; the final NV2A USER DMA PUT/GET were `0x1BD20` / `0x1B270`. The latest periodic GPU sample was 0.43 guest FPS at 69 flips, and OHCI served 5,512 periodic transfers (5,491 input reports, 21 non-control OUT packets). This is repeatable splash progression with active virtual input, not a title screen or gameplay. The run ended at its watchdog with no remaining game process. Artifacts stay local under `iso/local-analysis/logs/m3-usb-startup-180s-20261018/`. Progress bars remain unchanged; next determine the subsequent splash/title transition and keep accuracy and rendering work behind the existing backend approval gate.

A five-minute run with the same build and USB profile advanced the guest framebuffer to the Dolby Digital logo by capture 20, after the previously verified CAPCOM and Nude Maker logos. At the watchdog the guest stack still pointed into the logo draw/fade path; NV2A USER DMA PUT/GET were `0x2D0C0` / `0x2C628`. OHCI served 9,669 periodic transfers (9,627 input reports, 42 non-control OUT packets). The latest GPU sample reported 0.43 guest FPS at 117 flips. The watchdog ended the process after 300 seconds; no title screen, native-window presentation, audio, saves, or gameplay was verified. This confirms startup logo progression under the repeated Start probe but exposes extremely slow startup rendering. Artifacts remain local under `iso/local-analysis/logs/m3-usb-startup-300s-20261018/`; all progress bars remain unchanged. The next useful boot step is to trace the guest's post-Dolby state transition and address the renderer bottleneck only within the approved graphics architecture.

Static XBE call-graph analysis narrowed the five-minute checkpoint: startup function `sub_000467A0` calls `sub_000E0200`, and only after that returns does it enter its `sub_000E3510` event-dispatch loop. `sub_000E0200` invokes `sub_000DFF40` twice for its logo helpers. The 300-second watchdog stack contains return address `0x000E0362` from the second helper call (`sub_000DFF40` argument 2), with the draw path below it in `sub_000DFBC0`; it has not returned to the event dispatcher. The captured framebuffer shows Dolby at this checkpoint. This establishes that startup remains inside the logo routine, but does not distinguish an intentional wait, a missed guest-side input condition, or severe rendering delay. The next probe should record the logo helper's loop/timer/input condition and return edge, without patching guest behavior.

### 2026-10-18 watchdog instruction-pointer correction

A closer decode of the five-minute guest stack resolves the sampled instruction pointer `0x000DFE75` inside `sub_000DFBC0` (function range `0x000DFBC0–0x000DFE83`), the draw routine reached from `sub_000DFF40`; return address `0x000E0362` is the caller continuation after the second logo-helper call. This is a point-in-time guest PC inside the draw call, not evidence that a timer or input wait is the active instruction. In the same run, the GPU report had only 117 flips after 300 seconds, and the isolated raster timing probe measured 2.18–2.40 seconds in `raster_batch()` for each sampled splash frame. Together these observations make CPU software rasterization the leading measured startup bottleneck, while not proving it is the only cause of the missing title screen.

The earlier call-path note's alternatives (intentional timer wait or missed input condition) remain possible at other times but are not supported as the active watchdog location. At this historical checkpoint the next-renderer proposal was an incremental D3D12 backend. That proposal is superseded; the final project renderer is Vulkan only. Do not claim boot until the title screen is repeatable. No feature bars advance.

### Native GPU API selection and prototype status (2026-10-18)

Historical backend assessment (superseded): an earlier checkpoint recommended native Direct3D 12 based on Windows integration and CPU submission goals, while noting that no matched Steel Battalion benchmark proved it faster than Vulkan. The project decision is now fixed to Vulkan; this historical note does not authorize another backend change. The underlying measured opportunity remains CPU-side rendering cost (2.18–2.40 seconds per sampled splash frame).

A local-only D3D12 flat-triangle prototype was added to the ignored XboxRecomp checkout and the Windows x64 target builds successfully. The prototype is opt-in through `RECOMP_D3D12_RASTER=1`, retains the software reference path, and only attempts flat untextured draws with blending, depth, and alpha testing disabled. This is not yet a useful acceleration of the observed splash workload: the traced first two startup draws use depth, and the second is textured, so they fall outside its supported state. No runtime image-parity test, performance comparison, or D3D12 coverage of the measured slow path has been verified. The current synchronous full-surface upload/readback design must not be treated as a performance result. Progress bars remain unchanged; no title screen is verified. Next redesign around batched NV2A work and GPU-resident surfaces, then compare identical guest frames and timings against the software renderer.

### D3D12 raster smoke check (2026-10-18)

A bounded 25-second launch used the Steel Battalion virtual USB profile, the repeated Start probe, `RECOMP_RASTER_TEST=1`, and `RECOMP_D3D12_RASTER=1`. The Windows x64 target built successfully and the ordinary software raster self-test produced the expected magenta triangle in the 640×480 guest framebuffer. The D3D12 device/queue setup proceeded to pipeline creation, but `CreateGraphicsPipelineState` returned `E_INVALIDARG`; the D3D12 self-test therefore fell back to software. The Windows Graphics Tools debug layer is unavailable on this machine (`D3D12GetDebugInterface` returned `0x887A002D`), so no driver validation message was captured. No D3D12 image parity, D3D12 acceleration, title screen, audio, or gameplay was verified. The bounded process was stopped after the capture and no `your_game_recomp.exe` process remained. Diagnostic logs and the guest-frame capture are local and ignored under `iso/local-analysis/logs/m3-d3d12-prototype-smoke-20261018-r7/` and `...-r8/`. Progress bars remain unchanged. Next resolve the PSO validation failure with a minimal D3D12 pipeline diagnostic before attempting to expand NV2A state coverage.

### D3D12 PSO fix and guest-surface smoke check (2026-10-18)

The earlier `E_INVALIDARG` was isolated to the scalar pixel-shader input signature. The minimal no-input and POSITION-only probes created PSOs; the full pipeline succeeded when the interpolated color was carried as a structured `TEXCOORD` between vertex and pixel shaders. All temporary probe variants were removed. After a fresh Release x64 rebuild, a bounded launch with `RECOMP_D3D12_RASTER=1` and `RECOMP_RASTER_TEST=1` logged `[D3D12-R] first flat triangle completed at 640x480` and `[GPU] D3D12 raster self-test passed`; the captured 640×480 guest framebuffer shows the expected magenta triangle. This verifies native D3D12 device/queue/PSO creation, a basic draw, and readback into guest memory. It does not accelerate the traced splash draws, which use depth and texture state, and it does not verify title-screen rendering, image parity against actual game draws, audio, or gameplay. The diagnostic run was externally bounded and left no game process. Artifacts stay local and ignored under `iso/local-analysis/logs/m3-d3d12-final-selftest-20261018/`. Progress bars remain unchanged. Next implement a batched stateful path for the actual startup draw, preserving the software renderer as the comparison reference.

A paired software-reference run disabled `RECOMP_D3D12_RASTER` but kept the same synthetic triangle and launch settings. Its BMP SHA-256 exactly matches the D3D12-enabled capture (`839BB69098BBFCB9A63CC0EED0E66DF99EC18EBF174D7F98903FE07AC69CD5ED`). This verifies byte-identical output for the synthetic flat triangle only; it is not a comparison of the game's textured/depth-enabled draws or a performance measurement.

### D3D12 actual startup strip checkpoint (2026-10-18)

The Release x64 target rebuilt successfully. A bounded launch with pushbuffer execution, synthetic AC'97 readiness, async I/O, virtual Steel Battalion USB, repeated Start pulses, and DSP acknowledgement unset activated the opt-in D3D12 path on the first measured guest draw. The matcher was corrected to the captured four-vertex triangle strip, not a quad. The runtime logged native D3D12 initialization, a six-vertex D3D12 batch at 640×480, and completion of the actual opaque-black depth-tested startup pass. This verifies the renderer accepts that specific guest draw state and writes through the experimental full-surface upload/readback route.

The first comparison used periodic framebuffer dumps and was inconclusive. Inspection showed the existing after-draw hook only covered fixed-function raster batches; transformed NV2A draws bypassed it. Added an opt-in capture directly after transformed draws and suppressed periodic dumps during that mode. Matching first-draw captures exposed a real D3D12 error: its vertex-buffer view declared room for three vertices although the strip batch submitted six, so the second triangle read outside the declared view. Changed the view size to the submitted vertex count and rebuilt successfully.

After the fix, the first two 640×480 captures taken at transformed-draw completion are byte-identical between D3D12 and the software reference. Both D3D12 captures and both software captures have SHA-256 `9DC5CDCF2B4ABD98A266B99496FA0062BEC2C56E30B979A7CB5D033275EED1B3`. This verifies parity for the captured startup black pass and following transparent textured pass only. It does not establish title-screen rendering, complete NV2A correctness, audio, gameplay, frame pacing, or a speedup. The current path synchronously uploads and reads back the full surface, so it remains unsuitable as the performance architecture. Logs/captures are ignored under `iso/local-analysis/logs/m3-sync-draw-d3d12-vbv-fix-20261018/` and `iso/local-analysis/logs/m3-sync-draw-software-20261018/`. Progress bars remain unchanged. Next extend correctness to a meaningful visible textured pass, then move to GPU-resident batching before measuring throughput.

### No-ack startup capture after D3D12 API decision (2026-10-18)

A fresh Release x64 build succeeded with the existing compiler warnings. A bounded 45-second launch used pushbuffer execution, synthetic AC'97 readiness, async file I/O, the virtual Steel Battalion USB profile, and a repeated Start probe, with DSP acknowledgement left unset. The guest bootstrapped both 2,048-word DSP programs and executed initial slices (GP 4,120 cycles; EP 1,020 cycles), then reported zero-cycle GP slices. Frame tracing observed one flip, a 640x480 color-surface clear, 235 unhandled NV2A methods, zero draws, and zero pixels written. The run did not reach the first transformed splash draw, so the temporary vertex-output trace yielded no vertex color/depth data and was removed. The process was externally bounded and no game process remains. Logs are ignored under iso/local-analysis/logs/m3-vsh-output-trace-retry-20261018/. This does not verify title rendering, audio, or gameplay and does not alter any progress bars. Next reconcile this no-ack startup trace with the earlier splash draw capture and its exact runtime flags before extending D3D12 state coverage.

### No-ack startup draw state reproduced (2026-10-18)

A 180-second bounded run used RECOMP_PB_EXEC=1, RECOMP_AC97_READY=1, RECOMP_ASYNC_IO=1, the virtual Steel Battalion USB profile, repeated Start pulses, and frame tracing. DSP acknowledgement remained unset. The run exited at the external bound; no project process remains. It reproduced the slow startup path: at the later sample the guest had three flips and four draw calls (eight triangles); GPU samples remained about 0.09 FPS on the brief intervals. The first two traced passes each cover roughly the 640x480 surface and use depth test LEQUAL with depth writes.

The first pass is untextured and unblended. All three sampled vertices have screen-space z=0, w=1, and d0=(0,0,0,1); combiner state is stage program 0, final0 0x200C0000, final1 0x00001C80. Evaluating that state through the current CPU combiner yields opaque black. The second pass samples a 512x512 DXT1 texture from guest offset 0x803DF800, blends with SRC_ALPHA / ONE_MINUS_SRC_ALPHA, and has constant vertex d0 RGB 0.690196 with alpha 0 in this sample. These are actual guest draw inputs, not a D3D12 parity result. The process still does not reach the title screen; actual audible output and gameplay remain unverified. The trace and guest-derived data remain local/ignored at iso/local-analysis/logs/m3-draw-repro-180s-20261018/.

The temporary vertex-output trace was removed from the ignored runtime source; a fresh Release x64 rebuild succeeded with existing warnings. Next implement and compare a batched D3D12 pass that can preserve depth and the observed combiner/texture/blend semantics. Do not use the current synchronous per-triangle full-surface upload/readback prototype as the performance architecture. Keep all progress bars unchanged.

### Historical native NV2A backend review (superseded by the fixed Vulkan decision)

This earlier Vulkan recommendation is superseded by the Windows D3D12 decision below. At that point, renderer maturity was considered, but no direct API benchmark was available.

The xemu Vulkan PGRAPH source review found a GPL-2-or-later header dependency and unresolved transitive license inputs. No Vulkan code was copied. The D3D12 prototype remains a correctness probe; its synchronous surface upload/readback is unsuitable for performance, and startup parity is limited to two splash passes. The software rasterizer remains the pixel reference.

No matching D3D12/Vulkan benchmark exists for this game's captures, and no renderer performance result was verified. This historical integration proposal was superseded by the D3D12 recommendation and is now superseded by the fixed Vulkan decision.

### Vulkan integration feasibility audit (2026-10-18)

Read-only inspection of xemu master `8fc3208` found 17 C translation units in `hw/xbox/nv2a/pgraph/vk/meson.build`; source files carry LGPL-2.1-or-later notices. The wrap files pin Volk (MIT), glslang (mixed BSD and additional component licenses), VMA (MIT), and SPIRV-Reflect (Apache-2.0) at exact commits now recorded in `docs/GRAPHICS_BACKEND_OPTIONS.md`. The Windows Vulkan headers/loader source is not pinned there. This remains a preliminary license inventory: audit compiled glslang pieces, transitive build dependencies/notices, and Windows runtime packaging before selecting the repository license or distributing binaries. Renderer functions are tightly coupled to xemu `NV2AState`/`PGRAPHState`, QEMU helper and memory-region APIs, shared xemu PGRAPH/surface/texture structures, and an offscreen GL context used for optional external-memory sharing.

The ignored XboxRecomp checkout has only a minimal PGRAPH state stub and a narrow D3D11 method handler. The Vulkan renderer cannot be linked in as-is. A port must map the real pushbuffer executor's guest state into a fuller NV2A/PGRAPH model or place the Vulkan renderer behind a new adapter contract, and must account for QEMU utility substitutions and the optional GL interop path. This is substantial engineering, not a hard dead end; it does not require the emulator CPU/kernel/machine loop. No source was copied, no build/test was run, and no milestone progress changed. The initial adapter seam is now documented: keep pushbuffer decoding and the current CPU VSH transform, send clipped geometry plus explicit render/surface/texture state to a Vulkan raster backend, preserve CPU raster as reference, and synchronize guest RAM only at true visibility boundaries. A read-only `vulkaninfo --summary` probe verified the installed loader sees the RTX 4070 SUPER (API 1.4.351, driver 617.42) and reports fragment-shader interlock, custom-border-color, external-memory-host, and dynamic-rendering extensions. No Vulkan SDK environment or development headers are configured. Next compare renderer extraction with a smaller Vulkan raster module, audit the exact build dependencies, and resolve a reproducible Windows Vulkan SDK/loader source without touching user ISO/game data.

### Historical: graphics integration route proposed after state-flow comparison (superseded 2026-10-18)

This historical proposal adapted xemu's PGRAPH method/state model and Vulkan renderer as the NV2A graphics subsystem. A later D3D12 recommendation superseded it; that recommendation is itself superseded by the current fixed Vulkan decision. Only the graphics subsystem is in scope; the XboxRecomp recompiled CPU, kernel, audio, input, and game boot remain, and xemu's emulator CPU/machine/PFIFO thread do not.

The machine query confirmed the RTX 4070 SUPER reports xemu's basic Vulkan feature requirements. This is hardware capability evidence only. No Vulkan renderer code was copied. The Vulkan integration route was not selected because its license closure remains unresolved and no comparative speed advantage was found. Milestone 3 and all bars remain unchanged.

### Pushbuffer packet boundary and Vulkan route update (2026-10-18)

Added `patches/xboxrecomp-v0.13.1-pushbuffer-packet-boundary.patch` for the pinned XboxRecomp v0.13.1 baseline (`193e299`). The scanner now keeps the method packet's parameter array, count, and increment mode intact at the executor boundary, while forwarding the same decoded methods to the existing per-method executor. This creates an integration seam for an eventual PGRAPH method processor; it does not implement PGRAPH or Vulkan rendering. The patch applies cleanly to a fresh detached baseline and passes `git diff --check` there.

The local ignored XboxRecomp checkout was built with the packet-boundary change using the existing Release x64 target; the build succeeded with pre-existing MSVC warnings. A 25-second watchdog-bounded launch using the virtual Steel Battalion USB profile reached OHCI operational state, detected the pad, and cleared one GPU surface. It logged 235 unhandled methods, 147 distinct methods, and zero draws/pixels in the sampled report. The run ended at the external watchdog; it did not reach the title screen. No renderer parity, audio, gameplay, or performance result was established. This only checks that the altered packet intake builds and survives an early startup smoke run.

The renderer integration route recorded at this point was xemu PGRAPH plus Vulkan. This historical proposal was superseded by a D3D12 recommendation and later restored as the fixed Vulkan direction.

Milestone 3 and all progress bars remain unchanged. The current fixed Vulkan decision governs implementation; keep the software renderer as a parity reference and do not start resolution or visual enhancements before title-screen boot and accurate rendering are established.

### Historical D3D12 recommendation, superseded by the fixed Vulkan decision (2026-10-18)

At that point the backend recommendation was D3D12, based on platform fit rather than a matched game benchmark. **That recommendation is historical and inactive.** The user later fixed Vulkan as the project backend and instructed us not to switch again. Retain the old evidence below only as decision history; it does not authorize new D3D12 implementation or an alternative runtime path.

At this earlier checkpoint, the xemu Vulkan route was deferred due unresolved renderer license/build inputs. That did not clear D3D12 for implementation, and the later user-directed Vulkan lock is the active decision. Static recompilation remains the CPU execution architecture; no full-system emulator substitution. See [the graphics backend decision record](GRAPHICS_BACKEND_OPTIONS.md).

Research sources: [XboxXBERecomp renderer and license](https://github.com/TGP482/XboxXBERecomp), [xemu Vulkan/OpenGL comparison issue #1838](https://github.com/xemu-project/xemu/issues/1838), and [xemu NV2A graphics debugging docs](https://github.com/xemu-project/xemu-website/blob/master/docs/docs/dev/debug/graphics.md). The latter documents debugging methods rather than a performance comparison.

Milestone 3 and all progress bars remain unchanged. Next perform the D3D12 renderer source/license suitability audit and continue the boot diagnosis; do not begin resolution or cosmetic enhancements before title-screen boot and accurate rendering are established.

### D3D12 textured startup fade parity and matched run (2026-10-18)

Added the experimental third renderer patch, `patches/xboxrecomp-v0.13.1-d3d12-textured-fade-experimental.patch`, against XboxRecomp v0.13.1 commit `193e299`. It adds a narrow native D3D12 texture/alpha pass for the captured 640x480 startup logo state and a guarded software depth-buffer clear update. The patch contains only `nv2a_d3d12_raster.c`, its header, and the pushbuffer executor changes; no XBE, game asset, or generated game-derived code is included. The three-patch D3D12 sequence applied to a cleanly extracted verification source tree and passed `git diff --check` there.

The Release x64 target built successfully with the current local dependency checkout. A bounded 115-second guest run with D3D12 enabled logged completion of both the opaque-black depth quad and the actual textured logo fade. Its software-reference pair used the same launch settings and time bound. Both runs reported 31 flips at about 0.33 guest FPS, and their final captured 640x480 BMPs had identical SHA-256 `AC9273FF3FCD34D083A05FD42CA3C09CD0B1AE66C5740FEFD0B3A2B6B08D134D`. Thus the narrow output matches byte-for-byte for this zero-alpha splash frame, but the matched run shows no measurable speed improvement. The final visible capture remains on CAPCOM; the D3D12 run emitted its watchdog diagnostic and the process was absent afterward.

No title-screen boot, audible audio, physical Steel Battalion controller response, save behavior, or campaign operation was verified. The D3D12 path still uses synchronous surface upload/readback and is not a performance-ready backend. Keep the software renderer as reference; the next renderer task is a GPU-resident/batched resource path that avoids per-draw synchronization, while boot diagnosis remains the Milestone 3 gate. All milestone and field progress bars remain unchanged. Captures/logs stay ignored under `iso/local-analysis/logs/`.

### Fresh bounded startup comparison (2026-10-18)

A 45-second hidden-window run used the newest existing `build-xpp-seeded\Release\your_game_recomp.exe`, with pushbuffer execution, asynchronous file I/O, diagnostic AC'97 readiness, and the virtual Steel Battalion XID profile. No build was run. The guest loaded and started both DSP programs, then executed the first bounded GP/EP slices. The captured report remained at one flip, one surface clear, zero draws, zero pixels, and 235 unhandled NV2A method instances across 147 IDs. The sampled guest logo timer and clock were zero; USER DMA PUT and GET both remained `0x495C`. This short run did not set the tracing, modeled vblank, and title-event switches used in the later matched captures, so it is not a controlled comparison with them. It does not establish a GPU deadlock. No title-screen, audio-output, controller-gameplay, or rendering-parity result follows. Progress bars and Milestone 3 remain unchanged.

Follow-up runs used the same existing executable with `RECOMP_TRACE_BUDGET=0`, pushbuffer execution, async I/O, diagnostic AC'97 readiness, modeled vblank/title events, and the virtual Steel Battalion XID profile. At 90 seconds the guest timer advanced through 0.4, 0.7, and 1.0, reset, and reached 0.75; the renderer reported 27 flips at about 0.44 guest FPS and OHCI served more than 2,200 input reports. At the 180-second bound, a captured framebuffer showed the Nude Maker splash. At 300 seconds, another captured framebuffer showed Dolby Digital; the renderer reported 117 flips at about 0.43 guest FPS, and USER DMA PUT/GET were equal at the final samples. The process was externally bounded each time and no runtime remains. The zero-timer 45-second snapshot was an early startup sample, while the matched longer run shows slow but continuing splash progression. This still does not reach the Steel Battalion title screen or verify native-window presentation, audible output, game-side controller response, or campaign play. Captures and logs remain ignored locally in `iso/local-analysis/logs/m3-matched-90s-20261018/`, `m3-matched-180s-20261018/`, and `m3-matched-300s-20261018/`. The remaining boot work is to understand and complete the logo-helper transition into the guest event loop without skipping original behavior; no progress bars advance.

### Guest splash helper exit analysis (2026-10-18)

Static review of the local-only XBE analysis and generated translation confirms that startup function `sub_000E0200` calls two `sub_000DFF40` logo helpers in order. Each helper draws while advancing the guest fade timer by 0.05 after a group of 11 draw-loop iterations, and its loop exits at the configured timer threshold. The caller proceeds to its event-dispatch path only after both helpers return. A prior five-minute watchdog sample placed the guest PC in the logo draw routine, with return address `0x000E0362`, immediately after the second helper call; that sample therefore had not yet returned to the event loop. This is consistent with the newer captures showing the Dolby splash after five minutes and about 0.43 guest FPS. The timing cost is a likely reason startup remains in the splash sequence, but it is not a verified fix or proof of the only cause. No input shortcut or guest behavior change was made, and the XBE-derived C remains local/ignored. Next verify the second helper's return and event-loop entry with a controlled longer run, or proceed with the approved GPU acceleration route when its license boundary is resolved. No progress bars advance.

### Bounded splash continuation after backend research (2026-10-18)

Continued the same five-minute hidden-window test using the existing Release x64 executable; no build was run. The virtual Steel Battalion USB profile remained neutral. At the 300-second external bound, the guest was still displaying Dolby Digital, with 111 flips and about 0.39 FPS in the final interval. The OHCI controller path had served more than 9,000 reports. The final captured 640x480 guest framebuffer also shows the Dolby splash. The process was stopped at the bound and no game process remained. This does not verify title boot, audible output, or game-side controller response. The slow splash remains consistent with the measured software-raster bottleneck; no guest behavior was changed. Logs and captures remain local/ignored in `iso/local-analysis/logs/m3-after-texobj-load-300s-20261018/`. Milestone 3 and progress bars remain unchanged. Next continue boot diagnosis and plan the batched D3D12 path; do not begin resolution or cosmetic changes until title-screen boot and accurate rendering are established.

### D3D12 renderer reuse audit (2026-10-18)

Read the current XboxXBERecomp D3D12 source and its API/license manifests without cloning it into the repository. Its renderer is a large native D3D12 backend driven through normalized XDK D3D8 state; it is not a raw NV2A PGRAPH packet consumer. It is MIT-licensed at the repository level and lists toml++, Dear ImGui, and SDL 3 in `THIRD_PARTY.txt`, but the renderer depends on that project’s app, window, diagnostics, and kernel APIs. Local XboxRecomp still has a distinct D3D8-to-D3D11 path; its `dev_BeginPush` and `dev_EndPush` return `E_NOTIMPL`. Steel Battalion startup is currently observed entering the independent low-level `nv2a_pb_exec` path. This makes the renderer a valuable state/resource-management reference, not a drop-in replacement for the observed pushbuffer path. No upstream code was copied and no local runtime source was changed.

The then-proposed D3D12 interface work is historical and superseded by Vulkan. Keep XboxRecomp's static-recompilation base and do not advance graphics enhancement work before title boot and rendering parity are achieved. Milestone 3 and progress bars remain unchanged.

### D3D12 splash-path bounded measurement (2026-10-18)

Ran the existing Release x64 executable for 120 seconds with the neutral Steel Battalion USB profile, the same pushbuffer/async-I/O/AC'97/vblank/title-event diagnostics as the matched splash runs, and `RECOMP_D3D12_RASTER=1`. No build was run. The D3D12 path initialized and completed the specific opaque-black, fullscreen depth-tested quad; all other draws continued through the CPU software rasterizer. By the external bound the guest still showed the CAPCOM splash, with 39 flips and about 0.43 FPS in the final sample, comparable to the prior software-only ~0.44 FPS matched run. This does not show a measurable performance gain. It confirms the current D3D12 implementation covers too narrow a state pattern to accelerate the actual splash sequence. The log also had no D3D8 `[D3D]` periodic Present counter lines while the raw pushbuffer flip count advanced, supporting that the observed rendering path is not currently being driven through the upstream-style high-level D3D8 backend. No title screen, audio output, or controller gameplay was verified. Process was externally stopped at 120 seconds and no game process remained. Logs/captures are ignored under `iso/local-analysis/logs/m3-d3d12-splash-120s-20261018/`. Next implement a textured/alpha NV2A draw path with preserved depth and exact CPU-reference comparison, then measure again; do not infer performance from device initialization or a single black pass.

### Symbolized boot watchdog sample (2026-10-18)

Ran the current Release x64 build for 35 seconds with D3D12 enabled and `RECOMP_WATCHDOG_NATIVE_PC=1`. The bounded watchdog exited with code 3 and no game process remained. Its symbolized host stack was `sub_00211E10` → `sub_0020E520` → `sub_000DFBC0` → `sub_000E0200`; the captured guest return address was `0x000DFE75`, inside the original logo helper. `sub_00211E10` contains a guest-side linked-list scan at `0x00211F10`. This sample places execution inside translated game code during logo drawing, rather than in a D3D12 wait/readback function. One stack sample does not show how much time this loop consumes or establish a fault in the translation.

Next quantify repeated samples or loop iterations around the guest `sub_00211E10` linked-list path while preserving the original code and splash timing. Do not patch generated XBE code or skip the logo sequence. Keep the software rasterizer as reference; broader GPU-resident batching remains deferred until boot-path timing identifies its contribution. Milestone 3 and all progress bars remain unchanged. Local trace output is ignored under `iso/local-analysis/logs/m3-watchdog-stack-35s-20261018/` and generated game code remains ignored under `iso/local-analysis/`.

A second 35-second watchdog run without native symbolization produced the same guest stack return address `0x000DFE75`, with the same saved caller frames through `0x0020E5C0` and `0x0021B790`. This independently confirms the splash helper call chain is still active at the sample time. A 20-second repeat with native symbolization did not finish its report: the process remained alive with the guest thread suspended and its log unchanged, so it was stopped. This exposes a hang risk in the optional DbgHelp symbolization path; do not use that option for further repeated sampling until the watchdog helper is bounded or fixed. The ordinary guest-stack watchdog completed normally with exit code 3. Neither run reached the title screen. Logs remain ignored in `iso/local-analysis/logs/m3-watchdog-guest-stack-35s-20261018/` and `m3-watchdog-stack-20s-20261018/`.

### Logo wait loop identified as an NV2A semaphore wait (2026-10-18)

Temporarily instrumented the ignored generated `sub_00211E10` translation to count loop iterations and sample the address it reads. Several calls looped on the unchanged dword at `0x80003000`, with scans reaching 580,000,001 and 596,534,849 iterations before the value advanced and the guest function returned. This is a polling wait, not a linked-list traversal. The generated XBE source was restored byte-for-byte from its local backup after the probe, and the clean Release target rebuilt successfully; no instrumentation or game-derived code was staged.

Then enabled the pushbuffer semaphore trace on the restored build. The executor resolved semaphore handle `0x8`, instance `0x11B0`, offset `0`, physical `0x3000`, guest VA `0x80003000`, and logged `BACK_END_WRITE_SEMAPHORE_RELEASE` values progressing from `5` through `0x17`. This is the producer of the exact word polled by `sub_00211E10`; the guest wait is tracking NV2A command completion. This rules out a missing kernel event as the immediate cause of the sampled wait. The executor does release the semaphore, but slow guest-visible progress remains consistent with the low software-renderer throughput and the narrow D3D12 coverage. It does not prove that rendering is the only limiting work.

Next measure and improve complete NV2A batch throughput while preserving semaphore ordering. The current D3D12 path still uploads and reads back the full surface synchronously; a GPU-resident path requires a coherence audit for CPU reads/writes, software fallbacks, and flips before changing that behavior. Keep the software path as reference; do not alter guest semaphore values or bypass the wait. Milestone 3 and every progress bar remain unchanged. Local captures/logs and the temporary generated-code backup stay ignored in `iso/local-analysis/`.

### Clean generated-code rebuild and splash continuation (2026-10-18)

A first bounded launch was discarded after its log unexpectedly contained `[XBE-LOOP]` instrumentation. Inspection showed the executable and `recomp_0015.obj` had been built before the generated C source was restored. The active CMake cache points to `iso/local-analysis/xboxrecomp-generated-xpp-traced/gen`, not the separate `xboxrecomp-generated/gen` directory. The configured `recomp_0015.c` was verified byte-identical to its pre-instrumentation backup (SHA-256 `2C9B70812633A82ABFC8C2EA2CC2D6B3FA400818385AF341EC73B93ED9BB7867`); its timestamp had allowed MSBuild to reuse the old object. Touching only this local generated source forced recompilation. The rebuilt object and executable have no `[XBE-LOOP]` strings. Generated code and build artifacts remain ignored and were not staged.

The rebuilt Release x64 executable then ran for about five minutes with pushbuffer execution, asynchronous I/O, modeled vblank/title events, diagnostic AC'97 readiness, and the virtual Steel Battalion USB profile. The clean log contains no loop-counter trace. At the last complete periodic reports it had reached 135 flips at approximately 0.41 guest FPS; NV2A DMA PUT and GET advanced together in sampled reports. The last report showed 268 draws, zero draws with valid coordinates, and 3,456 unhandled method instances. It did not reach the title screen. The run was stopped before its 600-second watchdog bound. No screenshot or title-timer trace was enabled, so the visible splash identity and fade-timer values are unverified for this run. The earlier traced-binary launch is invalid and must not be used as performance evidence. Next run a shorter bounded capture with `RECOMP_TITLE_TIMER_TRACE=1` and framebuffer dumps enabled, then compare the actual guest timer and screen across intervals. Milestone 3 and all progress bars remain unchanged.

The follow-up 120-second run used that rebuilt executable with `RECOMP_TITLE_TIMER_TRACE=1` and periodic framebuffer dumps. It exited at the configured watchdog with code 3 and left no game process. Reports showed 33 flips at 0.40 guest FPS and timer samples `0.4`, `1.0`, then `0.45` (thresholds `1/0`, step `0.05`). The last sample is consistent with the second logo helper having begun after the first reached its threshold; the timer continued advancing. The final local framebuffer capture still showed the CAPCOM logo. The title screen remains unverified. This confirms a slow but progressing splash sequence rather than a fixed timer or missing semaphore release. Logs and captures are ignored in `iso/local-analysis/logs/m3-title-timer-120s-20261018/`. Do not skip or accelerate the guest's logo behavior; next progress depends on a faster, correct NV2A backend and the user's approval of the proposed Vulkan architecture. No progress bars advance.

### Final graphics backend lock (2026-10-18)

The user's direction is explicit: stop switching among graphics APIs and choose one. **Vulkan is the sole production backend**, for NV2A pushbuffer rendering and graphics compatibility. No D3D11 or D3D12 alternative renderer or runtime backend selection will be added. Older D3D11/D3D12 entries in this chronological log describe superseded experiments, not current plans. The next renderer work proceeds on the Vulkan adapter path while preserving static recompilation; the software rasterizer remains a local comparison aid only. Milestone 3 remains incomplete, with the clean boot reaching only the CAPCOM splash. No milestone or field progress bars advance.

### Vulkan-only framebuffer adapter patch (2026-10-18)

Added the downstream patch `patches/xboxrecomp-v0.13.1-vulkan-fb-present.patch`. It adds a project-local Vulkan loader/declaration dependency and an opt-in Win32 window that uploads the completed guest framebuffer to a Vulkan swapchain. It is a host presentation adapter only: it does not implement NV2A scene rendering, shader translation, accurate display output, or title-screen boot. The patch applies cleanly in a reverse/check/reapply validation against the local XboxRecomp checkout, and the Release x64 game target builds successfully with it.

The earlier bounded smoke log confirmed Vulkan loader/device setup and creation of a 640x480, three-image swapchain. A subsequent bounded run with the documented startup switches selected the NVIDIA GeForce RTX 4070 SUPER and logged a successful first swapchain present. The process was stopped after that check; no game process remains. This verifies Vulkan host presentation plumbing, not that the presented startup image contains correct game graphics or that any NV2A scene has rendered. Title-screen boot and visual correctness remain unverified. The separate host-presentation bar advances to 3/3; full Vulkan/NV2A scene rendering remains 0/3. Logs remain local/ignored under `iso/local-analysis/logs/m3-vulkan-presenter-confirm-20261018/`. Keep Vulkan as the one production graphics API; Xbox D3D8 calls are compatibility inputs to that renderer, not an alternate host backend.

### D3D12 NV2A prototype disabled (2026-10-18)

The user directed that graphics API selection stop changing. The Vulkan choice remains fixed. The local D3D12 NV2A prototype is now behind `XBOXRECOMP_EXPERIMENTAL_D3D12`, which the project does not define; the Windows build therefore compiles the no-op stubs. The kernel target no longer links `d3d12`, `dxgi`, or `d3dcompiler`. The Release x64 game target rebuilt successfully after this change. The new patch passed a temporary application check against the pre-disable source copies; its C source matched the current file exactly, and its CMake result matched after normalizing line endings. The D3D8 compatibility shim backed by D3D11 remains in the upstream runtime for Xbox D3D8 API calls; it is not an NV2A backend selection. Vulkan still only presents the guest framebuffer, and full NV2A GPU rendering/title boot remain unverified. The implementation patch is `patches/xboxrecomp-v0.13.1-disable-d3d12-experiment.patch`; older D3D12 experiment patches are historical and must not be applied without this disabling patch.

### Bounded splash recheck after backend lock (2026-10-18)

Ran the existing ignored Release x64 executable with the same pushbuffer, asynchronous file-I/O, diagnostic AC'97 readiness, modeled vblank/title events, and virtual Steel Battalion XID profile used in the matched splash captures. This was a pre-Vulkan diagnostic build; it does not exercise or verify Vulkan. After about 194 seconds, 14 local framebuffer captures showed the splash advancing from CAPCOM to Nude Maker. The last GPU report showed about 0.44 guest FPS, 75 flips, 148 draw batches with zero valid coordinates, 155 unhandled NV2A method IDs (2,016 method instances), and equal DMA PUT/GET at `0x1E780`. The guest was still on Nude Maker, not the Steel Battalion title. The run was stopped early because the process consumed about 952 CPU-seconds by the last sample; no process remains. Logs and captures remain ignored under `iso/local-analysis/logs/m3-vulkan-lock-boot-check-600s-20261018/`. This confirms splash progression only; no title boot, Vulkan rendering, audible output, physical-controller response, save/load, or gameplay was verified. Milestone 3 and every progress bar remain unchanged. Continue with the Vulkan-only NV2A renderer path; do not switch to D3D11/D3D12 or treat this software-renderer run as Vulkan evidence.

### Vulkan presenter aspect preservation (2026-10-18)

The presenter previously stretched the guest framebuffer to fill the swapchain. Added patches/xboxrecomp-v0.13.1-vulkan-aspect-fit.patch: it computes a centered fit rectangle from guest and swapchain dimensions, clears unused swapchain space to black, and adds a transfer-write barrier between the clear and blit. It does not modify guest pixels, simulation timing, or NV2A command handling. Patch application against a reconstructed copy of the original presenter source succeeded; resulting source lines matched the active source after line-ending normalization.

The Windows x64 Release target rebuilt successfully. A bounded launch selected the RTX 4070 SUPER, created the existing 640x480 Vulkan swapchain, and presented the first image successfully. The process was stopped after confirmation, and no game process remains. This confirms no regression in ordinary Vulkan presentation, but the test window remained 640x480, so widescreen letterboxing and visual output have not been runtime-verified. The run still reached an untranslated wbinvd no-op before presenting. No NV2A scene rendering or title-screen boot was verified; all progress bars and Milestone 3 status remain unchanged. Logs are ignored under iso/local-analysis/logs/m3-vulkan-aspect-fit-final-20261018/.

### xemu shader-generator license boundary clarified (2026-10-18)

A pinned-source review found that xemu's Vulkan PGRAPH target is not solely an LGPL renderer path. The Vulkan shader cache generates vertex and pixel GLSL on cache misses; the called vertex-program generator and pixel/register-combiner generator carry GPL-2-or-3 notices and identify Cxbx/Dxbx/Xeon as prior sources. The Vulkan compiler wrapper also directly invokes glslang preprocessing, parsing, linking, and SPIR-V generation. These are required runtime paths in xemu's design, not unused files. See docs/VULKAN_REUSE_AUDIT.md for pinned source links and file-level findings.

Consequently, do not copy the complete xemu Vulkan renderer and describe it as LGPL-only. Before reuse, either clear a compatible project-wide/dependency license path, or replace the GPL shader-generation components with independently authored code and complete the remaining glslang/QEMU include audit. The existing project-owned CPU VSH and combiner implementations cite xemu behavior as reference; their provenance also needs review before distribution. No xemu code was copied or new runtime code added in this research update. The Vulkan backend remains locked, and no progress bars or Milestone 3 status change.

### First narrow NV2A draw submitted through Vulkan (2026-10-18)

Added `patches/xboxrecomp-v0.13.1-vulkan-textured-logo-slice.patch`. At the existing `raster_batch_program()` boundary, the exact observed 640x480 DXT1 fullscreen splash-logo state is expanded to a triangle list, decoded to a project-owned RGBA texture, and submitted to a project-owned Vulkan graphics pipeline. The preceding exact opaque-black/depth quad is reproduced with a CPU rectangle/depth fill. The Vulkan path reads its result back into the guest surface so later legacy CPU draws observe the same memory; unsupported states still use the CPU reference. Removed the D3D12 raster branches from the active pushbuffer executor. Vulkan remains the only host GPU direction.

DXC 1.9.2609 compiled the project-owned HLSL to SPIR-V embedded as C arrays; the DXC tool and intermediate binaries are local only. The Release x64 target built successfully through the installed Visual Studio Build Tools. A bounded seeded startup run selected the RTX 4070 SUPER, created the Vulkan presenter and guest pipeline without the pipeline-unavailable fallback, presented a frame, and logged `[Vulkan] textured logo fade completed at 640x480`. The guest advanced to three flips and then stayed at DMA PUT/GET `0x54A8` with a stalled title clock while consuming CPU; that exact test process was stopped. Its log is ignored at `iso/local-analysis/logs/m3-vulkan-textured-logo-seeded-120s-20261018/`.

The run proves that the narrow Vulkan submission path executes, not that its pixels match the CPU renderer. No framebuffer capture was taken; logo orientation/color parity, later draw ordering, performance improvement, title-screen boot, audio, controller response, or campaign play remain unverified. Keep all progress bars and Milestone 3 status unchanged. Next compare a captured Vulkan frame against the existing CPU reference and capture a guest stack at the `0x54A8` stall before expanding this path to other draws.

### Vulkan splash pixel match and modeled startup timing (2026-10-18)

Reused the existing Release x64 executable; no build was needed. The test explicitly enabled the opt-in modeled vblank (`RECOMP_VBLANK=1`) and title-built event bridge (`RECOMP_TITLE_KEVENTS=1`), which the earlier three-flip Vulkan run had omitted. The event at `0x0021DCE4` reached signal state 1 and the guest device/query value at `0x351F5C`/`0x355730` advanced. This shows the prior logo wait can progress with these diagnostics; it does not establish that those diagnostic shortcuts are safe defaults or faithfully model hardware timing.

Captured every flip to ignored local BMPs under `iso/local-analysis/logs/m3-vulkan-vblank-event-frames-30s-20261018/`. Exact full-file SHA-256 matches prove pixel equality at two nonblack fade states: Vulkan `frame_00003.bmp` matches CPU-reference `frame_00005.bmp` (`8D9944BEA318126E177D0CAE585D0344F4852033BD9D5F58DC65D21451D8A64D`), and Vulkan `frame_00004.bmp` matches CPU-reference `frame_00007.bmp` (`618E1445D61B94C43FEE56F8CCEE81A8840285ECA837C2DE455EBEB39C384B1A`). This verifies the single recognized splash draw at those sampled fade states, not general NV2A rendering or performance.

The 30-second watchdog later sampled the guest in its queue-fence wait at `0x80003000`: completed `0x15`, submitted `0x21`, 12 outstanding against a threshold of 8; NV2A USER PUT was `0x648C` and GET was `0x54A8`. Prior logs show this cursor can advance later, so this is a bounded lag sample. The test exited at its watchdog, and no game process remains. The title screen, audio, physical controller, and campaign remain unverified. Milestone 3 and progress bars remain unchanged. Vulkan remains the sole graphics backend.

### Vulkan splash progression to 13 flips (2026-10-18)

Repeated the capture with a 60-second watchdog and the same opt-in vblank/event configuration. NV2A GET advanced from the earlier `0x54A8` snapshot to `0x9ED0`, the guest produced 13 flips, and the logo fade timer reached `0.65` before the watchdog. At that sample the guest queue fence had completed `0x49` of submitted `0x55` (12 outstanding; threshold 8), with USER PUT=`0xA968`, GET=`0x9ED0`. This shows continuing progress while queued, not a permanent DMA deadlock; the title screen was not reached.

All six nonblack Vulkan frames in the captured fade segment exactly matched CPU-reference frames by full-file SHA-256: Vulkan frames `00003`–`00008` correspond to CPU-reference frames `00005`, `00007`, `00009`, `00011`, `00013`, and `00015`. The first pair hash is `8D9944BEA318126E177D0CAE585D0344F4852033BD9D5F58DC65D21451D8A64D`; the last pair hash is `AC9273FF3FCD34D083A05FD42CA3C09CD0B1AE66C5740FEFD0B3A2B6B08D134D`. Captures are ignored/local under `iso/local-analysis/logs/m3-vulkan-vblank-event-frames-60s-20261018/`; no game image was added to Git. The watchdog ended the exact test process, which exited with code 3; no game process remains. Milestone 3 remains active and player-facing graphics/progression bars remain unchanged; the narrow splash pixel-parity diagnostic remains 1/1.

### Vulkan splash sequence to 41 flips (2026-10-18)

Continued with the same existing Release x64 binary and opt-in vblank/event configuration for a 120-second watchdog bound. The per-flip capture contains 41 640×480 frames; the last visible frame (`frame_00040.bmp`) shows a dim CAPCOM splash. This verifies further rendering and startup progression only; it is not the Steel Battalion title screen.

At the watchdog, the guest was again in its queue fence on `0x80003000`: completed `0xAB`, submitted `0xB7`, 12 outstanding against an 8-entry threshold. NV2A USER PUT=`0x128A0`, GET=`0x11E08`; GET had advanced from `0x9ED0` at 60 seconds, but the queue had not fully caught up at 120 seconds. The sampled guest device query continued to advance (`0x351F5C`/`0x355730`=`0x1103`). The process exited at watchdog code 3; no game process remains. No build was run. Milestone 3 and player-facing feature bars remain unchanged; the diagnostic splash parity bar remains 1/1.

### Trace-free Vulkan startup capture (2026-10-18)

A source audit found the test executable used generated C with `RECOMP_TRACE_ENTER`/`EXIT`/`ESP` calls. Those hooks printed up to 400,000 lines and add overhead, so traced-run timings are not clean performance measurements. Created an ignored local overlay of the current generated code with those trace macros compiled to no-ops, preserving the newer dispatch entry for `0x0025D059`. Rebuilt the Release x64 executable successfully; a scan of generated object files found no references to the trace hooks.

With the Vulkan presenter, per-flip local capture, diagnostic vblank/title-event modeling, async I/O, diagnostic AC'97 readiness, and virtual Steel Battalion USB profile enabled, a 180-second bounded run completed its watchdog. Vulkan selected the RTX 4070 SUPER, initialized the 640x480 swapchain, presented its first image, and submitted the textured logo draw. It reached 51 flips; frame captures show the CAPCOM logo fading to black. The guest queue wait was at `0x80003000`: completed `0xD9`, submitted `0xE5`, 12 outstanding against threshold 8; DMA PUT=`0x162FC`, GET=`0x15318`. This trace-free run removes guest function-trace overhead but still uses the incomplete CPU reference renderer for unsupported guest draws. It did not reach the Steel Battalion title screen. Captures/generated code remain ignored under `iso/local-analysis/`; no title-derived material was staged. The prior traced executable is preserved locally for comparison.

No compatibility or progress bar advances: title-screen boot, gameplay, audio, physical controller response, and campaign remain unverified. Next profile pushbuffer segment processing and identify why queue completion lags the guest reuse threshold while preserving semaphore ordering.

### Vulkan draw-path timing investigation (2026-10-18)

Added temporary, opt-in local timing around pushbuffer segments, NV2A method handlers, and draw batches. A corrected 30-second watchdog run selected the RTX 4070 SUPER, initialized the 640×480 Vulkan swapchain, and presented the first image. It produced three local 640×480 captures and exited at watchdog code 3; the Steel Battalion title screen was not reached. At the watchdog, USER DMA PUT was `0x5F40` and GET was `0x54A8`, so the guest had submitted more work than the compatibility worker had completed.

The slow segment `0x4F5C–0x54A8` took 2.453 seconds. Its four `SET_BEGIN_END` calls accounted for 2.340 seconds. Draw-level timing separated that work: two four-vertex textured batches fell through to the CPU reference rasterizer and took 1.137 and 1.165 seconds; the narrowly matched Vulkan logo batch took 37 ms, and the opaque-black depth quad took 9 ms. This is direct evidence that the remaining generic CPU draw fallback is the dominant bottleneck in this startup sample. It does not establish stable frame rate, general Vulkan rendering correctness, or title-screen compatibility. The timing code, executable, captures, and logs remain local and ignored; no game-derived material is tracked.

An earlier exploratory timing edit accidentally left an extra executor call and therefore executed packets twice. That run was discarded. The duplicate was removed before the corrected build; source inspection confirms the executor call occurs once on either instrumentation branch. The corrected build succeeded, and its watchdog run produced the measurements above. No progress bars advance. Continue on the fixed Vulkan backend by expanding accurate Vulkan coverage for the measured textured draw state, retaining the software reference path for unsupported states until parity is verified.
#### Latest bounded Vulkan input probe (90 seconds)
- `RECOMP_PAD_SCRIPT=5000:a:500` with the Steel Battalion USB profile logged `PAD: t=5000 ms step 0 (digital 0x00 analog 0x01)`. OHCI continued serving periodic reports after the press (final snapshot: 1,180 setup reports and 118 output reports). This verifies that the scheduled synthetic A value reached the USB report-generation path and was serviced by the virtual device. It does not verify that the game accepted or acted on the mapped XID bit: the captured screen remained on the Nude Maker logo. At the 90-second watchdog, NV2A USER `PUT=GET=0x6BFE8`, guest `EDI=0x00261918`, and transfers were no longer being queued.
- Logs and captures are ignored under `iso/local-analysis/logs/m3-vulkan-pad-script-early-a-90s-20261018/`. No runtime process remains. Vulkan remains the sole host renderer.


#### Startup file-helper investigation
- Rebuilt and ran a 120-second Vulkan launch with the known opt-in pushbuffer, async-I/O, modeled-vblank, title-event, AC'97, and Steel Battalion USB settings. It ended at the 90-second-known guest stack (ESP=0x00F7FE18, EDI=0x00261918), with 193,352 indirect calls and NV2A USER PUT=GET=0x60108; the final OHCI snapshot recorded 1,558 periodic transfers. It did not reach the title prompt.
- A temporary RECOMP_NT_CREATE_TRACE hook recorded 111 NtCreateFile requests, including the expected music streams and first-launch save probes. No ri26nml.bmf path appeared in this NtCreateFile trace before the watchdog. This does not rule out other file APIs or diagnose the guest wait. The trace hook was removed after the run.
- A separate 200-second live-input-file run with no input appended also ended at the same stack. Its last image remained black and USB periodic transfers stopped being queued. No prompt was present, so no input was sent.
- The normal Release x64 target rebuilt successfully after removing the temporary trace; no game process remains. Input, audio, and general compatibility remain unverified; progress bars are unchanged. Next: add a bounded guest-side PC/call-site probe around the stuck file-helper frame before proposing a compatibility change.

### USB XID request sequence during startup (2026-10-18)

A separate 120-second Vulkan run enabled OHCI request tracing with the Steel Battalion profile. The guest fetched the device descriptor, the 32-byte configuration descriptor, then issued `C1 06` / `wValue=0x4200` for the 16-byte XID descriptor and `A1 01` / `wValue=0x0100` for a 26-byte input report. The runtime returned all requested bytes. The control trace recorded no USB stalls and no `GET_CAPABILITIES` request. OHCI then completed 464 periodic transfers before the watchdog (370 input reports, 94 other endpoint transfers, 6 setup packets).

The captured framebuffer remained on the Nude Maker logo; watchdog state was guest `EDI=0x00261918`, 186,851 indirect calls, and NV2A USER `PUT=GET=0x5CC10`. This reproduces the early font-loading stall and does not establish controller response at the title screen. The descriptor values and report layout align with the [documented Steel Battalion XID descriptor and report table](https://xboxdevwiki.net/Xbox_Input_Devices). The locally captured request/response sequence is stronger evidence of guest-side enumeration than periodic packet counts alone. Logs and screenshots remain ignored/local under `iso/local-analysis/logs/m3-xid-control-trace-120s-20261018/`; no bars advance, and Milestone 3 remains active.
### Vulkan renderer lock and startup file-helper trace (2026-10-18)

Vulkan remains the one and only selected host renderer. The latest bounded 120-second run selected the RTX 4070 SUPER, initialized the Vulkan swapchain/presenter, and its final 640×480 framebuffer showed the Steel Battalion title screen with the faint “PRESS MAIN WEAPON BUTTON” prompt. A temporary guest file-helper trace captured four startup open-helper calls for guest path pointers `0x00261918`, `0x002618FC`, `0x002618E0`, and `0x002618C4`; each returned `0x4800007B`, a positive handle-like value. This rules out those four observed calls immediately failing, but does not identify every path or explain earlier runs that stopped at the Nude Maker logo. The guest remained running until the 120-second watchdog; the snapshot showed NV2A `PUT=GET=0x651E4`. No input was sent during this run, so controller response, audio, title progression, and gameplay remain unverified.

Removed all temporary file-helper trace code from the active generated C source and rebuilt the normal Release x64 `your_game_recomp` target successfully. Confirmed the executable has no trace-marker strings. Generated code and captures remain local/ignored. Milestone 3 and all progress bars remain unchanged. Keep Vulkan fixed; do not reopen the D3D11/D3D12/Vulkan choice absent an explicit user request.

### Steel Battalion input mapping cross-check (2026-10-18)

Cross-checked the title probe against the public [Xbox Input Devices reference](https://xboxdevwiki.net/Xbox_Input_Devices#Controller_to_Xbox): the 26-byte Steel Battalion report defines `RightJoyMainWeapon` at byte 2, mask `0x01`. The prior live probe delivered that exact bit in the press/release report, but the title framebuffer stayed unchanged. The report field and host-side A mapping therefore agree with the published table; game-side consumption is still unverified. Next inspect whether the title consumes XID input from control `GET_REPORT` or interrupt-IN transfers, and trace the guest's response path before changing the bit mapping.

The current XInput fallback is partial by design and is not complete controller support. It maps A/B/X to three right-joystick buttons, maps the two gamepad sticks to only some axes, and leaves the remaining switches, buttons, pedals, tuner, and `SightChangeY` unassigned. The original controller and its indicators have not been tested on physical hardware. Do not claim full Steel Battalion controller support or commit the speculative XInput mapping until guest response is verified.

### Interrupt-IN report delivery trace (2026-10-18)

Added a temporary local-only `RECOMP_USB_REPORT_TRACE` hook at the OHCI interrupt-IN write point and rebuilt the Release x64 target. The trace confirmed that a full 26-byte neutral Steel Battalion report was copied into the guest DMA buffer (`0x010816C3`) on endpoint 2. The 150-second run stopped at the Nude Maker splash. A longer run progressed through Dolby Digital, then stopped producing new framebuffer captures; its final OHCI sample counted 8,182 periodic transfers (8,120 reports). The configured watchdog produced no timeout report, so the isolated process was stopped manually. No title prompt appeared and no button was sent. This verifies host-to-guest DMA-buffer delivery of neutral reports during periodic polling, not game-side recognition or response.

Restored `ohci.c` byte-for-byte to SHA-256 `21E55855E52C34CBAB1755B72981324CC51D31C62BDA8B2B0F513327369ED3A7`, removed the temporary trace, and rebuilt the ordinary Release x64 target successfully. Captures and logs remain local/ignored under `iso/local-analysis/logs/m3-title-interrupt-report-trace-{150s,240s}-20261018/`. Milestone 3 and progress bars remain unchanged. Next obtain a title-screen run without the startup stall, then send a press while tracing the same DMA delivery path; investigate why this diagnostic run stops before the title without attributing the stall to USB.

### 2026-10-18 Title prompt live-input comparison and clean rebuild

The 300-second title prompt probe emitted a synthetic A press and release while the Steel Battalion XID interrupt-IN report path was active. The reports were copied to guest VA `0x010816C3` as 26-byte packets with byte 2 toggling `0x01` for the press. Captures `frame.bmp00023.bmp` and `frame.bmp00026.bmp` have identical SHA-256 `2E58A28276D9EB28B63D57C7A2D878EB491ACEA6E35F208B2DB74D62845BF086`; the watchdog ended the run at 300 seconds. This confirms report-buffer delivery and no visible title-screen change in those samples; game-side input response remains unverified.

A stale instrumented USB object was found because the restored `ohci.c` file had an earlier timestamp than its object file. Touched the restored source and rebuilt the Release x64 `your_game_recomp` target. Verified the source remains at SHA-256 `21E55855E52C34CBAB1755B72981324CC51D31C62BDA8B2B0F513327369ED3A7` and both temporary trace markers are absent from the rebuilt executable. No game process remains. No progress bars advance; Milestone 3 remains active. Next: investigate guest-side controller report consumption and title-screen response before treating any mapping as validated.

### Guest-side XInput state probe (2026-10-18)

Static inspection identified the guest poll/conversion path: `sub_00049970` enumerates connected input devices, requests device capability data through `sub_00256F26`, and invokes `sub_00257103` to copy the device state into an XInput-style result. Added a temporary diagnostic immediately after this conversion, then ran two bounded probes with the Steel Battalion USB profile: a 5-second A pulse over 90 seconds and a 5-second A start with a 145-second hold over 180 seconds. OHCI periodic reports continued (the hold run reached 5,378 reports), but the guest-state trace never logged nonzero button/trigger fields. The sustained run remained in startup file reads and ended at the watchdog snapshot `ESP=0x00F7FED4`; it did not reach the title prompt. This narrows the next investigation to whether the guest poll/conversion path is entered during startup and whether its result object is the controller path the game consumes. It does not prove that USB input is rejected or that the report mapping is wrong.

Restored generated source byte-for-byte (SHA-256 `B67252979427C1CB1C6E3CB27D82FE2311B4B36DF8AD59A30E66F299CFC7BA94`) and rebuilt the ordinary Release x64 target successfully. Verified the rebuilt executable contains none of the guest-input or USB-report trace markers, and no game process remains. The first 300-second late-input probe did not progress to its scheduled pulse and was stopped at its bound when its watchdog did not fire. Logs/captures remain ignored under `iso/local-analysis/logs/`. Progress bars and Milestone 3 remain unchanged.

### Guest poll entry and live title-time pulse (2026-10-18)

Improved the temporary local trace to log entry into guest `sub_00049970` and nonzero XInput button/trigger results after `sub_00257103`. Static caller search found call sites in `sub_0004A960` and `sub_0004AA80`. In a 320-second run with no synthetic input at startup, an external live `a:500` pulse was appended at USB time 235,141 ms. The guest poll trace logged its first invocation but no 6,000-call checkpoint and no nonzero XInput result. OHCI continued periodic USB transfers, while the guest continued loading files including `TEXOBJ.BIN` and `TEXMOVIE.BIN`; the watchdog ended at ESP `0x00F7FEEC`, with NV2A USER PUT=GET=`0x3B354`. This run contains no title-screen or gameplay verification. The trace establishes that the poll routine is entered, but does not determine whether the live button was consumed by the game; the title/input phase was not verified.

Restored the generated source byte-for-byte (SHA-256 `B67252979427C1CB1C6E3CB27D82FE2311B4B36DF8AD59A30E66F299CFC7BA94`) and rebuilt the ordinary Release x64 target successfully. Confirmed the executable contains neither temporary `GUEST_INPUT_POLL` nor `GUEST_XINPUT` markers, and no runtime process remains. No feature bars advance; Milestone 3 remains active. Next: resolve the startup asset-loading wait and capture the poll routine's full call frequency and state once the title input loop is active.

### Guest input gate from static XPP path inspection (2026-10-18)

A follow-up read of generated guest code clarifies the controller path. `sub_00049DD0` clears global `0x351CB0`, calls `sub_00256BDE` to enumerate devices, iterates four device slots, and for each live handle calls `sub_00257103` to obtain state. The helper sets `0x351CB0` when a slot is recognized. Its callers `sub_0004A960` and `sub_0004AA80` call `sub_00049970` only when that global is nonzero. This is a conditional guest XInput-style path, separate from OHCI DMA delivery. The 320-second trace logged the first `sub_00049970` invocation but no 6,000-call checkpoint; it did not record the device mask, and the button-state log stayed silent. Thus the remaining unknown is whether device enumeration leaves the game-side gate active during the title prompt. Do not change controller mapping based on the report trace alone.

### Device gate verified; intermittent polling cutoff (2026-10-18)

The refined guest trace logged `[GUEST_INPUT_POLL] calls=1 active=00000001`. Since `sub_0004A960`/`sub_0004AA80` call `sub_00049970` only when `0x351CB0` is nonzero, this proves device discovery passed the guest gate at least once. No 100-call checkpoint or nonzero XInput result appeared before the run stalled.

The late-input run was not a valid mapping test: OHCI stopped recording periodic work at 8,304 transfers (about 207 seconds of report time), while the live `a:500` line was appended later at process time 287 seconds. The file remained unread by the live-input path; the process log stopped updating around 20:20, and the configured 340-second watchdog did not fire. By comparison, the earlier title-prompt run continued past 10,800 transfers, delivered A at report time 262,110 ms, and its before/after title captures were identical. This separates an intermittent startup/polling cutoff from game-level button acceptance; neither the late pulse in this run nor the XInput state was verified.

Stopped the exact test process after its bound, restored generated source byte-for-byte (SHA-256 `B67252979427C1CB1C6E3CB27D82FE2311B4B36DF8AD59A30E66F299CFC7BA94`), and rebuilt the ordinary Release x64 target successfully. Confirmed the executable contains no temporary guest-trace markers and no game process remains. Progress bars and Milestone 3 remain unchanged. Next: trace the guest event/wait path where OHCI stops receiving periodic transfers, then repeat the title-time pulse only after polling stays active through the prompt.

### OHCI worker cutoff follow-up (2026-10-18)

Added a temporary opt-in worker heartbeat and ran the Release x64 target with the existing 240-second watchdog and OHCI transfer stats. The heartbeat's frame counter advanced from `0x195C` to `0xA68C`, and the virtual device's input-report count rose from 582 to 9,006. Periodic transfers passed the earlier run's apparent cutoff near 8,304 and continued through the 240-second watchdog report. The OHCI worker therefore remained active in this reproduction; the earlier stopped log does not establish that the worker stopped.

The XID endpoint descriptor was empty (`head == tail`) in some five-second snapshots, including snapshots while report counts continued to rise. That can be a transient between guest re-arming requests and is not evidence that input polling permanently ceased. This run did not inject a button or verify a game response. The watchdog reported the guest at ESP `0x00F7FEEC`; the runtime exited afterward. Restored the temporary OHCI source instrumentation and rebuilt Release x64 successfully; confirmed no heartbeat marker remains in the executable and no game process remains. No feature bar advances; Milestone 3 remains active. Next: compare the guest's periodic-endpoint re-arm and interrupt completion path across the earlier log-stall and this worker-live run.
