# Lab 8: File Tests and Applied Decision-Making

## Introduction

In Lab 7 you learned how to compare strings and numbers, how to read settings from configuration files, and how to react to `$?`. This lab adds the last major category of test: **file tests** — checking whether something exists on disk, and what kind of thing it is, *before* you try to use it.

You will use file tests to inspect the collected tree from Lab 4, and then write scripts that answer two practical questions against all three collected logs: does this IP address appear, and does this username appear?

**Case question for this lab:** which attacking addresses appear in which logs, and did the firewall see them?

## Objectives

By the end of this lab, you should be able to:

1. Use file test operators (`-e`, `-f`, `-d`, `-r`, `-w`, `-x`, `-s`) before acting on a path.
2. Combine file tests with `&&` and `||`.
3. Write guard clauses that reject bad input early, with distinct exit codes.
4. Search logs for an exact IP address without false matches, using `grep -F` and `grep -w`.
5. Write scripts that determine whether an IP address or username appears in a log, and respond differently depending on the result.

# Part 1: Prepare Your Lab Directory

From the repository root:

```bash
mkdir lab08
cp -r lab04-data lab08/case
mkdir lab08/intel
cp lab03-data/iocs.txt lab03-data/users.csv lab08/intel/
cd lab08
```

# Part 2: File Test Operators

You have already used `[ -f "$LOGFILE" ]` and `[ -s "$1" ]`. They are two of several file test operators:

| Operator  | Meaning                                                   |
| --------- | --------------------------------------------------------- |
| `-e path` | something exists at this path (file, directory, or other) |
| `-f path` | a **regular file** exists                                 |
| `-d path` | a **directory** exists                                    |
| `-r path` | readable by you                                           |
| `-w path` | writable by you                                           |
| `-x path` | executable by you (for a directory: you may enter it)     |
| `-s path` | exists **and** is not empty                               |

Create `inspect_path.sh`:

```bash
#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path>" >&2
    exit 1
fi

TARGET=$1

if [ ! -e "$TARGET" ]; then
    echo "$TARGET does not exist"
    exit 2
elif [ -d "$TARGET" ]; then
    echo "$TARGET is a directory"
elif [ -f "$TARGET" ]; then
    echo "$TARGET is a regular file"
    if [ -s "$TARGET" ]; then
        echo "  and it is not empty ($(wc -c < "$TARGET") bytes)"
    else
        echo "  but it is empty"
    fi
else
    echo "$TARGET exists but is neither a regular file nor a directory"
fi
```

Test it against the collection:

```bash
./inspect_path.sh case/logs/auth.log
./inspect_path.sh case/nested
./inspect_path.sh case/evidence/empty.bin
./inspect_path.sh case/logs/missing.log
./inspect_path.sh /dev/null
```

- `!` negates a test, so `[ ! -e "$TARGET" ]` means "does not exist".
- Checking `-e` first avoids running the other checks against something that is not there.
- `/dev/null` exists but is a *character device*, not a regular file — the final `else` catches it.

**Worked example — a full permissions report.**

```bash
#!/bin/bash

FILE=$1

echo "Permission report for: $FILE"
[ -e "$FILE" ] && echo "  exists       : yes" || echo "  exists       : no"
[ -f "$FILE" ] && echo "  regular file : yes" || echo "  regular file : no"
[ -d "$FILE" ] && echo "  directory    : yes" || echo "  directory    : no"
[ -r "$FILE" ] && echo "  readable     : yes" || echo "  readable     : no"
[ -w "$FILE" ] && echo "  writable     : yes" || echo "  writable     : no"
[ -x "$FILE" ] && echo "  executable   : yes" || echo "  executable   : no"
[ -s "$FILE" ] && echo "  non-empty    : yes" || echo "  non-empty    : no"
```

Save as `permissions_report.sh` and run it against `case/scripts/check.sh`, against your own `inspect_path.sh`, and against the directory `case/evidence`.

**Worked example — a shell script that cannot run.** Combine a file test with the string comparison from Lab 7 to spot a script that has a shebang but is not executable:

```bash
#!/bin/bash

FILE=$1

if [ ! -f "$FILE" ]; then
    echo "$FILE: not a regular file" >&2
    exit 2
fi

FIRST_TWO=$(head -c 2 "$FILE")

if [ "$FIRST_TWO" = "#!" ] && [ ! -x "$FILE" ]; then
    echo "$FILE: has an interpreter line ($(head -n 1 "$FILE")) but is NOT executable"
elif [ "$FIRST_TWO" = "#!" ]; then
    echo "$FILE: executable script ($(head -n 1 "$FILE"))"
else
    echo "$FILE: no interpreter line"
fi
```

Save as `script_check.sh` and run it on each file in `case/scripts`. `head -c 2` prints the first two **bytes** of the file.

Remember the rule: you inspect collected scripts, you never run them.

**Worked example — permissions you don't expect.** Work on a scratch copy, never on the evidence itself:

```bash
cp case/logs/firewall.log scratch.log
chmod 444 scratch.log
./permissions_report.sh scratch.log
rm scratch.log
```

`chmod 444` removes write permission for everyone. Confirm the report shows `writable: no`. When you `rm` it, you may be asked to confirm, but deletion still works — because deleting a file is controlled by the permissions of the *directory* it is in, not the file itself.

## Exercise 1

1. Run `inspect_path.sh` against the five paths above. Record each output and exit code.
2. Add an `-r` check: if a regular file exists but is **not** readable, print a specific warning.
3. Run `permissions_report.sh` against `case/scripts/check.sh`, your own `inspect_path.sh` and `case/evidence`. Why does a *directory* report `executable: yes`?
4. Run `script_check.sh` on all three files in `case/scripts`. Which has an interpreter line? Which is executable? Which one would `file` fail to recognise as a script, and why?
5. Try the `scratch.log` example. Were you able to delete a read-only file? Explain in one or two sentences.

# Part 3: Combining File Tests

File tests combine with `&&` and `||` exactly like the string and numeric tests in Lab 7.

**Worked example — a combined guard clause.** Guard clauses sit at the top of a script and reject bad input before anything else runs:

```bash
#!/bin/bash

FILE=$1

if [ -z "$FILE" ]; then
    echo "Usage: $0 <file>" >&2
    exit 1
fi

if [ -f "$FILE" ] && [ -r "$FILE" ] && [ -s "$FILE" ]; then
    echo "$FILE is a readable, non-empty file — proceeding."
else
    echo "$FILE failed a required check (regular file / readable / non-empty)." >&2
    exit 2
fi
```

Save as `guard_clause.sh` and test it against `case/logs/auth.log`, `case/evidence/empty.bin` and `case/logs`.

**Worked example — `||` for "either is acceptable".**

```bash
#!/bin/bash

TARGET=$1

if [ -f "$TARGET" ] || [ -d "$TARGET" ]; then
    echo "$TARGET is a file or a directory."
else
    echo "$TARGET is neither (or does not exist)."
fi
```

Save as `either_test.sh`.

## Exercise 2

1. Test `guard_clause.sh` against all three paths above. For `empty.bin`, which of the three combined tests fails?
2. Why check `-f` before `-r` when combining them with `&&`?
3. Run `either_test.sh` against `case`, `case/logs/auth.log` and `/dev/null`. Explain the result for `/dev/null`.
4. Rewrite `guard_clause.sh` so that each of the three failures prints its **own** message and exit code (`2` not a regular file, `3` unreadable, `4` empty).

# Part 4: Does an IP Appear in a Log?

Before writing the script, look at a problem with using `grep` to find IP addresses.

**Worked example — two ways a search for an IP can go wrong.**

```bash
printf '203.0.113.100\n203x0y113z10\n203.0.113.10\n' > fake.log
grep "203.0.113.10" fake.log
```

All **three** lines match, but only one is the address you asked for:

- `203.0.113.100` matches because `203.0.113.10` is a **substring** of it.
- `203x0y113z10` matches because in a regular expression `.` means **any character**.

Two `grep` options fix this:

```bash
grep -F "203.0.113.10" fake.log      # -F: fixed string, '.' is just a dot
grep -wF "203.0.113.10" fake.log     # -w: must be a whole word, not part of a longer one
rm fake.log
```

With `-wF`, only the real address matches. Because `-w` works on *word boundaries* rather than on surrounding text, the same search works in all three log formats, whether the address follows `from`, starts the line, or is followed by `->`.

Create `check_ip.sh`:

```bash
#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <logfile> <ip_address>" >&2
    exit 1
fi

LOGFILE=$1
IP=$2

if [ ! -f "$LOGFILE" ]; then
    echo "Error: '$LOGFILE' not found" >&2
    exit 2
fi

if grep -qwF "$IP" "$LOGFILE"; then
    COUNT=$(grep -cwF "$IP" "$LOGFILE")
    echo "FOUND: $IP appears $COUNT time(s) in $LOGFILE"
    exit 0
else
    echo "NOT FOUND: $IP does not appear in $LOGFILE"
    exit 3
fi
```

Make it executable and test it:

```bash
./check_ip.sh case/logs/auth.log 203.0.113.10
./check_ip.sh case/logs/firewall.log 203.0.113.10
./check_ip.sh case/logs/access.log 203.0.113.200
./check_ip.sh case/logs/missing.log 203.0.113.10
```

The script uses **three** distinct exit codes: `1` for bad usage, `2` for a missing file, `3` for "ran fine, but not found". This lets a caller distinguish "something went wrong" from "the search legitimately came back empty".

**Worked example — using `check_ip.sh`'s exit code from another script.**

```bash
#!/bin/bash

./check_ip.sh case/logs/firewall.log "$1" > /dev/null
RESULT=$?

if [ "$RESULT" -eq 0 ]; then
    echo "Decision: $1 is known to the firewall — check what action was taken."
elif [ "$RESULT" -eq 3 ]; then
    echo "Decision: the firewall never saw $1."
else
    echo "Decision: could not complete the check (exit code $RESULT)."
fi
```

Save as `ip_decision.sh` and try it with `198.51.100.24` and `198.51.100.77`.

## Exercise 3

1. Run `check_ip.sh` for each of the **three IP addresses** in `intel/iocs.txt` against each of the **three logs** in `case/logs` (nine runs). Record the results in a table in `investigation.txt`:

```text
IP               auth.log   access.log   firewall.log
203.0.113.10
198.51.100.24
203.0.113.200
```

2. Confirm the exit code differs between a found IP, a not-found IP and a missing log file.
3. Why does it make sense for "not found" to be a *different* exit code from "an error occurred"?
4. Run `grep -c "203.0.113.1" case/logs/auth.log` and `./check_ip.sh case/logs/auth.log 203.0.113.1`. Explain the difference.
5. Extend `ip_decision.sh` so that when the firewall knows the IP, it also prints the firewall line itself (the action and the destination).
6. Nine separate commands for Exercise 3.1 is tedious and error-prone. Keep your table — in a future Lab you will produce it with a single loop.

# Part 5: Does a Username Appear in a Log?

Create `check_username.sh`, which produces one of **three** messages:

```bash
#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <logfile> <username>" >&2
    exit 1
fi

LOGFILE=$1
USERNAME=$2

if [ ! -f "$LOGFILE" ]; then
    echo "Error: '$LOGFILE' not found" >&2
    exit 2
fi

if ! grep -q "for $USERNAME " "$LOGFILE"; then
    echo "$USERNAME: no activity found"
    exit 3
fi

FAILS=$(grep -c "Failed password for $USERNAME " "$LOGFILE")
ACCEPTS=$(grep -c "Accepted password for $USERNAME " "$LOGFILE")

if [ "$FAILS" -gt 0 ]; then
    echo "$USERNAME: $FAILS failed and $ACCEPTS accepted login(s) — investigate"
else
    echo "$USERNAME: $ACCEPTS successful login(s) only"
fi

exit 0
```

Test it with `root`, `admin`, `alice`, `charlie` and `frank`.

**Worked example — which hosts did a user log in from?** A successful login is only suspicious in context. Extract the source addresses for one user:

```bash
#!/bin/bash

USERNAME=$1
LOG="case/logs/auth.log"

SOURCES=$(grep "Accepted password for $USERNAME " "$LOG" |
    awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | sort -u)

if [ -z "$SOURCES" ]; then
    echo "$USERNAME: no successful logins"
else
    COUNT=$(echo "$SOURCES" | wc -l)
    echo "$USERNAME logged in from $COUNT different address(es):"
    echo "$SOURCES"
fi
```

Save as `login_sources.sh` and try it for `alice`, `bob`, `eve` and `charlie`.

## Exercise 4

1. Run `check_username.sh` for five usernames and record the three different message types.
2. `! grep -q ...` negates the test. Explain what the first `if` block checks, and why it `exit`s early.
3. Why is the pattern `"for $USERNAME "` (with a trailing space) safer than `"$USERNAME"`? Give an example username where the difference matters.
4. Extend `check_username.sh` so that more than 5 failed attempts also prints `HIGH RISK`.
5. Run `login_sources.sh` for every account that logged in successfully. Which account logged in from the most addresses? Cross-reference with `case/evidence/passwords.txt` — is it one of the accounts whose password was stored in plain text?

# Part 6: Common Mistakes and Debugging

| Symptom                                                         | Likely cause                                                       | Fix                                                                   |
| --------------------------------------------------------------- | ------------------------------------------------------------------ | --------------------------------------------------------------------- |
| `-f`/`-d` test always fails, although the path "looks right"    | You are not in the directory you think you are, or there is a typo | Run `pwd` and `ls -l`; test with an absolute path                     |
| A search reports "FOUND" for an address that isn't really there | Substring match, or `.` matching any character                     | Use `grep -wF`                                                        |
| A guard clause exits but no message appears                     | The `echo` was placed after the `exit`                             | `exit` stops the script immediately — always `echo` first             |
| `[ -f $FILE ]` behaves oddly when no argument is given          | An empty, unquoted variable leaves `[ -f ]`, which is always true  | Always quote: `[ -f "$FILE" ]`, and check for an empty argument first |
| A directory reports as "executable"                             | For directories, `x` means "may enter"                             | Check `-d` before interpreting `-x`                                   |

**Worked example — the unquoted empty-variable trap.**

```bash
FILE=""
[ -f $FILE ] && echo "unquoted: looks like a file"
[ -f "$FILE" ] && echo "quoted: looks like a file"
```

Only the unquoted version prints. With the quotes removed and `FILE` empty, the test becomes `[ -f ]`, which Bash reads as "is the string `-f` non-empty?" — and it is. The quoted version correctly asks whether a regular file named `""` exists (the answer is always no).

## Exercise 5

1. Reproduce the empty-variable trap above.
2. Reproduce at least one more row from the table using a broken copy of one of your scripts.
3. Would `grep -w` alone (without `-F`) be enough to fix the `203x0y113z10` problem? Test it and explain.

# Part 7: Investigation Challenge

Write a script called `investigate.sh` that:

1. Takes exactly two arguments: a log file and a search term (an IP address or a username).
2. Validates that the log file exists, is a regular file and is readable, with a distinct exit code for each failure.
3. Validates that the search term is not empty, with its own exit code.
4. Decides whether the term looks like an IP address:

```bash
if echo "$TERM_ARG" | grep -Eq '^[0-9]+(\.[0-9]+){3}$'; then
```

5. **If it is an IP address:**
   
   - counts its occurrences in the given log with `grep -cwF`;
   
   - counts its `Failed password` events and classifies them with the Lab 7 risk thresholds;
   
   - checks `case/logs/firewall.log` and prints any firewall lines for that address;
   
   - reports whether the address is listed in `intel/iocs.txt` (`grep -qxF`).
6. **Otherwise (a username):**
   
   - counts its failed and accepted logins;
   
   - reports whether it is a CURRENT, LEGACY or UNKNOWN account (Lab 7, Part 5).
7. Exits `0` if the term was found in the log, and a distinct non-zero code if it was not.

Do **not** call your variable `TERM` — that name is already used by the shell to describe your terminal. Use something like `TERM_ARG`.

Run it for at least these cases, recording every command, its output and its exit code in `investigation.txt`:

```text
case/logs/auth.log     198.51.100.77
case/logs/auth.log     203.0.113.200
case/logs/access.log   203.0.113.77
case/logs/auth.log     admin
case/logs/auth.log     alice
case/logs/missing.log  admin
```

Then answer:

1. `198.51.100.77` made 8 failed login attempts. Is it in the IOC list? Is it in the firewall log? What does that tell you about relying on the IOC list alone?
2. `203.0.113.200` is in the IOC list. Which service did the firewall block it from, and which service does `auth.log` show it attacking? (Look up which service normally uses port 3389.)
3. `203.0.113.77` appears in the web log but not the auth log. Look at its requests (`grep -wF 203.0.113.77 case/logs/access.log`). What was it doing?

# Part 8: Concepts and Commands Covered

You should now be comfortable with:

```text
-e -f -d          exists, regular file, directory
-r -w -x          readable, writable, executable
-s                exists and is not empty
!                 negating a test
[ A ] && [ B ]    both tests must succeed
[ A ] || [ B ]    at least one test must succeed
head -c N         the first N bytes of a file
grep -F           fixed-string search (no regex)
grep -w           whole-word match
grep -x           whole-line match
grep -E           extended regular expressions
```

# Part 9: Commit Your Work

Do **not** modify anything in `case/` or `intel/`.

Commit your scripts (`inspect_path.sh`, `permissions_report.sh`, `script_check.sh`, `guard_clause.sh`, `either_test.sh`, `check_ip.sh`, `ip_decision.sh`, `check_username.sh`, `login_sources.sh`, `investigate.sh`) and `investigation.txt`.

Suggested commit:

```text
Complete Lab 8
```

Push your changes to GitHub.

# End of Lab 8
