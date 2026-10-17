# Steel Battalion Static Recompilation

A Windows x64 project to investigate and, if technically feasible, statically recompile the original Xbox version of *Steel Battalion* (2001) into a native application. The intended execution model is ahead-of-time translation of the game's x86 code plus Xbox compatibility layers. Full-system emulation is not the project's execution architecture.

Milestone 1 identified the user's retail XBEH for *STEEL BATTALION* (title ID `0x43430002`, XDK build 4627), with 78 sections and 123 kernel imports. The user selected **sp00nznet/xboxrecomp** for static recompilation. Milestone 2 produced a local Windows x64 executable from 9,125 translated functions. The artifact and all game-derived C remain ignored and are not distributed. The executable has not been run; boot, rendering, audio, and input are unverified. xboxrecomp's documented Windows renderer uses D3D11, so the D3D12 target remains unmet.

## Game files

Users must supply their own legally obtained game files. This repository does not contain or distribute game images, XBE files, extracted assets, generated game code, or proprietary Xbox SDK files. Keep any such files local and out of version control.

## Requirements under evaluation

- Native Windows x64 application using genuine static recompilation.
- Launcher with ISO selection and validation, settings, logs, and an opt-in option to add the installed game to the user's Steam library.
- Support for the original Steel Battalion controller, alongside modern input options. The original device requires a dedicated input path and Windows driver configuration; implementation and physical-device testing remain outstanding.
- Correct baseline behavior before graphics or frame-rate enhancements.

See `C:\Project\PROJECT_MEMORY.md` for current research, limitations, and next steps.
