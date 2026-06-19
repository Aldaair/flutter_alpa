# Proposal: Offline Authz Normalization

## Intent

Normalize offline authorization so Dashboard module visibility and Taladro Horizontal equipment availability come from additive local auth tables instead of legacy user fields. This reduces drift with the already-normalized backend and lets the app refresh critical auth data during the daily connectivity window or via an explicit user-triggered refresh.

## Scope

### In Scope
- Add local normalized auth tables: `ProcesoAutorizado`, `UsuarioProceso`, and `UsuarioEquipo`, keyed by backend process IDs and persisted `Equipo.id`.
- Persist normalized auth payloads on online profile refresh/login, compare them against local auth state, and update them transactionally.
- Move Dashboard auth reads to normalized process authorization with fallback to `Usuario.operaciones_autorizadas` when normalized rows are absent.
- Filter Taladro Horizontal equipment by `UsuarioEquipo`; users may still enter the module and see an empty list when no equipment is authorized.
- Support refresh of auth-critical data during normal connectivity windows and via a user-triggered refresh action.

### Out of Scope
- Removing legacy columns or finishing legacy cleanup in this change.
- Expanding normalized equipment authorization to screens beyond Dashboard and Taladro Horizontal.
- Revisiting the completed `api-v2-horizontal-offline-ids` work.

## Capabilities

### New Capabilities
- `offline-authorization`: Normalized local process/equipment authorization storage, refresh, and read paths for offline use.

### Modified Capabilities
- None.

## Approach

Use additive migration only: bump DB version, create new auth tables/indexes, keep `Usuario` as the identity table, keep `operaciones_autorizadas` as transitional fallback, and treat `autorizado_equipo` as deprecated compatibility data. Backend contract assumption: `/usuarios/perfil` returns normalized auth data for `usuarios`, `procesos`, `usuario_procesos`, and `usuario_equipos`, with backend process IDs as canonical process identity and equipment references matching persisted local `Equipo.id`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/config/data/database_helper.dart` | Modified | Add schema, migration, transactional auth persistence |
| `lib/services/user_service.dart` | Modified | Validate/map normalized auth payloads |
| `lib/screens/Dash/reporte_sreen.dart` | Modified | Read normalized process auth with legacy fallback |
| `lib/screens/Operaciones/Tal horizontal/widgets/operacion_card.dart` | Modified | Apply `UsuarioEquipo` filtering and empty-state behavior |
| `lib/screens/login/login_screen.dart` | Modified | Ensure online auth refresh feeds offline state |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Backend omits normalized auth relations | Med | Keep fallback read path and fail contract checks loudly |
| Dual-read transition causes inconsistent access | Med | Centralize auth reads in one repository/helper |

## Rollback Plan

Rollback by disabling normalized readers, keeping legacy `operaciones_autorizadas` as the active source, and leaving additive tables unused. Do not drop new tables or legacy columns in this change.

## Dependencies

- Backend `/usuarios/perfil` MUST expose normalized process/equipment auth relations.
- Prior stable remote-ID behavior from `api-v2-horizontal-offline-ids` remains a prerequisite, but this change stays separate because it changes offline authorization domain behavior, not catalog identity plumbing.

## Success Criteria

- [ ] Dashboard authorization works from normalized process rows after online refresh/login, with legacy fallback preserved for pre-migration users.
- [ ] Taladro Horizontal shows only authorized equipment offline and shows an empty list, not a failure, when authorization is empty.
- [ ] Auth data can be refreshed during available connectivity and via an explicit user-triggered refresh path.
