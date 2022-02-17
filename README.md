# par

`par` is a bash script to run multiple commands in parallel and to output the results color-coded and without lines interleaving.

* Executes programs in parallel
* Human-readable output:
	* Color-coded lines by process. Up to 6 colors: red, green, yellow, purple, pink, or cyan
	* Prefixed lines with process name. Up to 72 characters (or truncated)
	* Prevents interleaving process outputs. Side effect: truncates lines at about 4000 characters
	* Combines stdout and stderr file descriptors for each process
* Kills all processes if any one exits with a nonzero exit code. Otherwise waits for all processes to exit zero

The combined output is inspired by Docker's color-coding. The interleaving prevention is adapted from [http://catern.org/pipes.html](http://catern.org/pipes.html)'s approach.

## fork

Unrelated helper function in bash to run a process and get results even after logging out of ssh.

```
function fork {
    nohup sh -c "$1 | mail -s \"`hostname`,`date`,$1\" email@example.com" &
}
```
