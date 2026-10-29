<div align="center">

# Steel Battalion for Windows

**A community preservation project exploring static recompilation of the original Xbox game**

### Experimental development · No playable build yet

[Can I play it?](docs/PLAYER_GUIDE.md) · [Project progress](docs/DEVELOPMENT_STATUS.md) · [Community and controller plans](docs/community-compatibility-preservation.md)

</div>

> **For players:** there is no game to download yet. The latest bounded AOT new-pilot diagnostic (r179) reached a black post-title/loading transition, created a preload worker, and recorded seven mode-2 loader scans. The saved framebuffer is black; no mission frame or playable boot is verified. The traces do not establish whether loading, graphics, or synchronization is responsible. Audio and physical-controller support remain unverified. There is no installer or launcher. Please do not send game files.

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

The translated Windows program builds, but it is not reliable or playable. In r179, the new-pilot route returned 39/39 file-copy callbacks, created worker 6, and completed seven mode-2 scans with result 0 before the screen and activity plateaued. The final captured frame is black. Earlier runs identified incomplete copies and cache misses, but those did not establish a single cause, and later runs completed the observed copies. DMA-ACK sampling filled its cap before the loading interval, and the dump's last AOT program counter is only a candidate; the evidence does not prove a graphics backlog, file dependency, or unsignaled DCF4 wait. The separate DirectSound list crash remains unresolved. Audio, physical-controller support, and campaign completion remain unverified. See the [r173–r179 loading evidence](analysis/m3-pilot-loader-r159-r160-report-20261028.md) and [loader handoff](analysis/astra-pilot-loading-handoff.md).

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
| Overall project milestones | [#####---------------] 2/8 | Milestone 3 remains active. r340 confirmed a renderer pixel store corrupting DirectSound list fields at the Campaign menu; its active surface state still needs correlation. No first mission frame. See the [r340–r344 report](analysis/m3-r340-r344-surface-and-storage-20261029.md). |
| Research and architecture | [####################] 3/3 | Approach and technical limits documented. |
| XBE analysis and decompilation | [##########----------] 2/4 | XBE parsing and ahead-of-time translation output are available; per-function correctness and complete runtime dependencies are not yet verified. |
| Initial code translation | [####################] 100% | Translation output exists; correctness is not established by output count. |
| Windows build | [####################] 100% | A local build completes. |
| Boot and compatibility | [########------------] 4/5 | r342 reached the Campaign menu. r343/r344 stalled at a black title-stage frame before Campaign; no first mission frame or loader dependency is verified. |
| Loader dependency tracing | [##########----------] 2/4 | r340–r344 did not reach the mission loader. The first stalled mission dependency remains unknown; title DCF4, the Campaign audio-list crash, rendering cost, and later loading plateaus remain separate. |
| First mission frame | [--------------------] 0/1 | No in-mission framebuffer has been verified. |
| 60-FPS mission performance | [--------------------] 0/1 | No playable mission frame or gameplay frame-time sample has been verified; startup/loading measurements do not count. |
| Startup rendering performance | [##########----------] 2/4 | r340 recorded raster work near the Campaign crash, but no evidence ties a growing render backlog to the title freeze or mission loading. |
| CPU raster throughput | [##########----------] 2/4 | Four workers remain the measured default; a synthetic sweep found no benefit from 8–16 workers. The local clipping fast path and raster regression harness have synthetic-only evidence; mission frame time and 1% lows are unverified. |
| GPU scene rendering | [#####---------------] 1/4 | A narrow splash-render path is verified; general NV2A scene rendering, mission GPU use, and image parity remain unverified. |
| Virtual controller input | [#############-------] 2/3 | Earlier screen-gated captures correlated XID/DMA, guest edge handling, pilot callback `0x000E18D8` / branch `0x000E193B`, and row action `0x83`. Physical adapter compatibility and the full original controller mapping/outputs remain unverified. |
| Guest DSP and audio | [█-------------------] 1/2 | r340 confirmed `put_pixel` writing into the DirectSound list before its invalid-node crash. The active render target and safe fix remain unverified; audible output is not verified. |
| Storage and incremental builds | [##############------] 3/4 | The workspace is 49.860 GiB allocated / 1.261 TiB logical after sparse-file accounting. Closed diagnostic logs were compressed with hash checks; the warm build cache remains intact. |
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
