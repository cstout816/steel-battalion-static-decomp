# Graphics Backend Decision

**Fixed target: Vulkan.** The project has one graphics-backend decision and no runtime backend selector. A project-owned Vulkan pipeline now handles one exact fullscreen splash-logo draw at the observed `nv2a_pb_exec` handoff; other guest draws continue through the CPU reference rasterizer. The presenter still uploads the guest framebuffer for display, and the new draw is read back into guest memory. The first bounded runtime run confirmed submission but did not verify image parity and stalled after three flips. XboxRecomp's inherited D3D8-to-D3D11 and PGRAPH-to-D3D11 code remain to be migrated where title traces show they are needed; neither is a selected renderer. Keep the static-recompilation CPU, kernel, filesystem, audio, and input architecture; this graphics decision does not introduce full-system emulation.

## Why Vulkan

Vulkan is the fixed project choice. No matched Steel Battalion capture measures performance against another API. The current exact splash slice is project-owned and does not reuse xemu renderer source. xemu remains a behavior and architecture reference; its Vulkan renderer is not a drop-in library, and shader license constraints prevent treating the whole path as cleared for reuse. Overall performance and full-frame parity remain unverified.

The RTX 4070 SUPER exposes the Vulkan features the inspected xemu renderer requires. That verifies device capability only; it does not verify that the port initializes, renders the game correctly, or reaches the title screen.

## Implementation boundary

- Expand the project-owned Vulkan guest renderer from the exact splash slice to decoded clears and general NV2A/PGRAPH draw state.
- Reuse only the GPU subsystem and individually license-reviewed files. Do not bring in xemu's CPU, kernel, machine boot, or full-system emulator loop.
- Keep the statically recompiled x86 game and existing Xbox runtime architecture.
- The pushbuffer executor sends one exact textured splash quad through Vulkan, then reads the target back into guest memory. Other draws still use the CPU reference renderer, and the presenter displays the copied guest framebuffer.
- The active Windows Xbox D3D8 compatibility layer is backed by D3D11, including shader compilation and combiner calls. This is existing runtime behavior, not the selected direction. Replace it as part of the Vulkan migration; do not add an API selector or another renderer choice.
- The D3D12 NV2A prototype is disabled in the active project build. Its old patches are historical records only.
- Keep the selected Vulkan direction through initial boot and campaign play. The software rasterizer remains a temporary diagnostic/reference and unsupported-draw fallback.

## Current state and constraints

Milestone 3, Boot and Compatibility, remains incomplete. The Vulkan presenter selects the RTX 4070 SUPER and presents a 640x480 image. A narrow Vulkan textured-logo pipeline was created and submitted during startup, but a bounded run stopped at three flips with the guest clock stalled. No framebuffer capture was taken, so correct logo pixels and later title progression are unverified. General NV2A rendering, title-screen boot, audio output, and physical Steel Battalion controller behavior also remain unverified.

The xemu renderer is not a drop-in library. Its PGRAPH state and renderer use QEMU services and xemu-specific data structures. A port needs a host adapter for guest RAM, pushbuffer state, surfaces, textures, shader translation, synchronization, and presentation. Source files have differing license notices; audit every reused file and dependency before integration or distribution. No distribution license has been selected. Do not install system-wide Vulkan tooling; use a project-local, reproducible dependency setup after its license review.

The file-by-file xemu renderer and dependency findings are in [VULKAN_REUSE_AUDIT.md](VULKAN_REUSE_AUDIT.md). The source-level implementation map is in [VULKAN_MIGRATION_MAP.md](VULKAN_MIGRATION_MAP.md). No xemu renderer code has been copied; its shader/preprocessor dependency and the project-wide license path remain under review.

## Evidence

- [xemu Vulkan NV2A renderer and active work](https://github.com/xemu-project/xemu/tree/master/hw/xbox/nv2a/pgraph/vk)
- [xemu's Vulkan/OpenGL performance issue](https://github.com/xemu-project/xemu/issues/1838), which shows results vary by game and hardware.
- [XboxRecomp](https://github.com/sp00nznet/xboxrecomp), the selected static-recompilation foundation. Its Windows D3D8 compatibility library is D3D11-backed; the Steel Battalion pushbuffer executor is a separate CPU-raster path.

## Decision history

Earlier D3D11 and D3D12 experiments are retained in dated engineering history. The project decision is Vulkan, with no backend switching. Current source inspection confirms the Windows game graphics path has not migrated yet; work remains to route guest graphics through Vulkan.
