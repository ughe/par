# par

`par` is a bash script to run multiple commands in parallel and to output the results color-coded and without lines interleaving.

* Executes programs in parallel
* Human-readable output:
	* Color-coded lines by process. Up to 6 colors: red, green, yellow, purple, pink, or cyan
	* Prefixed lines with process name. Up to 72 characters (or truncated)
	* Prevents interleaving process outputs. Side effect: truncates lines at about 4000 characters
	* Combines stdout and stderr file descriptors for each process
* Kills all processes if any one exits with a nonzero exit code. Includes children one level deep. Otherwise waits for all processes to exit zero

The combined output is inspired by Docker compose's color-coding. The interleaving prevention is adapted from [http://catern.org/pipes.html](http://catern.org/pipes.html)'s approach.

## Tests

Unit tests must be executed from inside the `tests` directory since they expect it to be the current working directory. For example run `make test` or:

```
cd tests && ./test_crash.sh
```

The tests are demonstrations and have no assertions. Tests pass when they terminate and fail if they don't. All tests should print "Done" on the last line. Additionally, running `ps -ef | grep par` should yield no instances of the tests afterwards.

## Examples

There are several ways to run commands in parallel. Three approaches are shown using `par`, `xargs`, and email. Here's an example with `par`:

```
par 'ping google.com' 'ping apple.com'
```

Another approach, is to use `xargs` (good for very quick tasks in parallel but interleaves output):

```
echo '"ping google.com | head -n5" "ping apple.com | head -n5"' | xargs -n1 -P4 -I {} sh -c "echo '{}'; {}"
```

A third alternative, is to start each process manually and email the results when finished (good for very long tasks i.e. days and doesn't interleave output):

```
function fork {
    nohup sh -c "$1 | mail -s \"`hostname`,`date`,$1\" email@example.com" &
}
fork 'ping google.com | head -n5'
fork 'ping apple.com | head -n5'
```
