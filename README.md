<div align="center">

# Steel Battalion for Windows

**A community preservation project exploring static recompilation of the original Xbox game**

### Experimental development · No playable build yet

[Can I play it?](docs/PLAYER_GUIDE.md) · [Project progress](docs/DEVELOPMENT_STATUS.md) · [Community and controller plans](docs/community-compatibility-preservation.md)

</div>

> **For players:** there is no game to download yet. A local diagnostic run has visually reached the title screen, but it is very dark and controller response, audio, and gameplay are not verified. There is no installer or launcher. Please do not download unofficial builds or send game files.

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

The project is still experimental. The translated Windows program builds, and a local diagnostic run has displayed the title screen. The captured screen is very dark and shows a “PRESS MAIN WEAPON BUTTON” prompt; response to that input is still being checked. Audio, gameplay, saving, and campaign play are not verified. The tracker records observed engineering work separately from features players can use.

## Controller compatibility

The original 40-button Steel Battalion controller and pedals are central compatibility targets, alongside keyboard, mouse, gamepad, HOTAS, and custom controller profiles. These are planned capabilities and have not yet been implemented or verified.

## What you can do here

- **Learn the current state:** read the [player guide](docs/PLAYER_GUIDE.md) and [project progress tracker](docs/DEVELOPMENT_STATUS.md).
- **Follow the technical work:** see [research and architecture](docs/milestone-1-research.md) and the [audio DSP integration plan](docs/audio-dsp-integration-plan.md).
- **Share community knowledge:** visit [Steel Battalion Online on Reddit](https://www.reddit.com/r/steelbattaliononline/) or the [community Discord](https://discord.gg/steelbattalion).

When a tested release exists, players will need to provide their own legally obtained game copy. This repository will not include the ISO, XBE, extracted game code, textures, audio, or cinematics. The planned launcher may offer an option to add the game to Steam as a non-Steam shortcut; it will not grant a Steam store license.

## Progress at a glance

| Work area | Progress | Current result |
| --- | --- | --- |
| Overall project milestones | [#####---------------] 2/8 | Milestone 3, boot and compatibility, is active; the title appeared in two bounded runs, but reliable startup is unverified. |
| Research and architecture | [#-------------------] 3/3 | Approach and technical limits documented. |
| Initial code translation | [#-------------------] 100% | Translation output exists; correctness is not established by output count. |
| Windows build | [#-------------------] 100% | A local build completes. |
| Boot and compatibility | [######--------------] 3/5 | Two local bounded runs reached the title screen; another stopped earlier during startup. Input response, audio, gameplay, and reliable boot are not yet verified. |
| Campaign, controller, launcher | [--------------------] | Not yet verified or available. |

These bars describe engineering work, not playable features or campaign completion. See the [detailed tracker](docs/DEVELOPMENT_STATUS.md) for field-by-field evidence.

## Who makes this?

Most of the research, code, and documentation in this repository have been produced with **ChatGPT Codex**. GitHub maintainer and project contact: [@cstout816](https://github.com/cstout816). This is a community preservation effort; reported progress separates completed engineering work from game behavior that has actually been verified.

## Technical approach

The project uses [sp00nznet/xboxrecomp](https://github.com/sp00nznet/xboxrecomp) for ahead-of-time Xbox x86 translation. **Vulkan is the fixed and only host renderer; the migration is not complete.** The project-owned Vulkan path handles a tightly checked textured splash-logo draw, with six nonblack fade frames matching CPU-reference captures byte-for-byte. Other NV2A pushbuffer draws still use the CPU reference rasterizer. A local 180-second diagnostic run visually reached the Steel Battalion title screen, but the picture was very dark and input response was not verified. XboxRecomp's inherited D3D8-to-D3D11 compatibility code is legacy Xbox API plumbing only; it is not a host renderer choice. D3D12 experiments are disabled and historical. There is no renderer selector or plan to switch APIs. The CPU remains statically recompiled—this does not use full-system emulation. Kernel, general graphics, audio, filesystem, controller, and campaign compatibility still need work.

The work prioritizes campaign reliability and the original Steel Battalion controller before visual enhancements. See the [community compatibility and preservation plan](docs/community-compatibility-preservation.md) for planned controller support, campaign checks, accessibility, and future Line of Contact research.

This independent project is not affiliated with or endorsed by Capcom or Microsoft. Product names and trademarks belong to their respective owners. A Windows release will be considered only after compatibility work and license review.
