---
type: take
---
## Rules and Models

Computing now runs on two paradigms. Code follows [rules](https://en.wikipedia.org/wiki/Symbolic_artificial_intelligence) its authors wrote, so it is exact and auditable, but brittle outside the cases they foresaw. A [large language model](https://en.wikipedia.org/wiki/Large_language_model) reasons from statistics learned in training, so it handles the open-ended case, but it can be wrong without signaling it. Joining the two is called [neuro-symbolic AI](https://en.wikipedia.org/wiki/Neuro-symbolic_AI).

The join already works. DeepMind's [AlphaGeometry](https://en.wikipedia.org/wiki/AlphaGeometry) pairs a language model with a rule-based engine. The model proposes constructions, and the engine checks them into proofs. It solved 25 of 30 olympiad geometry problems under contest time limits, close to the average human gold medalist. Neither half could do that alone.

The implication for computing, as I read it, is that code moves from doing the task to fencing and checking it. Tests, types, permissions, and proofs surround a model that does the open-ended part. The model proposes, and the rules verify. That is what a [domain-specific harness](before-agi.md) is. The pairing resembles the [two systems](../mind/two-systems.md) of the mind, fast intuition checked by slow rules, though that is only an analogy.

Code gives guarantees, and models give judgment. Neither replaces the other. Like everything I write about AGI, this is provisional.
