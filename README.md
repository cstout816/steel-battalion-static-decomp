<div align="center">

# Steel Battalion for Windows

**A preservation project for the original Xbox game**

**Most project research, code, and documentation are created with ChatGPT Codex, under the direction of project owner Connor Stout (`cstout816`).**

<table>
  <tr>
    <td align="center" width="50%"><img src="docs/images/steel-battalion-controller.jpg" alt="Original Steel Battalion controller and pedals" width="100%"></td>
    <td align="center" width="50%"><img src="docs/images/steel-battalion-project-concept.png" alt="AI-generated concept image of a home simulator control station; not the original controller or game" width="100%"></td>
  </tr>
  <tr>
    <td align="center">Original controller and pedals · photo by John Tregoning, CC BY 2.0</td>
    <td align="center">Project concept artwork · generated with ChatGPT</td>
  </tr>
</table>

### Experimental development · Not ready to play

[What this project is](#the-short-version) · [Current progress](#current-progress) · [Planned setup](#when-a-playable-release-is-ready) · [Project details](#project-details)

</div>

> **Player status:** There is no playable build yet. Development has not reached the title screen. The repository is a work in progress, and the photos above show the original hardware and project concept art—not running game footage.

## The short version

The goal is to make the original *Steel Battalion* run as a Windows application while keeping the original game and its demanding campaign intact. The project uses **static recompilation**: translating the game's original Xbox processor instructions ahead of time, then providing the Xbox services it needs through compatibility code.

This is not an Xbox emulator presented under another name. The project is still early: it has not reached the title screen, and there is no playable download, installer, or one-click setup yet.

> **For players:** There is nothing to install or play from this repository yet. Please check back for a tested release. When one is ready, you will need to provide your own legally obtained game copy. The project will never include or modify your game files.

## Current progress

| Area | Status |
| --- | --- |
| Research and architecture | Complete; static recompilation remains the chosen approach. |
| Initial Windows translation | Built locally; translation gaps mean this is not yet proof of correct game behavior. |
| Game startup | In progress; startup stalled before the title screen. A bounded semaphore-release compatibility path is prepared, but it has not yet been rebuilt or runtime-verified. |
| Playable release and launcher | Not available. |
| Full campaign compatibility | Not verified. No mission-completion or campaign-progression testing has been completed. |

**The latest verified state is not a playable game.** The title screen, graphics, sound, controller input, saves, cinematics, mission completion, and campaign progression remain unverified. We will report compatibility only after the complete campaign has been tested mission by mission.

## When a playable release is ready

The intended setup is designed to be straightforward:

1. Download the project launcher from a reviewed release.
2. Select your own legally obtained original Xbox game image; the launcher will check it and explain any problems.
3. Choose the original Steel Battalion controller or a supported keyboard, mouse, gamepad, or HOTAS setup.
4. Start the game and adjust display or control options as needed.

These steps describe the plan. **The launcher and these features are not available today.** The planned launcher will also offer an optional action to add the game to a user's Steam library as a non-Steam game; Steam will not provide the game or grant a store entitlement.

## What the project is working toward

- **Campaign reliability first:** test every mission, save, cinematic, audio event, controller function, and progression step.
- **Full controller support:** preserve the original Steel Battalion controller and indicator lights where hardware permits, while making keyboard, mouse, modern controllers, HOTAS, and custom HID devices accessible.
- **A simple Windows launcher:** check a user-supplied game image, offer settings and diagnostics, and optionally add the game to Steam.
- **Careful modernization:** offer original and enhanced graphics settings, widescreen and high-resolution output, and frame-rate options that preserve game timing.
- **Future research:** investigate *Steel Battalion: Line of Contact* separately and check compatibility with Insignia, XLink Kai, and existing community sessions before considering multiplayer changes.

These are goals, not features of a released application. Experimental options will remain separate from the original experience.

## Who is building this?

This is **primarily a ChatGPT Codex project**. ChatGPT Codex has produced the majority of the research, documentation, code, and development work in this repository. Project owner Connor Stout (`cstout816`) sets priorities, makes architecture and release decisions, provides the legally obtained game copy for private local analysis, and directs verification. This authorship is stated plainly so visitors can understand how the project is being made. Progress notes distinguish work that was written or inspected from features that have actually been verified.

## Project details

The selected foundation is [sp00nznet/xboxrecomp](https://github.com/sp00nznet/xboxrecomp), which translates Xbox x86 code ahead of time. Its documented Windows graphics path uses Direct3D 11; the requested Direct3D 12 path is not implemented. Xbox kernel, graphics, audio, filesystem, and controller behavior still need compatibility work. The project will not quietly substitute ordinary emulation for the selected static-recompilation architecture.

Third-party components and licenses are being reviewed before a distribution license or Windows release is chosen. No proprietary Xbox SDK files are intended for inclusion.

## Your game files stay yours

This repository contains project code, configuration, and documentation only. **It does not include an Xbox ISO, XBE executable, extracted game code, textures, audio, cinematics, or other game files.** Users must supply their own legally obtained game copy. The original image will not be changed or redistributed.

## Follow the work

- [Project status and architecture notes](docs/milestone-1-research.md) — research, decisions, and verification records.
- [Community compatibility and preservation plan](docs/community-compatibility-preservation.md) — controller, campaign, graphics, and future multiplayer priorities.
- [Image credits and licenses](docs/ATTRIBUTIONS.md).
- [Steel Battalion community on Reddit](https://www.reddit.com/r/steelbattaliononline/).
- [Steel Battalion community Discord](https://discord.gg/steelbattalion).
- [ChatGPT Codex](https://openai.com/codex/).

The project is not affiliated with or endorsed by Capcom, Microsoft, or the image creators. Product names and trademarks belong to their respective owners. A Windows release will be considered only after compatibility work, license review, and project-owner approval.

For a no-jargon explanation of what players can expect, see the [player guide](docs/PLAYER_GUIDE.md). The repository will be updated as meaningful work is completed; routine changes will be pushed to GitHub so the public project record stays current.
