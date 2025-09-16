#!/bin/sh

local_time="$(TZ=America/Argentina/Buenos_Aires date '+%Y-%m-%d %H:%M:%S %Z')"
utc_time="$(TZ=UTC date '+%Y-%m-%d %H:%M:%S %Z')"
pdt_time="$(TZ=America/Los_Angeles date '+%Y-%m-%d %H:%M:%S %Z')"

cat <<EOF
{
  "text": "$(date '+%H:%M')",
  "tooltip": "󰥔 Local: $local_time\n󰥔 UTC:   $utc_time\n󰥔 PDT:   $pdt_time"
}
EOF
