# JIT Access Broker

GitHub-native Privileged Access Management (PAM) with OPA/Rego policy enforcement, Terraform provisioning, and automatic privilege revocation.

**No separate PAM vendor required.** Just-in-time access using the tools you already have.

---

## The Problem

Traditional PAM solutions are expensive, complex, and require yet another infrastructure layer. For teams already on GitHub + Terraform + OPA, standing privilege is a policy problem, not a vendor problem.

This project treats privilege elevation as a CI/CD pipeline:

1. **Request** — Developer opens a PR against the access repo
2. **Validate** — OPA/Rego policies check justification, time bounds, and risk
3. **Approve** — Human review for high-risk access
4. **Provision** — Terraform applies the role binding
5. **Revoke** — Scheduled GitHub Action removes the binding automatically

## Architecture

```
Access Request (GitHub PR)
         │
    ┌────┴────┐
    ▼         ▼
 OPA Gate   Human Review
 (auto)     (high-risk)
    │         │
    └────┬────┘
         ▼
   Terraform Apply
   (role binding)
         │
         ▼
   Cloud IAM
   (GCP/AWS/Azure)
         │
         ▼
   Auto-Revoke
   (GitHub Actions
    scheduled job)
```

## Policy Enforcement

OPA/Rego policies enforce:

| Rule | Description |
|---|---|
| `max_duration` | Access grants expire within 4 hours (default) or 24 hours (exception) |
| `require_justification` | Every request must include business justification |
| `emergency_override` | Emergency access requires secondary approval |
| `separation_of_duties` | Requester cannot approve their own access |
| `role_tiering` | Primitive roles (`roles/owner`, `roles/editor`) require CISO approval |
| `time_restricted` | No privileged access outside business hours (configurable) |

## Quick Start

### Prerequisites

- GitHub repository (this repo)
- Terraform Cloud or local Terraform with cloud provider credentials
- OPA CLI (`opa`) installed locally for testing

### Request Access

```bash
# 1. Create a new access request file
cp templates/access-request.yaml.template \
   requests/$(date +%Y%m%d)-lanre-prod-read.yaml

# 2. Fill in the details
vim requests/$(date +%Y%m%d)-lanre-prod-read.yaml

# 3. Open a PR — CI will validate with OPA
gh pr create --title "JIT: Prod read access for incident #1234" \
             --body "Investigating production latency spike"
```

### Access Request Format

```yaml
# requests/20250630-lanre-prod-read.yaml
requester: lanre-oluokun
resource: projects/production-project-123
role: roles/compute.viewer
justification: "Investigating incident INC-2025-0630-001"
duration: 4h
emergency: false
requested_at: 2025-06-30T09:00:00Z
```

### Local Policy Testing

```bash
# Validate a request against OPA policies
opa eval -d policies/ -i requests/20250630-lanre-prod-read.yaml \
  "data.jit.allow"

# Run all unit tests
opa test policies/ tests/ -v
```

## Repository Layout

```
JIT-ACCESS-BROKER/
├── policies/
│   ├── lib/utils.rego           # Shared helpers (time parsing, role tiers)
│   ├── jit.rego                # Main allow/deny logic
│   ├── constraints/
│   │   ├── duration.rego       # Max duration rules
│   │   ├── justification.rego  # Justification requirements
│   │   ├── emergency.rego      # Emergency override rules
│   │   ├── sod.rego           # Separation of duties
│   │   ├── role_tiering.rego  # Role classification
│   │   └── time_restricted.rego # Business hours enforcement
│   └── tests/
│       ├── duration_test.rego
│       ├── justification_test.rego
│       ├── emergency_test.rego
│       ├── sod_test.rego
│       ├── role_tiering_test.rego
│       └── time_restricted_test.rego
├── terraform/
│   ├── main.tf                 # Core infrastructure
│   ├── modules/
│   │   ├── github-repo/        # GitHub repo configuration
│   │   ├── access-binding/     # Cloud IAM role binding
│   │   └── revocation-job/     # Scheduled revocation
│   ├── variables.tf
│   └── outputs.tf
├── .github/
│   ├── workflows/
│   │   ├── validate-request.yml   # OPA validation on PR
│   │   ├── provision-access.yml   # Terraform apply on merge
│   │   └── revoke-expired.yml     # Scheduled revocation (every 15 min)
│   └── jit-templates/
│       └── access-request.yaml
├── requests/
│   └── .gitkeep               # Request files go here via PR
├── scripts/
│   ├── validate.sh            # Local validation helper
│   └── revoke-expired.py      # Revocation logic
├── tests/
│   └── integration/
│       └── test_revocation.py
└── docs/
    ├── architecture.md        # ADR-003: Why GitHub-native PAM
    ├── security-model.md      # Threat model and mitigations
    └── runbook.md             # Operational procedures
```

## CI/CD Pipelines

| Workflow | Trigger | Purpose |
|---|---|---|
| `validate-request.yml` | PR opened/edited | OPA validates request format, constraints, and policies |
| `provision-access.yml` | PR merged | Terraform applies the IAM role binding |
| `revoke-expired.yml` | Schedule (every 15 min) | Removes expired role bindings, commits state |

## Security Model

### Threats Mitigated

| Threat | Mitigation |
|---|---|
| Standing privilege | All access is time-bound; max 4 hours default |
| Privilege escalation | OPA blocks primitive roles without CISO approval |
| Self-approval | Separation of duties: requester cannot merge own PR |
| Audit gaps | All access requests are Git commits — immutable audit trail |
| Orphaned permissions | Auto-revocation removes bindings on schedule |

### Trust Boundaries

- **GitHub Actions** (trusted compute) — runs Terraform and revocation
- **Terraform Cloud** (optional) — state storage with locking
- **Cloud IAM** (trusted enforcement) — actual permission boundary
- **OPA/Rego** (policy decision point) — declarative, version-controlled rules

## Cost

| Component | Cost |
|---|---|
| GitHub Actions (public repo) | Free |
| Terraform Cloud (free tier) | Free |
| Cloud IAM | Free |
| **Total** | **$0/month** |

## ADR-003: GitHub-Native PAM Architecture

See [`docs/architecture.md`](docs/architecture.md) for the full Architecture Decision Record covering:
- Why not a commercial PAM vendor
- Why GitHub over a custom UI
- Why OPA/Rego over procedural validation
- Threat model and residual risks

## License

MIT
