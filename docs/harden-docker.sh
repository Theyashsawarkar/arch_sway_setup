#!/usr/bin/env bash
# Restricts Docker's published ports to localhost + private LAN ranges by
# default, closing the gap where Docker's own iptables rules bypass UFW
# entirely. See docs/DOCKER_SECURITY.md for the full explanation, testing
# steps, and rollback.
#
# Safe to re-run: deletes only the rules this script previously added
# (tagged with a comment) before re-adding them, so re-running doesn't
# pile up duplicates.
#
# NOT auto-run by install.sh -- this changes network-filtering behavior,
# which is not something to apply silently on every machine without the
# operator reading and deciding on it first.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo bash harden-docker.sh" >&2
  exit 1
fi

if ! command -v iptables >/dev/null 2>&1; then
  echo "iptables not found -- nothing to do." >&2
  exit 1
fi

COMMENT="dotfiles-docker-harden"

# RFC1918 private ranges + loopback. Adjust if your LAN uses something
# else (check `ip addr` on this machine for its actual subnet).
TRUSTED_RANGES=(
  127.0.0.0/8
  10.0.0.0/8
  172.16.0.0/12
  192.168.0.0/16
)

# DOCKER-USER only exists once dockerd has started at least once.
if ! iptables -L DOCKER-USER >/dev/null 2>&1; then
  echo "DOCKER-USER chain doesn't exist -- is the docker daemon running?" >&2
  exit 1
fi

echo "Removing any rules this script previously added..."
while iptables -D DOCKER-USER -m comment --comment "$COMMENT" 2>/dev/null; do :; done

echo "Allowing established/related connections through untouched..."
iptables -A DOCKER-USER -m comment --comment "$COMMENT" \
  -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN

for range in "${TRUSTED_RANGES[@]}"; do
  echo "Allowing new connections from $range..."
  iptables -A DOCKER-USER -m comment --comment "$COMMENT" -s "$range" -j RETURN
done

echo "Dropping new connections to published ports from everywhere else..."
iptables -A DOCKER-USER -m comment --comment "$COMMENT" -j DROP

echo
echo "Done. Current DOCKER-USER chain:"
iptables -L DOCKER-USER -n -v --line-numbers
echo
echo "Test this from another device on your LAN before trusting it -- see"
echo "docs/DOCKER_SECURITY.md. Rollback: sudo iptables -F DOCKER-USER"
