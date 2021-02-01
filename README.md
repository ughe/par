1) Run all scripts in parallel (make sure not deprioritized)
2) Print a message when finished or if exited with error (and abort with any error -- with option to keep running and return status code)
./par.sh ./fst ./snd ./trd


Reserve colors for stderr or Exit-code non-zero vs Exit code 0?


Useful cousin:

```
function fork {
    nohup sh -c "$1 | mail -s \"`hostname`,`date`,$1\" wughetta@princeton.edu" &
}
```
