# Player guide

## Can I play it now?

**No. This project does not have a playable Windows release yet.** It has not reached the game's title screen, and there is no installer or launcher to download. The team is working on getting the original game to start reliably before adding modern display or controller options.

Please do not download an unofficial build or expect an ISO to be included here. The project will never distribute the game, its disc image, or its extracted files.

## What is being made?

The goal is a Windows application that translates the original Xbox game ahead of time and supplies the Xbox services it needs. This approach is called **static recompilation**. It is not a separate Xbox emulator bundled under a different name.

Most of the project's research, code, and documentation have been produced with ChatGPT Codex. Connor Stout (`cstout816`) maintains the project. Progress reports distinguish work that has been written or built from game behavior that has actually been tested.

## What will I need when a tested release is available?

The planned launcher will guide players through setup. The current plan is:

1. Use a supported 64-bit Windows 10 or Windows 11 PC.
2. Provide your own legally obtained original Xbox copy of *Steel Battalion* in a supported image format.
3. Choose your original Steel Battalion controller, if available, or a supported keyboard, mouse, gamepad, HOTAS, or custom controller profile.
4. Adjust the display and control settings, then start the game from the launcher.

These are planned capabilities, not available features. The original Steel Battalion controller's inputs and indicator lights are a priority, but hardware and adapter support still needs to be implemented and verified. The launcher is also planned to offer an optional shortcut that adds the game to Steam as a non-Steam game; it will not add a Steam store license.

## How will compatibility be checked?

Reaching the title screen will not count as a playable release. The campaign needs mission-by-mission checks for loading, stability, cinematics, sound, controls, saves, frame pacing, completion, and progression. Controller support and higher resolutions will be reported as verified only after they have been tested.

## Follow progress

- [Project overview and current status](../README.md)
- [Research and architecture notes](milestone-1-research.md)
- [Community compatibility and preservation plan](community-compatibility-preservation.md)
- [Image credits](ATTRIBUTIONS.md)
- [Detailed progress tracker](DEVELOPMENT_STATUS.md)
- [Steel Battalion Online community](https://www.reddit.com/r/steelbattaliononline/)
- [Project discussions on Discord](https://discord.gg/steelbattalion)
