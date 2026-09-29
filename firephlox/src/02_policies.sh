# shellcheck shell=bash
# 02_policies.sh — Task 1: enterprise policy and AutoConfig injection.
# Writes only within the writable system surface: /var/snap/firefox/common.

firephlox_apply_policies() {
	firephlox_section 'Task 1 · Enterprise policy & AutoConfig injection'

	# Step A — policies.json: the primary, Snap-native enforcement mechanism.
	firephlox_write_file "${FIREPHLOX_POLICIES_FILE}" 0644 <<'JSON'
{
  "policies": {
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "Preferences": {
      "toolkit.telemetry.cachedClientID": {
        "Value": "00000000-0000-0000-0000-000000000000",
        "Status": "locked"
      },
      "browser.newtabpage.activity-stream.impressionId": {
        "Value": "{}",
        "Status": "locked"
      },
      "toolkit.telemetry.unified": {
        "Value": false,
        "Status": "locked"
      },
      "toolkit.telemetry.server": {
        "Value": "http://127.0.0.1",
        "Status": "locked"
      }
    }
  }
}
JSON
	firephlox_ok "policies.json → ${FIREPHLOX_POLICIES_FILE}"

	# Step B — traditional AutoConfig (mozilla.cfg) as a belt-and-braces lock.
	# NOTE: the very first line MUST stay a comment; Firefox skips line one.
	firephlox_write_file "${FIREPHLOX_CFG_FILE}" 0644 <<'CFG'
// firephlox mozilla.cfg — the first line MUST remain a comment.
lockPref("toolkit.telemetry.cachedClientID", "00000000-0000-0000-0000-000000000000");
lockPref("browser.newtabpage.activity-stream.impressionId", "{}");
lockPref("toolkit.telemetry.unified", false);
lockPref("toolkit.telemetry.server", "http://127.0.0.1");
CFG
	firephlox_ok "mozilla.cfg → ${FIREPHLOX_CFG_FILE}"

	# The pointer file that instructs Firefox to read the mozilla.cfg above.
	firephlox_write_file "${FIREPHLOX_AUTOCONFIG_FILE}" 0644 <<'PREF'
// firephlox AutoConfig pointer.
pref("general.config.filename", "mozilla.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
PREF
	firephlox_ok "autoconfig.js → ${FIREPHLOX_AUTOCONFIG_FILE}"
}
