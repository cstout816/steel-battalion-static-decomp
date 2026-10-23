# Measuring CPU and GPU use

Use `tools/Measure-ProcessPerformance.ps1` to record host-side process usage while a game run is already open. It records process CPU time, CPU percentages, working-set memory, and Windows GPU Engine 3D and Copy utilization to CSV.

```powershell
$game = Get-Process your_game_recomp | Select-Object -First 1
.\tools\Measure-ProcessPerformance.ps1 `
  -ProcessId $game.Id `
  -OutputCsv .\iso\local-analysis\logs\cpu-gpu-usage.csv `
  -GuestStderrLog .\iso\local-analysis\logs\run\stderr.log `
  -IntervalSeconds 5 `
  -DurationSeconds 300
```

`CpuPercentOfOneLogicalProcessor` expresses process CPU use relative to one logical processor; `CpuPercentOfMachine` divides that by the system's logical processor count. GPU columns aggregate the matching process contexts for that engine type. Windows may omit GPU counters on unsupported drivers; CPU and memory sampling still works. A GPU utilization reading shows activity, not frame-time quality or correct rendering.

For a useful comparison, keep the executable, save, input route, display mode, and capture interval the same; change only `RECOMP_RASTER_THREADS`. Save each CSV beside that run's logs. Record the guest flip-rate samples and whether the run reached a gameplay frame separately. Do not compare an instrumented diagnostic run with a clean performance run as if they were equivalent.

When `-GuestStderrLog` is supplied, each row repeats the latest `[GPU] ... fps (... flips)` report read incrementally from the runtime log. This is the guest flip-rate report, not a per-frame timing histogram or a 1% low. The sampler refreshes GPU-engine discovery every 30 seconds and queries the target process's discovered engines between refreshes; a longer interval reduces measurement overhead. Keep all other `RECOMP_*` settings identical in thread-count comparisons, especially the scheduling and graphics settings; record any differences in the run notes.
