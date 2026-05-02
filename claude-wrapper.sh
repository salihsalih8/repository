#!/bin/bash
# Claude Code wrapper — PTY fix + auto-cleanup + 15-min timeout
# 
# Architecture:
# 1. Kill stale claude processes using sudoers-granted pkill
# 2. Write a temp script that runs claude as claude-worker
# 3. Run via socat PTY (forces TTY mode for claude output)
# 4. Wrap everything in timeout 900 (auto-kills hangs >15min)

# Step 1: Kill any stale claude processes (using sudoers rule)
sudo /usr/bin/pkill -u claude-worker "^/usr/bin/claude " 2>/dev/null
sleep 0.5
sudo /usr/bin/pkill -9 -u claude-worker "^/usr/bin/claude " 2>/dev/null

ARGS=()
PENDING=""

for arg in "$@"; do
  if [ -n "$PENDING" ]; then
    if [ -f "$arg" ]; then
      COPY="/tmp/cw-$(basename $arg)-$$"
      cp "$arg" "$COPY" 2>/dev/null && chmod 644 "$COPY" 2>/dev/null
      ARGS+=("$PENDING" "$COPY")
    else
      ARGS+=("$PENDING" "$arg")
    fi
    PENDING=""
    continue
  fi
  case "$arg" in
    --append-system-prompt-file|--mcp-config|--plugin-dir|--settings)
      PENDING="$arg" ;;
    *) ARGS+=("$arg") ;;
  esac
done
[ -n "$PENDING" ] && ARGS+=("$PENDING")

# Step 2: Build the command
RUN_CMD="cd / && exec sudo -u claude-worker /usr/bin/claude"
for a in "${ARGS[@]}"; do
  a_sq="${a//\'/\'\\\'\'}"
  RUN_CMD+=" '$a_sq'"
done

# Write temp script
TMPSCRIPT=$(mktemp /tmp/claude-run-XXXXXX.sh)
echo '#!/bin/bash' > "$TMPSCRIPT"
echo "$RUN_CMD" >> "$TMPSCRIPT"
chmod 755 "$TMPSCRIPT"

# Step 3: Run via socat PTY with 5-minute timeout
# timeout 300 = max 5 min per query (prevents infinite hangs)
# socat pty = forces TTY mode so claude produces output
exec timeout 900 socat EXEC:"$TMPSCRIPT",pty,ctty,echo=0,raw STDOUT 2>/dev/null
