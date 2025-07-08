---
title: "Consensus Mechanism"
slug: "consensus-mechanism"
publishDate: "2025-07-08"
chapter: "Token Economy"
section: "Consensus Mechanism"
parentSlug: "token-economy"
order: 2
toc: true
description: ""
draft: false
---

The protocol distinguishes between consensus-based groups and reputation-based groups, each reflecting different approaches to truth verification. Consensus-based groups require three unique oracle submissions to validate objective, verifiable facts that multiple parties can independently confirm from the same sources. These groups distribute MAHOUT according to submission order: 80% to the first oracle, 15% to the second oracle, and 5% to the third oracle.

Three vMAHOUT tokens are minted per consensus group submission cycle, one for each of the three oracles. This design ensures that governance power flows from verified contributions rather than economic stakes, creating alignment between network utility and decision-making authority.

Reputation-based groups such as Photo Metadata and HOA award 100% of their MAHOUT allocation to a single oracle. Oracles must stake reputation to contribute to these groups, which involve subjective assessment or specialized access rather than objective verification. Non-consensus groups do not mint any vMAHOUT tokens, focusing purely on MAHOUT rewards for data contribution.

This dual structure prevents the system from falling into either extreme: pure consensus would paralyze subjective assessments, while pure reputation would enable manipulation of objective facts. The protocol recognizes that different types of truth require different verification mechanisms---a design principle that scales from individual properties to entire markets.
