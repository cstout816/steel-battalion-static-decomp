# XBE inspection and Ghidra support

## Findings

- The local Ghidra 12.1.4 workspace already includes the XboxDev `ghidra-xbe` extension and its XbSymbolDatabase integration. This is the preferred path for importing and analyzing the original-Xbox XBE. The portable Java annotator, verifier, candidate CSV, and upstream license notice are in [`tools/reverse-engineering/xbox-kernel-ordinals/`](../tools/reverse-engineering/xbox-kernel-ordinals/README.md) and were installed in the active Ghidra script workspace.
- Upstream review confirms XbSymbolDatabase is an MIT-licensed OOVPA pattern-signature library, and `ghidra-xbe` uses it for library-symbol recovery. This is a complementary source for recognizing compiled XDK/library routines in the XBE; it is not a verified build-4627 ordinal-name table. Keep its matches separate from the provisional ordinal CSV and verify recovered names against code and call sites. No XbSymbolDatabase or Ghidra extension code was copied into this repository.
- The supplied Steel Battalion executable is a retail `XBEH` image; the local parser reports XDK library build 4627 and 123 distinct kernel thunk imports. All 123 ordinals occur in the current xboxrecomp candidate map. That map's own notes say it is cross-checked against kernel builds 3944 and 4039, so the Ghidra labels remain explicitly provisional for this build.
- Cxbx-Reloaded contains an XBE metadata printer and loader checks for XBE signatures and section integrity. Those are useful independent metadata checks. Cxbx-Reloaded is an emulator, so running it does not create or validate this project's statically recompiled Windows executable.
- Exact-name public-source searches did not verify a project named **XbeTripper** or **xberewrite**. Do not base the pipeline on either name until a repository or project URL is supplied and its source/licensing can be reviewed.

## Why this is not an executable patch

The Ghidra script labels existing kernel thunk cells and never modifies the XBE. No custom hooks or cave are needed for this step. Any future hook proposal must first prove a specific need and must be reviewed against the XBE section table, mapped section bounds, alignment, and code/data references. A zero/NOP byte run alone is not proof that bytes are unused. Prefer a separately added, correctly aligned PE section for host-side instrumentation; do not patch user game bytes without a separate, reviewed design.

## References

- [ghidra-xbe](https://github.com/XboxDev/ghidra-xbe) — XBE loader and XbSymbolDatabase integration.
- [XbSymbolDatabase](https://github.com/Cxbx-Reloaded/XbSymbolDatabase) — MIT-licensed OOVPA library-signature database used by `ghidra-xbe`; useful for identifying compiled library routines, not as proof of 4627 ordinal names.
- [XboxRecomp XBE parser](https://github.com/sp00nznet/xboxrecomp/blob/main/tools/xbe_parser/xbe_parser.py) — XBE metadata and kernel ordinal candidate names.
- [Cxbx-Reloaded](https://github.com/Cxbx-Reloaded/Cxbx-Reloaded) — emulator-side XBE loader/diagnostic reference.
- [Cxbx-Reloaded README](https://github.com/Cxbx-Reloaded/Cxbx-Reloaded) — identifies the project as an original-Xbox emulator and lists its GPL-2.0 license. No Cxbx code is incorporated.
- [Cxbx-Reloaded XbePrinter.cpp](https://github.com/Cxbx-Reloaded/Cxbx-Reloaded/blob/master/src/common/xbe/XbePrinter.cpp) — reference implementation for printing XBE metadata.
- [Cxbx-Reloaded XBE loader](https://github.com/Cxbx-Reloaded/Cxbx-Reloaded/blob/master/src/core/kernel/init/CxbxKrnl.cpp) — source path for signature and section-integrity checks during emulator launch.
- [Cxbx-Reloaded Xbe.h](https://github.com/Cxbx-Reloaded/Cxbx-Reloaded/blob/master/src/common/xbe/Xbe.h) — reference for its XBE section structures and retail/debug entry-point and thunk XOR constants. This is implementation reference material, not a selected runtime dependency.
- [XBE format overview](https://xboxdevwiki.net/Xbe) — XBE header, sections, and thunk-table format.

### Revalidation note

The local parser was run read-only on the supplied XBE: seven library records all report build 4627; the 123 distinct imported ordinals all occur in the 371-entry candidate CSV. Ghidra 12.1.4 headless applied candidate labels to 123 thunk cells in both `SteelBattalionStartupDecomp` and the larger `SteelBattalionStartup` project; separate read-only verification passes found all 123 labels persisted in each. The larger existing database defines 6,463 functions in 79 memory blocks. A read-only trace-address walk maps the DCF4 wait, `KeSetEvent` callback, and DPC handler to saved function boundaries and call references. Treat all of these as database analysis, not manual validation of every function boundary or a proven runtime cause. The labels are provisional because the CSV's cross-checks cover builds 3944/4039, not 4627. The XBE bytes were not modified. See the tool README for the exact commands and limits.
