package jit.tests.emergency

import rego.v1

test_emergency_with_approver_allowed if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/compute.viewer
justification: "Critical production outage needs immediate attention"
duration: 2h
emergency: true
approver: bob@example.com
requested_at: "2025-06-30T10:00:00Z"
`
	result.allow
}

test_emergency_without_approver_denied if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/compute.viewer
justification: "Critical production outage"
duration: 2h
emergency: true
requested_at: "2025-06-30T10:00:00Z"
`
	not result.allow
	result.denys[_] == "Emergency access requires a secondary approver different from the requester"
}

test_emergency_self_approval_denied if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/compute.viewer
justification: "Critical production outage"
duration: 2h
emergency: true
approver: alice@example.com
requested_at: "2025-06-30T10:00:00Z"
`
	not result.allow
}
