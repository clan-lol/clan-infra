{ config, lib, pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.writers.writeDashBin "zt-init" ''
      set -efux
      NODEID=$(cat /var/lib/zerotier-one/identity.public | cut -d: -f1)
      NEW_NET=$(${pkgs.curl}/bin/curl -X POST "http://localhost:9993/controller/network/''${NODEID}______" -H "X-ZT1-AUTH: $(sudo cat /var/lib/zerotier-one/authtoken.secret)" -d {})
    '')
    (pkgs.writers.writeDashBin "zt-network-edit" ''
      set -efux
      TMP_NET_CONFIG=$(mktemp)
      trap 'rm -f "$TMP_NET_CONFIG"' EXIT
      NETWORK_ID=''${NETWORK_ID:-$(zerotier-cli listnetworks -j | jq -r '.[0] | .id')}
      ${pkgs.curl}/bin/curl "http://localhost:9993/controller/network/''${NETWORK_ID}" -H "X-ZT1-AUTH: $(sudo cat /var/lib/zerotier-one/authtoken.secret)" -d {} > "$TMP_NET_CONFIG"
      $EDITOR "$TMP_NET_CONFIG"
      ${pkgs.curl}/bin/curl "http://localhost:9993/controller/network/''${NETWORK_ID}" -H "X-ZT1-AUTH: $(sudo cat /var/lib/zerotier-one/authtoken.secret)" -d @"$TMP_NET_CONFIG"
    '')
    (pkgs.writers.writeDashBin "zt-member-ls" ''
      set -eu
      NETWORK_ID=''${NETWORK_ID:-$(zerotier-cli listnetworks -j | jq -r '.[0] | .id')}
      cat /var/lib/zerotier-one/controller.d/network/$NETWORK_ID/member/* | jq -s
    '')
    (pkgs.writers.writeDashBin "zt-member-auth" ''
      set -efux
      MEMBER_ID=$1
      if ! printf '%s' $MEMBER_ID | grep -q '^[0-9a-f]\{10\}$'; then
        echo '$MEMBER_ID is not a valid member id'
        exit 1
      fi
      URL='http://localhost:9993/controller/'
      TOKEN=''${TOKEN:-$(cat /var/lib/zerotier-one/authtoken.secret)}
      NETWORK_ID=''${NETWORK_ID:-$(zerotier-cli listnetworks -j | jq -r '.[0] | .id')}

      curl -fSs -H "X-ZT1-AUTH: $TOKEN" "$URL/network/$NETWORK_ID/member/$MEMBER_ID" -d '{"authorized": true}'
    '')
  ];
}
