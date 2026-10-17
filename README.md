# Steel Battalion Static Recompilation

A Windows x64 project to investigate and, if technically feasible, statically recompile the original Xbox version of *Steel Battalion* (2001) into a native application. The goal is ahead-of-time translation of the game's x86 code with an Xbox compatibility runtime. Full-system emulation is not the project's execution architecture.

This project is at the research and architecture stage. No game executable has been analyzed, no game has been recompiled, and no boot or compatibility result is claimed. Runtime and graphics architecture selection remains subject to the project's architecture review.

## Game files

Users must supply their own legally obtained game files. This repository does not contain or distribute game images, XBE files, extracted assets, generated game code, or proprietary Xbox SDK files. Keep any such files local and out of version control.

## Requirements under evaluation

- Native Windows x64 application using genuine static recompilation.
- Launcher with ISO selection and validation, settings, logs, and an option to add the installed game to the user's Steam library.
- Support for the original Steel Battalion controller, alongside the planned modern input options. Exact hardware and keyboard/mouse mappings remain to be investigated.
- Correct baseline behavior before graphics or frame-rate enhancements.

See `C:\Project\PROJECT_MEMORY.md` for current research, limitations, and next steps.
