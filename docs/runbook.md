# JIT Access Broker — Operational Runbook

## Emergency Access Procedure

When immediate privileged access is needed for incident response:

1. **Create emergency request** (using the requester account):
   ```bash
   cp templates/access-request.yaml requests/$(date +%Y%m%d%H%M)-$(whoami)-emergency.yaml
   ```

2. **Fill in the emergency request**:
   ```yaml
   requester: your-email@example.com
   resource: projects/production-project
   role: roles/compute.admin
   justification: "INC-2025-XXXX: Production database unresponsive, need to restart instances"
   duration: 2h
   emergency: true
   approver: oncall-engineer@example.com
   requested_at: "2025-06-30T14:30:00Z"
   ```

3. **Get secondary approval** from the on-call engineer
4. **Merge the PR** — access is provisioned within 2 minutes
5. **Revocation is automatic** after 2 hours (or when incident is resolved)

## Revocation Failure Response

If the auto-revocation job fails:

1. Check GitHub Actions status: `.github/workflows/revoke-expired.yml`
2. If failed, run manual revocation:
   ```bash
   cd terraform
   terraform plan -target='module.active_bindings'
   # Review the plan, then:
   terraform apply -target='module.active_bindings'
   ```
3. Alert security team via Slack #security-alerts

## Adding New Constraints

To add a new policy constraint:

1. Create `policies/constraints/<name>.rego`
2. Add tests in `policies/tests/<name>_test.rego`
3. Import in `policies/jit.rego`
4. Open PR — CI will validate

Example constraint template:

```rego
package jit.constraints.example

import rego.v1
import data.jit.lib.utils

check if {
    # Your constraint logic
}

reason := "Human-readable denial reason" if {
    not check
}
```

## On-Call Rotation

| Role | Responsibility | Escalation |
|---|---|---|
| Primary | Approve emergency access, investigate revocation failures | Secondary after 15 min |
| Secondary | CISO approval for primitive roles, incident command | External CISO after 30 min |

## Audit Procedure

Monthly audit checklist:

- [ ] Review all access requests from previous month (git log)
- [ ] Verify no orphaned permissions (revocation job logs)
- [ ] Check emergency access justifications (should link to incident IDs)
- [ ] Validate primitive role grants (should have CISO approval)
- [ ] Review OPA test coverage (should be 100%)

Run audit:
```bash
git log --since="1 month ago" --oneline -- requests/
```
