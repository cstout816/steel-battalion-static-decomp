<div align="center">

# Steel Battalion for Windows

**A community preservation project exploring static recompilation of the original Xbox game**

### Experimental development · No playable build yet

[Can I play it?](docs/PLAYER_GUIDE.md) · [Project progress](docs/DEVELOPMENT_STATUS.md) · [Community and controller plans](docs/community-compatibility-preservation.md)

</div>

> **For players:** there is no game to download yet. A previous diagnostic reached the title screen with guest DSP execution, but only when the runtime's optional codec-ready signal was enabled. A traced follow-up loaded title sound banks and displayed the Dolby logo before frame updates stopped. Audible output, stable boot, controller response, and gameplay are not verified. There is no installer or launcher. Please do not download unofficial builds or send game files.

## The game and its controller

<table>
  <tr>
    <td width="50%" align="center">
      <a href="https://commons.wikimedia.org/wiki/File:Steel_Battalion_controllers.jpg"><img src="https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e7/Steel_Battalion_controllers.jpg/1280px-Steel_Battalion_controllers.jpg" alt="Original Steel Battalion controller and foot pedals" width="100%" /></a><br />
      <sub>Original controller and pedals · Photo by John Tregoning · <a href="https://creativecommons.org/licenses/by/2.0/">CC BY 2.0</a></sub>
    </td>
    <td width="50%" align="center">
      <a href="https://www.purexbox.com/games/xbox/steel_battalion"><img src="https://images.purexbox.com/screenshots/137992/large.jpg" alt="Gameplay screenshot from the original Xbox version of Steel Battalion" width="100%" /></a><br />
      <sub>Original Xbox gameplay · <a href="https://www.purexbox.com/games/xbox/steel_battalion">Pure Xbox screenshot gallery</a></sub>
    </td>
  </tr>
</table>

These externally hosted images show the original hardware and game. They are not stored in this repository; image rights remain with their respective creators and publishers.

## What this project is

The goal is to translate the original Xbox version of *Steel Battalion* (2002) ahead of time into a Windows application and recreate the Xbox services it needs. This is called **static recompilation**. The project is not an emulator packaged under another name.

The project is still experimental. The translated Windows program builds, and a prior Release run displayed the “PRESS MAIN WEAPON BUTTON” title prompt with guest DSP execution. That image was very dim and advanced at roughly 0.4–1.8 frames per second. A repeat without codec readiness returned `DSERR_NODRIVER` and crashed during DirectSound cleanup; with the optional codec-ready setting, DirectSound initialized and title audio assets opened, but the display stopped on the Dolby logo. Startup is not reliable. Prompt response, audible output, gameplay, saving, and campaign play are not verified. The tracker records observed engineering work separately from features players can use.

## Controller compatibility

The original 40-button Steel Battalion controller and pedals are central compatibility targets, alongside keyboard, mouse, gamepad, HOTAS, and custom controller profiles. A narrow virtual-device test has verified the 26-byte Main Weapon report and a corresponding guest action-state change; no complete control scheme or in-game response is verified.

## What you can do here

- **Learn the current state:** read the [player guide](docs/PLAYER_GUIDE.md) and [project progress tracker](docs/DEVELOPMENT_STATUS.md).
- **Follow the technical work:** see [research and architecture](docs/milestone-1-research.md) and the [audio DSP integration plan](docs/audio-dsp-integration-plan.md).
- **Share community knowledge:** visit [Steel Battalion Online on Reddit](https://www.reddit.com/r/steelbattaliononline/) or the [community Discord](https://discord.gg/steelbattalion).

When a tested release exists, players will need to provide their own legally obtained game copy. This repository will not include the ISO, XBE, extracted game code, textures, audio, or cinematics. The planned launcher may offer an option to add the game to Steam as a non-Steam shortcut; it will not grant a Steam store license.

## Progress at a glance

| Work area | Progress | Current result |
| --- | --- | --- |
| Overall project milestones | [#####---------------] 2/8 | Milestone 3, boot and compatibility, is active. A state-gated startup-render optimization passed 2.3 million per-fragment comparisons. A prior Release run reached the title prompt; newer runs expose an optional audio-codec initialization requirement and an intermittent display stall before or at the title. |
| Research and architecture | [#-------------------] 3/3 | Approach and technical limits documented. |
| XBE analysis and decompilation | [##########----------] 2/4 | XBE parsing and ahead-of-time translation output are available; per-function correctness and complete runtime dependencies are not yet verified. |
| Initial code translation | [#-------------------] 100% | Translation output exists; correctness is not established by output count. |
| Windows build | [#-------------------] 100% | A local build completes. |
| Boot and compatibility | [######--------------] 3/5 | Clear-rectangle methods are handled by an isolated patch. The guest DCF4 event signals correctly, and exact-state CPU combiner shortcuts passed 2.17 million reference comparisons with zero mismatches while retaining coverage, depth, texture sampling, and blending. A prior run reached the title prompt. A traced run now confirms DirectSound creation succeeds with the optional codec-ready setting and title sound banks open, but scanout later stops; repeatable startup, prompt response, audible output, and gameplay remain unverified. |
| Startup rendering performance | [##########----------] 2/4 | In the title-reaching Release run, 46 targeted 512×512 format-0x0E draws used the new paths: diffuse passthrough median 14.27 ms and diffuse-times-texture median 48.77 ms, compared with earlier generic fallback draws over 1.2 seconds. The full run still presented at about 0.4–1.8 FPS; other formats and title-scene work remain bottlenecks. |
| Virtual controller input | [#############-------] 2/3 | A synchronized diagnostic confirmed the Main Weapon report and guest action-state change. No title transition or complete input support is verified. |
| Guest DSP and audio | [█-------------------] 1/2 | Guest DSP instructions execute in a title-reaching run. Codec readiness is supplied synthetically for the diagnostic path; the title audio banks open, but audible output is not verified. |
| Campaign, controller, launcher | [--------------------] | Not yet verified or available. |

These bars describe engineering work, not playable features or campaign completion. See the [detailed tracker](docs/DEVELOPMENT_STATUS.md) for field-by-field evidence.

## Who makes this?

Most of the research, code, and documentation in this repository have been produced with **ChatGPT Codex**. GitHub maintainer and project contact: [@cstout816](https://github.com/cstout816). This is a community preservation effort; reported progress separates completed engineering work from game behavior that has actually been verified.

## Technical approach

The project uses [sp00nznet/xboxrecomp](https://github.com/sp00nznet/xboxrecomp) for ahead-of-time Xbox x86 translation; it does not use full-system emulation. The graphics work currently reproduces a narrow splash-logo draw, while general graphics, kernel, audio, filesystem, controller, and campaign compatibility still need work. See the [development tracker](docs/DEVELOPMENT_STATUS.md) for what has actually been verified.

The work prioritizes campaign reliability and the original Steel Battalion controller before visual enhancements. See the [community compatibility and preservation plan](docs/community-compatibility-preservation.md) for planned controller support, campaign checks, accessibility, and future Line of Contact research.

This independent project is not affiliated with or endorsed by Capcom or Microsoft. Product names and trademarks belong to their respective owners. A Windows release will be considered only after compatibility work and license review.
