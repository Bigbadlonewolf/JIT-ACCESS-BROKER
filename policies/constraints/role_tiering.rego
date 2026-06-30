package jit.constraints.role_tiering

import rego.v1

import data.jit.lib.utils

# Primitive roles require CISO approval
# Predefined roles are allowed with standard approval
# Custom roles are preferred

check if {
	not utils.is_primitive_role
}

check if {
	utils.is_primitive_role
	utils.parsed_request.ciso_approved == true
}

reason := sprintf("Primitive role %s requires CISO approval", [utils.parsed_request.role]) if {
	not check
}
