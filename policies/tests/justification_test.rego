package jit.tests.justification

import rego.v1

test_valid_justification_allowed if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/compute.viewer
justification: "Investigating production incident related to latency spike"
duration: 2h
emergency: false
requested_at: "2025-06-30T10:00:00Z"
`
	result.allow
}

test_short_justification_denied if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/compute.viewer
justification: "test"
duration: 2h
emergency: false
requested_at: "2025-06-30T10:00:00Z"
`
	not result.allow
}

test_placeholder_justification_denied if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/compute.viewer
justification: "TBD"
duration: 2h
emergency: false
requested_at: "2025-06-30T10:00:00Z"
`
	not result.allow
}
