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
Function translation output emitted              [####################] 9,148 / 9,148 (100%)
Unsupported instruction sites resolved           [--------------------] 0 / 243 (0%)
Unresolved call targets implemented              [--------------------] 0 / 351 (0%)
Generated Windows executable builds              [####################] 1 / 1 (100%)
Verified title-screen startup                    [--------------------] 0 / 1 (0%)
```

The ordinal bar records names mapped to the kernel import table, not implementations verified against live game behavior. The build bar records a local executable build only. Startup still fails before a verified title screen; the 9,148 emitted functions do not imply complete or correct decompilation.

```text
Static recompilation: functions emitted       [####################] 9,148 / 9,148 (100%)
Static recompilation: unsupported ops resolved [--------------------] 0 / 243 (0%)
Static recompilation: unresolved calls resolved [--------------------] 0 / 351 (0%)
Windows target: build completes locally         [#-------------------] 1 / 1 (100%)
Xbox runtime: guest entry and asset read         [##------------------] 2 / 4 (50%)
Xbox runtime: title screen and gameplay frame    [--------------------] 0 / 2 (0%)
Xbox kernel and synchronization                  [--------------------] 0 / 3 (0%)
Filesystem and ISO validation                    [--------------------] 0 / 3 (0%)
Direct3D/NV2A: full scene rendering              [--------------------] 0 / 3 (0%)
Audio: DSP processing and audible output         [--------------------] 0 / 2 (0%)

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

For example, “guest entry and asset read” records two observed startup checkpoints, while “title screen and gameplay frame” remains at zero. The DSP doorbell acknowledgment is diagnostic only, so it does not count as DSP processing or audible output. Diagnostic logging and local project documentation exist, but deterministic replay, a clean playable package, and completed license review do not. Counts will move only when the corresponding outcome is verified. These detailed bars supplement the milestone and top-level field bars above; they do not change the milestone gate or imply campaign compatibility.

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
Translation: emitted functions                            [####################] 9,148 / 9,148 (100%)
Translation: unsupported instruction sites resolved        [--------------------] 0 / 243 (0%)
Translation: unresolved call targets implemented           [--------------------] 0 / 351 (0%)
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
Audio: upstream xemu GP/EP behavior mapped                   [#-------------------] 1 / 1 research (100%)
Audio: DSP56300 C FFI capabilities and gaps reviewed          [#-------------------] 1 / 1 research (100%)
Audio: existing xemu Rust-JIT adapter audited                 [#-------------------] 1 / 1 research (100%)
Audio: MIT FFI / project-owned bridge selected                 [#-------------------] 1 / 1 architecture (100%)
Audio: Windows DSP FFI dependency licenses inventoried         [#-------------------] 1 / 1 research (100%)
Audio: GP/EP DSP MMIO windows routed                        [--------------------] 0 / 1 (0%)
Audio: GP/EP X/Y/P memory mapped                             [--------------------] 0 / 1 (0%)
Audio: game DSP firmware loaded and started                  [--------------------] 0 / 1 (0%)
Audio: DSP56300 GP/EP execution integrated                  [--------------------] 0 / 1 (0%)
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
Functions emitted                                      [####################] 9,148 / 9,148 (100%)
Unsupported instruction sites resolved                 [--------------------] 0 / 243 (0%)
Unresolved call targets implemented                    [--------------------] 0 / 351 (0%)
Windows executable builds locally                      [#-------------------] 1 / 1 (100%)
Title-screen boot verified                             [--------------------] 0 / 1 (0%)

BOOT AND RUNTIME COMPATIBILITY
Guest startup progression                              [#-------------------] 1 / 3 (33%)
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
GP/EP guest firmware loading and execution             [--------------------] 0 / 1 (0%)
DSP cycle, interrupt, FIFO, and DMA behavior           [--------------------] 0 / 1 (0%)
DSP processing and audible game sound                  [--------------------] 0 / 2 (0%)
Basic in-game input                                    [--------------------] 0 / 1 (0%)

The optional C harness for GP/EP memory boundaries, engine initialization, reset, and destruction compiled, linked, and passed in an isolated verification worktree. This verifies only the C FFI mapping/lifecycle scaffold; GP/EP MMIO, firmware, cycles, interrupts, DMA, DSP output, and game audio remain unimplemented or unverified.

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
Function output generated                         [####################] 9,148 / 9,148 (100%)
Unsupported instruction sites handled             [--------------------] 0 / 243 (0%)
Unresolved call targets implemented               [--------------------] 0 / 351 (0%)
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
| Game startup | In progress; normal startup fails during audio setup. Experimental audio and async-I/O diagnostics load three title assets and issue GPU draws, but the image is unverified and no title screen has been reached. |
| Playable release and launcher | Not available. |
| Full campaign compatibility | Not verified. No mission-completion or campaign-progression testing has been completed. |

**The latest verified state is not a playable game.** The title screen, graphics, sound, controller input, saves, cinematics, mission completion, and campaign progression remain unverified. We will report compatibility only after the complete campaign has been tested mission by mission.

### Prior bounded startup and DSP mapping check (2026-10-17)

The optional DSP56300 bridge aliases the GP/EP DSP memory descriptors to the ordinary guest RAM windows. A focused synthetic test passed for those aliases and their boundaries. With the pushbuffer executor enabled, the guest semaphore advances and both GP and EP reset-release transitions are visible. The next guest wait posts DSP commands at 0x803B8810; real firmware bootstrap and DSP cycles remain absent. The diagnostic fake ACK can advance file and GPU work but does not calculate DSP output. No recognizable Steel Battalion title screen, audio, controller, save, or campaign behavior is verified. The bounded process exited, and a subsequent check found no project game/emulator process active. At that checkpoint, the timer/event wait release and real DSP bootstrap remained unresolved. The later opt-in event/GPU check below verifies only the diagnostic wait release; real DSP firmware/cycles remain absent. Milestone 3 remains active.

### Latest opt-in event and GPU executor check (2026-10-17)

The title-built event wait returned success and advanced its guest signal/counter state under the opt-in event bridge. A separate 45-second watchdog-bounded run continued consuming NV2A commands through GET `0x9ED0` while PUT reached `0xA968`, counting 28 vertex-program batches and 56 triangles. It did not produce a recognizable Steel Battalion title screen: the raster trace still reports degenerate coordinates and no usable textured batches. The event/vblank paths and AC'97/DSP shortcuts were diagnostic only; default synchronization, real DSP/audio, correct rendering, input, and campaign remain unverified. The specific opt-in wait-release diagnostic bar is now 1/1; all playable-feature and default-compatibility bars remain unchanged. Next inspect the live vertex/index and texture-stage inputs for these batches without changing guest behavior.
