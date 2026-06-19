## Verification Report

**Change**: api-v2-horizontal-offline-ids
**Version**: N/A
**Mode**: Strict TDD

### Completeness
| Metric | Value |
|--------|-------|
| Tasks total | 12 |
| Tasks complete | 11 |
| Tasks incomplete | 1 (`4.3`) |

### Build & Tests Execution
**Build / Analyze**: ❌ Failed (`flutter analyze`, rc=1)
```text
Command: flutter analyze
Result: 2450 issues found. (ran in 2.3s)
Environment: Flutter 3.44.2 / Dart 3.12.2 satisfies pubspec sdk ^3.11.1
Classification: codebase/static-analysis failure, not a toolchain blocker
Relevant changed-file findings observed in analyzer output:
- lib/config/data/database_helper.dart: depend_on_referenced_packages, unnecessary_import, many pre-existing avoid_print infos
- test/database_helper_horizontal_identity_test.dart: unnecessary_import
- test/horizontal_create_flow_test.dart: depend_on_referenced_packages
```

**Tests**: ❌ Failed broad suite / ✅ Passed targeted change suite
```text
Broad command: flutter test
Result: rc=1
Failure: test/widget_test.dart: Counter increments smoke test
Reason: the default counter smoke test still expects counter text "0"/"1", but MyApp boots LoginScreen instead of the Flutter counter app.

Targeted command: flutter test test/database_helper_horizontal_identity_test.dart test/horizontal_create_flow_test.dart test/exportar_horizontal_service_test.dart test/user_service_profile_contract_test.dart
Result: 17/17 tests passed
```

**Coverage**: targeted changed-file coverage collected via `flutter test --coverage` → ⚠️ Below for multiple changed files

### TDD Compliance
| Check | Result | Details |
|-------|--------|---------|
| TDD Evidence reported | ✅ | `apply-progress` includes a TDD Cycle Evidence table |
| All tasks have tests | ✅ | 5/5 apply-tracked tasks reference existing test files |
| RED confirmed (tests exist) | ✅ | `test/database_helper_horizontal_identity_test.dart`, `test/horizontal_create_flow_test.dart`, `test/exportar_horizontal_service_test.dart` exist |
| GREEN confirmed (tests pass) | ✅ | All change-related tests passed in targeted execution |
| Triangulation adequate | ✅ | Catalog refresh, draft/syncable save, export, and profile contract all have multiple non-trivial cases |
| Safety Net for modified files | ✅ | Apply progress recorded safety-net runs for modified horizontal flow/export slices |

**TDD Compliance**: 6/6 checks passed

---

### Test Layer Distribution
| Layer | Tests | Files | Tools |
|-------|-------|-------|-------|
| Unit | 5 | 2 | `flutter_test`, `http/testing` |
| Integration | 12 | 2 | `flutter_test`, `sqflite_common_ffi` |
| E2E | 0 | 0 | not installed |
| **Total** | **17** | **4** | |

Notes:
- `test/exportar_horizontal_service_test.dart` and `test/user_service_profile_contract_test.dart` behave as unit tests.
- `test/database_helper_horizontal_identity_test.dart` and `test/horizontal_create_flow_test.dart` execute real SQLite interactions, so they were classified as integration-style tests.

---

### Changed File Coverage
| File | Line % | Branch % | Uncovered Lines | Rating |
|------|--------|----------|-----------------|--------|
| `lib/config/data/database_helper.dart` | 5.0% | N/A | many; sample `L53`, `L70`, `L72`, `L93-94` | ⚠️ Low |
| `lib/config/data/horizontal_catalog_repository.dart` | 94.0% | N/A | `L64`, `L76`, `L117` | ⚠️ Acceptable |
| `lib/config/data/horizontal_create_flow.dart` | 100.0% | N/A | — | ✅ Excellent |
| `lib/services/user_service.dart` | 66.7% | N/A | `L13-14`, `L20`, `L27-28`, `L44`, `L59`, `L71` | ⚠️ Low |
| `lib/services/envio nube/horizontal/exportar_service.dart` | 90.6% | N/A | `L22`, `L32`, `L38`, `L91-92` | ⚠️ Acceptable |
| `lib/core/sync/sync_service.dart` | 0.0% | N/A | sample `L14-16`, `L21-22`, `L25`, `L27-29` | ⚠️ Low |
| `lib/screens/login/login_screen.dart` | 1.0% | N/A | sample `L11-12`, `L25-27`, `L30-31`, `L36-37` | ⚠️ Low |
| `lib/screens/Operaciones/Tal horizontal/widgets/operacion_card.dart` | 0.0% | N/A | sample `L23`, `L33`, `L35-36`, `L50` | ⚠️ Low |
| `lib/screens/Operaciones/Tal horizontal/lista_perforacion_sreen.dart` | 0.0% | N/A | sample `L22-23`, `L25`, `L27`, `L61` | ⚠️ Low |
| `lib/screens/Envio a nube/Tal.horizontal/detalle_horiontal_screen.dart` | 0.0% | N/A | sample `L18`, `L22`, `L24`, `L26` | ⚠️ Low |
| `lib/models/Equipo.dart` | 100.0% | N/A | — | ✅ Excellent |
| `lib/models/Seccion.dart` | 100.0% | N/A | — | ✅ Excellent |
| `lib/models/JefeGuardia.dart` | 100.0% | N/A | — | ✅ Excellent |
| `lib/services/get nube/llamadas/api_services_Equipo.dart` | 0.0% | N/A | sample `L8-9`, `L14`, `L16-18`, `L21-22` | ⚠️ Low |
| `lib/services/get nube/llamadas/ApiServiceSeccion.dart` | 0.0% | N/A | sample `L8-9`, `L14`, `L16-18`, `L21-22` | ⚠️ Low |
| `lib/services/get nube/llamadas/ApiServiceJefeGuardia.dart` | 0.0% | N/A | sample `L8-9`, `L14`, `L16-18`, `L21-22` | ⚠️ Low |

**Average changed file coverage**: 34.8%

---

### Assertion Quality
**Assertion quality**: ✅ All assertions verify real behavior

---

### Quality Metrics
**Linter / Analyzer**: ❌ `flutter analyze` returned rc=1 with 2450 issues
**Type Checker**: ➖ Covered by analyzer in this Dart/Flutter repo

### Spec Compliance Matrix
| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| Persist horizontal catalogs with remote identity | Refresh cached catalog labels | `test/database_helper_horizontal_identity_test.dart` > `refreshes horizontal catalogs by remote id and prunes missing rows` | ✅ COMPLIANT |
| Persist logged-in operator remote ID | Store operator identity after login | `test/user_service_profile_contract_test.dart` + `test/database_helper_horizontal_identity_test.dart` | ⚠️ PARTIAL |
| Persist logged-in operator remote ID | Missing operator ID in local profile | `test/horizontal_create_flow_test.dart` > `buildHorizontalCreatePlan allows only a non-syncable draft when operador_id is missing` | ✅ COMPLIANT |
| Validate new-format Horizontal creation inputs | Save blocked by missing required catalog ID | `test/horizontal_create_flow_test.dart` > `buildHorizontalCreatePlan blocks save when a cached catalog ID is missing` | ✅ COMPLIANT |
| Validate new-format Horizontal creation inputs | Save succeeds with required IDs present | `test/horizontal_create_flow_test.dart` > `resolved cached rows carry label snapshots and remote IDs`; `insertOperacionTalHorizontal stores a syncable row when all IDs exist` | ✅ COMPLIANT |
| Preserve draft and syncability state by identity completeness | Version boundary keeps scope narrow | `test/database_helper_horizontal_identity_test.dart` > `returns only syncable api v2 horizontal rows pending export`; `test/exportar_horizontal_service_test.dart` > `skips drafts and legacy rows...` | ✅ COMPLIANT |
| Preserve draft and syncability state by identity completeness | Complete identity becomes syncable | `test/horizontal_create_flow_test.dart` > `insertOperacionTalHorizontal stores a syncable row when all IDs exist` | ✅ COMPLIANT |
| Export API v2 payloads with remote IDs only | Export syncable new-format record | `test/exportar_horizontal_service_test.dart` > `exports persisted remote IDs for syncable api v2 horizontal rows`; `exports ids without depending on legacy label-based identity` | ✅ COMPLIANT |
| Export API v2 payloads with remote IDs only | Skip non-syncable draft export | `test/exportar_horizontal_service_test.dart` > `skips drafts and legacy rows when exporting horizontal api v2 payloads` | ✅ COMPLIANT |

**Compliance summary**: 8/9 scenarios fully compliant, 1/9 partial, 0 failing, 0 untested

### Correctness (Static Evidence)
| Requirement | Status | Notes |
|------------|--------|-------|
| DB stores remote identity and syncability flags | ✅ Implemented | DB v21 migration adds `operador_id`, `equipo_id`, `seccion_id`, `jefe_guardia_id`, `identity_version`, and `syncable`; pending query filters to `identity_version = 2 AND syncable = 1`. |
| Catalog refresh preserves backend IDs | ✅ Implemented | `HorizontalCatalogRepository` refreshes by `id` with transactional upsert + prune behavior. |
| Login/profile contract persists `operador_id` | ✅ Implemented | `UserService.getUserProfile()` throws when `operador_id` is missing; `login_screen.dart` persists profile through `saveUser()`. |
| Horizontal create blocks missing catalog IDs and allows draft-only missing operator | ✅ Implemented | `buildHorizontalCreatePlan()` blocks missing catalog IDs and returns non-syncable drafts when `operador_id` is absent; save path passes those flags into DB insertion. |
| Export payload uses IDs only and skips non-exportable rows | ✅ Implemented | `ExportarHorizontalService` exports only rows with `identity_version == 2`, `syncable == 1`, and non-null remote IDs. |

### Coherence (Design)
| Decision | Followed? | Notes |
|----------|-----------|-------|
| Reuse catalog `id` as backend stable identity | ✅ Yes | `Equipo`, `Seccion`, and `JefeGuardia` preserve backend `id` in model serialization and repository upsert. |
| Gate new-format rows with `identity_version = 2` | ✅ Yes | Create/save code writes version 2; pending export and UI exportability checks filter by `identity_version == 2`. |
| Persist `syncable` instead of inferring only at export time | ✅ Yes | Save flow stores `syncable`, export flow and selection UI both honor it. |

### Issues Found
**CRITICAL**
- `flutter test` broad verification fails because `test/widget_test.dart` is still the default counter smoke test and no longer matches the app shell (`MyApp` boots `LoginScreen`). This blocks a passing repo-wide verification result.
- `openspec/changes/api-v2-horizontal-offline-ids/tasks.md` still leaves task `4.3` unchecked, so the task artifact does not yet reflect completed broad verification and the change is not archive-ready.

**WARNING**
- `flutter analyze` returns rc=1 with 2450 issues. This is NOT a toolchain problem anymore: the local environment now runs Flutter 3.44.2 / Dart 3.12.2, which satisfies `pubspec.yaml` (`^3.11.1`).
- Scenario `Store operator identity after login` is only partially covered at runtime: tests verify the `/usuarios/perfil` contract and `saveUser()` persistence, but there is no passing runtime test proving the UI/create flow reads the stored `operador_id` from the local profile end-to-end.
- Changed-file coverage is low for several touched files (`login_screen.dart`, `sync_service.dart`, `operacion_card.dart`, `lista_perforacion_sreen.dart`, export selection UI, and catalog API services), so regressions in the interactive flow could still slip through.

**SUGGESTION**
- Replace or rewrite `test/widget_test.dart` to match the current `LoginScreen` app shell instead of the Flutter template counter.
- Add a focused runtime test that seeds a local user with `operador_id`, mounts the horizontal create flow, and proves the stored ID is propagated into the saved row.
- Add targeted tests for `SyncService`, export selection UI, and catalog API service wiring to raise changed-file coverage above the current 34.8% average.

### Verdict
FAIL
The change implementation is mostly aligned with the spec/design and its targeted Strict-TDD suite passes, but verification still fails because the broad repo test suite is red and the task artifact has not been closed out.
