# Development status

This page is for people who want the detailed engineering tracker. The project is experimental and has **not** reached a playable title screen. Progress bars describe tracked work; they do not mean that a game feature is playable.

For the plain-language overview, see the [README](../README.md) or the [player guide](PLAYER_GUIDE.md).
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
Direct3D/NV2A: full scene rendering              [--------------------] 0 / 3 (0%)
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
