---
description: Collaborative planning lifecycle for AI-assisted work across dual-cluster homelab infrastructure
tags: ["Planning", "RiskAssessment", "PreMortem", "IncidentResponse", "Collaboration"]
audience: ["LLMs", "Humans"]
categories: ["Workflows[100%]", "Philosophy[70%]"]
---

# Collaborative Planning Lifecycle

Structured collaboration between human and AI produces better outcomes than ad-hoc requests. This document captures the lifecycle: **Idea → Planning → Risk Assessment → Execution → Incident Response**.

---

## Philosophy

**Why structure matters**: Complex changes benefit from exploration before action. Rushing to implementation risks missing dependencies, breaking existing functionality, or solving the wrong problem.

**Lightweight, not bureaucratic**: These phases are mental checkpoints, not formal gates. A simple change might flow through all five in minutes. A complex migration might spend hours in planning.

**Dual-cluster awareness**: Every phase must consider which cluster (main, staging, or both) is affected. Cross-cluster changes require explicit discussion.

---

## The Five Phases

```
Idea → Planning → Risk Assessment → Execution → Incident Response
  │        │              │              │              │
  │        │              │              │              └─ Learn from failures
  │        │              │              └─ Small steps, verify each
  │        │              └─ What could go wrong?
  │        └─ Explore before proposing
  └─ Problem + outcome, not solution
```

| Phase     | Focus      | Key Question                                  |
| --------- | ---------- | --------------------------------------------- |
| Idea      | Intent     | What problem are we solving?                  |
| Planning  | Discovery  | What exists? What patterns? Which cluster?    |
| Risk      | Prevention | What could go wrong? What's the blast radius? |
| Execution | Progress   | Did each step succeed? Can we verify?         |
| Incident  | Learning   | What happened? What did we learn?             |

---

## Phase Capsules

### Capsule: IdeaCapture

**Invariant**
State the problem and desired outcome; avoid prescribing implementation.

**Example**

- Good: "Immich needs persistent storage for photos on main cluster"
- Bad: "Add rook-ceph PVC to immich"

The first invites exploration; the second assumes a solution.

**Depth**

- Distinction: Intent describes the problem; solution describes one fix
- Trade-off: Open framing takes longer but finds better solutions
- NotThis: Jumping straight to "add X" or "change Y"
- SeeAlso: ExplorationFirst

---

### Capsule: ClusterSpecificity

**Invariant**
Always specify which cluster (main, staging, both) during planning and execution.

**Example**

- Good: "Deploy Grafana to staging cluster first, then main cluster after validation"
- Bad: "Deploy Grafana to the cluster"

**Depth**

- Critical: Main and staging clusters are independent; changes don't cross over
- Questions: Which cluster needs this? Does the other cluster need it too?
- Trade-off: Extra mental overhead vs preventing cross-cluster confusion
- NotThis: Assuming "the cluster" is obvious from context
- SeeAlso: DualClusterIsolation (in ARCHITECTURE.md)

---

### Capsule: ExplorationFirst

**Invariant**
Understand the codebase before proposing changes; use tools to discover what exists.

**Example**

```
Grep for similar apps → read existing HelmReleases → identify patterns → propose approach
```

//BOUNDARY: Never propose changes to code you haven't read

**Depth**

- Techniques: Grep, Glob, Read existing manifests in kubernetes/{main,staging}/apps/
- Critical: Check BOTH clusters if the change might affect both
- Trade-off: Time exploring vs missing critical dependencies
- NotThis: Proposing solutions based on assumptions
- SeeAlso: RiskDiscovery

---

### Capsule: RiskDiscovery

**Invariant**
Ask "what could go wrong?" during planning; identify blast radius and dependencies.

**Example**
Before changing a shared component:

1. What uses this? (grep across kubernetes/{main,staging}/apps/)
2. What breaks if this fails? (blast radius)
3. Which cluster(s) affected? (main, staging, both)
4. What's the rollback? (revert path)

//BOUNDARY: Changes with unknown blast radius require explicit acknowledgment

**Depth**

- Questions: What depends on this? What does this depend on? Can we test in staging first?
- Techniques: Cross-namespace grep, install.yaml dependsOn chains, HelmRelease dependencies
- Staging advantage: Test risky changes in staging before applying to main
- NotThis: Formal pre-mortem sessions (integrate naturally into planning)
- SeeAlso: IncrementalExecution

---

### Capsule: IncrementalExecution

**Invariant**
Make small, verifiable changes; validate before proceeding to next step.

**Example**
Deploying a new app to main cluster:

1. Create app folder structure → verify files exist
2. Add ExternalSecret → `flux get externalsecrets -n <namespace> --context main` shows Ready
3. Deploy HelmRelease → `flux get hr -n <namespace> --context main` shows Ready
4. Add HTTPRoute → `curl` confirms accessible
5. Validate in staging → then apply to main

**Depth**

- Checkpoints: After each logical unit, pause and verify
- Trade-off: Slower execution vs catching issues early
- Staging-first: Consider deploying to staging cluster before main for risky changes
- NotThis: Big-bang deployments that change everything at once
- SeeAlso: RiskDiscovery, ClusterSpecificity

---

### Capsule: BlamelessLearning

**Invariant**
When things fail, ask "what happened" and "how", never "who" or "why didn't you".

**Example**

- Good: "What information was missing when that decision was made?"
- Good: "What did you expect to happen? What actually happened?"
- Bad: "Why didn't you check the dependencies first?"

**Depth**

- Focus: System factors and missing information, not individual fault
- Questions: What did you see? What did you expect? What was surprising?
- Goal: Understanding over fixing; learning over blame
- NotThis: Finding someone to blame; rushing to "fix it"
- SeeAlso: Etsy's blameless postmortem philosophy

---

## Risk Discovery Techniques

Lightweight risk assessment integrated into the planning phase. Not a formal pre-mortem—just good habits.

### Dependency Discovery

Before modifying a resource, find what uses it:

```bash
# Find all references to a resource across both clusters
grep -r "ResourceName" kubernetes/main/apps/
grep -r "ResourceName" kubernetes/staging/apps/

# Find HelmReleases that depend on a namespace resource
grep -r "dependsOn" kubernetes/main/apps/<namespace>/
```

Natural language: "Let me check what else references this in both clusters..."

### Blast Radius Assessment

For each proposed change:

- **Which cluster(s)?** (main, staging, both)
- **If this fails, what stops working?** (downstream impact)
- **If we need to revert, how?** (rollback path via Git)
- **Can we test in staging first?** (staging as safety net)

Check: install.yaml `dependsOn`, HelmRelease `dependsOn`, cross-namespace references

### Gap Detection

Before implementing, search for existing patterns:

```bash
# Find similar implementations in both clusters
grep -r "similar-pattern" kubernetes/main/apps/
grep -r "similar-pattern" kubernetes/staging/apps/

# Check if pattern exists in one cluster but not the other
diff <(ls kubernetes/main/apps/<namespace>) <(ls kubernetes/staging/apps/<namespace>)
```

Questions:

- "Are there similar implementations I should follow?"
- "Does this namespace already have this pattern?"
- "Does the other cluster have this already?"

### Explicit Unknowns

When uncertain, say so:

- "I'm not sure how X interacts with Y—should we verify?"
- "This might affect both clusters but I'd need to check"
- "Should we test this in staging first?"

Mark confidence: High (verified), Medium (inferred), Low (assumption)

---

## Incident Response Principles

When things go wrong, shift to learning mode.

### The Blameless Mindset

**Core belief**: People make decisions that seem reasonable given the information they have at the time. If an action caused problems, the interesting question is "what made that action seem reasonable?"

### Questions That Help

| Instead of                     | Ask                                               |
| ------------------------------ | ------------------------------------------------- |
| "Why did you do that?"         | "What were you trying to achieve?"                |
| "Didn't you see the warning?"  | "What information did you have at the time?"      |
| "Which cluster did you break?" | "Which cluster was affected? What was the scope?" |
| "Why wasn't this tested?"      | "What testing was done? What was missed?"         |

### Learning Over Fixing

The first instinct after an incident is to fix it immediately. Resist this:

1. **Understand first** - What actually happened? What was the sequence? Which cluster?
2. **Gather perspectives** - What did each person see and think?
3. **Identify gaps** - What information or tooling would have helped?
4. **Then remediate** - Now fix the immediate issue
5. **Finally prevent** - What systemic changes reduce recurrence?

---

## Cluster-Specific Considerations

### When to Use Staging

**Consider staging first for**:

- New app deployments (validate before main)
- Breaking changes to existing apps
- Networking or gateway changes
- Storage or PVC modifications
- Experimental features

**Skip staging for**:

- Documentation updates
- Config changes that are cluster-specific
- Emergency fixes to production (main cluster) issues

### Verifying Cross-Cluster Consistency

When applying the same change to both clusters:

1. **Apply to staging first** - Validate the change works
2. **Review differences** - Are there cluster-specific values?
3. **Apply to main** - Adapt for main cluster specifics
4. **Verify both** - Ensure both clusters are in expected state

```bash
# Check Flux status on both clusters
flux get helmreleases -A --context staging
flux get helmreleases -A --context main
```

---

## Verification Checklist

### Before Making Changes

- [ ] State problem and outcome, not solution (IdeaCapture)
- [ ] Specify which cluster(s) affected (ClusterSpecificity)
- [ ] Explore codebase in relevant cluster(s) (ExplorationFirst)
- [ ] Identify what could go wrong and blast radius (RiskDiscovery)
- [ ] Decide if staging-first testing is appropriate

### During Execution

- [ ] Make small changes with verification (IncrementalExecution)
- [ ] Test in staging before main (when appropriate)
- [ ] Verify each step before proceeding
- [ ] Document unexpected behaviors

### After Incidents

- [ ] Ask "what/how" not "who/why" (BlamelessLearning)
- [ ] Document what happened and what was learned
- [ ] Update documentation to prevent recurrence

---

## Common Pitfalls

### Cluster Confusion

**Symptom**: Applying changes to wrong cluster or not knowing which cluster you're working on.

**Prevention**:

- Always check current kubeconfig context before commands
- Use cluster-specific shell prompts or aliases
- Explicitly state cluster in commit messages
- Double-check file paths (kubernetes/main/ vs kubernetes/staging/)

### Assumption Failures

**Symptom**: Changes fail because assumed resources/configs don't exist.

**Prevention**:

```bash
# Before using MutatingAdmissionPolicy (specify cluster context)
kubectl api-resources --context main | grep -i mutating

# Before referencing ExternalSecret store (specify cluster context)
kubectl get clustersecretstore --context main

# Before referencing ConfigMap by name (specify cluster context)
kubectl get configmaps -n <namespace> --context main
```

### Missing Dependencies

**Symptom**: New app fails to start due to missing prerequisites.

**Prevention**:

- Check existing apps in same namespace for patterns
- Verify ExternalSecret exists and is Ready before deploying app
- Check storage class exists before creating PVC
- Ensure namespace exists before deploying resources

---

## Sources

- [Atlassian Pre-Mortem Play](https://www.atlassian.com/team-playbook/plays/pre-mortem) - Risk identification methodology
- [Etsy Debriefing Facilitation Guide](https://www.etsy.com/codeascraft/debriefing-facilitation-guide) - Blameless postmortem philosophy
- [PagerDuty Blameless Postmortem](https://postmortems.pagerduty.com/culture/blameless/) - "What/how" questioning techniques
