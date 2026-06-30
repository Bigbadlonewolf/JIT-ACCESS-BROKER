package jit.lib.utils

import rego.v1

# Parse the request from input
parsed_request := request if {
	request := yaml.unmarshal(input)
}

# Validate request format
request_valid if {
	parsed_request.requester
	parsed_request.resource
	parsed_request.role
	parsed_request.justification
	parsed_request.duration
	parsed_request.requested_at
}

# Role classification
primitive_roles := {"roles/owner", "roles/editor", "roles/viewer"}

is_primitive_role if parsed_request.role in primitive_roles

# Time parsing helpers
parse_duration(d) := minutes if {
	# Format: "4h", "30m", "1h30m"
	regex.match(`^(\d+)h$`, d, [hours_str])
	to_number(hours_str, hours)
	minutes := hours * 60
}

parse_duration(d) := minutes if {
	regex.match(`^(\d+)m$`, d, [mins_str])
	to_number(mins_str, minutes)
}

parse_duration(d) := minutes if {
	regex.match(`^(\d+)h(\d+)m$`, d, [hours_str, mins_str])
	to_number(hours_str, hours)
	to_number(mins_str, mins)
	minutes := hours * 60 + mins
}

# Request age in hours
request_age_hours := hours if {
	requested_at := time.parse_rfc3339_ns(parsed_request.requested_at)
	now := time.now_ns()
	hours := (now - requested_at) / (1000000000 * 3600)
}
