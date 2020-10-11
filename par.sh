#!/bin/sh

# Print colored line (8 colors possible)
function println {
  printf '\033[1;%sm%s\033[0m\n' $(( 30+$1%8 )) "$2"
}

# Line up the output names
MAXLEN=0
for i; do if [ ${#i} -gt $MAXLEN ]; then MAXLEN=${#i}; fi; done
if [ $MAXLEN -gt 71 ]; then MAXLEN=$ABSMAX; fi

# Run each process
#C=0; for i; do declare TMP_$((C++))=$(mktemp); done
#C=0; for i; do t="TMP_$((C++))"; ${i} &> ${!t} & PIDS+=" $!"; done
#C=0; for i; do t="TMP_$((C++))"; cat ${!t}; rm ${!t}; done
#C=0; for i; do t="TMP_$((C++))"; ( ${i} | while read -r line; do printf "%-$(($MAXLEN+1))s| ${line}" "${i}"; done ) & PIDS+=" $!"; done

# Wait for each to finish
PIDS=""
C=0; for i; do t="TMP_$((C++))"; ( ${i} 2>&1 | while read line; do println $C "$(printf "%-$(($MAXLEN+1))s| %s" "$i" "$line")"; done ) & PIDS+=" $!"; done
for pid in $PIDS; do wait $pid; done

#C=0
#for i; do println C++ "$(printf "%-$(($MAXLEN+1))s| hello" "$i")"; done

# https://stackoverflow.com/questions/1570262/get-exit-code-of-a-background-process
