# shellcheck shell=bash
# Probe the live junk filter from outside. One deliberately spammy message per
# recipient: the control mailbox must refuse it, every mailbox with filtering
# off must take it. SERVER, PORT, FROM, CONTROL, UNFILTERED and MESSAGE come
# from spam-test.nix.

usage() {
  cat >&2 <<EOF
usage: spam-test [-s server] [-p port] [-f envelope-from] [recipient ...]

Sends one spammy message per recipient over SMTP and prints what the server
answered. With no recipients it probes:

  control     $CONTROL (must be rejected)
  unfiltered  $UNFILTERED (must be accepted)

and exits non-zero if either answer is wrong.

  -s  mailserver to talk to (default: $SERVER)
  -p  port to talk to (default: $PORT)
  -f  envelope sender to forge (default: $FROM)

Run it from a residential connection. From a mail provider's IP, SPF and DKIM
pass, the message scores near zero and lands everywhere regardless of this
config.
EOF
}

while getopts ":s:p:f:h" opt; do
  case "$opt" in
    s) SERVER="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    f) FROM="$OPTARG" ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done
shift $((OPTIND - 1))

# spam-test.eml carries no Date, no Message-ID, no charset and a forged
# paypal.com sender whose DMARC policy is reject. That is what scores past the
# reject threshold. The GTUBE pattern would not do: rspamd refuses it at parse
# time even where filtering is off, so it looks like a live filter no matter
# what.
message() {
  printf 'To: <%s>\n' "$1"
  cat "$MESSAGE"
}

# swaks prints the whole SMTP transcript. The verdict is the last reply that
# is neither the 220 greeting nor the 221 answer to QUIT: the response to the
# end of DATA, or the rejection that cut the transaction short.
probe() {
  local rcpt="$1" out code reply
  out=$(message "$rcpt" | swaks --server "$SERVER" --port "$PORT" --timeout 30 \
    --from "$FROM" --to "$rcpt" --data - 2>&1) || true
  reply=$(printf '%s\n' "$out" \
    | sed -n 's/^[[:space:]]*<[^ ]*[[:space:]]\{1,\}\([2-5][0-9][0-9].*\)/\1/p' \
    | grep -Ev '^(220|221)([ -]|$)' | tail -1) || true
  code=${reply%% *}
  if [ -z "$reply" ]; then
    printf '%s\n' "$out" >&2
    echo "no SMTP reply from $SERVER:$PORT for $rcpt" >&2
    return 2
  fi
  case "$code" in
    2*) verdict=accepted ;;
    *) verdict=rejected ;;
  esac
  printf '  %-28s %-8s %s\n' "$rcpt" "$verdict" "$reply"
}

failed=0

if [ $# -gt 0 ]; then
  echo
  for rcpt in "$@"; do
    probe "$rcpt" || failed=1
  done
  echo
  exit "$failed"
fi

echo
echo "control (filtering on, must be rejected):"
if ! probe "$CONTROL"; then
  failed=1
elif [ "$verdict" = accepted ]; then
  failed=1
  control_accepted=1
fi

echo
echo "unfiltered (must be accepted):"
for rcpt in $UNFILTERED; do
  if ! probe "$rcpt"; then
    failed=1
  elif [ "$verdict" = rejected ]; then
    failed=1
    unfiltered_rejected=1
  fi
done
echo

if [ -n "${control_accepted:-}" ]; then
  cat >&2 <<EOF
The control was accepted, so this run proves nothing: the message did not
score high enough from your IP. Send it from a residential connection. The
breakdown for any attempt is on the host:

  journalctl -u rspamd --since -10min | grep rspamd_task_write_log

EOF
fi

if [ -n "${unfiltered_rejected:-}" ]; then
  cat >&2 <<EOF
A mailbox that must never filter refused the message. On the host:

  rspamadm configdump settings
  journalctl -u rspamd --since -10min | grep rspamd_task_write_log

EOF
fi

exit "$failed"
