# Community Compatibility and Preservation Requirements

**Status:** Deferred feature scope. The user's instruction is to apply these priorities after the static recompilation/decomp work is complete. Do not let launcher, graphics, controller, or Line of Contact features distract from current boot work. Do not treat a title-screen or first-mission run as full compatibility.

## User priority order

1. Complete and stable Steel Battalion (2002) campaign from start through final progression.
2. Full original Steel Battalion controller, including all inputs and indicator-light outputs when hardware supports them.
3. Keyboard/mouse, Xbox/PlayStation gamepads, HOTAS, dual sticks and rudder pedals, multiple USB devices, and custom HID devices. Provide a labeled graphical editor with click-to-bind, toggle/gear semantics, calibration, combinations, and shareable/importable/exportable profiles. Keep original controller semantics as default; offer keyboard/mouse, Xbox, and common HOTAS defaults.
4. Easy ISO selection/configuration, portable Windows install, built-in diagnostics, opt-in crash reports, community documentation links, and screen/video-friendly presentation.
5. Original and enhanced graphics presets: original appearance; 1080p/1440p/4K, correct widescreen, optional cockpit monitor noise and film grain, texture filtering, shader/pipeline cache, and simulation-safe frame limits. Keep experimental options separate; do not permanently remove effects or change mechanics.
6. Community controller profiles.
7. Consider Steel Battalion: Line of Contact (2004) only as a distinct future user-supplied title with a separate compatibility profile. Investigate Insignia, XLink Kai, Xbox system-link and community sessions before any networking implementation; do not create a replacement protocol first.

## Campaign acceptance matrix

Track each mission and campaign transition for: mission load, gameplay stability, cinematics, audio, each controller class, save/load, frame pacing, completion trigger, and campaign progression. Record build, mission, input profile/device, resolution/frame cap, expected result, actual result, logs/replay/save evidence, and issue ID. Final compatibility requires every campaign mission and transition to pass; title screen and first mission are smoke checks only.

## Community research snapshot (2026-10-17)

- [quizerno/Xemu-SB-VK](https://github.com/quizerno/Xemu-SB-VK) is an Xemu emulator fork, **not a static-recompilation component**. Its README reports configurable/rebindable keyboard input on the Vulkan fork (restart required), light-input recognition gaps, and incomplete input support parity between branches. It says direct joystick binding is not implemented there and suggests external Joystick Gremlin; it also lists configurable gear/tuner and more rebinding as work in progress. This overlaps the requested controller editor/profile priorities and can inform UX, but is not suitable as the CPU execution core. Performance/playability reports are community anecdotes and are not campaign verification.
- The Xemu-SB-VK repository includes QEMU GPLv2 license text and per-file license notices may vary. Do not copy code until each exact source file, derivative and dependency is audited against the project's chosen license and distribution plan.
- [r/steelbattaliononline](https://www.reddit.com/r/steelbattaliononline/) describes Line of Contact as actively played through Insignia and XLink Kai. Community posts describe keyboard/HOTAS rebinding workarounds, controller scarcity, custom controller/adapter projects, first-mission/first-few-mission emulator progress, and reports of inconsistent performance or crashes. These posts identify user pain points; they are anecdotal, version-dependent, and cannot establish compatibility.
- The [Insignia Line of Contact title page](https://insignia.live/games/43430009) distinguishes the original game's offline single-player campaign from LoC's online multiplayer focus. [Team XLink's LoC page](https://teamxlink.co.uk/wiki/Steel_Battalion:_Line_of_Contact_(Xbox)) lists system-link support and up to ten players, and warns its game-specific entries may be incomplete. Validate real compatibility with community sessions before claiming support. Insignia and XLink are separate network paths; do not assume either automatically works with a native recompiler.
- [XboxPeripheralLibusbTools](https://github.com/faha223/XboxPeripheralLibusbTools) documents libusb passthrough setup, including assigning WinUSB or libusbK on Windows. That is for Xemu USB passthrough, not a ready-made safe Windows input backend; driver reassignment must never happen silently.
- [ogx360_t4](https://github.com/Ryzee119/ogx360_t4) emulates Xbox and Steel Battalion controllers using a Teensy 4.1 on original Xbox hardware. It is useful hardware/protocol reference, not a Windows virtual controller implementation.
- The provided [Discord invite](https://discord.gg/steelbattalion) could not be inspected without joining/authenticated access. No community members were contacted.

No community code has been copied or adopted. Recheck repository state, licenses, compatibility and community guidance before implementation because these projects change.
