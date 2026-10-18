<div align="center">

# Steel Battalion for Windows

**A community preservation project exploring static recompilation of the original Xbox game**

### Experimental development · No playable build yet

[Can I play it?](docs/PLAYER_GUIDE.md) · [Project progress](docs/DEVELOPMENT_STATUS.md) · [Community and controller plans](docs/community-compatibility-preservation.md)

</div>

> **For players:** there is no game to download yet. The project has not reached the title screen, and there is no installer or launcher. Please do not download unofficial builds or send game files.

## What this project is

The goal is to translate the original Xbox version of *Steel Battalion* (2002) ahead of time into a Windows application and recreate the Xbox services it needs. This is called **static recompilation**. The project is not an emulator packaged under another name.

The project is still experimental. The translated Windows program builds, but it has not reached the title screen. Graphics, sound, controls, saving, and campaign play are not verified. The tracker records observed engineering work separately from features players can use.

## The original controller

The original 40-button controller is a central compatibility target. This reference photo shows the controller and pedals the project aims to support; it is credited in [image attributions](docs/ATTRIBUTIONS.md).

<p align="center">
  <img src="docs/images/steel-battalion-controller.jpg" alt="Original Steel Battalion controller with dual joysticks and foot pedals" width="720" />
</p>

## What you can do here

- **Learn the current state:** read the [player guide](docs/PLAYER_GUIDE.md) and [project progress tracker](docs/DEVELOPMENT_STATUS.md).
- **Follow the technical work:** see [research and architecture](docs/milestone-1-research.md) and the [audio DSP integration plan](docs/audio-dsp-integration-plan.md).
- **Share community knowledge:** visit [Steel Battalion Online on Reddit](https://www.reddit.com/r/steelbattaliononline/) or the [community Discord](https://discord.gg/steelbattalion).

When a tested release exists, players will need to provide their own legally obtained game copy. This repository will not include the ISO, XBE, extracted game code, textures, audio, or cinematics. The planned launcher may offer an option to add the game to Steam as a non-Steam shortcut; it will not grant a Steam store license.

## Progress at a glance

| Work area | Progress | Current result |
| --- | --- | --- |
| Research and architecture | [#-------------------] 3/3 | Approach and technical limits documented. |
| Initial code translation | [#-------------------] 100% | Translation output exists; correctness is not established by output count. |
| Windows build | [#-------------------] 100% | A local build completes. |
| Boot and compatibility | [######--------------] 3/5 | A corrected run loads and executes the guest GP/EP DSP programs and reaches an NV2A surface clear. The DSP command still stalls; the Steel Battalion title screen is not verified. |
| Campaign, controller, launcher | [--------------------] | Not yet verified or available. |

These bars describe engineering work, not playable features or campaign completion. See the [detailed tracker](docs/DEVELOPMENT_STATUS.md) for field-by-field evidence.

## Who makes this?

Most of the research, code, and documentation in this repository have been produced with **ChatGPT Codex**. GitHub maintainer and project contact: [@cstout816](https://github.com/cstout816). This is a community preservation effort; reported progress separates completed engineering work from game behavior that has actually been verified.

## Technical approach

The current foundation is [sp00nznet/xboxrecomp](https://github.com/sp00nznet/xboxrecomp), which translates Xbox x86 code ahead of time. The documented Windows graphics path uses Direct3D 11; the requested Direct3D 12 path is not implemented. Xbox kernel, graphics, audio, filesystem, and controller behavior still need compatibility work. The project will not quietly replace static recompilation with ordinary emulation.

The work prioritizes campaign reliability and the original Steel Battalion controller before visual enhancements. See the [community compatibility and preservation plan](docs/community-compatibility-preservation.md) for planned controller support, campaign checks, accessibility, and future Line of Contact research.

This independent project is not affiliated with or endorsed by Capcom or Microsoft. Product names and trademarks belong to their respective owners. A Windows release will be considered only after compatibility work and license review.
