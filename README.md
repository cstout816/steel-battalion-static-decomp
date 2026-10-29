<div align="center">

# Steel Battalion for Windows

**A community preservation project exploring static recompilation of the original Xbox game**

### Experimental development · No playable build yet

[Can I play it?](docs/PLAYER_GUIDE.md) · [Project progress](docs/DEVELOPMENT_STATUS.md) · [Community and controller plans](docs/community-compatibility-preservation.md)

</div>

> **For players:** there is no playable build to download yet. The latest bounded AOT run (r348) reached the new-pilot and Normal-difficulty screens, then stopped progressing before a visible loading transition. No first mission frame, complete audio, or physical-controller support is verified. A separate Campaign-stage run (r340) captured a DirectSound-list corruption, whose active render surface is still unknown. There is no installer or launcher. Please do not send game files.

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

The translated Windows program builds, but it is not reliable or playable. r340 directly captured `put_pixel` writing into three guest DirectSound-list fields before the list walk crashed; the active surface state at those exact stores remains unknown, so no runtime repair is justified. r348 used the surface probe and did not reproduce that write. It reached the name editor, confirmed `01/01/2002` and Normal difficulty, and began mode-2 readiness scans, but the saved frame stayed on the difficulty menu and NV2A progress later stopped. The 4 MiB reserve fallback to 2 MiB returned success; it is not established as the cause. No missing loader dependency or first mission frame is proven. Keep this run separate from title DCF4 waits, the r340 audio-list corruption, and raster performance. See the [r348 report](analysis/m3-r348-mode2-plateau-and-storage-20261029.md) and [project status index](docs/PROJECT_STATUS.md).

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
| Overall project milestones | [#####---------------] 2/8 | Milestone 3 remains active. r348 reached the new-pilot Normal-difficulty route, then stopped before a visible loading transition; first mission frame remains unverified. The separate r340 Campaign list corruption still lacks active-surface correlation. See the [r340–r348 report](analysis/m3-r340-r344-surface-and-storage-20261029.md). |
| Research and architecture | [####################] 3/3 | Approach and technical limits documented. |
| XBE analysis and decompilation | [##########----------] 2/4 | XBE parsing and ahead-of-time translation output are available; per-function correctness and complete runtime dependencies are not yet verified. |
| Initial code translation | [####################] 100% | Translation output exists; correctness is not established by output count. |
| Windows build | [####################] 100% | A local build completes. |
| Boot and compatibility | [########------------] 4/5 | r342 reached Campaign; r343–r345 stalled at a black title-stage frame before Campaign. No first mission frame or loader dependency is verified. |
| Loader dependency tracing | [##########----------] 2/4 | r348 emitted 19 mode-2 readiness scans after the new-pilot route, but no visible `NOW LOADING` frame or missing dependency was captured. The first mission blocker remains unknown; title DCF4, the Campaign audio-list crash, rendering cost, and loading plateaus stay separate. |
| First mission frame | [--------------------] 0/1 | No in-mission framebuffer has been verified. |
| 60-FPS mission performance | [--------------------] 0/1 | No playable mission frame or gameplay frame-time sample has been verified; startup/loading measurements do not count. |
| Startup rendering performance | [##########----------] 2/4 | r348's sampled NV2A progress stopped after mode-2 scans; no evidence ties the separate r340 list corruption or older title/loading plateaus to a shared render backlog. |
| CPU raster throughput | [##########----------] 2/4 | Four workers remain the measured default; a synthetic sweep found no benefit from 8–16 workers. The local clipping fast path and raster regression harness have synthetic-only evidence; mission frame time and 1% lows are unverified. |
| GPU scene rendering | [#####---------------] 1/4 | A narrow splash-render path is verified; general NV2A scene rendering, mission GPU use, and image parity remain unverified. |
| Virtual controller input | [#############-------] 2/3 | Earlier screen-gated captures correlated XID/DMA, guest edge handling, pilot callback `0x000E18D8` / branch `0x000E193B`, and row action `0x83`. Physical adapter compatibility and the full original controller mapping/outputs remain unverified. |
| Guest DSP and audio | [█-------------------] 1/2 | r340 confirmed `put_pixel` writing into the DirectSound list before its invalid-node crash. The active render target and safe fix remain unverified; r348 reproduced no watched write and audible output is not verified. |
| Storage and incremental builds | [##############------] 3/4 | The latest scan is 48.983 GiB allocated / 1,290.154 GiB logical. Verified lossless compression reclaimed 945,311,744 bytes from 41 reproducible historical motion-cache copies; the warm build cache and unique saves remain intact. See the [cleanup manifest](analysis/current-cleanup-manifest-20261029.md). |
| Campaign, controller, launcher | [--------------------] | Not yet verified or available. |

These bars describe engineering work, not playable features or campaign completion. See the [detailed tracker](docs/DEVELOPMENT_STATUS.md) for field-by-field evidence.

## Who makes this?

Most of the research, code, and documentation in this repository have been produced with **ChatGPT Codex**. GitHub maintainer and project contact: [@cstout816](https://github.com/cstout816). This is a community preservation effort; reported progress separates completed engineering work from game behavior that has actually been verified.

## Technical approach

The project uses [sp00nznet/xboxrecomp](https://github.com/sp00nznet/xboxrecomp) for ahead-of-time Xbox x86 translation; it does not use full-system emulation. The graphics work currently reproduces a narrow splash-logo draw, while general graphics, kernel, audio, filesystem, controller, and campaign compatibility still need work. See the [development tracker](docs/DEVELOPMENT_STATUS.md) for what has actually been verified.

The work prioritizes campaign reliability and the original Steel Battalion controller before visual enhancements. See the [community compatibility and preservation plan](docs/community-compatibility-preservation.md) for planned controller support, campaign checks, accessibility, and future Line of Contact research.

## Performance and hardware use

  The runtime uses CPU worker threads for general Xbox graphics rasterization and the RTX 4070 SUPER for presentation and a small, verified GPU-rendered splash draw. A previous runtime log confirms the NVIDIA card was selected. The available synthetic raster test was fastest with 4–6 workers; 8–16 workers did not improve it, so the current 4-worker default stays in place until a repeatable mission benchmark supports changing it. A verified CPU fast path reduced a repeated raster test's median process time by about 1.9%; its effect on game frames is unmeasured. A four-worker matched-save run reached `NOW LOADING` at about 0.56–0.60 guest FPS, but did not show a mission frame. A later six-worker retry froze at the title after 535 flips; per-process GPU 3D samples reached about 25% during startup and fell to 0% while the title was frozen. These startup/loading readings are not gameplay benchmarks. The full scene is not yet GPU-rendered; gameplay GPU utilization or 60 FPS has not been verified.

This independent project is not affiliated with or endorsed by Capcom or Microsoft. Product names and trademarks belong to their respective owners. A Windows release will be considered only after compatibility work and license review.
