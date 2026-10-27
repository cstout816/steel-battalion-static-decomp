<div align="center">

# Steel Battalion for Windows

**A community preservation project exploring static recompilation of the original Xbox game**

### Experimental development · No playable build yet

[Can I play it?](docs/PLAYER_GUIDE.md) · [Project progress](docs/DEVELOPMENT_STATUS.md) · [Community and controller plans](docs/community-compatibility-preservation.md)

</div>

> **For players:** there is no game to download yet. The latest bounded new-pilot replay reached “NOW LOADING” but still had no mission frame after 419 loader passes. File reads completed successfully, DCF4 counters advanced, and the exact loading condition remains unknown. The game is not yet reliably playable. These diagnostics used a synthetic DSP acknowledgement; audible audio is not verified. There is no installer or launcher. Please do not send game files.

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

The translated Windows program builds, but it is not reliable or playable. The latest diagnostic, r89, verified a screen-gated XID input through the visible `LIST AS NEW` row action, then crashed in the DirectSound deferred-settings list before reaching `NOW LOADING`. The immediate invalid-node dereference is supported by guest registers and generated code; the earlier corruption remains unknown. Its bounded all-wait trace observed only the title startup event before the crash. The previous r88 run reached `NOW LOADING`: its 419 mode-2 scans returned through `0x000C32D6`; the observed state pair stabilized, but its role as a progress counter is unverified. XBE section `seg00` loaded successfully. Reads, DCF4 callbacks, and NV2A counters progressed, but no first mission frame or first blocked loader dependency has been established. Raster work was severe, without proof of a sustained growing queue. Audio, physical controller support, and campaign completion remain unverified. See the [r89 findings](analysis/m3-pilot-loading-r89-all-waits-20261027.md) and [r88 loading evidence](analysis/m3-pilot-loading-r88-dcf4-producer-20261027.md).

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
| Overall project milestones | [#####---------------] 2/8 | Milestone 3, boot and compatibility, remains active. r88 reached `NOW LOADING` without a first-mission frame. r89 verified the new-pilot row input but crashed in a malformed DirectSound list before the loading screen. No first loader dependency is established. See the [r89 trace](analysis/m3-pilot-loading-r89-all-waits-20261027.md) and [r88 loading evidence](analysis/m3-pilot-loading-r88-dcf4-producer-20261027.md). |
| Research and architecture | [####################] 3/3 | Approach and technical limits documented. |
| XBE analysis and decompilation | [##########----------] 2/4 | XBE parsing and ahead-of-time translation output are available; per-function correctness and complete runtime dependencies are not yet verified. |
| Initial code translation | [####################] 100% | Translation output exists; correctness is not established by output count. |
| Windows build | [####################] 100% | A local build completes. |
| Boot and compatibility | [########------------] 4/5 | r88 reached `NOW LOADING` but no mission frame; its state pair is not a verified progress counter, and no loader dependency was identified. New r89 wait telemetry verified the visible pilot-row action but the run naturally crashed before loading: a malformed DirectSound list caused an immediate invalid-node dereference, while the earlier corrupting write remains unknown. DCF4/frame counters progressed. The first loader dependency and mission frame remain unknown. See the [r89 trace report](analysis/m3-pilot-loading-r89-all-waits-20261027.md), [r88 loading report](analysis/m3-pilot-loading-r88-dcf4-producer-20261027.md), and [loader handoff](analysis/astra-pilot-loading-handoff.md). |
| First mission frame | [--------------------] 0/1 | No in-mission framebuffer has been verified. |
| 60-FPS mission performance | [--------------------] 0/1 | No playable mission frame or gameplay frame-time sample has been verified; startup/loading measurements do not count. |
| Startup rendering performance | [##########----------] 2/4 | r86 repeatedly measured 27 batches / 56 triangles, about 2.0–2.2 seconds batch wall and 7.8–8.5 seconds summed worker-active time across four workers. This is severe CPU raster cost, but no growing queue or causal link to the loader was proven. |
| CPU raster throughput | [##########----------] 2/4 | Four workers remain the measured default; a synthetic sweep found no benefit from 8–16 workers. The local clipping fast path and raster regression harness have synthetic-only evidence; mission frame time and 1% lows are unverified. |
| GPU scene rendering | [#####---------------] 1/4 | Vulkan presentation and a narrow splash-render path use the RTX 4070 SUPER. General NV2A scene rasterization still runs on CPU; sampled `nvidia-smi` readings were 0% during the title/loading route. Mission GPU-engine use and accelerated-scene image parity are unverified. |
| Virtual controller input | [#############-------] 2/3 | In r88, screen-gated presses reached XID/DMA and guest edge/predicate handling, then `LIST AS NEW` callback `0x000E18D8` / branch `0x000E193B`; row action `0x83` changed the item state. The dedicated `[SB-SNAPSHOT]` marker emitted no record. Physical adapter compatibility and full original controller mapping/outputs remain unverified. |
| Guest DSP and audio | [█-------------------] 1/2 | Nonzero packets reach the DirectSound stream processor, XMO returns success, and the deferred callback reaches XBE routine `0x00227F9C`. A separate capture reproduced the invalid release argument in an audio callback while draining a DPC-managed list. The corrected loading run did not reach that same cleanup path, and audible output remains unverified. |
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
