#!/usr/bin/env bash
# ----------------------------------------------------------------------
# Purpose: Convert a reverse‑proxy JSON definition into /etc/hosts entries.
# Requires: jq (JSON processor)
# ----------------------------------------------------------------------

set -euo pipefail

# --------------------------- Config ------------------------------------
JSON_FILE="/usr/syno/etc/www/ReverseProxy.json"
TMP_OUTPUT=$(mktemp)                                      # temporary raw output

DESTINATION_PATH_FOLDER="/volume1/ssl_certs"
NEW_HOSTS_FILE="$DESTINATION_PATH_FOLDER/reverse_proxy_hosts.txt"   


# ----------------------------------------------------------------------
# 1️⃣  Required files
# ----------------------------------------------------------------------
if [[ ! -f "$JSON_FILE" ]]; then
    echo "Error: file '$JSON_FILE' does not exist."
    exit 1
fi

# ----------------------------------------------------------------------
# 2️⃣  Helper: turn numeric protocol into a readable word
# ----------------------------------------------------------------------
proto_name() {
    case "$1" in
        0) echo "http" ;;
        1) echo "https" ;;
        *) echo "unknown" ;;
    esac
}

# ----------------------------------------------------------------------
# 3️⃣  Extract data with jq and build a map (same as before)
# ----------------------------------------------------------------------
jq -r '
    to_entries
    | map(select(.key != "version"))
    | .[]
    | {
        fe_fqdn: .value.frontend.fqdn,
        fe_proto: (.value.frontend.protocol // empty),
        be_fqdn: .value.backend.fqdn,
        be_port: .value.backend.port,
        be_proto: (.value.backend.protocol // empty)
    }
    | "\(.fe_fqdn)\t\(.fe_proto)\t\(.be_fqdn)\t\(.be_port)\t\(.be_proto)"
' "$JSON_FILE" > "$TMP_OUTPUT"

declare -A redirects   # associative array: key = frontend fqdn, value = newline‑separated descriptors

while IFS=$'\t' read -r fe_fqdn fe_proto be_fqdn be_port be_proto; do
    src=$(proto_name "$fe_proto")
    dst=$(proto_name "$be_proto")

    if [[ "$be_fqdn" == "$fe_fqdn" ]]; then
        descriptor="${src} → ${dst}"
    else
        if [[ -n "$be_port" && "$be_port" != "null" ]]; then
            dst_url="${dst}://${be_fqdn}:${be_port}"
        else
            dst_url="${dst}://${be_fqdn}"
        fi
        descriptor="${src} → ${dst_url}"
    fi

    if [[ -z "${redirects[$fe_fqdn]:-}" ]]; then
        redirects["$fe_fqdn"]="$descriptor"
    else
        redirects["$fe_fqdn"]+=$'\n'"$descriptor"
    fi
done < "$TMP_OUTPUT"

# ----------------------------------------------------------------------
# 4️⃣  Produce the final /etc/hosts lines (still writing to $NEW_HOSTS_FILE)
# ----------------------------------------------------------------------
SYNOLOGY_IP=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

cat > "$NEW_HOSTS_FILE" << EOF
# --- Custom Hosts File generated from Synology ReverseProxy.json ---
# Generated on $(date)
#
# INSTRUCTIONS:
# 1. Copy the content below.
# 2. On your Mac/Linux machine: sudo vi /etc/hosts
# 3. On your Windows machine: Open C:\\Windows\\System32\\drivers\\etc\\hosts as Administrator
# 4. Paste the content at the end of the file and save.
#
# ----------------------------------------------------------------------
# Standard Host Entries
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1       localhost
255.255.255.255 broadcasthost
::1             localhost
#
# ----------------------------------------------------------------------
# Hostnames below point to your Synology Reverse Proxy IP: $SYNOLOGY_IP
# ----------------------------------------------------------------------
EOF

for fe in "${!redirects[@]}"; do
    sorted_comment=$(printf "%s" "${redirects[$fe]}" |
        awk '
            {
                split($0, parts, "://")
                hostport = parts[2]
                split(hostport, hp, ":")
                host = hp[1]

                if (host ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ || host == "localhost")
                    ip = (ip ? ip " AND " : "") $0
                else
                    name = (name ? name " AND " : "") $0
            }
            END {
                if (name) printf "%s", name
                if (ip) {
                    if (name) printf " AND "
                    printf "%s", ip
                }
            }
        ')
    printf "%s\t%-30s\t# redirect %s\n" "$SYNOLOGY_IP" "$fe" "$sorted_comment"
done | sort -k2 >> "$NEW_HOSTS_FILE"

echo "=== Generated /etc/hosts entries in $NEW_HOSTS_FILE ==="
cat "$NEW_HOSTS_FILE"
echo "====================================="



rm -f "$TMP_OUTPUT" 

#!/bin/bash
# ----------------------------------------------------------------------
# Purpose: Convert a reverse‑proxy JSON definition into /etc/hosts entries.
# Requires: jq (JSON processor)
# ----------------------------------------------------------------------

set -euo pipefail

# --------------------------- Config ------------------------------------
JSON_FILE="/usr/syno/etc/www/ReverseProxy.json"
TMP_OUTPUT=$(mktemp)                                      # temporary raw output

DESTINATION_PATH_FOLDER="/volume1/ssl_certs"
NEW_HOSTS_FILE="$DESTINATION_PATH_FOLDER/reverse_proxy_hosts.txt"   


# ----------------------------------------------------------------------
# 1️⃣  Required files
# ----------------------------------------------------------------------
if [[ ! -f "$JSON_FILE" ]]; then
    echo "Error: file '$JSON_FILE' does not exist."
    exit 1
fi

# ----------------------------------------------------------------------
# 2️⃣  Helper: turn numeric protocol into a readable word
# ----------------------------------------------------------------------
proto_name() {
    case "$1" in
        0) echo "http" ;;
        1) echo "https" ;;
        *) echo "unknown" ;;
    esac
}

# ----------------------------------------------------------------------
# 3️⃣  Extract data with jq and build a map (same as before)
# ----------------------------------------------------------------------
jq -r '
    to_entries
    | map(select(.key != "version"))
    | .[]
    | {
        fe_fqdn: .value.frontend.fqdn,
        fe_proto: (.value.frontend.protocol // empty),
        be_fqdn: .value.backend.fqdn,
        be_port: .value.backend.port,
        be_proto: (.value.backend.protocol // empty)
    }
    | "\(.fe_fqdn)\t\(.fe_proto)\t\(.be_fqdn)\t\(.be_port)\t\(.be_proto)"
' "$JSON_FILE" > "$TMP_OUTPUT"

declare -A redirects   # associative array: key = frontend fqdn, value = newline‑separated descriptors

while IFS=$'\t' read -r fe_fqdn fe_proto be_fqdn be_port be_proto; do
    src=$(proto_name "$fe_proto")
    dst=$(proto_name "$be_proto")

    if [[ "$be_fqdn" == "$fe_fqdn" ]]; then
        descriptor="${src} → ${dst}"
    else
        if [[ -n "$be_port" && "$be_port" != "null" ]]; then
            dst_url="${dst}://${be_fqdn}:${be_port}"
        else
            dst_url="${dst}://${be_fqdn}"
        fi
        descriptor="${src} → ${dst_url}"
    fi

    if [[ -z "${redirects[$fe_fqdn]:-}" ]]; then
        redirects["$fe_fqdn"]="$descriptor"
    else
        redirects["$fe_fqdn"]+=$'\n'"$descriptor"
    fi
done < "$TMP_OUTPUT"

# ----------------------------------------------------------------------
# 4️⃣  Produce the final /etc/hosts lines (still writing to $NEW_HOSTS_FILE)
# ----------------------------------------------------------------------
SYNOLOGY_IP=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

cat > "$NEW_HOSTS_FILE" << EOF
# --- Custom Hosts File generated from Synology ReverseProxy.json ---
# Generated on $(date)
#
# INSTRUCTIONS:
# 1. Copy the content below.
# 2. On your Mac/Linux machine: sudo vi /etc/hosts
# 3. On your Windows machine: Open C:\\Windows\\System32\\drivers\\etc\\hosts as Administrator
# 4. Paste the content at the end of the file and save.
#
# ----------------------------------------------------------------------
# Standard Host Entries
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1       localhost
255.255.255.255 broadcasthost
::1             localhost
#
# ----------------------------------------------------------------------
# Hostnames below point to your Synology Reverse Proxy IP: $SYNOLOGY_IP
# ----------------------------------------------------------------------
EOF

for fe in "${!redirects[@]}"; do
    sorted_comment=$(printf "%s" "${redirects[$fe]}" |
        awk '
            {
                split($0, parts, "://")
                hostport = parts[2]
                split(hostport, hp, ":")
                host = hp[1]

                if (host ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ || host == "localhost")
                    ip = (ip ? ip " AND " : "") $0
                else
                    name = (name ? name " AND " : "") $0
            }
            END {
                if (name) printf "%s", name
                if (ip) {
                    if (name) printf " AND "
                    printf "%s", ip
                }
            }
        ')
    printf "%s\t%-30s\t# redirect %s\n" "$SYNOLOGY_IP" "$fe" "$sorted_comment"
done | sort -k2 >> "$NEW_HOSTS_FILE"

python3 - <<'PY' "$JSON_FILE" >> "$NEW_HOSTS_FILE"
import json
import sys
import os

def get_proto(p_code):
    return "https" if p_code == 1 else "http"

def process_json(raw_data):
    try:
        data = json.loads(raw_data)
    except json.JSONDecodeError:
        print("Error: Invalid JSON format.")
        return

    # Filter rules: must have customize_headers and ignore "version" key
    filtered_rules = [
        val for key, val in data.items()
        if key != "version" and val.get('customize_headers')
    ]

    # Sort by Frontend FQDN
    sorted_rules = sorted(filtered_rules, key=lambda x: x.get('frontend', {}).get('fqdn', ''))

    if not sorted_rules:
        return

    print("# " + "-" * 66)
    print("# Rules with Custom Headers (Sorted by URL)")
    print("# " + "-" * 66)
    print("#")

    for val in sorted_rules:
        f = val.get('frontend', {})
        b = val.get('backend', {})
        headers = val.get('customize_headers', [])

        f_fqdn, f_port = f.get('fqdn'), f.get('port')
        f_proto = get_proto(f.get('protocol'))

        b_fqdn, b_port = b.get('fqdn'), b.get('port')
        b_proto = get_proto(b.get('protocol'))

        h_list = [f"{h['name']}: {h['value']}" for h in headers]
        h_str = f"   (headers: {', '.join(h_list)})"

        print(f"# Rule: {f_fqdn}")
        print(f"#   {f_proto} -> {b_proto}://{b_fqdn}:{b_port}{h_str}")
        print("#")

if __name__ == "__main__":
    input_content = None

    # Priority 1: Argument (e.g., ./script.py file.json)
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
        if os.path.exists(file_path):
            with open(file_path, 'r') as f:
                input_content = f.read()
        else:
            print(f"Error: File '{file_path}' not found.")
            sys.exit(1)

    # Priority 2: Piped data (e.g., cat file.json | ./script.py)
    elif not sys.stdin.isatty():
        input_content = sys.stdin.read()

    # Priority 3: Default Synology Path
    else:
        default_path = '/usr/syno/etc/www/ReverseProxy.json'
        if os.path.exists(default_path):
            with open(default_path, 'r') as f:
                input_content = f.read()
        else:
            print("Error: No file provided and default Synology config not found.")
            sys.exit(1)

    if input_content:
        process_json(input_content)
PY
echo "=== Generated /etc/hosts entries in $NEW_HOSTS_FILE ==="
cat "$NEW_HOSTS_FILE"
echo "====================================="

rm -f "$TMP_OUTPUT" 
