# Offline Authorization Specification

## Purpose

Define offline authorization behavior for Dashboard visibility and Taladro Horizontal equipment access using normalized local authorization data.

## Requirements

### Requirement: Persist normalized offline authorization state

The system MUST persist additive local authorization tables for authorized processes and authorized equipment without removing legacy `Usuario` columns in this change. Normalized process identity MUST use the backend process ID as the canonical key.

#### Scenario: Store normalized auth relations

- GIVEN an online profile payload includes authorized processes and equipment
- WHEN the app persists offline authorization data
- THEN the local database stores process and equipment authorizations in normalized tables keyed by backend IDs
- AND legacy `Usuario` identity data remains intact

### Requirement: Refresh auth state on online login and explicit refresh

The system MUST refresh normalized offline authorization data after successful online login and during any supported user-triggered refresh executed inside an available connectivity window. Each refresh MUST replace that user's prior normalized authorization snapshot transactionally.

#### Scenario: Replace stale auth rows after online refresh

- GIVEN the user has stale normalized authorization rows locally
- WHEN online login or an explicit refresh obtains a newer profile snapshot
- THEN the user's normalized authorization rows are replaced as one atomic update
- AND removed backend authorizations are no longer granted offline

### Requirement: Authorize Dashboard modules from normalized process access

The system MUST determine Dashboard module visibility from normalized authorized-process rows when they exist for the logged-in user. If no normalized process rows exist yet for that user, the system SHALL fall back to `Usuario.operaciones_autorizadas` for Dashboard visibility.

#### Scenario: Dashboard reads normalized process authorization

- GIVEN the logged-in user has normalized process rows for Dashboard modules
- WHEN the Dashboard loads offline
- THEN only modules backed by authorized backend process IDs are shown

#### Scenario: Dashboard uses transitional fallback before migration

- GIVEN the logged-in user has no normalized process rows
- WHEN the Dashboard loads offline
- THEN module visibility is derived from `Usuario.operaciones_autorizadas`

### Requirement: Authorize Taladro Horizontal equipment from normalized equipment access

Taladro Horizontal MUST filter selectable equipment from normalized authorized-equipment rows for the logged-in user and the canonical Taladro Horizontal process. The user MAY enter the Taladro Horizontal module even when no equipment is authorized.

#### Scenario: Taladro Horizontal shows only authorized equipment

- GIVEN the user is authorized for Taladro Horizontal and has normalized equipment rows
- WHEN the equipment selector loads offline
- THEN only equipment referenced by those normalized rows is selectable

#### Scenario: Zero authorized equipment yields empty list

- GIVEN the user is authorized for Taladro Horizontal and the backend returned zero authorized equipment
- WHEN the user opens Taladro Horizontal offline
- THEN the module opens successfully
- AND the equipment list is empty rather than treated as an authorization failure

### Requirement: Bound legacy authorization fallback

The system SHALL treat `Usuario.operaciones_autorizadas` as a transitional read fallback only for Dashboard process authorization when normalized process rows are absent. The system MUST NOT use `Usuario.autorizado_equipo` to grant Taladro Horizontal equipment access in this change.

#### Scenario: Deprecated equipment field is ignored

- GIVEN a local user record still contains `autorizado_equipo`
- WHEN Taladro Horizontal equipment authorization is evaluated
- THEN that deprecated field does not grant or expand equipment access
