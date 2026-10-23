# NV2A raster batch regression

This test was adapted from XboxRecomp commit `0f69fa7` (MIT-licensed; attribution and license notice are in the source and `LICENSES/XboxRecomp-MIT.txt`). It submits many overlapping pixel-aligned quads through one pushbuffer batch, then checks every framebuffer pixel against the expected last-draw-wins result. This catches missing row ownership and out-of-order overlapping triangles.

The harness compiles the pinned XboxRecomp runtime source, so configure it after preparing the dependency checkout with the project's documented patches:

```powershell
cmake -S tests/nv2a_raster_batch -B build/nv2a-raster-batch -DXBOXRECOMP_SOURCE_DIR=local-tools/xboxrecomp
cmake --build build/nv2a-raster-batch --config Release
ctest --test-dir build/nv2a-raster-batch -C Release --output-on-failure
```

The test defaults to four threads. Run the built executable with `RECOMP_RASTER_THREADS=1`, `4`, and `8` to check correctness at each setting. `RECOMP_RASTER_TEST_REPEATS` repeats the same batch for timing comparisons; this synthetic workload is for relative scaling only, not a proxy for the full game.

This is a deterministic raster correctness check. It does not measure game FPS, frame pacing, or GPU scene utilization.
