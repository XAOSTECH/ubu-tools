# shellcheck shell=bash
# 05_verify.sh — final validation: confirm every configuration path was
# mapped correctly and report the authoritative locking mechanism.

firephlox_verify() {
	firephlox_section 'Verification · Path mapping & lock status'

	if firephlox_is_dry_run; then
		firephlox_info '(dry-run) Would verify the following mapped paths:'
		firephlox_info "  ${FIREPHLOX_POLICIES_FILE}"
		firephlox_info "  ${FIREPHLOX_CFG_FILE}"
		firephlox_info "  ${FIREPHLOX_AUTOCONFIG_FILE}"
		firephlox_info "  ${FIREPHLOX_USER_PROFILES_DIR}/<profile>/user.js"
		return 0
	fi

	local ok=1

	# --- Task 1 artefacts ------------------------------------------------
	if [[ -f "${FIREPHLOX_POLICIES_FILE}" ]]; then
		firephlox_ok "policies.json present: ${FIREPHLOX_POLICIES_FILE}"
		if command -v python3 >/dev/null 2>&1; then
			if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "${FIREPHLOX_POLICIES_FILE}" 2>/dev/null; then
				firephlox_ok 'policies.json is valid JSON.'
			else
				firephlox_error 'policies.json is NOT valid JSON.'; ok=0
			fi
		fi
	else
		firephlox_error "policies.json missing: ${FIREPHLOX_POLICIES_FILE}"; ok=0
	fi

	if [[ -f "${FIREPHLOX_CFG_FILE}" ]]; then
		firephlox_ok "mozilla.cfg present: ${FIREPHLOX_CFG_FILE}"
	else
		firephlox_error "mozilla.cfg missing: ${FIREPHLOX_CFG_FILE}"; ok=0
	fi

	if [[ -f "${FIREPHLOX_AUTOCONFIG_FILE}" ]]; then
		firephlox_ok "autoconfig.js present: ${FIREPHLOX_AUTOCONFIG_FILE}"
	else
		firephlox_error "autoconfig.js missing: ${FIREPHLOX_AUTOCONFIG_FILE}"; ok=0
	fi

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

	firephlox_info 'Enforced via Enterprise Policies (policies.json). mozilla.cfg is a traditional fallback, subject to the Snap AutoConfig search path.'
}
