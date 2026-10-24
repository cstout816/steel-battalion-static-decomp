# Community Debugging Brief: Steel Battalion AOT DCF4 Stall

This is a sanitized, copyable question for the original Xbox recompilation community. It shares diagnostic addresses and counters only; it does not include the game executable, save files, assets, or full private logs.

## Copyable question

> I am statically recompiling the original Xbox version of Steel Battalion with the current `sp00nznet/xboxrecomp`-based AOT runtime. The guest code remains ahead-of-time translated; this is not an emulator. I am keeping guest fence behavior unchanged and am not re-porting the small-triangle batch rasterizer already present in local commit `1ea1871`.
>
> On a saved-pilot route, the framebuffer reaches the Campaign menu, then stops advancing. A previously sampled guest stack places the main thread in `D3DDevice_Swap` → `D3D_BlockOnTime` → `KeWaitForSingleObject`. In the synchronized trace, DCF4 callback #294 is the last callback (`arg=0x03600021`, branch index 1 / `0x00216EC9`). The preceding `arg=0x5` callback selected index 5 / `0x0021701E`, but the event was subsequently reset. After that, the event stays clear and no callback arrives.
>
> At the stall, the guest frame is `0xEC`, counter `0x403`, wait target `0x3F7`, fence mirror `0x3FF`; semaphore reached `0x3FF`, and DMA PUT=GET=`0xBEA0`. Raster work ceased several hours earlier; its final sampled window was 113 batches / 226 triangles, 44.81 ms batch wall, 146.90 ms summed worker-active time on four workers. Queue depth was not instrumented. No `NOW LOADING` screen or mission frame appears in this run.
>
> I have not changed runtime behavior. What exact guest-side or NV2A publication state would you instrument next to distinguish a marker not being published from a published marker not being consumed? In particular, are there known expectations around `D3D_BlockOnTime`'s marker write (`0x40100, 5`), PFB flush completion, `sub_00211C70` / USER_DMA_PUT, and the branch-5 DCF4 event callback? Please point to source locations, known-good traces, or a minimal instrumentation strategy. I am looking for a diagnosis that preserves guest synchronization semantics and stays on the AOT path.

## Relevant public references

- [sp00nznet/xboxrecomp](https://github.com/sp00nznet/xboxrecomp) — current upstream AOT toolkit. Its October 2026 v0.16.0 notes contain disassembler, x86 stack-width, and relative save-path fixes; they do not describe this DCF4/NV2A handoff.
- [TGP482/XboxXBERecomp](https://github.com/TGP482/XboxXBERecomp) — another MIT-licensed original Xbox AOT toolkit with a D3D12 runtime. Useful for comparison, not a reason to switch this project without evidence.
- [quizerno/Xemu-SB-VK](https://github.com/quizerno/Xemu-SB-VK) — Steel Battalion-focused Xemu fork. It can inform controller and route expectations, but it is an emulator and cannot provide a drop-in AOT fix.
- [r/SteelBattalionOnline](https://www.reddit.com/r/steelbattaliononline/) — community context and route reports.

## Sharing boundary

Do not attach the ISO, XBE, extracted assets, or save data. If logs are shared, redact local usernames and paths, retain only the synchronized diagnostic window, and label the run accurately as Campaign-menu state rather than a mission-loading failure.

## Separate title-input question (2026-10-24)

Keep this issue separate from the DCF4 wait above. A later diagnostic clone stayed at the title prompt. The live A input reached the XID report and USB DMA buffer (`report[2]` changed 0→1→0); title input query #79 returned 1 once, while later queries returned 0. The framebuffer remained at the title prompt. That run used `saves-m3-known-save-copy-20261023`, whose content was not verified against the known-good save, so it is not a valid saved-pilot or mission-loading reproduction.

### Copyable question for the XboxRecomp community

> On an original-Xbox Steel Battalion AOT recompilation using the XboxRecomp XPP-seeded path, my diagnostic clone is displaying the title prompt. A screen-gated Main Weapon/A input is visible in the host XID report and the guest USB DMA report buffer (byte 2 toggles 0→1→0). The title-input trace reports one positive query (`sub_000C8050` result 1), then later queries return 0, but the framebuffer does not leave the title prompt. I have not verified the save contents for this run, so it is not evidence about the saved-pilot loading stall.
>
> What would you trace next to identify the title/menu input consumer and its expected edge/hold semantics? In particular, which caller/control-flow branch should be logged around `sub_000C8050`, and what guest state confirms that the prompt accepted Main Weapon? Please point to existing XboxRecomp input diagnostics or source locations. I want to diagnose before changing input behavior, retain static AOT translation, and keep this separate from the Campaign-screen DCF4 wait and the older `NOW LOADING` capture.

## Community findings

- The XboxRecomp release page now lists v0.16.0, while this project's local dependency is pinned to v0.13.1. The newer release includes disassembler/function-discovery and x86-width fixes, including functions behind NOP padding; it does not claim a Steel Battalion DCF4 or title-input fix. Treat it as a targeted generator comparison candidate, not an automatic runtime upgrade.
- The Steel Battalion community's Xemu status discussion reports keyboard mapping and reaching the first level in an emulator build. This is useful for screen/route and controller expectations only; it is not verification of this AOT executable and supplies no direct fix for the DCF4 path.
- The XboxRecomp maintainer's recomp Discord is the best public venue for the two sanitized, separate questions above. Do not post local logs, save data, ISO/XBE files, usernames, or filesystem paths.
