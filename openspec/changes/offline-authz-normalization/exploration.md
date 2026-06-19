## Exploration: offline-authz-normalization

### Current State
Local offline authorization is still split between one legacy JSON-like field and one effectively unused legacy text field. `DatabaseHelper._onCreate()` defines `Usuario.operaciones_autorizadas TEXT` and `Usuario.autorizado_equipo TEXT`, and `DatabaseHelper.saveUser()` persists both from the online profile (`lib/config/data/database_helper.dart`). Dashboard visibility is driven only by `operaciones_autorizadas`: `DashboardScreen` loads the stored user, `jsonDecode`s that field, and conditionally renders each module button with `estaAutorizadoPara(...)` (`lib/screens/Dash/reporte_sreen.dart`). I verified NO current reader for `autorizado_equipo`; it is write-only today. Equipment selection is also not user-authorized yet: Taladro Horizontal loads all local `Equipo` rows through `DatabaseHelper.getEquipos()`, then filters only by `equipo.proceso == 'PERFORACIÓN HORIZONTAL'` before showing options (`lib/screens/Operaciones/Tal horizontal/widgets/operacion_card.dart`). That means offline module authorization exists, but offline equipment authorization does not actually exist in code yet. The recent `api-v2-horizontal-offline-ids` work already made local `Usuario.operador_id`, `Operacion_tal_horizontal.*_id`, and catalog IDs stable enough to support normalized joins without disturbing sync.

### Affected Areas
- `lib/config/data/database_helper.dart` — owns the `Usuario` schema, migrations, `saveUser()`, `getUserByDni()`, and all catalog reads; this is the main migration point.
- `lib/screens/Dash/reporte_sreen.dart` — current and only reader of `operaciones_autorizadas`; must switch to normalized process authorization with fallback.
- `lib/screens/login/login_screen.dart` — online login is where the local user snapshot is persisted before offline use.
- `lib/services/user_service.dart` — current `/usuarios/perfil` contract validation only requires `operador_id`; normalized auth payload shape must be validated here or via a dedicated mapper.
- `lib/screens/Operaciones/Tal horizontal/widgets/operacion_card.dart` — current equipment picker loads all horizontal equipment; this is the first realistic place to enforce offline `usuario_equipos` filtering.
- `lib/config/data/horizontal_catalog_repository.dart` — already resolves cached equipment/catalog IDs and can be reused by a new offline auth repository instead of duplicating lookup logic.
- `lib/services/get nube/llamadas/api_services_Equipo.dart` — depends on stable local `Equipo.id`; normalized `usuario_equipos` should reference these persisted remote IDs.
- `test/user_service_profile_contract_test.dart` — should expand to assert normalized auth payload requirements.
- `test/database_helper_horizontal_identity_test.dart` — existing user persistence coverage is the closest DB test anchor, but auth normalization likely deserves its own focused repository/migration tests.

### Approaches
1. **Parallel normalized auth tables with legacy fallback** — Add local normalized auth tables now, keep legacy `Usuario` fields during transition, and migrate readers incrementally.
   - Pros: Lowest risk to offline login, preserves dashboard behavior during rollout, reuses the new remote-ID horizontal foundation, and lets equipment filtering start with one screen.
   - Cons: Temporary dual-write/dual-read complexity until legacy fields are removed.
   - Effort: Medium

2. **Immediate replacement of legacy fields** — Remove JSON/text auth usage as soon as normalized tables land and switch all readers in one cutover.
   - Pros: Cleaner end state faster, no prolonged fallback logic.
   - Cons: Higher migration risk, larger review surface, and unsafe unless the profile payload already guarantees normalized auth data for every offline login path.
   - Effort: High

### Recommendation
Use **Parallel normalized auth tables with legacy fallback** and keep this change SEPARATE from `api-v2-horizontal-offline-ids`.

Minimum normalized local model:
- keep existing `Usuario` as the offline identity/profile table
- add `ProcesoAutorizado` (or `ProcesoAuth`) for canonical process/module keys and labels
- add `UsuarioProceso` keyed by local user (`codigo_dni` or `Usuario.id`) + process key/id
- add `UsuarioEquipo` keyed by local user + `Equipo.id`

Field disposition:
- `Usuario.operaciones_autorizadas` — **transitional**; keep writing it until dashboard and any other readers fully move to normalized tables
- `Usuario.autorizado_equipo` — **deprecated immediately**; there are no verified readers, so it only needs compatibility retention, not continued product dependence

Minimum safe migration path:
1. Bump DB version additively and create the new auth tables plus indexes; do NOT remove legacy columns.
2. Extend the online profile persistence path to store normalized process/equipment authorizations transactionally after successful login.
3. Add one auth repository/helper that reads normalized rows first and falls back to legacy `operaciones_autorizadas` when no normalized process rows exist.
4. Move `DashboardScreen` to that repository first.
5. Enforce equipment authorization first in `Tal horizontal/widgets/operacion_card.dart` by intersecting the horizontal process catalog with `UsuarioEquipo`; leave other operation screens for a later slice unless the proposal explicitly broadens scope.
6. After normalized readers are stable, stop writing `autorizado_equipo`; remove legacy fields only in a later cleanup change.

This ordering protects offline login and DOES NOT interfere with the new horizontal sync path because the horizontal exporter and operation persistence use `operador_id` and cached catalog IDs, not the legacy authorization fields.

### Risks
- Contract risk: `/usuarios/perfil` currently validates only `operador_id`; if normalized auth arrays/relations are not included yet, local tables cannot be populated reliably.
- Scope risk: applying equipment authorization across every operation screen now would expand the change far beyond the minimum safe slice.
- Identity risk: `UsuarioEquipo` is only safe if local `Equipo.id` continues to represent the backend-stable remote ID, which the previous horizontal change now assumes.
- Migration risk: dual-read logic must be explicit, or offline users with pre-migration DBs could lose dashboard access until they log in online again.

### Ready for Proposal
Yes — proceed with a proposal scoped to additive local auth normalization, dashboard process authorization migration, and Taladro Horizontal equipment filtering first. Keep it as a separate change from `api-v2-horizontal-offline-ids`; that earlier change is dependency/foundation work, while this one is broader offline authorization domain behavior.
