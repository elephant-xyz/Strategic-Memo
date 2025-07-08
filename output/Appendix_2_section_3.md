---
title: "Generic Relationship Objects: Universal Property Semantics"
slug: "generic-relationship-objects-universal-property-semantics"
publishDate: "2025-07-08"
chapter: "Appendix: Elephant Framework Data Relationship Layer"
section: "Generic Relationship Objects: Universal Property Semantics"
parentSlug: "appendix-elephant-framework-data-relationship-layer"
order: 3
toc: true
description: ""
draft: false
---

The Relationship class forms Elephant’s core innovation—a polymorphic, bidirectional, schema-validated object that can represent any connection between entities. This generic abstraction enables the protocol to handle everything from simple ownership to complex financial instruments without special-casing each relationship type.

Every Relationship contains essential components that ensure both flexibility and verifiability:

Every Relationship contains essential components:

- **id**: Unique identifier (UUID) for the relationship instance

- **schema**: IPFS CID pointing to the governing schema definition

- **entities**: Array of CIDs for the two connected entities

- **merkleRoots**: Array of Merkle roots for entity state verification

- **metadata**: JSON object containing relationship-specific data

- **signatures**: Array of oracle signatures validating the relationship

- **timestamp**: Block number when relationship was created

This structure enables powerful properties. Bidirectionality ensures relationships are discoverable from either entity—finding all properties owned by a person or all owners of a property requires identical queries. Schema validation happens at relationship creation, preventing invalid connections. Merkle roots enable historical queries without storing complete history. Oracle signatures provide graduated trust based on validation thoroughness.

The metadata field enables relationship-specific data without modifying schemas. An ownership relationship might include purchase price, transfer date, and deed reference. A mortgage relationship includes principal amount, interest rate, and payment schedule. This flexibility allows schemas to remain simple while relationships capture full complexity.

Relationships compose into knowledge graphs that mirror legal reality. Complex transactions involve relationship graphs: selling a mortgaged property requires relationships between buyer, seller, property, existing mortgage, new mortgage, title company, and various government entities. Each relationship maintains independent verification while the graph ensures transaction atomicity. Either all relationships commit or none do, preventing partial transfers that plague traditional systems.
