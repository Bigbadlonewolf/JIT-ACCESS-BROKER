package jit.tests.duration

import rego.v1

test_standard_duration_allowed if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/compute.viewer
justification: "Investigating production incident"
duration: 4h
emergency: false
requested_at: "2025-06-30T10:00:00Z"
`
	result.allow
}

test_excessive_duration_denied if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/compute.viewer
justification: "Investigating production incident"
duration: 8h
emergency: false
requested_at: "2025-06-30T10:00:00Z"
`
	not result.allow
	result.denys[_] == "Duration exceeds maximum allowed: requested 8h, max standard 240m, max emergency 1440m"
}

test_emergency_duration_allowed if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/compute.viewer
justification: "Critical production outage"
duration: 12h
emergency: true
approver: bob@example.com
requested_at: "2025-06-30T10:00:00Z"
`
	result.allow
}
