package jit.constraints.sod

import rego.v1

import data.jit.lib.utils

# Separation of duties: requester cannot approve their own access
# This is enforced at the CI level (GitHub branch protection)
# This policy provides an additional OPA-level check

check if {
	# If an approver is specified, they must be different from requester
	not utils.parsed_request.approver
}

check if {
	utils.parsed_request.approver
	utils.parsed_request.approver != utils.parsed_request.requester
}

reason := "Separation of duties violated: approver cannot be the requester" if {
	not check
}
