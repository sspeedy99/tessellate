<p align="center">
  <strong>Tessellate</strong>
</p>

<p align="center">
  An autonomous network fabric control plane — eBPF telemetry, LLM-drafted BGP policy, Z3-verified safety gating, and Raft-based consensus, applied to SONiC switches.
</p>

---

## What is Tessellate?

Tessellate is an experimental, closed-loop AI control plane for SONiC-based network fabrics. It lets an LLM propose BGP policy changes in response to live network conditions, formally verifies every proposed change with Z3 before it's allowed anywhere near a switch, and uses distributed consensus to keep that policy state identical across every node in the fabric.


In short: AI proposes, Z3 verifies, consensus commits — and the fabric stays consistent the way tessellating tiles stay consistent: no gaps, no overlaps, no node out of sync.

## Why

Tessellate isn't trying to prove that AI can run a network unsupervised — it's testing a narrower, falsifiable claim: that an LLM can be trusted to author control-plane changes if and only if those changes pass through a deterministic formal-verification gate first, and that the resulting policy can propagate consistently across a distributed fabric without depending on a single point of failure. The repo includes reproducible demos of both: a Z3 gate catching an unsafe AI-generated policy before it reaches a switch, and policy state staying consistent across nodes when a consensus leader is killed mid-propagation.

| | |
|---|---|
| **Telemetry** | eBPF programs (kprobes/tracepoints) capture drops, queue depth, and BGP flaps straight from the kernel, streamed out over a ring buffer. |
| **Policy generation** | A fine-tuned LLM drafts BGP policy changes — route-maps, prefix-lists, community tags — from telemetry-triggered signals. |
| **Formal verification** | Every generated policy is translated to SMT-LIB2 and checked by Z3 against an extensible set of safety invariants before it's allowed downstream. |
| **Consensus** | Raft-based commit protocol keeps policy state consistent across nodes, even if a leader dies mid-propagation. |
| **SONiC integration** | Only Z3-verified, committed policy is written to each node's CONFIG_DB/APPL_DB. |

## License

MIT — see [LICENSE](LICENSE).
