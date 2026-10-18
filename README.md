<div align="center">

# Steel Battalion for Windows

**A preservation project exploring static recompilation of the original Xbox game**

<img src="docs/images/project-banner.svg" alt="Steel Battalion preservation project banner" width="100%" />

**Experimental development · No playable build yet**

[Can I play it?](docs/PLAYER_GUIDE.md) · [Project progress](docs/DEVELOPMENT_STATUS.md) · [Research and architecture](docs/milestone-1-research.md) · [Image credits](docs/ATTRIBUTIONS.md)

</div>

> **Current status:** the translated Windows program builds, but it has not reached the game's title screen. There is no playable release, installer, or launcher. Rendering, audio, controller support, saves, and campaign progress are not yet verified.

## The short version

This community preservation project is exploring whether the original Xbox version of *Steel Battalion* can be translated ahead of time into a Windows application. The project is using **static recompilation**: translating the game's original processor instructions and rebuilding the Xbox services it needs. It is not an Xbox emulator bundled under another name.

### Progress at a glance

| Work area | Progress | What that means |
| --- | --- | --- |
| Research and architecture | [#-------------------] 3/3 | The project approach has been selected and documented. |
| Initial code translation | [#-------------------] 100% | Translation output is produced; that alone does not prove correct gameplay. |
| Windows build | [#-------------------] 100% | The translated program builds locally. |
| Boot and compatibility | [####----------------] 2/5 | Startup investigation continues; no title screen yet. |
| Campaign, controller, launcher | [--------------------] | Not yet verified or available. |

See the [detailed project tracker](docs/DEVELOPMENT_STATUS.md) for field-by-field progress and verification notes. Bars track development tasks, not game completion.

## Photos and project artwork

<table>
  <tr>
    <td align="center" width="33%">
      <img src="docs/images/steel-battalion-box.jpg" alt="Original Steel Battalion Xbox game package" width="240" />
      <br /><sub>Original game package · Xboxsupervisioncreator · CC BY-SA 3.0</sub>
    </td>
    <td align="center" width="33%">
      <img src="docs/images/steel-battalion-controller.jpg" alt="Original Steel Battalion controller and pedals" width="320" />
      <br /><sub>Original controller and pedals · John Tregoning · CC BY 2.0</sub>
    </td>
    <td align="center" width="33%">
      <a href="https://www.mobygames.com/game/7805/steel-battalion/promo/group-116838/image-907173/">
        <img src="https://cdn.mobygames.com/promos/11408273-steel-battalion-screenshot.jpg" alt="Steel Battalion gameplay screenshot hosted by MobyGames" width="320" />
      </a>
      <br /><sub>Gameplay screenshot · hosted by MobyGames · X02 North America press disc</sub>
    </td>
  </tr>
</table>

The project banner is original text-and-shape SVG artwork. No generated photos or game screenshots are stored in this repository. The gameplay image above is loaded from its source page; it is not part of the project files. See [image credits and terms](docs/ATTRIBUTIONS.md).

## What is—and isn't—available

- **Available now:** research notes, source code and development progress.
- **Not available yet:** a playable Windows build, launcher, setup wizard, controller editor, or campaign compatibility.
- **When a tested release exists:** players will need to provide their own legally obtained original Xbox copy. This repository will not include the ISO, XBE, extracted game code, textures, audio, or cinematics.
- **Planned:** original Steel Battalion controller support, keyboard and mouse, modern controllers and HOTAS, plus optional graphics and display settings.
- **Planned:** the launcher may offer a button to add the game to Steam as a non-Steam game. This does not provide a Steam store license.

The [player guide](docs/PLAYER_GUIDE.md) explains the project in everyday terms and describes what a future setup is intended to look like.

## Who makes the project?

Most of the research, code, and documentation in this repository have been produced with **ChatGPT Codex**. **Connor Stout (cstout816) maintains the project.** Progress reports distinguish work that has been written or built from game behavior that has actually been verified.

## Project approach

The current foundation is [sp00nznet/xboxrecomp](https://github.com/sp00nznet/xboxrecomp), which translates Xbox x86 code ahead of time. The documented Windows graphics path uses Direct3D 11; the requested Direct3D 12 path is not implemented. Xbox kernel, graphics, audio, filesystem, and controller behavior still need compatibility work. The project will not quietly replace its chosen static-recompilation approach with ordinary emulation.

The project is prioritizing campaign reliability and original controller support before visual enhancements. Read the [community compatibility and preservation plan](docs/community-compatibility-preservation.md) for the feature priorities.

## Start here

- New to the project? Read the [player guide](docs/PLAYER_GUIDE.md).
- Want technical detail? See [research and architecture](docs/milestone-1-research.md).
- Want the audio reuse plan? Read the [MCPX DSP integration plan](docs/audio-dsp-integration-plan.md).
- Want all current progress bars? Open the [development status page](docs/DEVELOPMENT_STATUS.md).
- Looking for image sources and licenses? See [image credits](docs/ATTRIBUTIONS.md).
- Want to help? Share reproducible compatibility findings or join the [Steel Battalion Online community on Reddit](https://www.reddit.com/r/steelbattaliononline/) and [Discord](https://discord.gg/steelbattalion).

This is an independent preservation effort and is not affiliated with or endorsed by Capcom or Microsoft. Product names and trademarks belong to their respective owners. A Windows release will be considered only after compatibility work and license review.
