# r410 diagnostic source preservation manifest

The r410 binary is an AOT diagnostic build. Its only generated-code edits are bounded, opt-in trace records for the post-mode-2 asset producer and consumer. No proprietary generated source is committed or included in this manifest.

## Reproduction

Use `tools/Apply-Mode2ReadinessInstrumentation.ps1` against the current generated-source directory, then use the existing `tools/Build-ProducerTrace.ps1` workflow with `-EnableMode2ReadinessTrace`. The instrumentation script is idempotent and refuses a partial patch state. The runner sets `RECOMP_MODE2_READINESS_TRACE=1`; records are capped and output to the existing bounded asynchronous relay.

| Local file | SHA-256 |
|---|---|
| `tools/Apply-Mode2ReadinessInstrumentation.ps1` | `D6E3F1FFF7E91C94ADC4E9E11A63848D606E1B2BD68DA550348CB153411A6892` |
| `gen/recomp_0000.c` | `CA4D9750519B5C15CA322394D0248CC56D4F497758327B85C010B3A976D61150` |
| `gen/recomp_0004.c` | `D75AE225C75B890D377A5A897100A2190272686E258B42F8BC1ECC3ECDCA592F` |

Generated source files above remain local under `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`. The compact script reproduces the instrumentation without publishing generated game code.

## Exact run bundle

Run `m3-mode2-readiness-producer-consumer-r410-20261030` used the following exact r409 candidate in `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-mode2-readiness-producer-consumer-r409-20261030/Release`:

| File | SHA-256 |
|---|---|
| EXE | `13486060C5977578207377CE47CFEA82760C48D3FCC57B9DA1C0821A5FB2A23A` |
| PDB | `0FF3A109EFEAEE7E16BA222CCED7638C37E119F92681413538FF201DEE389F17` |
| MAP | `51FE8DB2E420EC0C44C2556F398434995FA0C72EB2B0FB118851B2B1DBC91994` |
| Plateau dump | `1D2A715DA9D0FAB09C365ABC926DFCBBCEADB247724497757FC9E8C865EA2D65` |

Keep this bundle with that dump because the guest main chain is unresolved. Do not substitute another EXE/PDB/MAP set for future unwind work.
