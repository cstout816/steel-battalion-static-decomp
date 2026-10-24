# Xbox kernel ordinal labels for Ghidra

This directory contains a Ghidra Java annotator, a read-only verifier, and the 371-entry candidate ordinal/name CSV used for the local Steel Battalion XBE analysis.

## Use

Import the user's `default.xbe` into a Ghidra project with the XboxDev `ghidra-xbe` loader. Copy this directory into a Ghidra script directory, then run the annotator with the CSV path as its only script argument:

```text
analyzeHeadless <project-location> <project-name> -process default.xbe -noanalysis -scriptPath <script-directory> -postScript AnnotateXboxKernelOrdinals.java <path-to-xbox_kernel_ordinals.csv>
```

To verify saved labels without modifying the project:

```text
analyzeHeadless <project-location> <project-name> -process default.xbe -readOnly -noanalysis -scriptPath <script-directory> -postScript VerifyXboxKernelOrdinalLabels.java
```

To inventory the already analyzed memory blocks and function bodies without changing the project:

```text
analyzeHeadless <project-location> <project-name> -process default.xbe -readOnly -noanalysis -scriptPath <script-directory> -postScript SummarizeXbeAnalysis.java
```

The annotator was run against both `SteelBattalionStartupDecomp` and the larger `SteelBattalionStartup` project in Ghidra 12.1.4. It reported the retail entry point `0x00192C47`, thunk table `0x0025D0E0`, and 123 annotated cells. Separate read-only runs verified all 123 labels in each database after save/reopen. The summary script reports that the existing `SteelBattalionStartup` database has 79 memory blocks and 6,463 defined functions. This count describes the current Ghidra database; it does not prove every function boundary has been manually validated. No XBE bytes or instructions were changed.

## Naming confidence and provenance

The XBE reports XDK build 4627. The CSV's candidate names come from the XboxRecomp XBE parser map, which documents cross-checks for kernel builds 3944 and 4039. Labels therefore include `Candidate` and are not asserted as exact for build 4627. Unknown ordinals retain ordinal-only names.

The Java scripts are project utilities. The CSV is derived from the MIT-licensed XboxRecomp parser/reference map; its upstream license text is included as `UPSTREAM-MIT-LICENSE.txt`.

## Limits

The annotator labels existing kernel thunk cells. It does not recover function prototypes, resolve statically linked library code, add hooks, or make an XBE runnable as a native Windows executable.
