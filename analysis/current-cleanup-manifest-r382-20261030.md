# Current cleanup and storage manifest — r382, 2026-10-30

## Measurement basis

Inventory: `C:\Project\sb-inventory-current-r382-20261030.csv`, created by `tools/Measure-WorkspaceInventory.ps1`. It separates allocated bytes from logical file lengths and skips reparse paths. Thirteen Rust tool reparse executables were queried separately. The inventory was taken after the initial r382 top-level evidence compression and before the bulk closed-log/dump pass; the latter's exact before/after allocation delta was measured and applied to the workspace total below. Eight retained r382 framebuffer-history files were separately checked against the run manifest.

| Working set | Allocated | Logical |
| --- | ---: | ---: |
| Workspace ordinary files before bulk compression | 41,335,077,621 B | 1,396,989,869,866 B |
| Rust tool reparse files | 165,381,632 B | Not summed by inventory |
| Closed log/dump compression delta | −11,709,326 B | 0 B |
| **Workspace after compression** | **41,488,749,927 B (38.639 GiB)** | **1,396,989,869,866 B** |
| r382 run folder after compression | 4,172,308 B | 18,525,846 B |
| Warm `build-xpp-seeded` | 6,918,921,034 B | 13,871,927,762 B |
| Canonical generated AOT source | 155,887,568 B | 155,887,568 B |
| r368 save root | 110,706,564 B | 5,422,140,106 B |
| `iso/local-analysis/logs` after bulk compression | 3,007,201,865 B | 1,036,061,458,034 B |

The workspace total is path-summed. Sparse image logical lengths are not disk usage. The 14.9 MB inventory CSV is stored under `C:\Project`, outside the workspace total. The previous complete r378 workspace total was 41,483,006,588 allocated bytes; the current workspace is 5,743,339 bytes higher after r379–r382 retained run evidence and the compression actions below.

## Realized space reduction

- r382's 11 top-level closed evidence files were losslessly NTFS-compressed. Allocation fell from **4,261,220 B to 3,435,028 B**, reclaiming **826,192 B**. All 11 logical lengths and SHA-256 hashes matched.
- A further **2,665** closed `.log` and `.dmp` files under `iso/local-analysis/logs` were compressed. Their combined allocated use fell from **16,607,401 B to 4,898,075 B**, reclaiming **11,709,326 B**. All logical lengths remained unchanged. The eight retained r382 history screenshots matched their run-manifest SHA-256 hashes and lengths after compression; their allocation was already compressed, so that image check reclaimed zero bytes.
- Total measured allocation reclaimed this pass: **12,535,518 bytes**. No logical file contents were shortened or converted to a lossy format.

## Protected material and duplicate review

No files were deleted or moved. The original ISO, extracted game files, unique saves, dirty source checkouts, manually edited generated code, licenses, exact unresolved-dump EXE/PDB/MAP bundles, canonical AOT generation, and warm incremental cache remain intact. Saves were neither copied nor hard-linked.

The biggest retained entries are expected working inputs: the original ISO (~7.29 GiB allocated), warm build tree (~6.44 GiB), extracted cinematics/assets, and unique save data. The Ghidra 12.1.4 and 12.2 archives have different hashes and are distinct versions; the two identical JDK `lib/modules` files belong to separate runtime trees documented for separate Ghidra installations. Neither is a verified duplicate installation to remove. One external delete-later Ghidra archive copy has the same hash as the retained 12.1.4 archive, but was already NTFS-compressed to under 1 MiB allocated; deleting it would reclaim little and would invalidate the historical archive manifest. It remains untouched.

No hot compiler/Cargo cache was purged. The last measured warm incremental build remains about 9.1 seconds; no build ran in r379–r382. No other-chat game process was interrupted. r382 PID `184428` was stopped only after its exact executable path, run identity, and dump capture were verified.

## Diagnostic cap and next action

r382 used a 64 MiB run budget, 32,768-line bounded relay, and eight retained framebuffer-history slots. Trace counts show no async-relay overflow or trace cap. The screenshot history evicted seven captures and recorded one dropped copy due to a source/copy hash mismatch; the visible loading frame `capture-0014.bmp` remains retained and hash-verified.

Keep the current warm build and one canonical generation. Next test the r382 hypothesis with the existing hardware write-breakpoint utility at guest `0x82A9BFFC` (host `0x82AABFFC`, based on the run's `+65536` memory offset). Capture writer RIP/thread/value plus synchronized loader, DMA, DCF4, and screen state before making any runtime change.

## Final post-documentation inventory

The final scan after the r382 report, status index, and project memory updates is `C:\Project\sb-inventory-current-r382-final-20261030.csv` (outside the workspace). It measured **77,579 ordinary files**, **41,323,383,188 allocated bytes**, and **1,396,989,884,759 logical bytes**. Thirteen Rust tool reparse executables were skipped by the scanner and measured separately at **165,381,632 allocated bytes**, for combined allocation **41,488,764,820 bytes (38.639 GiB)**. This supersedes the preliminary total above; logical lengths include sparse files and must not be read as actual disk use.
