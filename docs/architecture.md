# ADR-003: GitHub-Native PAM Architecture

## Status

**Accepted** — 2025-06-30

## Context

Traditional Privileged Access Management (PAM) solutions (CyberArk, Delinea, HashiCorp Vault) provide robust access control but introduce significant operational complexity:

- **Infrastructure overhead**: Dedicated servers, HA setup, backup/restore
- **Integration complexity**: Custom connectors for each cloud provider
- **Cost**: $50K-$200K/year for enterprise deployments
- **Learning curve**: Separate UI, workflows, and mental model

For teams already using GitHub + Terraform + OPA, standing privilege is fundamentally a policy problem, not a vendor problem.

## Decision

Build a GitHub-native PAM system that leverages existing tools:

| Function | Traditional PAM | GitHub-Native PAM |
|---|---|---|
| Access request | Web form | GitHub PR |
| Approval workflow | Custom UI | GitHub branch protection + reviewers |
| Policy engine | Proprietary | OPA/Rego |
| Provisioning | Custom connector | Terraform |
| Audit trail | Database | Git commit history |
| Auto-revocation | Scheduled job | GitHub Actions cron |

## Why Not a Commercial PAM?

| Factor | Commercial PAM | GitHub-Native |
|---|---|---|
| Setup time | Weeks | Hours |
| Infrastructure | Dedicated servers | GitHub Actions (free) |
| Policy language | Proprietary | OPA/Rego (open standard) |
| Audit trail | Vendor-controlled | Immutable git history |
| Cost | $50K-$200K/year | $0/year |
| Vendor lock-in | High | None |

## Why GitHub Over a Custom UI?

- **Familiarity**: Developers already live in GitHub
- **Workflow integration**: PR reviews, CI checks, and approvals are native
- **Audit trail**: Every action is a git commit — tamper-evident by design
- **Access control**: GitHub's own auth/authorization model

## Why OPA/Rego Over Procedural Validation?

- **Declarative**: Policies express intent, not implementation
- **Testable**: Unit tests for every constraint
- **Composable**: Constraints can be mixed and matched
- **Version-controlled**: Policy changes are PR-reviewed like code

## Threat Model

| Threat | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Self-approval | Medium | High | Branch protection: PR author cannot merge |
| Orphaned permissions | Low | High | Auto-revocation every 15 minutes |
| Privilege escalation | Low | Critical | Primitive roles require CISO approval |
| Audit tampering | Very Low | Critical | Immutable git history |
| Emergency abuse | Medium | Medium | Secondary approver required |

## Residual Risks

- **GitHub compromise**: If GitHub org is compromised, PAM is compromised
- **Terraform state**: State file contains role binding information
- **Timing attacks**: Small window between approval and provisioning

## Alternatives Considered

1. **HashiCorp Vault**: Rejected due to complexity and cost for small teams
2. **Custom web UI**: Rejected — adds maintenance burden without clear benefit
3. **Native cloud PAM**: Rejected — GCP/AWS native solutions lack cross-platform consistency

## Future Enhancements

- [ ] Slack/Teams notification on access grant/revoke
- [ ] Automatic justification extraction from incident management system
- [ ] Risk scoring based on requester history
- [ ] Integration with SIEM for access analytics

## References

- NIST SP 800-53 AC-6 (Least Privilege)
- NIST SP 800-53 AC-10 (Concurrent Session Control)
- PCI DSS 7.2.1 (Access restrictions)
- SOC 2 CC6.3 (Logical access security)
