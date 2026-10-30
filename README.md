<div align="center">

# Steel Battalion for Windows

**A community preservation project exploring static recompilation of the original Xbox game**

### Experimental development · No playable build yet

[Can I play it?](docs/PLAYER_GUIDE.md) · [Project progress](docs/DEVELOPMENT_STATUS.md) · [Community and controller plans](docs/community-compatibility-preservation.md)

</div>

> **For players:** there is no playable build to download yet. The latest screen-gated new-pilot route (r415) reached the mode-2 loader after Normal, then stopped on a white frame before any verified mission image. A separate r416 title-stage DCF4 wait was reproduced before pilot-list dispatch. The last visually verified `NOW LOADING` screen was r382. Complete audio, the original Steel Battalion controller, and campaign completion remain unverified. There is no installer or launcher. Please do not send game files.

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

The translated Windows program builds, but it is not reliable or playable. r415 correlated the new-pilot route through Normal and mode-2 loading. Its trace showed resource `0x1E` becoming ready, its worker completing, and sampled file reads succeeding; the loader pair then stopped at `0x000ABA00/0`. A separate r416 title-stage DCF4 wait had idle raster workers after the queue drained. Neither run verified a mission frame. Keep title DCF4 waits, the r340 Campaign audio-list corruption, raster cost, and post-difficulty loading separate. See the [r414–r416 report](analysis/m3-r414-r416-loading-and-title-wait-20261030.md) and [current status index](analysis/CURRENT_STATUS.md).

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
| Overall project milestones | [#####---------------] 2/8 | Milestone 3 remains active. r415 reached mode-2 loading, then plateaued; r382 remains the latest verified `NOW LOADING` screen. No first mission frame is verified. See the [current status index](docs/PROJECT_STATUS.md). |
| Research and architecture | [####################] 3/3 | Approach and technical limits documented. |
| XBE analysis and decompilation | [##########----------] 2/4 | XBE parsing and ahead-of-time translation output are available; per-function correctness and complete runtime dependencies are not yet verified. |
| Initial code translation | [####################] 100% | Translation output exists; correctness is not established by output count. |
| Windows build | [####################] 100% | A local build completes. |
| Boot and compatibility | [########------------] 4/5 | r415 reached the Normal difficulty selection and mode-2 loader through the new-pilot route. The first mission frame is still unverified. |
| Loader dependency tracing | [################----] 4/5 | r415 confirmed resource `0x1E` readiness and worker completion; the later mode-2 state producer remains unknown. |
| First mission frame | [--------------------] 0/1 | No in-mission framebuffer has been verified. |
| 60-FPS mission performance | [--------------------] 0/1 | No playable mission frame or gameplay frame-time sample has been verified; startup/loading measurements do not count. |
| Startup rendering performance | [##########----------] 2/4 | r348's sampled NV2A progress stopped after mode-2 scans; no evidence ties the separate r340 list corruption or older title/loading plateaus to a shared render backlog. |
| CPU raster throughput | [##########----------] 2/4 | Four workers remain the measured default; a synthetic sweep found no benefit from 8–16 workers. The local clipping fast path and raster regression harness have synthetic-only evidence; mission frame time and 1% lows are unverified. |
| GPU scene rendering | [#####---------------] 1/4 | A narrow splash-render path is verified; general NV2A scene rendering, mission GPU use, and image parity remain unverified. |
| Virtual controller input | [#############-------] 2/3 | Earlier screen-gated captures correlated XID/DMA, guest edge handling, pilot callback `0x000E18D8` / branch `0x000E193B`, and row action `0x83`. Physical adapter compatibility and the full original controller mapping/outputs remain unverified. |
| Guest DSP and audio | [█-------------------] 1/2 | r340 captured a `put_pixel` list-field write; r355 logged invalid list nodes but lacks writer/surface correlation. r356 did not reproduce. Audible output and a safe fix are unverified. |
| Storage and incremental builds | [##################--] 3/4 | Latest scan: 38.956 GiB allocated / 1,301.933 GiB logical; warm build tree 6.65 GiB. The cache is preserved; r416 closed-evidence compression recovered 789,283 bytes. See the [current cleanup manifest](analysis/current-cleanup-manifest-r416-20261030.md). |
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
