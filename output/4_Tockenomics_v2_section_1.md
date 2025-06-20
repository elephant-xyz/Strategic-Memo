---title: "Truth Mining"slug: "truth-mining"parent_slug: "tokenomics"type: "section"order: "1"---
\## Truth Mining

At the core of Elephant’s economic model lies Truth Mining, a consensus
mechanism that transforms property data verification into a sustainable
economic activity. The protocol divides property information into 20
independent fact groups, each requiring verification from three unique
oracles. This granular approach ensures that no single entity can
monopolize the truth verification process while maintaining data
integrity through mathematical consensus.

When oracles submit data for verification, they stake their reputation
and tokens on the accuracy of their contributions. The protocol requires
unanimous consensus among all three oracles before any data is
permanently written to the blockchain and rewards are distributed. This
creates a powerful economic incentive for accuracy—oracles who submit
false or careless data not only forfeit their potential rewards but also
risk losing their staked tokens.

The reward distribution follows an exponential curve designed to
incentivize rapid, accurate submissions. For each fact group verified,
exactly 1 MAHOUT token is minted and distributed among the three
oracles. The first oracle to submit verified data receives approximately
81% of the reward, the second oracle receives 16%, and the third oracle
receives 3%. This exponential reward structure creates urgency in the
marketplace while still ensuring multiple independent verifications of
each data point.

$$\text{Reward Distribution} = \begin{cases}
\text{First Oracle: } 0.81 \text{ MAHOUT} \\
\text{Second Oracle: } 0.16 \text{ MAHOUT} \\
\text{Third Oracle: } 0.03 \text{ MAHOUT}
\end{cases}$$
