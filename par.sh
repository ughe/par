#!/usr/bin/env bash
#set +euf -o pipefail
#trap "kill 0" SIGINT

# Exit when first sub-process exits
FAILFAST=true

# Print colored line (6 colors: red, green, yellow, purple, pink, cyan). Default: 39
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
function println {
  printf '\033[1;%sm%s\033[0m\n' $(( $1 ? 31+$1%6 : 39 )) "$2"
}

# Line up the output names
MAXLEN=0
ABSMAX=71
for i; do if [ ${#i} -gt $MAXLEN ]; then MAXLEN=${#i}; fi; done
if [ $MAXLEN -gt $ABSMAX ]; then MAXLEN=$ABSMAX; fi
function println3 { println $1 "$(printf "%-$(($MAXLEN+1))s| %s" "$2" "$3")" ; }

# Pad: Thanks to http://catern.org/pipes.html
PIPEBUF=4096 #`getconf PIPE_BUF /` # Note: may break lines > 4096 characters
pad() { 2>/dev/null dd conv=block cbs=$PIPEBUF obs=$PIPEBUF ; }
unpad() { 2>/dev/null dd conv=unblock cbs=$PIPEBUF ibs=$PIPEBUF ; }

# Run each process
#C=0; for i; do declare TMP_$((C++))=$(mktemp); done
#C=0; for i; do t="TMP_$((C++))"; ${i} &> ${!t} & PIDS+=" $!"; done
#C=0; for i; do t="TMP_$((C++))"; cat ${!t}; rm ${!t}; done
#C=0; for i; do t="TMP_$((C++))"; ( ${i} | while read -r line; do printf "%-$(($MAXLEN+1))s| ${line}" "${i}"; done ) & PIDS+=" $!"; done
# Wait for each to finish
#PIDS="" ; C=0 ; for i; do t="TMP_$((C++))" ; (exec ${i} 2>&1 | while read line; do println $C "$(printf "%-$(($MAXLEN+1))s| %s" "$i" "$line")" ; done) & PIDS+=" $!"; done

UNIFIED=`mktemp -u -t PIPE_UNIFIED`
mkfifo $UNIFIED
PIDS=""
C=0
for i; do
  C=$(( $C + 1 ))
  t=`mktemp -u -t PIPE_TMP_$C`
  mkfifo $t
  ${i} &> $t &
  PIDS+=" $!"
  cat $t | while read line; do println3 $C "$i" "$line" ; done | pad >> $UNIFIED &
done

println3 0 "[PARALLEL]" "Started $C procs: $PIDS"
println3 0 "[PARALLEL]" "Waiting for first proc to exit with nonzero status code..."

# Output combined stream
cat $UNIFIED | unpad &
UNIFIED_PID="$!"

# Check every second for a process that terminated
# A bit messy... but has nice output
EXITCODE="0"
N_EXIT_ZERO="0"
PIDS_EXIT_ZERO=""
while $FAILFAST; do
  j=0
  for PID1 in $PIDS; do j=$(($j+1)); if ! &>/dev/null ps -p $PID1 && ! [[ $PIDS_EXIT_ZERO == *" $PID1 "* ]]; then
    wait $PID1
    EXITCODE=$?
    if [ $N_EXIT_ZERO -lt $(( $C - 1 )) ]; then
      println3 $j "[PARALLEL]" "PID $PID1 terminated with exit code: $EXITCODE. Command: '$(eval echo -n $`echo $j`)'" | pad >> $UNIFIED # Edge case: this doesn't work in last iteration
    else
      println3 $j "[PARALLEL]" "PID $PID1 terminated with exit code: $EXITCODE. Command: '$(eval echo -n $`echo $j`)'"
    fi
    if [ $EXITCODE -eq 0 ]; then
      N_EXIT_ZERO=$(( $N_EXIT_ZERO + 1 ))
      PIDS_EXIT_ZERO+=" $PID1 "
      continue
    fi
    println3 0 "[PARALLEL]" "Failure PID $PID1. Killing remaining processes" | pad >> $UNIFIED
    for PID2 in $PIDS; do &>/dev/null kill -9 $PID2; done ; FAILFAST=false; break
  fi; done
  if [ $N_EXIT_ZERO -eq $C ]; then
    println3 0 "[PARALLEL]" "Success. All processes exited zero"
    break
  fi
  sleep 1
done

# Ensure all $PIDS are finished
for PID in $PIDS; do wait $PID; EC=$? ; if [ $EXITCODE -eq 0 ]; then EXITCODE=$EC; fi; done

# Flush the output
rm $UNIFIED
wait $UNIFIED_PID
println3 0 "[PARALLEL]" "Done. Exit code: $EXITCODE"
exit $EXITCODE
