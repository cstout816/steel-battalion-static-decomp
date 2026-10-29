# Current cleanup manifest — r271 inventory (2026-10-29)

## Measured workspace

The refreshed inventory is `C:\Project\sb-inventory-current-20261029-r271.csv.gz`; its skipped-path list is `C:\Project\sb-inventory-current-20261029-r271.csv.skipped.txt`. It skipped 13 Rust tool reparse entries and reported no other scan errors.

- **Full post-r271 scan: 75,678 files; 57,530,257,315 bytes allocated (53.579227 GiB); 1,381,116,548,274 bytes logical (1,286.265020 GiB).** The 13 skipped entries are Rust tool reparse paths. After creating/updating the text status records, the current total was adjusted by remeasuring the four affected files: 75,680 files; 57,530,266,619 allocated bytes (53.579236 GiB); 1,381,116,557,578 logical bytes (1,286.265028 GiB). No other workspace paths changed between the scan and this adjustment.
- Compared with the full r270 scan: +172,298,361 allocated bytes and +174,741,326 logical bytes after the text-file adjustment. The main additions are the r271 bundle and evidence. Earlier r268 totals came from an incomplete scan and are not used as a clean baseline.
- r267 evidence folder was 4,838,539 logical bytes at exit; 64 MiB cap not hit, no trace-limit hits and no relay drops. Its lossless 640x480 BMP and matching dump remain.
- r268 run manifest reports `RunStorageBytesAtExit=61,823`; its current 11-file folder totals 65,998 logical bytes.
- r270 added a three-file EXE/PDB/MAP bundle using 169,852,207 allocated bytes. Its eleven-file run folder uses 2,240,529 allocated bytes and 4,137,314 logical bytes currently; the runner reported 4,129,411 logical bytes at exit, below its 64 MiB cap.
- r271 added a three-file EXE/PDB/MAP bundle using 169,853,890 allocated bytes. Its eleven-file run folder uses 2,422,431 allocated bytes and 4,865,396 logical bytes. The runner reported 4,856,964 bytes at stop, below its 64 MiB cap.

## Preserve

- Original ISO and extracted assets; all 16 unique full `Partition5.img` saves; dirty source checkouts; edited generated source; legal notices; the canonical generated tree; warm incremental CMake/Cargo caches.
- Exact binary/symbol bundles tied to unresolved dumps. r249 bundle: EXE `1CF805050BCF31C29575D3850C0C34F5346FCA358F5BC8E81AD8AC315E31FB98`, PDB `6FF161D1DFE60683B8AC9B9C5C32A193EC109311432B1CABFF2794B70BF6D057`, MAP `0D987E74FB4CCE6E0DEE10ABD1F4DF231C10C7D4A340FF514763091747FF9944`.
- r264 exact bundle and its dump: EXE `6C5E142CCDA79474D75787B32F927EA8C4BB439B983BC5284E2F79BC2027DD27`, PDB `E6638D46A269C740C46565FEB678853DB8C1A128C857CFEAFA51DEA62B8E3FA8`, MAP `889C4D9A4F262A3999A4DA30BA3388C7A524F2339E6D959F913E78A20334A8CE`. Retain together while its DCF4 finding remains open.
- r270 exact bundle and dump are also protected: EXE `A2562059D5B76FEE0F100F4AC86ADFF4B29F4760EFCA6A54330EB8AFA16B709A`, PDB `BF9C2C3454537803D04E52C4CF8C5807443BD58799EEBF3B7CBC4FBB396B0AC5`, MAP `A015790C97492C60D547C65F2A1EAD457C1AFB1413A322A63BE719E0CE9B93D2`.
- r271 exact bundle and dump are preserved while the title DCF4 handoff remains unresolved: EXE `4B4B4D1992EE121D174F3E5D9C42A60345731B1BD66CB7B775E372F8D7612BE4`, PDB `24B951DCE31F5CE2DA61BFF70CBFA7D14D865D208EBA0BB7F6768EB8040130FA`, MAP `D84AD7E0B146605F0F4888041AA302A18C8182FD85AEE4C6935F76FF590F9A10`.
- All full save partitions have distinct hashes and allocate 12,582,912,000 bytes in total; preserve. Never hard-link writable saves.

## Space reclaimed and candidates

- **This pass recovered 0 bytes.** No workspace files were removed, compressed in place, or relocated.
- Fourteen closed r259–r261 logs were previously marked NTFS-compressed; the measured allocated-byte reduction was zero. Do not repeat that operation without a new measured benefit.
- Eight verified zero-only save partitions were previously made sparse, recovering about 8.300 GiB; 12,101 exact duplicate screenshots were removed in an earlier authorized cleanup. Neither action was repeated.
- Forty identical `Cache/TEXOBJ.BIN` copies (~1.758 GiB allocated, SHA-256 `70770E70991737D28898BABF814DD603AFD9E085D740F3A64BB24FB37BFB7C7A`) remain untouched because a prior direct removal was rejected by automatic review. Do not route around that rejection. These are the largest identified duplicate candidates, but no space has been credited as reclaimed.
- No historical capture, save, source tree, cache, or old build was removed in this pass. Exact dump bundles remain protected. The r264 side-by-side bundle is required for r267/r269 dumps; r270 and r271 bundles remain paired with unresolved DCF4 dumps.

## Budget and next steps

- Diagnostic output remains capped at 64 MiB per run. r271 had complete marker counts and zero relay drops but hit the `[DCF4-OUTER-CAP] limit=2048` first-N trace cap before the final stall. The side-by-side build completed in about 30 seconds without purging the warm cache; no comparative build-time benchmark was recorded.
- Current blocker and diagnostic plan: [r271 title DCF4/outer-loop report](m3-r271-title-dcf4-outer-loop-20261029.md). No runtime behavior was changed; no first-mission frame was reached.

## Current attempted compression

The r267 closed-text archive-and-replace command was rejected by command policy before any files changed. A later request to archive/replace 20 historical `C:\Project` inventory CSVs was also rejected before any files changed; their raw files remain intact. No alternate deletion method was attempted. The 40 byte-identical texture-cache copies and all other previously identified candidates remain untouched. Space savings remain zero.

## r271 outcome and exact-workspace additions

The latest diagnostic establishes an unsignaled DCF4 wait at guest callsite `0x00211F3B`. Callback 453 / index 5 / target `0x0021701E` produced DCF4 set 127; callback 454 / index 1 / target `0x00216EC9` returned zero from the gate, and wait 128 has no return. Final raster queues were idle; this does not support a queued rendering backlog. The screen-gated input was sent only after guest callback progress had stopped and reached XID DMA without a later guest input predicate, so this run does not verify the new-pilot route. Details and exact bundle hashes: [r271 evidence report](m3-r271-title-dcf4-outer-loop-20261029.md).

The post-r271 scan was adjusted for the exact allocated/logical sizes of the four status/report text files changed after scanning; no other paths changed. Workspace allocation grew by 172,298,361 bytes (0.160466 GiB) from r270, mainly the diagnostic bundle and run evidence; this is retained evidence, not reclaimed space. No project files were removed or compressed. Build cache remains warm and incremental efficiency is unchanged.
