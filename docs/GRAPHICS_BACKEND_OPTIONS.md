# Graphics Backend Decision

**Final choice: Vulkan is the sole host graphics backend for this project.** This applies to the NV2A pushbuffer renderer and the graphics compatibility layer as it is brought onto the selected backend. Do not develop or switch to D3D11 or D3D12 as alternate production renderers. Keep the existing XboxRecomp static-recompilation CPU, kernel, filesystem, audio, and input architecture; this decision does not introduce full-system emulation.

## Why Vulkan

No matched Steel Battalion capture has measured Vulkan against D3D12, so this is not a claim that Vulkan is inherently faster. It is the firm project choice based on the best attainable performance path: xemu provides the most complete existing GPU-backed NV2A/PGRAPH implementation to adapt, while the local D3D12 work only covered two narrow splash passes, used synchronous full-surface transfers, and showed no frame-rate improvement. xemu's Vulkan/OpenGL reports are mixed across games, so the title still needs measured performance and frame-parity validation.

The RTX 4070 SUPER exposes the Vulkan features the inspected xemu renderer requires. That verifies device capability only; it does not verify that the port initializes, renders the game correctly, or reaches the title screen.

## Implementation boundary

- Adapt the xemu NV2A/PGRAPH Vulkan graphics subsystem to the XboxRecomp guest-memory and pushbuffer interfaces.
- Reuse only the GPU subsystem and individually license-reviewed files. Do not bring in xemu's CPU, kernel, machine boot, or full-system emulator loop.
- Keep the statically recompiled x86 game and existing Xbox runtime architecture.
- Use the software rasterizer only as a local correctness reference during bring-up. It is not a fallback or alternate production backend.
- Retire the earlier D3D11/D3D12 renderer experiments from the active path. Existing D3D12 experiment patches remain isolated historical records and must not be applied to the production build.
- Keep one Vulkan renderer path from initial boot through campaign play. Do not add API selection or backend switching.

## Current state and constraints

Milestone 3, Boot and Compatibility, remains incomplete. The clean software-rendered build advances through the Steel Battalion logo sequence at about 0.4 guest FPS; the latest captured frame still shows CAPCOM. No Vulkan renderer code has been copied or integrated, no title-screen boot is verified, and audio output and physical Steel Battalion controller behavior remain unverified.

The xemu renderer is not a drop-in library. Its PGRAPH state and renderer use QEMU services and xemu-specific data structures. A port needs a host adapter for guest RAM, pushbuffer state, surfaces, textures, shader translation, synchronization, and presentation. Source files have differing license notices; audit every reused file and dependency before integration or distribution. No distribution license has been selected. Do not install system-wide Vulkan tooling; use a project-local, reproducible dependency setup after its license review.

The file-by-file xemu renderer and dependency findings are in [VULKAN_REUSE_AUDIT.md](VULKAN_REUSE_AUDIT.md). No xemu renderer code has been copied; its shader/preprocessor dependency and the project-wide license path remain under review.

## Evidence

- [xemu Vulkan NV2A renderer and active work](https://github.com/xemu-project/xemu/tree/master/hw/xbox/nv2a/pgraph/vk)
- [xemu's Vulkan/OpenGL performance issue](https://github.com/xemu-project/xemu/issues/1838), which shows results vary by game and hardware.
- [XboxRecomp](https://github.com/sp00nznet/xboxrecomp), the selected static-recompilation foundation; its existing Windows path uses D3D11 and is not the selected production renderer.
- Local matched splash runs: the narrow D3D12 prototype produced no measurable FPS gain; software output and the two-pass prototype capture matched for the sampled frame. Neither run reached the title screen.

## Decision history

D3D11 and D3D12 were investigated as interim or native alternatives. They are not current choices. On 2026-10-18 the project settled on Vulkan for the sole production graphics path based on renderer maturity and attainable title support, and the user's subsequent instruction made the single-backend requirement explicit. Future backend reconsideration would require new measured evidence and a direct user request; absent that, implementation stays on Vulkan.
