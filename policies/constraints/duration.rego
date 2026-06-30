package jit.constraints.duration

import rego.v1

import data.jit.lib.utils

# Default max duration: 4 hours for standard access
# Exception max duration: 24 hours (requires additional approval)
max_standard_duration := 240  # 4 hours in minutes
max_exception_duration := 1440  # 24 hours in minutes

check if {
	duration_mins := utils.parse_duration(utils.parsed_request.duration)
	duration_mins <= max_standard_duration
}

check if {
	duration_mins := utils.parse_duration(utils.parsed_request.duration)
	duration_mins <= max_exception_duration
	utils.parsed_request.emergency == true
}

reason := sprintf("Duration exceeds maximum allowed: requested %s, max standard %dm, max emergency %dm", [
	utils.parsed_request.duration,
	max_standard_duration,
	max_exception_duration,
]) if {
	not check
}
