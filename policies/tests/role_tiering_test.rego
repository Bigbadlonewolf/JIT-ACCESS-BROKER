package jit.tests.role_tiering

import rego.v1

test_predefined_role_allowed if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/compute.viewer
justification: "Investigating production incident"
duration: 2h
emergency: false
requested_at: "2025-06-30T10:00:00Z"
`
	result.allow
}

test_primitive_role_without_ciso_denied if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/editor
justification: "Investigating production incident"
duration: 2h
emergency: false
requested_at: "2025-06-30T10:00:00Z"
`
	not result.allow
	result.denys[_] == "Primitive role roles/editor requires CISO approval"
}

test_primitive_role_with_ciso_allowed if {
	result := data.jit.result with input as `
requester: alice@example.com
resource: projects/test
role: roles/editor
justification: "Investigating production incident"
duration: 2h
emergency: false
ciso_approved: true
requested_at: "2025-06-30T10:00:00Z"
`
	result.allow
}
