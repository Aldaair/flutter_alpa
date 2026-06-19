# Proposal: API V2 Horizontal Offline IDs

## Intent
Move Taladro Horizontal offline records to API v2 remote-ID identity so locally created operations sync with stable backend IDs instead of display names.

## Scope
### In Scope
- Taladro Horizontal only, starting with the released app version that introduces this change.
- Persist remote IDs plus label snapshots for operator, section, guard leader, and equipment in local profile, catalogs, and `Operacion_tal_horizontal`.
- Export only API v2 ID-based payloads for new-format records; block save when required catalog IDs are missing, except allow drafts when `operador_id` is missing.

### Out of Scope
- Legacy name-to-ID fallback or retrofitting pre-release horizontal rows.
- Other operation modules, broad backend rollback, or cross-module catalog redesign beyond horizontal needs.

## Capabilities
### New Capabilities
- `horizontal-offline-api-v2-ids`: Create, persist, validate, and sync Taladro Horizontal offline records using backend IDs with offline-safe label snapshots.

### Modified Capabilities
- None.

## Approach
Use dual-key local storage: keep remote IDs as identity and labels as UI snapshots. Migrate user and horizontal catalogs to store backend IDs, refresh catalogs by remote-ID upsert, source `operador_id` from the logged-in local profile, and mark draft/new-format records by released app version boundary. New-format records without `equipo_id`, `seccion_id`, or `jefe_guardia_id` cannot be saved; records without `operador_id` may stay local drafts and must not sync.

## Affected Areas
| Area | Impact | Description |
|------|--------|-------------|
| `lib/config/data/database_helper.dart` | Modified | Schema, migrations, validation, version boundary |
| `lib/screens/Operaciones/Tal horizontal/...` | Modified | Offline selection, save blocking, draft handling |
| `lib/screens/login/login_screen.dart` / `lib/services/user_service.dart` | Modified | Persist logged-in remote user ID |
| `lib/services/get nube/...` | Modified | Catalog/profile fetch with remote-ID upserts |
| `lib/services/envio nube/horizontal/exportar_service.dart` | Modified | API v2 ID-based payload export |

## Risks
| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Backend profile/catalog contract is incomplete | Med | Treat stable IDs as release prerequisite |
| Old rows are mistaken for new-format rows | Med | Gate by released app version and keep legacy rows unsynced by v2 path |

## Rollback Plan
Stop creating and syncing new-format horizontal records in the releasing app version. Leave existing pre-release rows untouched and avoid adding compatibility fallback.

## Dependencies
- Backend profile payload or offline-user-catalog endpoint exposing stable `operador_id`.
- Stable backend IDs for `equipo`, `seccion`, and `jefe_guardia`, with contract changes coordinated before apply.

## Success Criteria
- [ ] New Taladro Horizontal offline records created by the release store and export backend IDs, not names.
- [ ] Missing cached required IDs block save, while missing `operador_id` creates a non-syncable draft only.
