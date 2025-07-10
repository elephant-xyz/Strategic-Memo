---
title: "Field-Level Semantics: Self-Describing Data"
slug: "field-level-semantics-self-describing-data"
publishDate: "2025-07-10"
chapter: "Appendix: Elephant Framework Data Relationship Layer"
section: "Field-Level Semantics: Self-Describing Data"
parentSlug: "appendix-elephant-framework-data-relationship-layer"
order: 5
toc: true
description: ""
draft: false
---

Every data field in Elephant carries explicit semantic metadata that transforms raw values into self-describing, self-validating information units. This field-level intelligence enables automatic UI generation, comprehensive validation, and cross-system interoperability without central coordination or documentation.

Schema field definitions include rich semantic annotations:

- **Type constraints**: Beyond primitive types, fields specify semantic types (Address, TaxID, DeedReference)

- **Validation rules**: Regular expressions, range constraints, enumerated values, cross-field dependencies

- **UI hints**: Display formatting, input masks, help text, localization keys

- **Legal semantics**: Required for validity, audit trail requirements, retention policies

- **Oracle requirements**: Which oracle types can verify this field, minimum signature counts

This semantic richness enables powerful automation. Frontend applications generate appropriate UI components automatically—address fields render with autocomplete, date fields with calendar widgets, currency fields with proper formatting. Validation happens client-side before submission, reducing failed transactions. Oracle interfaces know exactly which fields require verification and acceptable evidence types.

Consider a property address field:

Consider a property address field specification:

**AddressField Schema Definition:**

- **type**: "GeoAddress" (semantic type for geographic addresses)

- **required**: true (must be present for valid entity)

- **validation**: PostalServiceAPI (external validation service)

- **display**: "street, city, state postal" (UI rendering format)

- **oracle**: \["County Records", "Postal Service"\] (acceptable validators)

- **retention**: "permanent" (data retention policy)

This single definition enables complete field handling across the entire stack. Smart contracts validate addresses against postal service APIs. Oracles know to verify against county records. UIs render appropriate input forms. Archives retain address history permanently. No component requires hardcoded knowledge about address handling—the schema provides everything needed.
