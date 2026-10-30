# r406 heap-failure trace source manifest

This source delta adds bounded diagnostics to the existing dirty XboxRecomp checkout. It does not change heap limits, allocation return values, guest behavior, generated AOT code, or synchronization.

| Item | Value |
|---|---|
| Source | `local-tools/xboxrecomp/src/kernel/xbox_memory_layout.c` |
| Source SHA-256 after r406 change | `B879EB65FEA7FF7B191EEE74F0BDE78DE7DAD78ED2DA2CE66DC4B3F1AD3CCEEA` |
| Reconstructed pre-r406 source SHA-256 | `902FD615DAA3C11167E066E709C4895FDC103F62664F6C6D5E68F160D8D97CC0` |
| Patch | [`preservation-heap-oom-trace-r406.patch`](preservation-heap-oom-trace-r406.patch) |
| Patch SHA-256 | `8522AD7FAADA7FFE67FD28AD65A0B7C844B53E760D39B9C8ED962D94A31E4FCC` |

The patch contains only two hunks: a file-scope cap counter and an eight-record cap at the heap-allocation failure branch. Each record includes host TID, failed allocation size/alignment, aligned candidate address, heap bounds, guest ESP/EBP, and six words from the guest stack when its address is within mapped memory.

`git apply --reverse --check` succeeded against the r406 source, confirming the recorded change is the current source delta. The r406 build and run are documented in [the r402–r406 follow-up](m3-r402-r406-loader-storage-followup-20261030.md). Proprietary generated game code is not included.
