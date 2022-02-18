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

There are several ways to run commands in parallel. Here's how one could use `par`:

```
par 'ping google.com' 'ping apple.com'
```

Note: `par` expects a command for each argument and does not support arbitrary bash.

Alternatively, one could use `xargs`:

```
echo '"ping google.com" "ping apple.com"' | xargs -n1 -P4 -I {} sh -c "echo '{}'; {}"
```

An advantage of `xargs` is that there's nothing to install or set up. A drawback is that output characters have the potential to interleave. We can also add a timeout:

```
echo '"ping google.com & EC=$! ; sleep 5; kill -9 $EC ; exit 1 " "ping apple.com & EC=$! ; sleep 5; kill -9 $EC ; exit 1 "' | xargs -n1 -P4 -I {} sh -c "echo '{}'; {}"
```

Another approach besides `par` or `xargs` is to just invoke each process manually and email the results. For example:

```
function fork {
    nohup sh -c "$1 | mail -s \"`hostname`,`date`,$1\" email@example.com" &
}
fork 'ping google.com & EC=$! ; sleep 5; kill -9 $EC ; exit 1'
fork 'ping apple.com & EC=$! ; sleep 5; kill -9 $EC ; exit 1'
```
