# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Current State

**Pre-code.** Repo has no `go.mod`, no source, no README yet — only planning docs (`docs/superpowers/specs/`, `docs/superpowers/plans/`) and the original project brief (`prompt.txt`). Task 1 of the Phase 1 plan (repo skeleton) has not been executed. When implementing, follow `docs/superpowers/plans/2026-08-09-phase1-containerlab-harness.md` task-by-task (write → verify → commit per step) rather than inventing structure.

Read these two files first, in full, before doing any implementation work:
- `docs/superpowers/specs/2026-08-09-autonomous-network-fabric-design.md` — locked project-wide decisions + phase breakdown
- `docs/superpowers/plans/2026-08-09-phase1-containerlab-harness.md` — current phase's step-by-step implementation plan

That plan file notes it's written for **manual, human-driven implementation** (author implementing by hand with Claude assisting/reviewing) — skip agentic subagent-dispatch instructions when executing its steps.

## Project

Autonomous Network Fabric: an open-source, cloneable control-plane project combining eBPF kernel telemetry, LLM-drafted BGP policy, Z3-verified safety gating, Raft-based consensus, and SONiC CONFIG_DB/APPL_DB integration, validated against a reproducible containerlab test harness. Goal is an honestly-scoped working artifact — every README claim backed by code and tests that actually run, not a throwaway PoC.

### Locked project-wide decisions (apply across all phases)

- **License:** MIT.
- **Stack:** C for eBPF kernel programs (kprobes/tracepoints — drops, queue depth, BGP flaps), Go for all userspace services, `cilium/ebpf` for BPF program loading and map/ring-buffer access.
- **Repo structure:** single root `go.mod`, multi-binary monorepo (`cmd/<service>/` binaries, shared `internal/` packages) — avoids module version-skew across services that share types along the telemetry → policy → verify → swss-integ pipeline.
- **Consensus:** Raft (`hashicorp/raft`), not QuePaxa. QuePaxa has no mature Go implementation; a home-grown consensus impl risks recreating the routing-loop/blackhole hazard the Z3 gate exists to prevent, just downstream of it. Leaderless/WAN-optimized consensus is documented future work only.
- **Deployment:** Docker + docker-compose only, no Kubernetes. eBPF telemetry needs direct host-kernel and containerlab-veth-netns access that a K8s CNI/pod-netns layer would obstruct; k8s also adds kind/minikube/kubectl as clone-and-run prerequisites.
- **No CI.** Every target shipped must be locally runnable and verified by the person building it.

### Phase decomposition

Each phase is independently buildable/testable with its own spec + plan under `docs/superpowers/`:

1. **Repo skeleton + containerlab harness** (current phase — not yet built)
2. **Verification service** — Z3/SMT-LIB2 safety gate, Go invariant-struct framework
3. **Telemetry service** — eBPF C programs + Go userspace, ring buffer → internal API
4. **Policy-generation service** — LLM-drafted route-maps/prefix-lists/community tags from telemetry signals
5. **SWSS-integration service** — writes verified+committed policy to SONiC CONFIG_DB/APPL_DB (go-redis/GNMI)
6. **Consensus service** — Raft-based commit consistency across SONiC nodes

### Phase 1 target architecture

`deploy/containerlab/minimal.clab.yml`: 1 spine + 2 leaf, all `kind: sonic-vs` (SONiC-VS's built-in FRR for eBGP), plus 1 `kind: linux` FRR edge injector peered via eBGP off leaf1, advertising `192.0.2.0/24` as a controllable test prefix. This is the only topology profile shipped (a 2-spine/3-leaf "full" profile is explicitly out of scope — doesn't fit the 12-core/15GB no-swap verified target machine, and there's no CI to test it).

Planned repo layout:
```
cmd/{telemetry,policygen,verify,consensus,swss-integ}/   # future service binaries, placeholders in phase 1
internal/                                                  # shared packages, empty in phase 1
deploy/containerlab/minimal.clab.yml                       # topology
deploy/containerlab/configs/                                # per-node SONiC/FRR startup config
scripts/fetch-sonic-image.sh                                # imports pinned docker-sonic-vs.gz (no plain docker pull exists)
scripts/configure-fabric.sh                                 # post-deploy SONiC iface/BGP config via docker exec + vtysh
scripts/check-bgp-status.sh                                 # polls all nodes until eBGP sessions Established, times out non-zero
go.mod / Makefile / LICENSE / README.md
```

Network design (locked): spine1 AS65000, leaf1 AS65001, leaf2 AS65002, edge1 AS65100; `/31` point-to-point links; SONiC-VS default port stride is `Ethernet0`/`Ethernet4`/... — empirically confirmed in Task 3 of the plan before relied on elsewhere.

### Commands (once Phase 1 skeleton exists)

```bash
make image ARTIFACT=/path/to/docker-sonic-vs.gz   # one-time: import pinned SONiC-VS image (idempotent)
make up                                            # containerlab deploy + configure-fabric.sh
make status                                        # poll all nodes for BGP Established, non-zero exit on timeout
make down                                          # containerlab destroy
make clean                                         # down + remove imported SONiC-VS image
```

Phase 1 success criterion: `make image && make up && make status` exits 0 with all eBGP sessions `Established`.

There is no scriptable download for the SONiC-VS image artifact (`docker-sonic-vs.gz`) — it must be fetched manually from `https://sonic-build.azurewebsites.net/ui/sonic/pipelines` (vs platform, pick branch, latest successful build, Artifacts → `target/docker-sonic-vs.gz`); `scripts/fetch-sonic-image.sh` only automates the import half.

### Future work (explicitly deferred, do not build unless asked)

- Leaderless/WAN-optimized consensus (QuePaxa-style)
- Kubernetes packaging/operator
- Full 2-spine/3-leaf containerlab profile
