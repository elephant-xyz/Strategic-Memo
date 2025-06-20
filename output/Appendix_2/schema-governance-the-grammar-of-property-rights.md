---
title: "Schema Governance: The Grammar of Property Rights"
slug: "schema-governance-the-grammar-of-property-rights"
parent_slug: "Appendix_2"
type: "section"
order: 3
---

# Schema Governance: The Grammar of Property Rights

Schemas in Elephant function as the constitutional framework governing
all data relationships. Unlike traditional database schemas that merely
structure data, Elephant schemas encode legal semantics, validation
rules, and cross-jurisdictional compatibility into immutable,
version-controlled specifications that ensure global coherence while
allowing local adaptation.

Each schema defines a Group---a semantic container for related
interaction patterns. The \"Ownership\" group contains schemas for
various ownership types: simple ownership, joint tenancy, tenancy in
common, corporate ownership, trust ownership. Each schema within the
group shares common interfaces while implementing specific legal logic:

-   Entity type constraints (e.g., only Natural Persons can be joint
    tenants)

-   Relationship cardinality (e.g., property can have multiple owners
    but each share must sum to 100%)

-   Validation predicates (e.g., trust ownership requires valid trust
    documentation)

-   Temporal constraints (e.g., life estates terminate upon grantor
    death)

Schema governance operates through decentralized consensus rather than
centralized authority. New schemas are proposed, reviewed, and adopted
through DAO governance. This ensures schemas reflect actual usage needs
rather than theoretical completeness. Popular schemas gain network
effects as more relationships reference them, creating natural
standardization without enforcing rigid uniformity.

The versioning system enables evolution without breaking existing
relationships. Schema v2 can extend v1 with additional fields or
constraints while maintaining backward compatibility. Relationships
explicitly reference schema versions, ensuring perpetual
interpretability. A relationship created in 2025 remains verifiable in
2050 using its original schema, even as newer versions emerge.

This governance model solves the protocol ossification problem plaguing
many blockchains. Bitcoin's simplicity ensures security but limits
expressiveness. Ethereum's complexity enables innovation but complicates
verification. Elephant's schema governance achieves both: simple base
protocol with complex semantics layered through governed schemas. The
protocol remains minimal while applications gain unlimited
expressiveness.
