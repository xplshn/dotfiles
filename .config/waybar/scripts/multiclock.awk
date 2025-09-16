#!/usr/bin/awk -f

BEGIN {
  cmd_local = "TZ=America/Argentina/Buenos_Aires date '+%Y-%m-%d %H:%M:%S %Z'"
  cmd_utc   = "TZ=UTC date '+%Y-%m-%d %H:%M:%S %Z'"
  cmd_pdt   = "TZ=America/Los_Angeles date '+%Y-%m-%d %H:%M:%S %Z'"
  cmd_short = "date '+%H:%M'"

  cmd_local | getline local; close(cmd_local)
  cmd_utc   | getline utc;   close(cmd_utc)
  cmd_pdt   | getline pdt;   close(cmd_pdt)
  cmd_short | getline short; close(cmd_short)

  tooltip = "󰥔 Local: " local "\\n󰥔 UTC:   " utc "\\n󰥔 PDT:   " pdt

  printf("{\"text\":\"%s\",\"tooltip\":\"%s\"}\n", short, tooltip)
}
