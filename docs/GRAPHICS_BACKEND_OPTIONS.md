# Graphics Backend Decision

**Fixed target: Vulkan.** The project has one graphics-backend decision and no runtime backend selector. The migration is incomplete: the current Windows guest-rendering path still uses XboxRecomp's D3D8-to-D3D11 compatibility layer, while the project-owned Vulkan module only uploads and presents a copied framebuffer. Vulkan does not yet render NV2A scenes or replace the D3D11-backed XDK graphics calls. Complete that migration before describing the game runtime as Vulkan-rendered. Keep the XboxRecomp static-recompilation CPU, kernel, filesystem, audio, and input architecture; this graphics decision does not introduce full-system emulation.

## Why Vulkan

Vulkan is the fixed project choice. No matched Steel Battalion capture measures its performance against another API. The implementation path is to adapt a license-compatible NV2A/PGRAPH renderer and replace the Windows D3D8 compatibility backend. xemu is a behavior and architecture reference; its Vulkan renderer is not a drop-in library, and shader license constraints prevent treating the whole path as cleared for reuse. Performance and frame parity remain unverified.

The RTX 4070 SUPER exposes the Vulkan features the inspected xemu renderer requires. That verifies device capability only; it does not verify that the port initializes, renders the game correctly, or reaches the title screen.

## Implementation boundary

- Adapt the xemu NV2A/PGRAPH Vulkan graphics subsystem to the XboxRecomp guest-memory and pushbuffer interfaces.
- Reuse only the GPU subsystem and individually license-reviewed files. Do not bring in xemu's CPU, kernel, machine boot, or full-system emulator loop.
- Keep the statically recompiled x86 game and existing Xbox runtime architecture.
- The pushbuffer executor still rasterizes on the CPU; the Vulkan presenter only displays its copied framebuffer.
- The active Windows Xbox D3D8 compatibility layer is backed by D3D11, including shader compilation and combiner calls. This is existing runtime behavior, not the selected direction. Replace it as part of the Vulkan migration; do not add an API selector or another renderer choice.
- The D3D12 NV2A prototype is disabled in the active project build. Its old patches are historical records only.
- Keep the selected Vulkan direction through initial boot and campaign play. The current software rasterizer may remain a temporary diagnostic/reference path until Vulkan rendering is verified.

## Current state and constraints

Milestone 3, Boot and Compatibility, remains incomplete. The clean software-rendered build advances through the Steel Battalion logo sequence at about 0.4 guest FPS; the latest captured frame still shows CAPCOM. A project-owned Vulkan presenter selects the RTX 4070 SUPER, creates a 640x480 swapchain, and presents a copied guest framebuffer. This verifies Vulkan presentation plumbing only. Current Windows game graphics still pass through D3D11, and Vulkan NV2A rendering, correct game pixels, and title-screen boot remain unverified. Audio output and physical Steel Battalion controller behavior also remain unverified.

The xemu renderer is not a drop-in library. Its PGRAPH state and renderer use QEMU services and xemu-specific data structures. A port needs a host adapter for guest RAM, pushbuffer state, surfaces, textures, shader translation, synchronization, and presentation. Source files have differing license notices; audit every reused file and dependency before integration or distribution. No distribution license has been selected. Do not install system-wide Vulkan tooling; use a project-local, reproducible dependency setup after its license review.

The file-by-file xemu renderer and dependency findings are in [VULKAN_REUSE_AUDIT.md](VULKAN_REUSE_AUDIT.md). No xemu renderer code has been copied; its shader/preprocessor dependency and the project-wide license path remain under review.

## Evidence

- [xemu Vulkan NV2A renderer and active work](https://github.com/xemu-project/xemu/tree/master/hw/xbox/nv2a/pgraph/vk)
- [xemu's Vulkan/OpenGL performance issue](https://github.com/xemu-project/xemu/issues/1838), which shows results vary by game and hardware.
- [XboxRecomp](https://github.com/sp00nznet/xboxrecomp), the selected static-recompilation foundation. Its current Windows D3D8 compatibility layer uses D3D11; replacing that path is required for the selected Vulkan direction.

## Decision history

Earlier D3D11 and D3D12 experiments are retained in dated engineering history. The project decision is Vulkan, with no backend switching. Current source inspection confirms the Windows game graphics path has not migrated yet; work remains to route guest graphics through Vulkan.
