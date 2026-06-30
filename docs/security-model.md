# JIT Access Broker — Security Model

## Trust Boundaries

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub (Trusted)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   PR Author  │  │   Approver   │  │  GitHub Actions  │  │
│  │  (Requester) │  │  (Reviewer)  │  │   (Provisioner)  │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│         Workload Identity Federation (Trusted)               │
│              (GCP Token Exchange)                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    GCP IAM (Trusted)                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Cloud Resource IAM Policies              │  │
│  │         (Role bindings — actual enforcement)         │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Assumptions

1. **GitHub organization is secure**: 2FA enforced, branch protection rules active
2. **Terraform state is secure**: Stored in Terraform Cloud or GCS with encryption
3. **Workload Identity Federation is properly configured**: Only this repo can impersonate the provisioner SA

## Attack Scenarios

### Scenario 1: Malicious PR Author

**Attack**: Developer opens PR granting themselves `roles/owner`

**Defenses**:
- OPA policy blocks primitive roles without CISO approval
- Branch protection requires external reviewer approval
- Self-approval blocked by separation of duties check

### Scenario 2: Compromised GitHub Account

**Attack**: Attacker gains access to developer's GitHub account

**Defenses**:
- 2FA required for GitHub access (org policy)
- Emergency access requires secondary approver
- All access is time-bounded (max 4 hours)

### Scenario 3: Compromised GitHub Actions Runner

**Attack**: Attacker compromises the GitHub Actions runner

**Defenses**:
- Workload Identity Federation limits token lifetime to job duration
- Provisioner SA has minimal permissions (securityAdmin only)
- Terraform state locking prevents concurrent modifications

### Scenario 4: Orphaned Permissions

**Attack**: Revocation job fails, permissions persist beyond expiry

**Defenses**:
- Revocation job runs every 15 minutes with alerting on failure
- Terraform state tracks all active bindings
- Manual audit possible via git history

## Monitoring

| Event | Detection | Response |
|---|---|---|
| Emergency access granted | GitHub Actions log | Immediate Slack alert |
| Primitive role requested | OPA denial log | Security team notification |
| Revocation job failure | GitHub Actions failure | PagerDuty alert |
| Self-approval attempt | OPA denial + PR block | Security review |

## Compliance Mapping

| Control | Framework | Implementation |
|---|---|---|
| Least Privilege | NIST AC-6 | Time-bounded access, role tiering |
| Separation of Duties | NIST AC-5 | Requester cannot approve own access |
| Access Reviews | SOC 2 CC6.2 | Git commit history, auto-revocation |
| Emergency Access | PCI DSS 7.2.2 | Secondary approver, audit trail |
