# Vulkan NV2A Renderer Reuse Audit

**Scope:** assess whether xemu's Vulkan NV2A/PGRAPH renderer can be adapted to this project's XboxRecomp static-recompilation runtime. This is a source and license review, not legal advice. No xemu source has been copied into this repository or the local XboxRecomp checkout.

**Reviewed revision:** xemu `8fc3208697181253eeb6befe09bda53e4ac3adc9` (2026-10-17). Its Vulkan target contains 17 renderer translation units: `blit.c`, `buffer.c`, `command.c`, `debug.c`, `display.c`, `draw.c`, `glsl.c`, `gpuprops.c`, `image.c`, `instance.c`, `renderer.c`, `reports.c`, `shaders.c`, `surface-compute.c`, `surface.c`, `texture.c`, and `vertex.c`. The [pinned Meson target](https://github.com/xemu-project/xemu/blob/8fc3208697181253eeb6befe09bda53e4ac3adc9/hw/xbox/nv2a/pgraph/vk/meson.build) confirms the source list and links Volk, glslang, VMA, Vulkan, and SPIRV-Reflect.

## License findings

| Component | Reviewed license | Relevance |
| --- | --- | --- |
| xemu Vulkan PGRAPH `.c`/`.h` files | LGPL-2.1-or-later notices | Preserve each notice and the LGPL source/relinking terms if distributed. The xemu repository itself is GPL-2.0; review individual source notices rather than infer every file's license from the repository badge. |
| `hw/xbox/nv2a/pgraph/vsh_regs.h` | GPL-2.0-or-3.0 | Reached through xemu's shader-generation dependencies. A port that retains it is not an LGPL-only reuse. |
| Volk, pinned commit `3ca312a4f38baa63d8006b6905abbeeb89c8087d` | MIT | Dynamic Vulkan function loading. |
| Vulkan Memory Allocator, pinned commit `3aa921224c154a0d2c43912bc88e1c42ce1f7607` | MIT | GPU allocation helper. |
| Vulkan-Headers | Apache-2.0 OR MIT | Vulkan API declarations; select and retain the applicable license notice. |
| SPIRV-Reflect, pinned commit `f3e261fda74ca81b44d1941931c6b7b5fe236d0e` | Apache-2.0 | Shader interface reflection. |
| glslang, pinned commit `e1b562a8bed273a02f30b59b66a5d499793cede5` | BSD-3-Clause core plus additional preprocessing terms | xemu calls `glslang_shader_preprocess`; glslang's license includes a separate 2002 NVIDIA license for preprocessor code. Review that text before bundling or redistribution. |
| XboxRecomp base | MIT, with existing LGPL-2.1-or-later exceptions for `src/apu/` and `src/nv2a/nv2a_regs.h` | Its published [contribution policy](https://github.com/sp00nznet/xboxrecomp/blob/v0.13.1/CONTRIBUTING.md) says not to port GPL code from xemu. Keep any project-specific renderer adapter downstream and isolated; do not submit GPL-derived patches upstream. |

Primary license evidence: [xemu's pinned Vulkan target](https://github.com/xemu-project/xemu/blob/8fc3208697181253eeb6befe09bda53e4ac3adc9/hw/xbox/nv2a/pgraph/vk/meson.build), [GPL shader register header](https://github.com/xemu-project/xemu/blob/8fc3208697181253eeb6befe09bda53e4ac3adc9/hw/xbox/nv2a/pgraph/vsh_regs.h), [glslang license](https://github.com/KhronosGroup/glslang/blob/e1b562a8bed273a02f30b59b66a5d499793cede5/LICENSE.txt), [SPIRV-Reflect license](https://github.com/KhronosGroup/SPIRV-Reflect/blob/f3e261fda74ca81b44d1941931c6b7b5fe236d0e/LICENSE), [Volk license](https://github.com/zeux/volk/blob/3ca312a4f38baa63d8006b6905abbeeb89c8087d/LICENSE.md), and [VMA license](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/blob/3aa921224c154a0d2c43912bc88e1c42ce1f7607/LICENSE.txt). Vulkan-Headers documents its dual license in the [official repository](https://github.com/KhronosGroup/Vulkan-Headers).

## Compatibility and integration consequences

- A combined work containing Apache-2.0 SPIRV-Reflect cannot be distributed under a GPL-2-only choice. A GPL-3-compatible project license or avoiding/replacing that dependency would need evaluation. This repository has no project-wide license selected; this audit does not change it.
- The GPL-2-or-3 shader header can be used under GPL-3 terms, but that does not resolve the NVIDIA preprocessor terms or all QEMU utility/header obligations. Do not treat a GPL-3 choice as cleared until those exact terms and the complete include graph are reviewed.
- The 17 files are not a drop-in library: they use QEMU memory, synchronization, allocation, logging, version, and xemu window/settings interfaces. The target still needs a guest-RAM and pushbuffer adapter for XboxRecomp, as well as a Vulkan presentation surface. No CPU, machine-boot, or full-system emulator code is required or proposed.
- Volk and Vulkan-Headers can support a separately authored Windows Vulkan surface/presentation adapter without importing xemu code. Such a first step would only present the existing guest framebuffer; it would not accelerate NV2A draws or count as title-screen/rendering parity.

## Decision and next step

Vulkan remains the one selected production graphics API. This audit does not reopen D3D11/D3D12. The legal path for reusing xemu's shader/PGRAPH code is not fully cleared, so do not copy or adapt those files yet. Continue with original, project-owned Vulkan host integration using permissively licensed loader/header components, and finish the dependency license decision before any xemu-derived renderer code or distribution license is added. Keep the current software rasterizer as a local correctness reference only.
