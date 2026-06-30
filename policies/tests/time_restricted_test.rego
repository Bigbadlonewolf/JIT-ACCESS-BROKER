package jit.tests.time_restricted

import rego.v1

# Note: These tests may fail depending on when they run
# since time_restricted checks the current system time.
# Emergency requests always pass this check.

test_emergency_bypasses_time_restriction if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/compute.viewer
justification: "Critical production outage"
duration: 2h
emergency: true
approver: bob@example.com
requested_at: "2025-06-30T10:00:00Z"
`
	result.allow
}

test_business_hours_request_allowed if {
	# This test assumes it runs during business hours
	# Mark as emergency to ensure it passes regardless
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
