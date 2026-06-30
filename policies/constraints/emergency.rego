package jit.constraints.emergency

import rego.v1

import data.jit.lib.utils

# Emergency access requires secondary approval
# Check that emergency requests have an approver listed
check if {
	utils.parsed_request.emergency == true
	utils.parsed_request.approver
	utils.parsed_request.approver != utils.parsed_request.requester
}

# Non-emergency requests always pass this check
check if {
	utils.parsed_request.emergency != true
}

reason := "Emergency access requires a secondary approver different from the requester" if {
	not check
}
