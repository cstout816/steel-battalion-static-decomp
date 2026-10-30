# Source preservation manifest — current r348 snapshot (2026-10-29)

## Latest recovery snapshot — r348

Project and XboxRecomp checkouts remain dirty and uncommitted. The latest tracked-file recovery patches are based on the revisions below; they exclude ignored `iso/`, build outputs, save data, the self-referential current cleanup index, and proprietary generated game source. New untracked evidence/report files remain in their named paths and are not embedded in these patches.

| Checkout | Base commit | Patch | SHA-256 | Bytes |
|---|---|---|---|---:|
| Project workspace | `d314e3c7bce6d4121f15631634dce84fb81789c0` | `patches/preservation-project-current-20261029.patch` | `BE3D5A8A546BF13414C8BE38FA2BD6585597FC0311B04809096675E160A49D64` | 935,850 |
| XboxRecomp checkout | `193e2995ffaec871bb3be43a43bd66aa5fccfeb1` | `patches/preservation-xboxrecomp-current-20261029.patch` | `3A1E5E35A2A4305CD72645134428F3D8619677EFBC2AEB0B8DBFD20DA2446C57` | 658,042 |

The current r342 EXE/PDB/MAP and r340/r348 dump identities are recorded in `analysis/m3-r340-r344-surface-and-storage-20261029.md` and `analysis/m3-r348-mode2-plateau-and-storage-20261029.md`. The bounded overlap trace is in `patches/diagnostics/dsound-surface-overlap-r341.patch` (100,382 bytes, SHA-256 `C79C2407BE0A5A849DCFE705447A730EF797097152F26D6EA5FF671AE4DC2DCC`). `tools/Start-ProducerTrace.ps1` exposes `-EnableDsoundSurfaceTrace`; source and candidate artifacts are reproducible from the retained checkouts and warm build tree. Both current recovery patches reverse-apply cleanly. Generated AOT code and game assets remain local only.

Current canonical generated source remains a separate local-only 27-file manifest. Do not commit or distribute generated game code, original game data, saves, or diagnostic executable bundles.

---

# Historical source preservation entries

## Current recovery snapshot — r314

The two dirty source checkouts remain uncommitted. These current patch snapshots supersede r312 and earlier snapshots for recovery; both reverse-apply checks passed against the current worktrees. The project patch excludes `iso/` and `local-tools/`; the XboxRecomp patch contains only its tracked checkout diff. Neither contains proprietary generated game code.

| Checkout | Base commit | Patch file | SHA-256 | Bytes |
|---|---|---|---|---:|
| Project workspace | `3450e6b97e78ee0b92034aaa0495e3d6ab102cf8` | `preservation-project-worktree-r314.patch` | `FA672774BA5D1EB2E3ED410B327F7122E0979EDDF7B4BF5DA90A7487E94AC1B3` | 190,254 |
| `local-tools/xboxrecomp` | `193e2995ffaec871bb3be43a43bd66aa5fccfeb1` | `preservation-xboxrecomp-worktree-r314.patch` | `EFAD7DC9E716F046A310A8D86CDEE300D91ACA99CA47327F76BD1038255A13F8` | 642,441 |

The matched r313 diagnostic build uses the current trace code, including `kernel_hal.c` (`DB377615B296831D6D258BD8DF62F61D502CEE8F5F4F1712C7C803417427BAA2`), `kernel_guest_cpu.c` (`E07C62555439D399818D3A0A71328B8EB6DBEE93040E464137280FACB2E0E50A`), `kernel_bridge.c` (`7A9C218CEE65E0B8FA5D73A43DC7200695217A86B39FD96BBCA617FFEE1B5986`), and `xbox_memory_layout.c` (`902FD615DAA3C11167E066E709C4895FDC103F62664F6C6D5E68F160D8D97CC0`). Exact r313 EXE/PDB/MAP hashes and the r314 dump hashes are in `m3-r310-r314-loader-storage-followup-20261029.md`. The canonical generated source and its local-only hash manifest below remain unchanged; do not commit or distribute generated game source.

---

This is a recovery index, not a commit. The project and XboxRecomp checkouts remain dirty and uncommitted. Patches include tracked source/config/documentation changes only; proprietary generated game source is not embedded in either patch.

| Checkout | Base commit | Patch file | Patch SHA-256 | Bytes |
| Project workspace | `4761b0b31e17792b195c2918c353e4a31b74779c` | `preservation-project-worktree-20261029.patch` | `95F0510A3A499FDF97B8083F62A1EC46ED36CDADA26F51E85B813FFEAF2FC3E2` | 148,156 |
| `local-tools/xboxrecomp` | `193e2995ffaec871bb3be43a43bd66aa5fccfeb1` | `preservation-xboxrecomp-worktree-20261029.patch` | `6D0D4C693796839EC6330F89E0058789BE17ADA47027A733D4A1B7A361909E0F` | 628,043 |

Canonical generated source is preserved in place at `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`. Its 27 files total approximately 155.877 MB. Exact relative paths, sizes and SHA-256 hashes are in `generated-source-preservation-20261029.csv` (current CSV SHA-256 `3391EF39A26323CFCED12E45F13FC3AA25D11EE1B164D17E72261F11B3DE4D76`). The current `recomp_0015.c` entry is 2,238,467 bytes, SHA-256 `60E50CF36735E871B985EFFED45BF3F0AA0D9522AB8AA919FA930A1B31AFCDC1`. The r284 trace-only edit to `recomp_0004.c` is 6,959,411 bytes, SHA-256 `AECF7130AD3E02B7D53CE078F5A3835E0D43448A1321565CDB13AE06776F7CD8`; its byte-for-byte pre-edit rollback is `iso/local-analysis/source-rollback/recomp_0004.c.pre-r284` (6,956,383 bytes, SHA-256 `F70BB8AB5F9607AF8CDB73E83A068D12B342CB2041B1FC327B75CD9BBBCEDD9E`). The r275-built `recomp_0015.c` hash is `2151BE1955FFB85F5C7C16FE5B5AFCDC9C4569CA2604DB15F258FBB82AD2C924`. Keep generated game source and rollback files local-only; do not commit or distribute them.

The r275 EXE/PDB/MAP hashes and the mutated route-save image hash are recorded in `m3-r275-newpilot-black-frame-stall-20261029.md`. Preserve that matched symbol bundle with the run evidence. No save image was hard-linked or deleted.

## r291–r292 supplemental preservation

The current working-tree patch snapshots supersede the older patch files above and contain tracked source/configuration/documentation only; they exclude `iso` and `local-tools` at the project root, and the XboxRecomp patch contains only tracked checkout files. No generated game source is embedded. Project patch: `preservation-project-worktree-r292.patch`, 173,834 bytes, SHA-256 `11FDD9719EEE17A568F9B06147CDD1CE472A2404484C2F436DB5A0AF0B9F73B7`. XboxRecomp patch: `preservation-xboxrecomp-worktree-r292.patch`, 651,172 bytes, SHA-256 `B36599146AB5E25FAB7583D80FE6305D11E3F3E4D27450324682B45332853676`.

Current trace-relevant file hashes: `tools/Start-ProducerTrace.ps1` SHA-256 `EEF1D7BB3A98840144EC44ED4CEC60A5258CDAC6CFF6EE63B98E929677CF4285`; modified XboxRecomp `src/kernel/kernel_bridge.c` SHA-256 `B092E2C74DC807F4942C4418287FD6EE847AEF34CDDDA23D9E0E7571D928FC47`; current generated `recomp_0015.c` SHA-256 `92C9A79DA3BC2A97290DA4C69CF67E96E812CB45A8CAE7C814749AAC88EF48BA`. Generated source stays local-only. These hashes identify the exact current files; retain the full source checkout and matching r291/r292 executable/symbol bundles.

## r293 supplemental preservation

Current full working-tree snapshots (tracked files only; no generated game code): project `preservation-project-worktree-r293.patch`, 176762 bytes, SHA-256 `47509A48905265BB408821F5AB0EA6200B8515EB2C8E2A6CFA8351F014D8BBA3`; XboxRecomp `preservation-xboxrecomp-worktree-r293.patch`, 653,606 bytes, SHA-256 `911681B68393634B89484A65C7401D0C638954FCDAD334CE7CC7C91743E611B9`. Both source checkouts remain dirty and uncommitted.

Trace source hashes: `local-tools/xboxrecomp/src/kernel/kernel_bridge.c` SHA-256 `1C07F2207870B398747B854EA04B6FB63A4A2F57D0F0D48DD801863DEE99F1DC`; `tools/Build-ProducerTrace.ps1` SHA-256 `CD07EF21DA135C4AEB49511FA4F9328FE0BDC6D2BC8781A1160281A569707254`; `tools/Start-ProducerTrace.ps1` SHA-256 `34DCD4C2587594F7286A6C052B037D4FA84872B50C551C949516472075161100`. The generated source tree was unchanged in r293; its preservation CSV continues to identify the local-only r291 `recomp_0015.c` hash.

## r367 supplemental preservation

`local-tools/xboxrecomp/src/kernel/kernel_path.c` currently has SHA-256 `718E27B83035E0F50B074720587AE74A501389F45E11DAEDC7822F00AF2E142F`. The one r367 diagnostic edit adds an explicit `Partition1\\TDATA\\` rule before the broader Partition1 asset rule, directing TDATA into the run-specific `TitleData` directory. It remains uncommitted and must not be treated as a permanent compatibility decision until the pilot-route comparison is completed. The exact tracked dirty XboxRecomp checkout, including this edit, is recoverable from `preservation-xboxrecomp-worktree-r367.patch` (658,801 bytes; SHA-256 `CE820D07AE505D9D11AA6CC579897CB39F1D743EB0DFF515FAE7B9A1D73BE727`). This patch contains tracked checkout changes only; it excludes untracked build outputs, ISO files, and proprietary generated game code. Existing untracked source files were left untouched.

r367's matching AOT diagnostic bundle is retained with its run: EXE `037E8DE482ABB57BDD33B6D36E6FF65B0925CA35E371E51BD53AC763BB26A760`, PDB `0D05E2F2A699D0BF9E7AD5D30CA4EB9FA26F2CB74341E33D3437EEC3DB9E41A5`, MAP `D3FC42DF4EA0028D052C35911548B585F38970FB19D50695B5D924E8C8601FD8`. Generated AOT source and the existing warm build cache were preserved; nothing was committed or pushed.
