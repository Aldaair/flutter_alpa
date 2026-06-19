## Exploration: api-v2-horizontal-offline-ids

### Current State
Taladro Horizontal is offline-first and stores one header row per shift in `Operacion_tal_horizontal`, then appends per-state details inside the `registros` JSON column. The operation header is created from `OperacionCard` UI selections and currently saves display strings for `seccion`, `operador`, `jefe_guardia`, `equipo`, `n_equipo`, and `modelo_equipo`. The logged-in user is resolved locally from `Usuario` by DNI and shown as a full name, but the local user table does not persist a remote backend user ID. Catalog refresh for `Equipo`, `Seccion`, `jefe_guardias`, and `Guardia` fetches API data, deletes local rows, removes backend `id`, and reinserts records with fresh SQLite autoincrement IDs, so local IDs are not stable remote IDs. When connectivity returns, `ConnectionProvider` triggers `SyncService`, which loads closed unsent horizontal rows, `ExportarHorizontalService` serializes them, strips `local_id`, and posts payloads that still contain legacy string fields (`seccion`, `operador`, `jefe_guardia`, `equipo`).

### Affected Areas
- `lib/screens/Operaciones/Tal horizontal/widgets/operacion_card.dart` — loads offline catalogs, resolves operator from local `Usuario`, and captures the selected display values used to create a horizontal operation.
- `lib/screens/Operaciones/Tal horizontal/lista_perforacion_sreen.dart` — creates Taladro Horizontal header rows via `insertOperacionTalHorizontal` and drives the offline operation lifecycle.
- `lib/config/data/database_helper.dart` — owns SQLite schema, user persistence, horizontal operation persistence, and catalog read helpers; this is the primary migration point.
- `lib/services/envio nube/horizontal/exportar_service.dart` — builds the sync payload and currently exports legacy display strings instead of API v2 IDs.
- `lib/core/sync/sync_service.dart` — batches closed offline horizontal records and sends them automatically after reconnection.
- `lib/services/get nube/llamadas/api_services_Equipo.dart` — refreshes equipment catalog but discards backend IDs before saving locally.
- `lib/services/get nube/llamadas/ApiServiceSeccion.dart` — refreshes section catalog but replaces backend IDs with local autoincrement IDs.
- `lib/services/get nube/llamadas/ApiServiceJefeGuardia.dart` — refreshes guard catalog but stores only names, not remote identifiers.
- `lib/services/get nube/actualizacion_service.dart` — orchestrates manual online catalog refresh, which is where renamed backend labels can flow back into offline caches.
- `lib/screens/login/login_screen.dart` and `lib/services/user_service.dart` — fetch and persist the logged-in user profile, which must become the source of `operador_id`.
- `lib/config/api/api_config.dart` and `lib/services/envio nube/operaciones_service.dart` — hold current API endpoints and sync transport assumptions; likely need new catalog/profile endpoints for API v2.

### Approaches
1. **Dual-key local catalogs** — Keep human-readable labels for UX, but persist backend IDs alongside them in local catalog tables and in `Operacion_tal_horizontal`.
   - Pros: Preserves offline UX, keeps sync payload deterministic, supports backend label refresh without mutating already-selected IDs, and fits the current offline-first shape.
   - Cons: Requires schema migrations for user, catalogs, and horizontal operations; touches creation, querying, and export paths together.
   - Effort: Medium

2. **Late ID resolution at sync time** — Keep storing only display strings offline and resolve IDs against fresh catalogs just before upload.
   - Pros: Smaller schema change up front.
   - Cons: Fragile offline contract, breaks when labels change, cannot guarantee `operador_id` from the logged-in user, and conflicts with the confirmed decision to avoid legacy fallback for pending horizontal records.
   - Effort: Medium

### Recommendation
Use **Dual-key local catalogs**. Add stable remote ID columns to the local user and horizontal-specific catalogs (`Usuario`, `Equipo`, `Seccion`, `jefe_guardias`, and likely `Guardia` if shift metadata later follows the same pattern), and persist both remote IDs and display labels in `Operacion_tal_horizontal`. For Taladro Horizontal header rows, store `operador_id`, `jefe_guardia_id`, `equipo_id`, and `seccion_id` as the backend IDs selected offline, while retaining label/code/model snapshots for UI and audit readability. `operador_id` should come exclusively from the logged-in local user record, not from a dropdown. Catalog refresh should upsert by remote ID so the same entities keep their identity while labels are refreshed on the next online update. The sync exporter should send API v2 IDs plus existing nested JSON fields, without any legacy name-to-ID translation for pending horizontal rows created after this release. Backend assumptions for this approach are: authenticated profile payload must expose a stable user ID; catalog endpoints must return stable IDs with labels for horizontal-compatible entities; and a dedicated offline-user-catalog endpoint is recommended if the existing profile endpoint cannot provide the operator identity and any horizontal-specific operator metadata needed offline.

### Risks
- SQLite migration risk: existing `Operacion_tal_horizontal` rows store only strings, so the change must define a clear boundary for pre-release/new-format-only records and avoid pretending old rows can be upgraded safely without source IDs.
- Catalog refresh risk: current refresh flow deletes and reinserts rows, so changing to remote-ID upserts is required or cached selections will continue to drift from backend identity.
- User identity risk: if `/usuarios/perfil` does not return a stable backend ID, `operador_id` cannot be derived correctly offline.
- Contract risk: if backend IDs are not immutable across catalog updates, cached offline selections become unreliable.

### Ready for Proposal
Yes — proceed to `sdd-propose` with a narrow scope: Taladro Horizontal only, new-format-only records, schema migration for remote IDs, catalog upsert-by-remote-ID, logged-in user remote ID persistence, and exporter/API v2 payload conversion. Call out the required backend contract explicitly before implementation.
