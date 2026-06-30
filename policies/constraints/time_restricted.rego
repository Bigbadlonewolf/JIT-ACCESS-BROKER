package jit.constraints.time_restricted

import rego.v1

import data.jit.lib.utils

# Business hours: Monday-Friday, 08:00-18:00 UTC
# Emergency access bypasses this restriction

business_days := {1, 2, 3, 4, 5}  # Monday=1 through Friday=5
business_start := 8   # 08:00 UTC
business_end := 18    # 18:00 UTC UTC

check if {
	utils.parsed_request.emergency == true
}

check if {
	# Get current time in UTC
	now := time.now_ns()
	[year, month, day, hour] := time.date(now)
	weekday := time.weekday(now)

	# Check business hours
	weekday in business_days
	hour >= business_start
	hour < business_end
}

reason := "Access requests outside business hours require emergency flag (Mon-Fri 08:00-18:00 UTC)" if {
	not check
}
