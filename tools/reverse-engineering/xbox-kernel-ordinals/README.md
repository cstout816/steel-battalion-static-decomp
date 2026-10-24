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

The scripts were run against the existing `SteelBattalionStartupDecomp` project in Ghidra 12.1.4. The annotator reported the retail entry point `0x00192C47`, thunk table `0x0025D0E0`, and 123 annotated cells. A separate read-only run verified all 123 labels after save/reopen. No XBE bytes or instructions were changed.

## Naming confidence and provenance

The XBE reports XDK build 4627. The CSV's candidate names come from the XboxRecomp XBE parser map, which documents cross-checks for kernel builds 3944 and 4039. Labels therefore include `Candidate` and are not asserted as exact for build 4627. Unknown ordinals retain ordinal-only names.

The Java scripts are project utilities. The CSV is derived from the MIT-licensed XboxRecomp parser/reference map; its upstream license text is included as `UPSTREAM-MIT-LICENSE.txt`.

## Limits

The annotator labels existing kernel thunk cells. It does not recover function prototypes, resolve statically linked library code, add hooks, or make an XBE runnable as a native Windows executable.
