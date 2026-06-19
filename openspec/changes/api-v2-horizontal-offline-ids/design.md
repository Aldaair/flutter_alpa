# Design: API V2 Horizontal Offline IDs

## Technical Approach

Taladro Horizontal will keep backend IDs as identity and keep current text fields as label snapshots. The change stays narrow: migrate the local user and `Operacion_tal_horizontal` schema, stop catalog refresh from `deleteAll()+insert`, resolve selected dropdown labels back to cached remote IDs before save, and export only rows explicitly marked as API v2 syncable.

## Architecture Decisions

| Decision | Alternatives considered | Choice / Rationale |
|---|---|---|
| Catalog identity | Add `remote_id` columns everywhere | Reuse existing catalog `id` as the backend stable ID for `Equipo`, `Seccion`, and `jefe_guardias`. Those tables already deserialize backend `id`, so keeping explicit IDs is the smallest change. |
| Horizontal version boundary | Infer by date/app build outside DB | Add `identity_version` on `Operacion_tal_horizontal` (`0=legacy`, `2=api-v2`). Creation writes `2`; existing rows stay `0`, so legacy rows are never reclassified. |
| Draft syncability | Infer at export time only | Persist `syncable` (`1/0`) on the row. Missing `operador_id` creates a saved local draft with `syncable=0`; missing `equipo_id`, `seccion_id`, or `jefe_guardia_id` blocks save entirely. |

## Data Flow

`login_screen` → `UserService.getUserProfile()` → `DatabaseHelper.saveUser(operador_id)`

`ActualizacionService` → catalog API services → transactional catalog upsert by backend `id` → cached labels refreshed

`OperacionCard` selections (label) → DB lookup of selected catalog rows → `lista_perforacion_sreen` save request → `DatabaseHelper.insertOperacionTalHorizontal(...)` writes IDs + label snapshots + `identity_version/syncable`

`SyncService` → `getOperacionesTaladroHorizontalNoEnviadas()` → `ExportarHorizontalService` builds API v2 payload with IDs only → mark `envio=1`

## File Changes

| File | Action | Description |
|---|---|---|
| `lib/config/data/database_helper.dart` | Modify | Bump DB to 21; migrate `Usuario.operador_id`; add `operador_id`, `equipo_id`, `seccion_id`, `jefe_guardia_id`, `identity_version`, `syncable` to `Operacion_tal_horizontal`; add catalog upsert/query helpers; narrow pending-sync query to `identity_version = 2 AND syncable = 1`. |
| `lib/models/Equipo.dart` | Modify | Keep backend `id` during local persistence; no longer strip it before save. |
| `lib/models/Seccion.dart` | Modify | Same as `Equipo`; use backend `id` as local identity. |
| `lib/models/JefeGuardia.dart` | Modify | Add backend `id` and preserve names as label snapshot. |
| `lib/services/get nube/llamadas/api_services_Equipo.dart` | Modify | Replace delete/reinsert with transaction: upsert incoming rows by `id`, then delete rows not present in the fetched ID set. |
| `lib/services/get nube/llamadas/ApiServiceSeccion.dart` | Modify | Same remote-ID-based refresh pattern. |
| `lib/services/get nube/llamadas/ApiServiceJefeGuardia.dart` | Modify | Same remote-ID-based refresh pattern. |
| `lib/screens/login/login_screen.dart` | Modify | Persist profile including `operador_id` on successful online login. |
| `lib/services/user_service.dart` | Modify | Document/validate that `/usuarios/perfil` returns `operador_id`. |
| `lib/screens/Operaciones/Tal horizontal/widgets/operacion_card.dart` | Modify | Load full catalog rows, not names only; map the selected label/codigo/modelo to the cached remote IDs and pass them in create payload. |
| `lib/screens/Operaciones/Tal horizontal/lista_perforacion_sreen.dart` | Modify | Enforce save blocking for missing required catalog IDs and allow only `operador_id`-missing local drafts. |
| `lib/services/envio nube/horizontal/exportar_service.dart` | Modify | Export API v2 fields from persisted IDs only and skip non-syncable drafts defensively. |

## Interfaces / Contracts

```dart
class HorizontalIdentityDraft {
  final int identityVersion; // 2 for this release
  final int? operadorId;
  final int equipoId;
  final int seccionId;
  final int jefeGuardiaId;
  final bool syncable; // operadorId != null
}
```

Persisted row contract:
- keep existing text columns (`operador`, `equipo`, `seccion`, `jefe_guardia`, `n_equipo`, `modelo_equipo`) as local display snapshots
- add integer ID columns for remote identity
- exporter payload reads only the ID columns for identity fields

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit | DB migration 20→21; syncability/version flags; catalog upsert semantics | `flutter_test` against `DatabaseHelper` helpers with in-memory/temp DB. |
| Unit | Horizontal exporter skips drafts and emits IDs only | `flutter_test` on `ExportarHorizontalService`. |
| Integration | Login profile save + horizontal create flow | Widget/service test around `saveUser`, `OperacionCard`, and `_handleNuevaOperacion`. |
| E2E | Not available | None in repo. |

## Migration / Rollout

Release with DB version 21. Migration is additive for `Usuario` and `Operacion_tal_horizontal`; existing horizontal rows remain `identity_version=0` and are ignored by the new API v2 export path. Catalog transition happens on next refresh: upsert incoming backend IDs, update labels in place, and delete rows missing from the latest payload. No legacy name-to-ID fallback is introduced.

## Open Questions

- [ ] Confirm final backend payload names for horizontal ID fields (`operador_id`, `equipo_id`, `seccion_id`, `jefe_guardia_id`) so exporter keys match the released contract exactly.
