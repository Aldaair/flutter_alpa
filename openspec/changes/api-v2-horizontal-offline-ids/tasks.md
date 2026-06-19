# Tasks: API V2 Horizontal Offline IDs

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 550-800 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 foundation/catalogs -> PR 2 horizontal flow/export/tests |
| Delivery strategy | single-pr |
| Chain strategy | pending |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: pending
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | DB/model/catalog identity foundation | PR 1 | Include DB migration, model updates, catalog upsert tests |
| 2 | Horizontal save/export flow | PR 2 | Depends on PR 1; include widget/service tests and analyzer/test pass |

## Phase 1: Foundation

- [x] 1.1 RED: add `test/database_helper_horizontal_identity_test.dart` for DB v20->21 migration, `Usuario.operador_id`, `Operacion_tal_horizontal.identity_version/syncable`, and pending-sync filtering.
- [x] 1.2 Update `lib/config/data/database_helper.dart` to DB version 21, add additive migration helpers, extend `saveUser`, `insertOperacionTalHorizontal`, and pending-sync queries for API v2 identity fields.
- [x] 1.3 Update `lib/models/Equipo.dart`, `lib/models/Seccion.dart`, and `lib/models/JefeGuardia.dart` so backend `id` remains the local identity and labels stay available for display.

## Phase 2: Catalog Refresh + Login

- [x] 2.1 RED: extend the DB test to prove catalog refresh upserts by remote `id`, updates labels in place, and removes rows absent from the latest payload.
- [x] 2.2 Modify `lib/services/get nube/llamadas/api_services_Equipo.dart`, `ApiServiceSeccion.dart`, and `ApiServiceJefeGuardia.dart` to replace `deleteAll()+insert` with transactional upsert-by-id refresh.
- [x] 2.3 Modify `lib/screens/login/login_screen.dart` and `lib/services/user_service.dart` so online login persists `operador_id` from `/usuarios/perfil` and fails loudly if the contract is missing.

## Phase 3: Horizontal Create Flow

- [x] 3.1 RED: add `test/horizontal_create_flow_test.dart` covering save blocked by missing cached `equipo_id/seccion_id/jefe_guardia_id`, draft-only save when `operador_id` is missing, and syncable save when all IDs exist.
- [x] 3.2 Modify `lib/screens/Operaciones/Tal horizontal/widgets/operacion_card.dart` to load full cached rows, resolve selected labels/codigo/modelo to remote IDs, and pass both IDs and label snapshots.
- [x] 3.3 Modify `lib/screens/Operaciones/Tal horizontal/lista_perforacion_sreen.dart` and `DatabaseHelper.insertOperacionTalHorizontal(...)` wiring so new rows write `identity_version=2`, persist remote IDs, block missing catalog IDs, and allow only non-syncable drafts for missing `operador_id`.

## Phase 4: Export + Verification

- [x] 4.1 RED: add `test/exportar_horizontal_service_test.dart` proving `lib/services/envio nube/horizontal/exportar_service.dart` exports remote IDs only and skips `syncable=0` drafts.
- [x] 4.2 Implement exporter filtering/payload changes in `exportar_service.dart`; confirm no legacy name-to-ID fallback remains for Horizontal.
- [ ] 4.3 Run `flutter test`, `flutter analyze`, and targeted migration/export tests after upgrading local Dart/Flutter to satisfy `pubspec.yaml` (`^3.11.1`); until then, record the SDK mismatch as a verification blocker.
