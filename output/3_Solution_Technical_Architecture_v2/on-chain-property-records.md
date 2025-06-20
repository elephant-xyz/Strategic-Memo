---
title: "On-Chain Property Records"
slug: "on-chain-property-records"
parent_slug: "3_Solution_Technical_Architecture_v2"
type: "section"
order: 3
---

# On-Chain Property Records

Properties exist in Elephant as minted digital data assets, not merely
as database entries or document repositories. Each asset embeds
verified, cryptographically signed data snapshots while maintaining
dynamic lifecycle support for the continuous changes that define real
property. This approach recognizes that real estate is not
static---properties are bought, sold, renovated, refinanced, and
transformed throughout their existence.

The protocol introduces a proprietary Lexicon data model that unifies
multiple real estate standards into a deeply relational, normalized
structure. This model is specifically optimized for ownership changes,
mortgage payoffs, property upgrades, and regulatory complexity. Rather
than forcing square pegs into round holes, the Lexicon acknowledges the
unique characteristics of real property while maintaining compatibility
with existing systems.

Each on-chain record links to comprehensive off-chain data through
cryptographic commitments, enabling programmable ownership, transfers,
upgrades, and event tracking. This design reduces data verification
costs from \$8,600 to \$2,400 per transaction---a 72% reduction that
compounds over millions of annual transactions. More importantly, it
creates permanent industry memory where every verified transaction,
upgrade, mortgage, transfer, and title change becomes permanently
traceable.
