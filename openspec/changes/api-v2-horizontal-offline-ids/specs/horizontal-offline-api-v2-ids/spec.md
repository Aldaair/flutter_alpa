# Horizontal Offline API V2 IDs Specification

## Purpose

Define Taladro Horizontal offline behavior for app versions that create API v2 records with remote-ID identity and local label snapshots.

## Requirements

### Requirement: Persist horizontal catalogs with remote identity

The system MUST persist Taladro Horizontal catalog entries with backend stable IDs as identity and SHOULD persist the latest backend label as a local display snapshot. Catalog refresh MUST upsert by remote ID and MUST NOT change record identity when labels change.

#### Scenario: Refresh cached catalog labels

- GIVEN a cached equipment, section, or guard-leader item already exists with a remote ID
- WHEN the app receives the same remote ID with an updated label from the backend
- THEN the cached item keeps the same remote ID identity
- AND the stored label snapshot is updated for display

### Requirement: Persist logged-in operator remote ID

The system MUST persist the logged-in user profile with its backend `operador_id` when the backend provides it. Taladro Horizontal creation SHALL source `operador_id` from the locally stored logged-in profile and MUST NOT derive it from display names.

#### Scenario: Store operator identity after login

- GIVEN a successful login response that includes a stable `operador_id`
- WHEN the user profile is stored locally
- THEN the local profile keeps that `operador_id`
- AND later Horizontal creation reads the same stored value

#### Scenario: Missing operator ID in local profile

- GIVEN the logged-in local profile does not contain `operador_id`
- WHEN the user creates a new Taladro Horizontal record
- THEN the record is allowed only as a local draft
- AND the record is marked as not eligible for sync

### Requirement: Validate new-format Horizontal creation inputs

For Taladro Horizontal records created by the released app version for this change, the system MUST treat the record as API v2 new-format. New-format save MUST require cached `equipo_id`, `seccion_id`, and `jefe_guardia_id`. The system MUST block save when any of those IDs is missing. The system MUST NOT use legacy name-to-ID fallback.

#### Scenario: Save blocked by missing required catalog ID

- GIVEN a new-format Horizontal record is being created offline
- AND `equipo_id`, `seccion_id`, or `jefe_guardia_id` is missing from local cache
- WHEN the user attempts to save
- THEN the save is blocked locally

#### Scenario: Save succeeds with required IDs present

- GIVEN a new-format Horizontal record has cached `equipo_id`, `seccion_id`, and `jefe_guardia_id`
- WHEN the user saves the record offline
- THEN the record is stored with those remote IDs and label snapshots
- AND no name-to-ID fallback is executed

### Requirement: Preserve draft and syncability state by identity completeness

The system MUST allow a saved new-format Horizontal record without `operador_id` only as a local non-syncable draft. The system MUST mark new-format records with complete required IDs and `operador_id` as syncable. The system MUST gate new-format behavior by the released app version boundary for this change.

#### Scenario: Version boundary keeps scope narrow

- GIVEN a Horizontal row was created before the release boundary
- WHEN sync or save rules are evaluated
- THEN the row is not reclassified as a new-format API v2 record by this change

#### Scenario: Complete identity becomes syncable

- GIVEN a new-format Horizontal record has `operador_id`, `equipo_id`, `seccion_id`, and `jefe_guardia_id`
- WHEN the record is stored locally
- THEN the record is marked eligible for API v2 sync

### Requirement: Export API v2 payloads with remote IDs only

The system MUST export new-format Taladro Horizontal records to API v2 using persisted remote IDs for operator, equipment, section, and guard leader. The export payload MUST NOT depend on display names for identity. Records marked non-syncable drafts MUST NOT be exported.

#### Scenario: Export syncable new-format record

- GIVEN a stored new-format Horizontal record is marked syncable
- WHEN the export service builds the API v2 payload
- THEN the payload contains remote IDs for identity fields
- AND display labels are not used as fallback identifiers

#### Scenario: Skip non-syncable draft export

- GIVEN a stored new-format Horizontal draft is marked non-syncable because `operador_id` is missing
- WHEN the export service evaluates pending records
- THEN that draft is excluded from API v2 export
