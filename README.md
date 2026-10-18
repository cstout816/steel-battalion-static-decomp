<div align="center">

# Steel Battalion for Windows

**A community preservation project exploring static recompilation of the original Xbox game**

<a href="https://www.purexbox.com/games/xbox/steel_battalion">
  <img src="https://images.purexbox.com/screenshots/137992/large.jpg" alt="Original Xbox Steel Battalion gameplay screenshot, screenshot 2 of 20 in the Pure Xbox gallery" width="100%" />
</a>

<sub>Original Xbox gameplay screenshot · <a href="https://www.purexbox.com/games/xbox/steel_battalion">Pure Xbox screenshot gallery</a></sub>

### Experimental development · No playable build yet

[Can I play it?](docs/PLAYER_GUIDE.md) · [Project progress](docs/DEVELOPMENT_STATUS.md) · [Community and controller plans](docs/community-compatibility-preservation.md) · [Image credits](docs/ATTRIBUTIONS.md)

</div>

> **For players:** there is no game to download yet. The project has not reached the title screen, and there is no installer or launcher. Please do not download unofficial builds or send game files.

## What this project is

The goal is to translate the original Xbox version of *Steel Battalion* (2002) ahead of time into a Windows application and recreate the Xbox services it needs. This is called **static recompilation**. The project is not an emulator packaged under another name.

The project is still experimental. The translated Windows program builds, but it has not reached the title screen. Graphics, sound, controls, saving, and campaign play are not verified. The tracker records observed engineering work separately from features players can use.

## See the game and its controller

These are real photographs and screenshots from the original game and hardware. Gameplay images are shown from the published Pure Xbox gallery and are **not stored in this repository**. Select any gameplay image to visit the source. This project has not captured its own gameplay yet because it does not boot to the title screen.

<table>
  <tr>
    <td align="center" width="33%">
      <a href="https://www.mobygames.com/game/7805/steel-battalion/promo/group-116838/image-907173/">
        <img src="https://cdn.mobygames.com/promos/11408273-steel-battalion-screenshot.jpg" alt="Original Steel Battalion cockpit view facing an enemy vertical tank" width="100%" />
      </a>
      <br /><sub>Original Xbox gameplay · MobyGames</sub>
    </td>
    <td align="center" width="33%">
      <a href="https://images.purexbox.com/screenshots/137993/large.jpg">
        <img src="https://images.purexbox.com/screenshots/137993/large.jpg" alt="Original Xbox Steel Battalion gameplay screenshot 3 of 20" width="100%" />
      </a>
      <br /><sub>Original Xbox gameplay · Pure Xbox</sub>
    </td>
    <td align="center" width="33%">
      <a href="https://images.purexbox.com/screenshots/137994/large.jpg">
        <img src="https://images.purexbox.com/screenshots/137994/large.jpg" alt="Original Xbox Steel Battalion gameplay screenshot 4 of 20" width="100%" />
      </a>
      <br /><sub>Original Xbox gameplay · Pure Xbox</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="33%">
      <a href="https://images.purexbox.com/screenshots/137995/large.jpg">
        <img src="https://images.purexbox.com/screenshots/137995/large.jpg" alt="Original Xbox Steel Battalion gameplay screenshot 5 of 20" width="100%" />
      </a>
      <br /><sub>Original Xbox gameplay · Pure Xbox</sub>
    </td>
    <td align="center" width="33%">
      <a href="https://images.purexbox.com/screenshots/137981/large.jpg">
        <img src="https://images.purexbox.com/screenshots/137981/large.jpg" alt="Original Xbox Steel Battalion gameplay screenshot 6 of 20" width="100%" />
      </a>
      <br /><sub>Original Xbox gameplay · Pure Xbox</sub>
    </td>
    <td align="center" width="33%">
      <a href="https://images.purexbox.com/screenshots/137982/large.jpg">
        <img src="https://images.purexbox.com/screenshots/137982/large.jpg" alt="Original Xbox Steel Battalion gameplay screenshot 7 of 20" width="100%" />
      </a>
      <br /><sub>Original Xbox gameplay · Pure Xbox</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <img src="docs/images/steel-battalion-controller.jpg" alt="The original Steel Battalion controller, dual joysticks, and foot pedals" width="100%" />
      <br /><sub>Original controller and pedals · John Tregoning · CC BY 2.0</sub>
    </td>
    <td align="center" width="50%">
      <img src="docs/images/steel-battalion-box.jpg" alt="Original Steel Battalion Xbox game package" width="100%" />
      <br /><sub>Original game package · Xboxsupervisioncreator · CC BY-SA 3.0</sub>
    </td>
  </tr>
</table>

Browse the [Steel Battalion screenshot gallery at Pure Xbox](https://www.purexbox.com/games/xbox/steel_battalion) for all 20 views. Image sources, creator credits, and licenses are listed in [Image credits](docs/ATTRIBUTIONS.md). No AI-generated photos or mockup images are used.

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
| Boot and compatibility | [####----------------] 2/5 | Pushbuffer execution and GP/EP reset release observed; real DSP startup and title screen remain blocked. |
| Campaign, controller, launcher | [--------------------] | Not yet verified or available. |

These bars describe engineering work, not playable features or campaign completion. See the [detailed tracker](docs/DEVELOPMENT_STATUS.md) for field-by-field evidence.

## Who makes this?

Most of the research, code, and documentation in this repository have been produced with **ChatGPT Codex**. GitHub maintainer and project contact: [@cstout816](https://github.com/cstout816). This is a community preservation effort; reported progress separates completed engineering work from game behavior that has actually been verified.

## Technical approach

The current foundation is [sp00nznet/xboxrecomp](https://github.com/sp00nznet/xboxrecomp), which translates Xbox x86 code ahead of time. The documented Windows graphics path uses Direct3D 11; the requested Direct3D 12 path is not implemented. Xbox kernel, graphics, audio, filesystem, and controller behavior still need compatibility work. The project will not quietly replace static recompilation with ordinary emulation.

The work prioritizes campaign reliability and the original Steel Battalion controller before visual enhancements. See the [community compatibility and preservation plan](docs/community-compatibility-preservation.md) for planned controller support, campaign checks, accessibility, and future Line of Contact research.

This independent project is not affiliated with or endorsed by Capcom or Microsoft. Product names and trademarks belong to their respective owners. A Windows release will be considered only after compatibility work and license review.
