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

echo "=== Generated /etc/hosts entries in $NEW_HOSTS_FILE ==="
cat "$NEW_HOSTS_FILE"
echo "====================================="


rm -f "$TMP_OUTPUT" 


