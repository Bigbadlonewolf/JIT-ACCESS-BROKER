package jit.constraints.justification

import rego.v1

import data.jit.lib.utils

check if {
	count(utils.parsed_request.justification) >= 10
	not regex.match(`^(?i)(test|todo|tbd|n/a|none).*$`, utils.parsed_request.justification)
}

reason := "Justification too short or invalid (minimum 10 characters, no placeholder text)" if {
	not check
}
