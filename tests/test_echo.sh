#!/usr/bin/env sh

if [ $# -ne 2 ]; then >&2 echo "usage: $0 72 0"; >&2 echo "usage: $0 line_length exit_code"; exit 1; fi

LINE_LENGTH="$1" # i.e. 4096
EXIT_CODE="$2" # i.e. 0
MAX_ITER=5

SCRIPT="echo_${LINE_LENGTH}_${EXIT_CODE}.sh"
cat >$SCRIPT <<EOF
#!/usr/bin/env bash
MAX_ITER=$MAX_ITER
LINE_LENGTH=$LINE_LENGTH
if [ \$# -lt 1 ]; then >&2 echo "usage: \$0 seconds [max_iter=\$MAX_ITER]"; exit 1; fi
if [ \$# -eq 2 ]; then MAX_ITER="\$2"; fi

for i in \`seq 1 \$MAX_ITER\`; do echo "[INFO] Wait \$1 seconds. Iteration: \$i Data: \$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c \$LINE_LENGTH)"; sleep \$1; done

EC=$EXIT_CODE
>&2 echo "Reached MAX_ITER: \$MAX_ITER. Exit code: \$EC"; exit \$EC
EOF

chmod u+x $SCRIPT

i=1 # Seconds
../par "./$SCRIPT $i $MAX_ITER" "./$SCRIPT $i" "./$SCRIPT $i" "./$SCRIPT $i 2" "./$SCRIPT $i" "./$SCRIPT $i"
EC=$?

# Cleanup
rm $SCRIPT
exit $EC
