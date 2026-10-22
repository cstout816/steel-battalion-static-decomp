<div align="center">

# Steel Battalion for Windows

**A community preservation project exploring static recompilation of the original Xbox game**

### Experimental development · No playable build yet

[Can I play it?](docs/PLAYER_GUIDE.md) · [Project progress](docs/DEVELOPMENT_STATUS.md) · [Community and controller plans](docs/community-compatibility-preservation.md)

</div>

> **For players:** there is no game to download yet. The corrected local launch now executes the initial graphics command ring and accepts virtual Steel Battalion controller input through pilot setup. A 420-second run reached “NOW LOADING,” but not a mission; its final trace still showed a backlog at the guest graphics fence. That route did not reach the same audio-cleanup path; a separate bounded capture reproduced an intermittent invalid release pointer during audio callback processing. Audio output and cleanup remain unverified. There is no installer or launcher. Please do not send game files.

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

The translated Windows program builds, but this is not a reliable or playable build. The initial graphics stall was traced to a missing launch setting: selecting the DMA walker alone does not execute commands; enabling its executor lets the first ring advance. A 420-second replay of the recorded input route reached pilot setup and `NOW LOADING`, but no mission appeared. An earlier 420-second notification trace showed sampled software notifications acknowledged by the guest and measured 0.68 FPS in its final interval, with 155 distinct unhandled graphics methods. The latest 420-second sparse fence trace again ended on `NOW LOADING`. Its semaphore advanced alongside the requested fence in periodic samples; at the watchdog, the target was `0x8A73`, semaphore `0x8A6F` (four behind), device put-counter `0x8A7B` (eight ahead), USER PUT/GET `0x7ECA8`/`0x7AEA8`, and DCF4 was signaled. This does not show a permanently stuck fence; loading progress and graphics throughput remain unresolved. Audio output, mission gameplay, saving, physical controller support, and campaign completion remain unverified. The detailed tracker records evidence and limits for each run.

## Controller compatibility

The original 40-button Steel Battalion controller and pedals are central compatibility targets, alongside keyboard, mouse, gamepad, HOTAS, and custom controller profiles. A virtual-device test verified the 26-byte Main Weapon report and a corresponding guest action-state change. In the pilot-name editor, a scripted left-stick input visibly moved the selected letter from A to B; the direction mapping still needs a matched up/down check. No complete control scheme or in-game response is verified.

## What you can do here

- **Learn the current state:** read the [player guide](docs/PLAYER_GUIDE.md) and [project progress tracker](docs/DEVELOPMENT_STATUS.md).
- **Follow the technical work:** see [research and architecture](docs/milestone-1-research.md) and the [audio DSP integration plan](docs/audio-dsp-integration-plan.md).
- **Share community knowledge:** visit [Steel Battalion Online on Reddit](https://www.reddit.com/r/steelbattaliononline/) or the [community Discord](https://discord.gg/steelbattalion).

When a tested release exists, players will need to provide their own legally obtained game copy. This repository will not include the ISO, XBE, extracted game code, textures, audio, or cinematics. The planned launcher may offer an option to add the game to Steam as a non-Steam shortcut; it will not grant a Steam store license.

## Progress at a glance

| Work area | Progress | Current result |
| --- | --- | --- |
| Overall project milestones | [#####---------------] 2/8 | Milestone 3, boot and compatibility, remains active. Correct DMA execution reaches “NOW LOADING,” but no mission appeared. The latest 420-second sparse trace shows fence progress but still ends on `NOW LOADING`; mission entry remains unverified. Rendering is slow and 155 graphics methods remain unhandled. |
| Research and architecture | [#-------------------] 3/3 | Approach and technical limits documented. |
| XBE analysis and decompilation | [##########----------] 2/4 | XBE parsing and ahead-of-time translation output are available; per-function correctness and complete runtime dependencies are not yet verified. |
| Initial code translation | [#-------------------] 100% | Translation output exists; correctness is not established by output count. |
| Windows build | [#-------------------] 100% | A local build completes. |
| Boot and compatibility | [########------------] 4/5 | Correctly enabling pushbuffer execution clears the initial zero-frame spin; the virtual Steel Battalion profile reaches pilot setup and loading. Mission entry remains unverified. The latest 420-second sparse trace ended in `D3DDevice_Swap` with DCF4 signaled, the semaphore four counts behind its target, and the device put-counter ahead. Periodic samples show progress, not a confirmed permanent fence deadlock. |
| Startup rendering performance | [##########----------] 2/4 | Earlier lower-overhead presentation fell to about 1.1 FPS. An instrumented windowed run reached 86 flips and reported 8.12 FPS; two 65-second windowed runs reached 765–767 flips and reported 7.83–7.84 FPS. The latest full trace reported 0.68 FPS in its final measurement interval, 1,843 flips, 136,283 draws, 801,587 vertices, and 155 distinct unhandled graphics methods. These are startup/loading measurements, not a stable gameplay benchmark. Stable frame pacing and gameplay performance are unverified. |
| Virtual controller input | [#############-------] 2/3 | Guest input queries accepted Main Weapon and camera-hat actions through the virtual Steel Battalion USB profile during pilot creation. Physical adapter compatibility and full original controller mapping/outputs remain unverified. |
| Guest DSP and audio | [█-------------------] 1/2 | Nonzero packets reach the DirectSound stream processor, XMO returns success, and the deferred callback reaches XBE routine `0x00227F9C`. A separate capture reproduced the invalid release argument in an audio callback while draining a DPC-managed list. The corrected loading run did not reach that same cleanup path, and audible output remains unverified. |
| Campaign, controller, launcher | [--------------------] | Not yet verified or available. |

These bars describe engineering work, not playable features or campaign completion. See the [detailed tracker](docs/DEVELOPMENT_STATUS.md) for field-by-field evidence.

## Who makes this?

Most of the research, code, and documentation in this repository have been produced with **ChatGPT Codex**. GitHub maintainer and project contact: [@cstout816](https://github.com/cstout816). This is a community preservation effort; reported progress separates completed engineering work from game behavior that has actually been verified.

## Technical approach

The project uses [sp00nznet/xboxrecomp](https://github.com/sp00nznet/xboxrecomp) for ahead-of-time Xbox x86 translation; it does not use full-system emulation. The graphics work currently reproduces a narrow splash-logo draw, while general graphics, kernel, audio, filesystem, controller, and campaign compatibility still need work. See the [development tracker](docs/DEVELOPMENT_STATUS.md) for what has actually been verified.

The work prioritizes campaign reliability and the original Steel Battalion controller before visual enhancements. See the [community compatibility and preservation plan](docs/community-compatibility-preservation.md) for planned controller support, campaign checks, accessibility, and future Line of Contact research.

This independent project is not affiliated with or endorsed by Capcom or Microsoft. Product names and trademarks belong to their respective owners. A Windows release will be considered only after compatibility work and license review.
