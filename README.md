# Steel Battalion Static Recompilation

A Windows x64 project to investigate and, if technically feasible, statically recompile the original Xbox version of *Steel Battalion* (2001) into a native application. The intended execution model is ahead-of-time translation of the game's x86 code plus Xbox compatibility layers. Full-system emulation is not the project's execution architecture.

Milestone 1 research has confirmed the user's XBE is a retail XBEH for *STEEL BATTALION* (title ID `0x43430002`, XDK build 4627) and mapped its 78 sections and 123 kernel imports. Executable function boundaries and control flow have not yet been generated. No game executable has been recompiled, and no boot, rendering, audio, or input result is claimed. Static-recompiler and graphics-runtime selection remains subject to the architecture approval gate.

## Game files

Users must supply their own legally obtained game files. This repository does not contain or distribute game images, XBE files, extracted assets, generated game code, or proprietary Xbox SDK files. Keep any such files local and out of version control.

## Requirements under evaluation

- Native Windows x64 application using genuine static recompilation.
- Launcher with ISO selection and validation, settings, logs, and an opt-in option to add the installed game to the user's Steam library.
- Support for the original Steel Battalion controller, alongside modern input options. The original device requires a dedicated input path and Windows driver configuration; implementation and physical-device testing remain outstanding.
- Correct baseline behavior before graphics or frame-rate enhancements.

See `C:\Project\PROJECT_MEMORY.md` for current research, limitations, and next steps.
