<div align="center">

# Steel Battalion for Windows

**A community preservation project exploring static recompilation of the original Xbox game**

### Experimental development · No playable build yet

[Can I play it?](docs/PLAYER_GUIDE.md) · [Project progress](docs/DEVELOPMENT_STATUS.md) · [Community and controller plans](docs/community-compatibility-preservation.md)

</div>

> **For players:** there is no game to download yet. With the optional codec-ready signal enabled, a synchronized diagnostic reached the title prompt, accepted a Main Weapon action, and displayed the menu with **CAMPAIGN** selected. Presentation remained very slow and the menu was dim. Audible output, reliable startup, full controller support, and gameplay are not verified. There is no installer or launcher. Please do not download unofficial builds or send game files.

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

The project is still experimental. The translated Windows program builds. A bounded diagnostic replay reached the Campaign menu and pilot setup after Main Weapon inputs, but stalled in a D3D fence wait with a large pushbuffer backlog. The event wait returned successfully; the software command executor had not yet retired the commands the game was waiting on. A separate startup timing sample measured repeated CPU-raster draws in the 14–49 ms range, with occasional 1024×1024 draws reaching 285 ms. This is not a reliable boot or playable build. Earlier title/menu captures were dim and slow. A diagnostic run without codec readiness returned `DSERR_NODRIVER`; with the optional codec-ready setting, DirectSound initialized and title audio assets opened. An isolated APU output-path fix now preserves each 256-sample guest block and matches XAudio2's block size to the APU cadence. A bounded retest stalled at the Dolby logo and its first 64 startup blocks remained silent; game audio remains unverified. Full controller support, gameplay, saving, and campaign play are not verified. The tracker records observed engineering work separately from features players can use.

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
| Overall project milestones | [#####---------------] 2/8 | Milestone 3, boot and compatibility, is active. Campaign and pilot setup screens have been captured after Main Weapon inputs. The wait event returns success; the final guest wait coincides with NV2A PUT ahead of GET, so command consumption remains the bottleneck. Startup timing still shows slow CPU-raster draws and no stable boot or gameplay. |
| Research and architecture | [#-------------------] 3/3 | Approach and technical limits documented. |
| XBE analysis and decompilation | [##########----------] 2/4 | XBE parsing and ahead-of-time translation output are available; per-function correctness and complete runtime dependencies are not yet verified. |
| Initial code translation | [#-------------------] 100% | Translation output exists; correctness is not established by output count. |
| Windows build | [#-------------------] 100% | A local build completes. |
| Boot and compatibility | [########------------] 4/5 | Clear-rectangle handling and a synchronous GPU-idle step are covered by isolated patches. Exact-state CPU combiner shortcuts passed 2.17 million reference comparisons with zero mismatches. A synchronized Main Weapon query returned success and a title-menu transition was captured. With the DSP page-mapping fix, a rendered Campaign menu was captured, but the run stopped at 566 flips in the D3D swap/fence wait; XPR stability across that transition is not yet confirmed. Stable startup, audio output, and gameplay remain unverified. |
| Startup rendering performance | [##########----------] 2/4 | Earlier lower-overhead presentation fell to about 1.1 FPS. An instrumented windowed run reached 86 flips and reported 8.12 FPS; two 65-second windowed runs reached 765–767 flips and reported 7.83–7.84 FPS, with roughly 42,000 unhandled NV2A method calls across 152 IDs. The second run used only low-volume tracing, so the slow rate is not caused solely by the temporary thread trace. These remain startup measurements, not a stable gameplay benchmark. A matching fullscreen title draw took 20.8 ms on the Vulkan fast path versus 24.3 ms on CPU in single instrumented samples; image parity is unresolved, so this is not a frame-rate result. Other draw states still use CPU rasterization, and 152 distinct NV2A methods remain unhandled. Stable frame pacing and gameplay performance are unverified. |
| Virtual controller input | [#############-------] 2/3 | A synchronized Main Weapon pulse reached the guest query, which returned success, and a title-menu transition was captured. Repeatable game interaction is not established; full original controller mapping and outputs remain unverified. |
| Guest DSP and audio | [█-------------------] 1/2 | Guest DSP instructions execute in a title-reaching run. Codec readiness is supplied synthetically for diagnostics. The APU output block/cadence fix builds, but the first 64 blocks in the bounded retest remained silent before a Dolby-logo stall. Game audio remains unverified. |
| Campaign, controller, launcher | [--------------------] | Not yet verified or available. |

These bars describe engineering work, not playable features or campaign completion. See the [detailed tracker](docs/DEVELOPMENT_STATUS.md) for field-by-field evidence.

## Who makes this?

Most of the research, code, and documentation in this repository have been produced with **ChatGPT Codex**. GitHub maintainer and project contact: [@cstout816](https://github.com/cstout816). This is a community preservation effort; reported progress separates completed engineering work from game behavior that has actually been verified.

## Technical approach

The project uses [sp00nznet/xboxrecomp](https://github.com/sp00nznet/xboxrecomp) for ahead-of-time Xbox x86 translation; it does not use full-system emulation. The graphics work currently reproduces a narrow splash-logo draw, while general graphics, kernel, audio, filesystem, controller, and campaign compatibility still need work. See the [development tracker](docs/DEVELOPMENT_STATUS.md) for what has actually been verified.

The work prioritizes campaign reliability and the original Steel Battalion controller before visual enhancements. See the [community compatibility and preservation plan](docs/community-compatibility-preservation.md) for planned controller support, campaign checks, accessibility, and future Line of Contact research.

This independent project is not affiliated with or endorsed by Capcom or Microsoft. Product names and trademarks belong to their respective owners. A Windows release will be considered only after compatibility work and license review.
