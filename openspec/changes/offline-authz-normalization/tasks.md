# Tasks: Offline Authz Normalization

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 480-650 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 foundation + tests -> PR 2 refresh/UI wiring |
| Delivery strategy | chained-pr |
| Chain strategy | stacked-to-main |

Decision needed before apply: No
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Normalize auth storage + repository + RED/GREEN tests | PR 1 | Base slice; DB, parser, repository, verification together |
| 2 | Wire login, Dashboard refresh, and Taladro Horizontal reads | PR 2 | Depends on PR 1; UI + service integration + focused behavior tests |

## Phase 1: RED / Foundation Tests

- [x] 1.1 Extend `test/user_service_profile_contract_test.dart` with failing cases for normalized `procesos`, `usuario_procesos`, `usuario_equipos`, and missing/invalid auth payload shapes.
- [x] 1.2 Extend `test/database_helper_horizontal_identity_test.dart` with failing checks for schema 22 tables/indexes, transactional auth replacement, Dashboard fallback cutoff, and deprecated `autorizado_equipo` being ignored.

## Phase 2: Data Model + Persistence

- [x] 2.1 Modify `lib/config/data/database_helper.dart` to bump schema 21->22, create `ProcesoAutorizado`, `UsuarioProceso`, `UsuarioEquipo`, and add guarded `_onUpgrade` creation/index logic.
- [x] 2.2 Add transactional snapshot writers/read helpers in `database_helper.dart` for profile upsert plus normalized auth replacement keyed by `codigo_dni` and backend `proceso_id`.
- [x] 2.3 Modify `lib/services/user_service.dart` to validate and normalize `/usuarios/perfil` auth relations into a single profile snapshot contract used by persistence.
- [x] 2.4 Create `lib/config/data/offline_authorization_repository.dart` with repository methods for normalized process reads, Dashboard fallback, and authorized equipment IDs by process.

## Phase 3: Integration Wiring

- [x] 3.1 Modify `lib/screens/login/login_screen.dart` to persist the normalized profile snapshot after successful online login before Dashboard navigation.
- [x] 3.2 Modify `lib/services/get nube/actualizacion_service.dart` to add an auth/profile refresh path reused by the daily connectivity window and explicit Dashboard-triggered refresh.
- [x] 3.3 Modify `lib/screens/Dash/actualizacion_dialog.dart` and `lib/screens/Dash/reporte_sreen.dart` so Dashboard refresh exposes the auth option and module visibility prefers repository auth, falling back only when normalized rows are absent.
- [x] 3.4 Modify `lib/screens/Operaciones/Tal horizontal/widgets/operacion_card.dart` to filter selectable `Equipo.id` values through the repository while allowing module entry with an empty equipment list.

## Phase 4: GREEN / Verification

- [x] 4.1 Make Phase 1 tests pass and add focused assertions that stale normalized rows are replaced atomically after login/refresh.
- [x] 4.2 Verify Dashboard scenarios: normalized process rows control visibility, legacy `operaciones_autorizadas` only applies before first normalized snapshot.
- [x] 4.3 Verify Taladro Horizontal scenarios: only authorized equipment is selectable, zero authorized equipment yields an empty list, and `autorizado_equipo` grants nothing.

## Phase 5: Cleanup / Apply Readiness

- [x] 5.1 Update `openspec/changes/offline-authz-normalization/tasks.md` during apply with completion state and keep PR slices aligned to the chosen chain strategy.
