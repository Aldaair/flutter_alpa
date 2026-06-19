## Verification Report

**Change**: offline-authz-normalization
**Version**: N/A
**Mode**: Strict TDD

### Completeness
| Metric | Value |
|--------|-------|
| Tasks total | 14 |
| Tasks complete | 14 |
| Tasks incomplete | 0 |

### Build & Tests Execution
**Build / Analyze**: ❌ Failed (`flutter analyze`, rc=1)
```text
Command: flutter analyze
Result: 2440 issues found. (ran in 1.8s)
Environment: Flutter 3.44.2 / Dart 3.12.2 satisfies pubspec sdk ^3.11.1
Classification: repo-wide static-analysis failure, not a toolchain blocker
Relevant change-file findings from targeted analyze:
- test/database_helper_horizontal_identity_test.dart and test/offline_authorization_dashboard_horizontal_test.dart import `package:path/path.dart`, but `path` is not declared in pubspec.yaml
- lib/screens/Dash/reporte_sreen.dart has change-area warnings: `unnecessary_null_comparison` and `unused_local_variable`
- most remaining findings are existing style/info noise (`avoid_print`, deprecated `withOpacity`, naming) in large legacy files
```

**Tests**: ❌ Failed broad suite / ✅ Passed targeted change suite
```text
Broad command: flutter test
Result: rc=1
Failure: test/widget_test.dart: Counter increments smoke test
Reason: the default Flutter counter smoke test still expects counter text "0"/"1", but the real app boots LoginScreen.
Classification: repo-wide / pre-existing, not introduced by this change.

Targeted commands:
- flutter test test/user_service_profile_contract_test.dart
- flutter test test/database_helper_horizontal_identity_test.dart
- flutter test test/offline_authorization_dashboard_horizontal_test.dart
- flutter test --coverage test/user_service_profile_contract_test.dart test/database_helper_horizontal_identity_test.dart test/offline_authorization_dashboard_horizontal_test.dart

Result: 18/18 targeted tests passed
```

**Coverage**: targeted changed-file coverage collected via `flutter test --coverage` → ⚠️ Below for multiple changed files

### TDD Compliance
| Check | Result | Details |
|-------|--------|---------|
| TDD Evidence reported | ❌ | No `apply-progress` artifact with a `TDD Cycle Evidence` table was available in OpenSpec, and the Engram apply-progress summary does not include that table |
| All tasks have tests | ⚠️ | 14/14 tasks are checked complete, but the login/explicit-refresh scenario lacks a passing entrypoint test |
| RED confirmed (tests exist) | ✅ | `test/user_service_profile_contract_test.dart`, `test/database_helper_horizontal_identity_test.dart`, and `test/offline_authorization_dashboard_horizontal_test.dart` exist |
| GREEN confirmed (tests pass) | ✅ | All 18 targeted change tests pass on execution |
| Triangulation adequate | ⚠️ | Parsing, fallback, repository filtering, and empty-equipment cases have multiple non-trivial assertions; login/refresh entrypoints are not triangulated at runtime |
| Safety Net for modified files | ⚠️ | Not verifiable because the strict-TDD apply artifact does not expose the required safety-net evidence |

**TDD Compliance**: 2/6 checks passed

---

### Test Layer Distribution
| Layer | Tests | Files | Tools |
|-------|-------|-------|-------|
| Unit | 5 | 1 | `flutter_test`, `http/testing` |
| Integration | 13 | 2 | `flutter_test`, `sqflite_common_ffi` |
| E2E | 0 | 0 | not installed |
| **Total** | **18** | **3** | |

Notes:
- `test/user_service_profile_contract_test.dart` behaves as a unit contract test.
- `test/database_helper_horizontal_identity_test.dart` and `test/offline_authorization_dashboard_horizontal_test.dart` execute real SQLite-backed flows, so they were classified as integration-style tests.

---

### Changed File Coverage
| File | Line % | Branch % | Uncovered Lines | Rating |
|------|--------|----------|-----------------|--------|
| `lib/config/data/database_helper.dart` | 6.2% | N/A | sample `L52`, `L69`, `L71`, `L92-93` | ⚠️ Low |
| `lib/config/data/offline_authorization_repository.dart` | 100.0% | N/A | — | ✅ Excellent |
| `lib/services/user_service.dart` | 82.8% | N/A | sample `L14-15`, `L21`, `L28-29`, `L45` | ⚠️ Acceptable |
| `lib/services/get nube/actualizacion_service.dart` | 0.0% | N/A | sample `L32`, `L38-39`, `L44-64`, `L71` | ⚠️ Low |
| `lib/screens/Dash/actualizacion_dialog.dart` | 0.0% | N/A | sample `L7`, `L11`, `L13-14`, `L63` | ⚠️ Low |
| `lib/screens/Dash/reporte_sreen.dart` | 17.3% | N/A | sample `L170-171`, `L173-174`, `L186-187`, `L190` | ⚠️ Low |
| `lib/screens/login/login_screen.dart` | 0.0% | N/A | sample `L9`, `L11-12`, `L25-27`, `L30-31` | ⚠️ Low |
| `lib/screens/Operaciones/Tal horizontal/widgets/operacion_card.dart` | 4.8% | N/A | sample `L38`, `L64`, `L74`, `L76-77` | ⚠️ Low |

**Average changed file coverage**: 26.4%

---

### Assertion Quality
**Assertion quality**: ✅ All assertions verify real behavior

---

### Quality Metrics
**Linter / Analyzer**: ❌ `flutter analyze` returned rc=1 with 2440 repo-wide issues
**Type Checker**: ➖ Covered by analyzer in this Dart/Flutter repo

### Spec Compliance Matrix
| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| Persist normalized offline authorization state | Store normalized auth relations | `test/user_service_profile_contract_test.dart` > `getUserProfile normalizes offline authorization payload`; `test/database_helper_horizontal_identity_test.dart` > `saveUserProfileSnapshot replaces normalized auth rows atomically` | ✅ COMPLIANT |
| Refresh auth state on online login and explicit refresh | Replace stale auth rows after online refresh | `test/database_helper_horizontal_identity_test.dart` > `saveUserProfileSnapshot replaces normalized auth rows atomically` | ⚠️ PARTIAL |
| Authorize Dashboard modules from normalized process access | Dashboard reads normalized process authorization | `test/offline_authorization_dashboard_horizontal_test.dart` > `dashboard prefers normalized process authorization over legacy JSON` | ✅ COMPLIANT |
| Authorize Dashboard modules from normalized process access | Dashboard uses transitional fallback before migration | `test/offline_authorization_dashboard_horizontal_test.dart` > `dashboard falls back to legacy authorization before normalized rows exist`; `test/database_helper_horizontal_identity_test.dart` > `offline authorization repository cuts over dashboard fallback` | ✅ COMPLIANT |
| Authorize Taladro Horizontal equipment from normalized equipment access | Taladro Horizontal shows only authorized equipment | `test/offline_authorization_dashboard_horizontal_test.dart` > `taladro horizontal returns only repository-authorized equipment` | ✅ COMPLIANT |
| Authorize Taladro Horizontal equipment from normalized equipment access | Zero authorized equipment yields empty list | `test/offline_authorization_dashboard_horizontal_test.dart` > `taladro horizontal stays open with an empty equipment list` | ✅ COMPLIANT |
| Bound legacy authorization fallback | Deprecated equipment field is ignored | `test/database_helper_horizontal_identity_test.dart` > `offline authorization repository ignores deprecated autorizado_equipo` | ✅ COMPLIANT |

**Compliance summary**: 6/7 scenarios fully compliant, 1/7 partial, 0 failing, 0 untested

### Correctness (Static Evidence)
| Requirement | Status | Notes |
|------------|--------|-------|
| Persist normalized offline authorization state | ✅ Implemented | DB version is 22, additive auth tables/indexes exist, and snapshot persistence replaces `UsuarioProceso` / `UsuarioEquipo` transactionally while keeping legacy `Usuario` fields. |
| Refresh auth state on online login and explicit refresh | ✅ Implemented | `login_screen.dart` and `ActualizacionService.refreshOfflineAuthorizationSnapshot()` both route through `UserService.syncOfflineProfileSnapshot()`. |
| Dashboard authorization prefers normalized process rows with bounded fallback | ✅ Implemented | `loadDashboardAuthorizationState()` reads repository-backed normalized processes first and decodes `operaciones_autorizadas` only when no normalized process rows exist. |
| Taladro Horizontal uses normalized equipment authorization | ✅ Implemented | `loadAuthorizedHorizontalEquipos()` resolves the canonical horizontal process from repository auth and filters `Equipo.id` against normalized `UsuarioEquipo` rows. |
| Deprecated equipment field grants nothing | ✅ Implemented | `OfflineAuthorizationRepository.getAuthorizedEquipoIds()` only reads `UsuarioEquipo`; `Usuario.autorizado_equipo` is never consulted for equipment grants. |

### Coherence (Design)
| Decision | Followed? | Notes |
|----------|-----------|-------|
| Additive auth tables instead of mutating legacy `Usuario` schema semantics | ✅ Yes | `ProcesoAutorizado`, `UsuarioProceso`, and `UsuarioEquipo` were added while legacy columns remain intact. |
| Shared repository read path for Dashboard and Taladro Horizontal | ✅ Yes | `OfflineAuthorizationRepository` is the common reader used by both flows. |
| Keep `operaciones_autorizadas` as Dashboard-only fallback and ignore `autorizado_equipo` | ✅ Yes | Dashboard fallback is bounded to the no-normalized-rows case; Taladro Horizontal equipment access never reads the deprecated field. |
| Reuse existing online refresh flow instead of `SyncService` upload logic | ✅ Yes | `ActualizacionService` exposes an `Autorizaciones` refresh option that reuses `UserService` profile sync. |

### Issues Found
**CRITICAL**
- Strict TDD verification is incomplete because no `apply-progress` artifact with the required `TDD Cycle Evidence` table was available. The Engram summary is not enough to prove RED / safety-net discipline.
- Spec scenario `Replace stale auth rows after online refresh` is only partially proven. Runtime tests cover transactional replacement itself, but there is no passing test that exercises the actual login or explicit-refresh entrypoints that trigger that replacement.
- `flutter test` broad verification fails because `test/widget_test.dart` is still the default counter smoke test and no longer matches the app shell. This is a repo-wide pre-existing failure, but it still blocks an all-green verification result.

**WARNING**
- `flutter analyze` returns rc=1 with 2440 repo-wide issues; targeted analyze for this slice still reports 274 findings, including a change-specific missing direct dependency on `path` for the new tests.
- Changed-file coverage is low for the interactive entrypoints (`login_screen.dart`, `actualizacion_service.dart`, `actualizacion_dialog.dart`, `reporte_sreen.dart`, `operacion_card.dart`) even though repository-level logic is covered.
- `lib/screens/Dash/reporte_sreen.dart` has targeted analyzer warnings (`unnecessary_null_comparison`, `unused_local_variable`) in the changed area.

**SUGGESTION**
- Add a focused runtime test for `LoginScreen` and/or `ActualizacionService` that proves online login and explicit refresh both persist a newer normalized auth snapshot end-to-end.
- Replace or rewrite `test/widget_test.dart` to match the current `LoginScreen` app shell instead of the Flutter template counter app.
- Add `path` as a direct dev dependency or remove the package import from the new test files.

### Verdict
FAIL
The normalized offline authorization implementation largely matches the spec/design and its focused test suite passes, but Strict TDD proof is incomplete and broad repo verification is still red.
