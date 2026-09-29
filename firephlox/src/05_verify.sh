# shellcheck shell=bash
# 05_verify.sh — final validation: confirm every configuration path was
# mapped correctly and report the authoritative locking mechanism.

firephlox_verify() {
	firephlox_section 'Verification · Path mapping & lock status'

	if firephlox_is_dry_run; then
		firephlox_info '(dry-run) Would verify the following mapped paths:'
		firephlox_info "  ${FIREPHLOX_ETC_POLICIES_FILE}"
		firephlox_info "  ${FIREPHLOX_SNAP_POLICIES_FILE}"
		firephlox_info "  ${FIREPHLOX_USER_PROFILES_DIR}/<profile>/user.js"
		return 0
	fi

	local ok=1

	_verify_policies_file() {
		local path="$1" label="$2"
		if [[ -f "${path}" ]]; then
			firephlox_ok "${label} present: ${path}"
			if command -v python3 >/dev/null 2>&1; then
				if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "${path}" 2>/dev/null; then
					firephlox_ok "${label} is valid JSON."
				else
					firephlox_error "${label} is NOT valid JSON."; ok=0
				fi
			fi
		else
			firephlox_error "${label} missing: ${path}"; ok=0
		fi
	}

	# --- Task 1 artefacts ------------------------------------------------
	_verify_policies_file "${FIREPHLOX_ETC_POLICIES_FILE}"  'policies.json (/etc)'
	_verify_policies_file "${FIREPHLOX_SNAP_POLICIES_FILE}" 'policies.json (snap)'

	# --- Task 2 artefacts ------------------------------------------------
	local -a profiles
	mapfile -t profiles < <(firephlox_discover_profiles)
	if [[ ${#profiles[@]} -eq 0 ]]; then
		firephlox_warn 'No profiles found to verify user.js.'
	else
		local profile
		for profile in "${profiles[@]}"; do
			if grep -q 'firephlox managed block' "${profile}/user.js" 2>/dev/null; then
				firephlox_ok "user.js managed block present: ${profile}/user.js"
			else
				firephlox_warn "user.js managed block missing in ${profile}"
			fi
		done
	fi

	printf '\n'
	if [[ "${ok}" -eq 1 ]]; then
		firephlox_ok "${FP_BOLD}All critical configuration paths mapped correctly.${FP_RESET}"
	else
		firephlox_die 'One or more configuration artefacts are missing. Review the log above.'
	fi

	firephlox_info 'Primary enforcement: /etc/firefox/policies/policies.json (Mozilla-documented).'
	firephlox_info 'Supplementary:      /var/snap/firefox/common/distribution/policies.json (Ubuntu snap).'
}
