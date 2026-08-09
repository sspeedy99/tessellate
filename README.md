<p align="center">
  <strong>Tessellate</strong>
</p>

<p align="center">
  An autonomous network fabric control plane — eBPF telemetry, LLM-drafted BGP policy, Z3-verified safety gating, and Raft-based consensus, applied to SONiC switches.
</p>

---

Tessellate watches a network fabric at the kernel level, drafts BGP policy changes in response to what it sees, and only lets a change reach a switch after it's been formally proven safe.

Most "self-healing network" tools either skip the safety proof or skip the real hardware-adjacent testing. Tessellate does neither: every policy change is checked against a Z3-backed invariant framework — no routing loops, no blackholed prefixes, no contradictory policy — before it's applied, and the whole system is validated against a reproducible containerlab fabric of SONiC-VS switches running real FRR eBGP.

| | |
|---|---|
| **Telemetry** | eBPF programs (kprobes/tracepoints) capture drops, queue depth, and BGP flaps straight from the kernel, streamed out over a ring buffer. |
| **Policy generation** | A fine-tuned LLM drafts BGP policy changes — route-maps, prefix-lists, community tags — from telemetry-triggered signals. |
| **Formal verification** | Every generated policy is translated to SMT-LIB2 and checked by Z3 against an extensible set of safety invariants before it's allowed downstream. |
| **Consensus** | Raft-based commit protocol keeps policy state consistent across nodes, even if a leader dies mid-propagation. |
| **SONiC integration** | Only Z3-verified, committed policy is written to each node's CONFIG_DB/APPL_DB. |

## License

MIT — see [LICENSE](LICENSE).
