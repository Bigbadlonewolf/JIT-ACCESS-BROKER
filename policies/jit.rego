package jit

import rego.v1

import data.jit.constraints.duration
import data.jit.constraints.emergency
import data.jit.constraints.justification
import data.jit.constraints.role_tiering
import data.jit.constraints.sod
import data.jit.constraints.time_restricted
import data.jit.lib.utils

# Main allow/deny logic
default allow := false

allow if {
	utils.request_valid
	duration.check
	justification.check
	emergency.check
	sod.check
	role_tiering.check
	time_restricted.check
}

deny contains reason if {
	not utils.request_valid
	reason := "Invalid request format"
}

deny contains reason if {
	utils.request_valid
	not duration.check
	reason := duration.reason
}

deny contains reason if {
	utils.request_valid
	not justification.check
	reason := justification.reason
}

deny contains reason if {
	utils.request_valid
	not emergency.check
	reason := emergency.reason
}

deny contains reason if {
	utils.request_valid
	not sod.check
	reason := sod.reason
}

deny contains reason if {
	utils.request_valid
	not role_tiering.check
	reason := role_tiering.reason
}

deny contains reason if {
	utils.request_valid
	not time_restricted.check
	reason := time_restricted.reason
}

# For CI validation: check if a request would be allowed
result := {
	"allow": allow,
	"deny": deny,
	"request": utils.parsed_request,
} if utils.request_valid

result := {
	"allow": false,
	"deny": {"Invalid request format"},
	"request": null,
} if not utils.request_valid
