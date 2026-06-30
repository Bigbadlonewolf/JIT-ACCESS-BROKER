package jit.tests.sod

import rego.v1

test_sod_different_approver_allowed if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/compute.viewer
justification: "Investigating production incident"
duration: 2h
emergency: true
approver: bob@example.com
requested_at: "2025-06-30T10:00:00Z"
`
	result.allow
}

test_sod_self_approval_denied if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/compute.viewer
justification: "Investigating production incident"
duration: 2h
emergency: true
approver: alice@example.com
requested_at: "2025-06-30T10:00:00Z"
`
	not result.allow
	result.denys[_] == "Separation of duties violated: approver cannot be the requester"
}
