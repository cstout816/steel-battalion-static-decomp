<div align="center">

# Steel Battalion for Windows

**A preservation project for the original Xbox game**

**Most project research, code, and documentation are created with ChatGPT Codex, under the direction of project owner Connor Stout (`cstout816`).**

<img src="docs/images/project-banner.svg" alt="Steel Battalion for Windows: a static recompilation and preservation project for the original Xbox game. Experimental development; no playable build yet." width="100%">

<p><img src="docs/images/steel-battalion-controller.jpg" alt="Original Steel Battalion controller and pedals" width="70%"><br>
<sub>Original controller and pedals · photo by John Tregoning, CC BY 2.0</sub></p>

### Experimental development · Not ready to play

[What this project is](#the-short-version) · [Current progress](#current-progress) · [Planned setup](#when-a-playable-release-is-ready) · [Project details](#project-details)

</div>

> **Player status:** There is no playable build yet. Normal startup fails during audio setup. Experimental audio and asynchronous-file-I/O diagnostics load several title assets and reach GPU draw calls, but the rendered image has not been visually verified and the title screen has not been reached. The banner describes the project; the hardware photo shows the original controller and pedals, not running game footage.

## The short version

The goal is to make the original *Steel Battalion* run as a Windows application while keeping the original game and its demanding campaign intact. The project uses **static recompilation**: translating the game's original Xbox processor instructions ahead of time, then providing the Xbox services it needs through compatibility code.

This is not an Xbox emulator presented under another name. The project is still early: it has not reached the title screen, and there is no playable download, installer, or one-click setup yet.

> **For players:** There is nothing to install or play from this repository yet. Please check back for a tested release. When one is ready, you will need to provide your own legally obtained game copy. The project will never include or modify your game files.

## Current progress

```text
Function translation output  [####################] 9,148 / 9,148 emitted (100%)
Project milestones          [##------] 2 / 8 complete (25%)

Research and architecture    [##########] 3 / 3 checks complete
Windows executable build    [##########] 1 / 1 local build verified
Boot and filesystem          [####------] 2 / 5 checks observed
Graphics rendering           [##--------] 1 / 4 checks observed
Audio                        [###-------] 1 / 3 checks observed
Original SB controller       [----------] 0 / 3 checks verified
Other controller support     [----------] 0 / 3 checks verified
Campaign completion          [----------] 0 / 1 full campaign verified
Performance                  [----------] 0 / 3 checks verified
Debugging automation         [#####-----] 1 / 2 checks available
Windows launcher             [----------] 0 / 4 features available
Line of Contact research     [###-------] 1 / 3 checks complete
Distribution                 [###-------] 1 / 3 checks complete
```

The function bar counts functions emitted by the current production translation run; it does **not** mean every instruction or call is understood or that the game works. That output still contains 243 unsupported instruction sites and 351 unresolved call targets routed to stubs. The milestone bar counts completed project milestones. The field bars count the named checkpoints below, not coding effort or overall completeness. A checkpoint observed with a diagnostic is not necessarily a working feature. Milestone 3 is still in progress, and there is no playable build.

Checkpoint details: research covers XBE identification, architecture selection, and documented constraints; the executable bar records a local build only. Boot checks are guest entry, game asset read, title screen, rendered scene, and normal audio startup. Graphics checks are pushbuffer/clear/flip processing, title-screen image, gameplay draw, and enhanced-resolution output. Audio checks are diagnostic APU initialization, real DSP processing, and audible output. Original controller checks are input, full control mapping, and indicator-light output; other-controller checks are keyboard/mouse, gamepad, and HOTAS/custom HID. Performance checks are an original-rate baseline, stable 60 FPS, and higher-rate/frame-pacing validation. Debugging checks are crash/watchdog logs and deterministic input replay. Launcher checks are ISO validation, settings UI, Steam shortcut, and update flow. Line of Contact checks are initial community research, existing-network compatibility verification, and a separate profile. Distribution checks are project repository/documentation, completed dependency-license review, and a reviewed playable release package.

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
Audio: device initialization                               [#-------------------] 1 / 3 (33%)
Audio: DSP processing and game sound                       [--------------------] 0 / 2 (0%)
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

The XBE entry point and section map are documented; that is static analysis, not verified runtime behavior. The title-asset bar records a diagnostic read of the three title XPR files only, not complete filesystem compatibility. Pushbuffer handling records command processing and draw calls, not a correct rendered scene. The campaign bars remain at zero because no mission has been verified from loading through completion and progression.

| Area | Status |
| --- | --- |
| Research and architecture | Complete; static recompilation remains the chosen approach. |
| Initial Windows translation | Built locally; translation gaps mean this is not yet proof of correct game behavior. |
| Game startup | In progress; normal startup fails during audio setup. Experimental audio and async-I/O diagnostics load three title assets and issue GPU draws, but the image is unverified and no title screen has been reached. |
| Playable release and launcher | Not available. |
| Full campaign compatibility | Not verified. No mission-completion or campaign-progression testing has been completed. |

**The latest verified state is not a playable game.** The title screen, graphics, sound, controller input, saves, cinematics, mission completion, and campaign progression remain unverified. We will report compatibility only after the complete campaign has been tested mission by mission.

## When a playable release is ready

The intended setup is designed to be straightforward:

1. Download the project launcher from a reviewed release.
2. Select your own legally obtained original Xbox game image; the launcher will check it and explain any problems.
3. Choose the original Steel Battalion controller or a supported keyboard, mouse, gamepad, or HOTAS setup.
4. Start the game and adjust display or control options as needed.

These steps describe the plan. **The launcher and these features are not available today.** The planned launcher will also offer an optional action to add the game to a user's Steam library as a non-Steam game; Steam will not provide the game or grant a store entitlement.

## What the project is working toward

- **Campaign reliability first:** test every mission, save, cinematic, audio event, controller function, and progression step.
- **Full controller support:** preserve the original Steel Battalion controller and indicator lights where hardware permits, while making keyboard, mouse, modern controllers, HOTAS, and custom HID devices accessible.
- **A simple Windows launcher:** check a user-supplied game image, offer settings and diagnostics, and optionally add the game to Steam.
- **Careful modernization:** offer original and enhanced graphics settings, widescreen and high-resolution output, and frame-rate options that preserve game timing.
- **Future research:** investigate *Steel Battalion: Line of Contact* separately and check compatibility with Insignia, XLink Kai, and existing community sessions before considering multiplayer changes.

These are goals, not features of a released application. Experimental options will remain separate from the original experience.

## Who is building this?

This is **primarily a ChatGPT Codex project**. ChatGPT Codex has produced the majority of the research, documentation, code, and development work in this repository. Project owner Connor Stout (`cstout816`) sets priorities, makes architecture and release decisions, provides the legally obtained game copy for private local analysis, and directs verification. This authorship is stated plainly so visitors can understand how the project is being made. Progress notes distinguish work that was written or inspected from features that have actually been verified.

## Project details

The selected foundation is [sp00nznet/xboxrecomp](https://github.com/sp00nznet/xboxrecomp), which translates Xbox x86 code ahead of time. Its documented Windows graphics path uses Direct3D 11; the requested Direct3D 12 path is not implemented. Xbox kernel, graphics, audio, filesystem, and controller behavior still need compatibility work. The project will not quietly substitute ordinary emulation for the selected static-recompilation architecture.

Third-party components and licenses are being reviewed before a distribution license or Windows release is chosen. No proprietary Xbox SDK files are intended for inclusion.

## Your game files stay yours

This repository contains project code, configuration, and documentation only. **It does not include an Xbox ISO, XBE executable, extracted game code, textures, audio, cinematics, or other game files.** Users must supply their own legally obtained game copy. The original image will not be changed or redistributed.

## Follow the work

- [Project status and architecture notes](docs/milestone-1-research.md) — research, decisions, and verification records.
- [Community compatibility and preservation plan](docs/community-compatibility-preservation.md) — controller, campaign, graphics, and future multiplayer priorities.
- [Image credits and licenses](docs/ATTRIBUTIONS.md).
- [Steel Battalion community on Reddit](https://www.reddit.com/r/steelbattaliononline/).
- [Steel Battalion community Discord](https://discord.gg/steelbattalion).
- [ChatGPT Codex](https://openai.com/codex/).

The project is not affiliated with or endorsed by Capcom, Microsoft, or the image creators. Product names and trademarks belong to their respective owners. A Windows release will be considered only after compatibility work, license review, and project-owner approval.

For a no-jargon explanation of what players can expect, see the [player guide](docs/PLAYER_GUIDE.md). The repository will be updated as meaningful work is completed; routine changes will be pushed to GitHub so the public project record stays current.
