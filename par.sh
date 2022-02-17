#!/usr/bin/env bash
###---------------------------------------------------------------------
### par
### Parallelize commands. Displays up to 6 colors. Max 4000 char lines
### William Ughetta. February 2022. MIT License
###---------------------------------------------------------------------
set +euf -o pipefail

if [ $# -lt 1 ]; then >&2 echo example: $0 \'ping\ {google,apple}.com\'; exit 1; fi

TAG='par'

# Print colored line (6 colors: red, green, yellow, purple, pink, cyan). Default color: 39
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
function print_color {
  printf '\033[1;%sm%s\033[0m\n' $(( $1 ? 31+$1%6 : 39 )) "$2"
}

# Line up the output names
ABSMAX=71
MAXLEN=0; for i; do if [ ${#i} -gt $MAXLEN ]; then MAXLEN=${#i}; fi; done
if [ $MAXLEN -gt $ABSMAX ]; then MAXLEN=$ABSMAX; fi
function println { print_color $1 "$(printf "%-$(($MAXLEN+1))s| %s" "$2" "$3")" ; }

# Pad: Adapted from http://catern.org/pipes.html
PIPEBUF=4096 #`getconf PIPE_BUF /` # Reduces interleaving
pad() { 2>/dev/null dd conv=block cbs=$PIPEBUF obs=$PIPEBUF ; }
unpad() { 2>/dev/null dd conv=unblock cbs=$PIPEBUF ibs=$PIPEBUF ; }

# Exit when first sub-process exits
UNIFIED=`mktemp -u -t PIPE_UNIFIED`; mkfifo $UNIFIED
PIDS=""; C=0
for i; do
  C=$(( $C + 1 )); t=`mktemp -u -t PIPE_TMP_$C`; mkfifo $t
  eval "${i} &> $t &"
  PIDS+="$! "
  cat $t | while read line; do println $C "$i" "$line" ; done | pad >> $UNIFIED &
done
println 0 "$TAG" "Started $C procs. Waiting for any nonzero exit. PIDs: $PIDS"


# Output stream. Prevents lines (< 4096 chars) from interleaving
# TODO: Improvement detect no output for TIMEOUT (i.e. 5 minutes) and halt

EXITCODE=0
N_EXIT_ZERO=0
PIDS_EXIT_ZERO=""
# Continuously echo to stdout
while [ $EXITCODE -eq 0 ] && [ $N_EXIT_ZERO -lt $C ]; do cat $UNIFIED | unpad; done &
# Check every second if all processes exited zero or if any one exited nonzero
while [ $EXITCODE -eq 0 ] && [ $N_EXIT_ZERO -lt $C ]; do
  j=0
  for PID1 in $PIDS; do j=$(($j+1))
    if ! ps -p $PID1 &>/dev/null && ! [[ $PIDS_EXIT_ZERO == *" $PID1 "* ]]; then
      &>/dev/null wait $PID1; EXITCODE=$?
      EXTRA=""; if [ $EXITCODE -ne 0 ]; then EXTRA=" Killing remaining processes..."; fi
      println $j "$TAG" "PID $PID1 terminated with exit code: $EXITCODE. Command: '$(eval echo $`echo $j`)'$EXTRA" | pad >> $UNIFIED
      if [ $EXITCODE -eq 0 ]; then N_EXIT_ZERO=$(( $N_EXIT_ZERO + 1 )); PIDS_EXIT_ZERO+=" $PID1 "; continue; fi
      for PID2 in $PIDS; do &>/dev/null kill -9 $PID2; done; break # All done!
    fi
  done
  sleep 1
done

for PID in $PIDS; do EC=$EXITCODE; &>/dev/null wait $PID; EC=$? ; if [ $EXITCODE -eq 0 ]; then EXITCODE=$EC; fi; done

println 0 "$TAG" "Done. Exit code: $EXITCODE"
exit $EXITCODE
