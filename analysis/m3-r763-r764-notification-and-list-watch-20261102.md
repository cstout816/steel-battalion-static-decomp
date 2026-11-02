# r763–r764 PGRAPH notification and DirectSound list follow-up (2026-11-02)

## Result

No mission scene was reached. r763 stopped on a fatal guest read at `sub_0021ED29+0x88`; r764 stopped after its 120-second DCF4 wait watchdog. No runtime fix, source change, build, or test was made. Both runs reused the exact r756 AOT candidate and the existing save root.

| Field | r763 | r764 |
| --- | --- | --- |
| PID / run | 107876 / `m3-r763-pgraph-notify-after-dcf4-20261102` | 96596 / `m3-r764-dsound-writer-before-campaign-20261102` |
| Executable SHA-256 | `03FC192D56C9CF4F33BD7B84A156FE706DB2CB18BD2556C912F284A96C594081` | same |
| Retained evidence, logical / allocated | 9,997,624 / 4,007,614 bytes | 5,746,580 / 2,188,657 bytes |
| Terminal evidence | crash at guest VA `0xFFFFFFF4` | black frame; DCF4 wait watchdog |

Both stayed below the existing 64 MiB run budget. r763's process was stopped automatically by the fatal-exception watchdog; r764's was stopped automatically after no DCF4 wait return for 120 seconds. No unrelated process was touched.

## r763: method notification arrives, then a DirectSound list read faults

The new bounded `RECOMP_PB_NOTIFY_TRACE=1` instrumentation ran without a rebuild. Its `PB-NOP` and `PGRAPH-NOTIFY` records confirm that software notification method `0x0100` reaches `nv2a_pb_exec_method`, raises a PGRAPH interrupt, and returns after the guest acknowledges it. The guest callback receives the corresponding data values, including `5`, `0x01080021`, and `0x03600021`. Thus the earlier trace's callback argument was sourced from PGRAPH trapped data, not inferred from a generic queue. The matching runtime code is `nv2a_pb_exec.c` (NOP handling) and `nv2a_core.c:604` (`nv2a_pgraph_notify`).

The run did not get far enough to isolate the terminal DCF4 producer path. It instead faulted at host RIP `0x7FF65C7B7C78`, with Xbox ESI `0xFFFFFFEC` and guest read address `0xFFFFFFF4`, in generated `sub_0021ED29+0x88` (`recomp_0016.c:1717`). The crash snapshot reported the DirectSound voice-list head at guest `0x01081014` as null. This matches the r760 invalid list traversal but does not identify the write that caused it. The final retained image is `iso/local-analysis/logs/m3-r763-pgraph-notify-after-dcf4-20261102/frame-history/capture-0005.bmp` (SHA-256 `49531E27E72CB4BFAFF8EDC941AC59884175E9AF4F1C217092A3DB3550FEC697`); it is not a mission frame. Full crash detail is in `iso/local-analysis/logs/m3-r763-pgraph-notify-after-dcf4-20261102/stderr.log` and `exception-stop.txt`.

## r764: list watch and DCF4 producer evidence

The bounded DirectSound watcher recorded initialization and link writes at guest addresses `0x8038C08C`, `0x8038C098`, and `0x8038C09C`. The observed sequence initializes the links and connects them to nonzero guest nodes; no malformed write was captured. The watcher monitors three fixed words, so this does not prove all list mutations are safe. The run ended in DCF4 wait, not the r763 access violation.

The DCF4 traces identify the waiting guest code and the missing handoff more precisely:

- Generated `sub_00211E10` at `recomp_0015.c:35080` writes a software marker descriptor at guest `0x80069B38`: method `0x00040100`, parameter `5`. It calls `sub_00211C40` to flush, then `sub_00211AB0` reports `0x2DA0`, above the guest `0x2000` threshold.
- At tick `278507875`, TID `92672` begins a wait on DCF4 object `0x0021DCF4`. The last method-5 PGRAPH notification before that marker was n=291 at tick `278507812`, and its interrupt was acknowledged. At tick `278507875`, PGRAPH consumed/acknowledged an unrelated `0x01080021`; the next recorded notification was `0x03600021` at tick `278507921`. No method-5 notification followed the marker write during the captured wait.
- The wait begins while three raster workers are pending. By tick `278508906`, the raster count is unchanged at 3,177 batches, active/pending work is zero, guest DCF4 is unsignaled, PGRAPH interrupt is zero, and DMA PUT=GET=`0x6C920`. The wait then persists through the watchdog. This rules out a continuing raster backlog as the final wait's explanation, but the trace does not yet prove whether the marker descriptor was published into the DMA pushbuffer or lost before PGRAPH execution.

Keep this as a producer-to-command-stream handoff candidate. Do not force the event or infer a renderer fix. The current unresolved point is the transition from the written descriptor at `0x80069B38` to an actual PGRAPH NOP packet carrying `5`.

## Route, saves, and next experiment

The existing save root remains in use; no save was copied, cleared, or modified. The eight verified empty pilot records remain in the r761 rollback folder, leaving the game-visible slots open.

The next experiment should add a bounded trace at the guest ring-publish callback (`device+0x21AC`, cursor `device+0x21B0`) and correlate the descriptor address with pushbuffer header/parameter addresses, DMA PUT/GET, method-5 notification, and DCF4 wait on one clock. Reuse the r756 bundle if its existing instrumentation covers these points; otherwise make only the narrow diagnostic addition. Keep the DirectSound writer watch enabled because the earlier invalid list read is still a separate first-stage crash candidate. Do not repeat an equivalent route without that producer-to-pushbuffer correlation.

The first mission frame remains **0/1**. No graphical enhancements, storage cleanup, or gameplay behavior changes were made in these runs.
