<div align="center">

# Steel Battalion: Native Windows Preservation Project

**Original Xbox · Windows 10/11 · Static recompilation research**

<img src="docs/images/steel-battalion-controller.jpg" alt="The original Steel Battalion controller and foot pedals" width="760">

*The original Steel Battalion controller and pedals. Photo by John Tregoning, CC BY 2.0; resized for this page. See [image credits](docs/ATTRIBUTIONS.md).*

**Project status: Experimental — there is no playable release yet.**

</div>

This project is working toward a Windows version of *Steel Battalion* for the original Xbox. The long-term goal is to translate the game's original processor instructions ahead of time and provide the Xbox services it expects through Windows compatibility code.

> **In plain terms:** We are trying to make the game run as a Windows app while preserving its original behavior. We are not presenting ordinary Xbox emulation as static recompilation. Getting the game to start is still an unsolved step, and a complete campaign has not been tested.

## Is it ready to play?

**No.** The project is still in early development. A local Windows program has entered the game's code, but startup stalled before the title screen while graphics hardware services were being initialized. The latest code translation adds a missing interrupt routine, but that update has not yet been rebuilt or verified. There is no installer or public game build to download.

We will not call the game compatible based on a title screen or a single mission. The goal is to verify the entire campaign, including mission completion and progression, saves, cinematics, sound, controls, and stable performance.

## What is being built

- A native Windows x64 application based on **static recompilation** and Xbox compatibility layers.
- A simple launcher for choosing and checking your own game image, changing settings, viewing logs, and optionally adding the app to Steam as a non-Steam game.
- Support for the original Steel Battalion controller, with accessible keyboard, mouse, gamepad, and HOTAS control options.
- Original and optional enhanced display settings, while preserving the game's effects and mechanics.
- Later investigation of *Steel Battalion: Line of Contact* as a separate game and compatibility profile. Any multiplayer support must be checked against existing Insignia, XLink Kai, and community sessions first.

These are project goals, not features available in a playable release today. See the [community compatibility and preservation plan](docs/community-compatibility-preservation.md) for the priorities and full-campaign test checklist.

## Development progress

- **Research and architecture:** complete. The project selected [sp00nznet/xboxrecomp](https://github.com/sp00nznet/xboxrecomp) for its ahead-of-time x86 translation and Xbox runtime components.
- **Initial translation and Windows build:** completed locally. Thousands of game functions have been translated to C and a Windows x64 executable was built. Some game instructions and function targets remain untranslated or approximated, so this does not prove correct behavior.
- **Game startup:** in progress. The current investigation is focused on Xbox graphics initialization and interrupt handling. The title screen, sound, input, and campaign remain unverified.
- **Launcher, controller editor, graphics options, and campaign testing:** not implemented yet.

The runtime currently documents a Direct3D 11 graphics path. The requested Direct3D 12 target is not met. The work will not silently switch to an emulator or describe emulation as recompilation.

## Who is making this?

**This is primarily a ChatGPT Codex project.** Most of the research, documentation, code, and development work in this repository is being produced with ChatGPT Codex, an AI coding agent from OpenAI. Project owner **Connor Stout (`cstout816`)** sets the goals, supplies the legally obtained game copy used for local analysis, makes project decisions, and directs verification and release approval. AI-generated work is recorded and checked as the project advances; results are reported only when they have actually been verified.

## What you will need when a release is ready

You will need to provide your own legally obtained copy of the original Xbox game. **This repository does not include the ISO, executable, extracted game files, generated game code, textures, sound, or cinematics.** We will not alter or redistribute your game image.

The launcher and one-click setup are planned but are not available yet. For now, there is no supported installation or play guide.

## Updates and useful links

- [Development and architecture notes](docs/milestone-1-research.md)
- [Community compatibility and preservation plan](docs/community-compatibility-preservation.md)
- [Steel Battalion community on Reddit](https://www.reddit.com/r/steelbattaliononline/)
- [Steel Battalion community Discord](https://discord.gg/steelbattalion)
- [ChatGPT Codex](https://openai.com/codex/)

The project owner will publish a Windows release only after it is ready and reviewed. Do not download game files from this repository or from unofficial mirrors.

## Photo credits

The controller photograph above is credited to **John Tregoning** and used under **Creative Commons Attribution 2.0**. It shows the controller and pedals, not the game software. See [ATTRIBUTIONS.md](docs/ATTRIBUTIONS.md) for the source and license details.
