# Design: Offline Authz Normalization

## Technical Approach

Add a small offline-authorization layer on top of the existing user-scoped SQLite database. The change keeps `Usuario` as the login/profile record, stores normalized auth snapshots in additive tables, writes them during online profile persistence, and introduces one repository so Dashboard and Taladro Horizontal read the same local rules. This stays separate from the completed horizontal API v2 ID migration: that work stabilized catalog identities; this work uses those identities for authorization.

## Architecture Decisions

| Decision | Options | Choice | Rationale |
|---|---|---|---|
| Auth storage | Reuse JSON fields vs additive tables | Additive tables `ProcesoAutorizado`, `UsuarioProceso`, `UsuarioEquipo` | Preserves offline login compatibility while enabling relational reads and transactional replacement. |
| Read path | Screen-specific SQL vs shared repository | Shared repository/helper | Avoids dual-read drift during transition and keeps Dashboard/Taladro rules consistent. |
| Legacy fallback | Remove immediately vs bounded fallback | Keep `operaciones_autorizadas` only for Dashboard when no normalized process rows exist | Protects pre-refresh users without letting deprecated `autorizado_equipo` keep granting access. |

## Data Flow

```text
/usuarios/perfil
  -> UserService validates normalized auth payload
  -> DatabaseHelper.saveUserProfileSnapshot(...)
      -> upsert Usuario
      -> replace UsuarioProceso/UsuarioEquipo rows in one transaction
  -> OfflineAuthorizationRepository
      -> Dashboard process visibility
      -> Taladro Horizontal equipment filtering
```

Refresh entry points remain:
- online login in `lib/screens/login/login_screen.dart`
- explicit Dashboard refresh via `ActualizacionService`
- daily connectivity window by routing the same profile-refresh action through the existing online refresh flow, not through `SyncService` upload logic

## File Changes

| File | Action | Description |
|---|---|---|
| `lib/config/data/database_helper.dart` | Modify | Bump DB version, add auth tables/indexes, add migration 21->22, and transactional auth snapshot persistence/read helpers. |
| `lib/services/user_service.dart` | Modify | Validate and normalize `/usuarios/perfil` auth relations (`procesos`, `usuario_procesos`, `usuario_equipos`). |
| `lib/config/data/offline_authorization_repository.dart` | Create | Central read model for authorized process IDs, Dashboard fallback, and Taladro Horizontal equipment IDs. |
| `lib/screens/login/login_screen.dart` | Modify | Persist normalized auth snapshot after successful online login. |
| `lib/screens/Dash/reporte_sreen.dart` | Modify | Load module visibility from repository first, fallback only when normalized rows are absent. |
| `lib/services/get nube/actualizacion_service.dart` | Modify | Add an auth/profile refresh option that reuses `UserService` + DB persistence during explicit refresh. |
| `lib/screens/Dash/actualizacion_dialog.dart` | Modify | Expose the auth refresh action in the existing refresh UI. |
| `lib/screens/Operaciones/Tal horizontal/widgets/operacion_card.dart` | Modify | Filter horizontal equipment by repository-authorized `Equipo.id`, while allowing empty results. |
| `test/user_service_profile_contract_test.dart` | Modify | Assert normalized auth payload validation/parsing. |
| `test/database_helper_horizontal_identity_test.dart` | Modify | Cover migration and auth snapshot replacement. |

## Interfaces / Contracts

```dart
class OfflineAuthorizationRepository {
  Future<Set<int>> getAuthorizedProcessIds(String dni);
  Future<bool> hasNormalizedProcessAuth(String dni);
  Future<bool> isDashboardProcessAuthorized(String dni, int processId, String legacyKey);
  Future<Set<int>> getAuthorizedEquipoIds({required String dni, required int processId});
}
```

SQLite additions:
- `ProcesoAutorizado(id INTEGER PRIMARY KEY, nombre TEXT NOT NULL)`
- `UsuarioProceso(codigo_dni TEXT, proceso_id INTEGER, PRIMARY KEY(codigo_dni, proceso_id))`
- `UsuarioEquipo(codigo_dni TEXT, proceso_id INTEGER, equipo_id INTEGER, PRIMARY KEY(codigo_dni, proceso_id, equipo_id))`
- indexes on `codigo_dni` and `(codigo_dni, proceso_id)`

`codigo_dni` should be the join key to match the repo’s user-scoped DB and avoid depending on local `Usuario.id` values.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit | Profile contract parsing | Extend `test/user_service_profile_contract_test.dart` with valid/missing normalized auth cases. |
| Unit/DB | Migration + transactional replacement | Extend `test/database_helper_horizontal_identity_test.dart` to verify 21->22 tables, row replacement, and no fallback after normalized rows exist. |
| Widget/light integration | Dashboard/Taladro read behavior | Prefer focused repository-backed tests over broad widget tests; current widget suite is minimal. |

## Migration / Rollout

Migration is additive only. Bump schema to 22, create new tables in `_onCreate`, and add guarded `oldVersion < 22` creation/index steps in `_onUpgrade`. Existing users keep access through `operaciones_autorizadas` until they complete an online login or explicit auth refresh. After normalized rows exist, Dashboard stops using the fallback for that user. Taladro Horizontal never reads `autorizado_equipo`; zero authorized equipment returns an empty selector list, not a module denial.

## Open Questions

- [ ] None.
