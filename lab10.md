# Lab 10: while Loops and Safer Iteration

## Introduction

In Lab 9, Exercise 2.2, you predicted a problem: `for INDICATOR in $(cat intel/iocs.txt)` splits on whitespace, not on lines, so it would break if an entry ever contained a space. You also found that simple globs such as `case/logs/*.log` miss files in deeper folders.

This lab introduces `while` loops, which fix both problems and add a second style of repetition: repeating an action **until a condition changes**, rather than once per item in a list. You will read the IOC list and the account list safely, split CSV and firewall records into fields, and process the output of `find` in a way that works for any filename.

**Case question for this lab:** across *every* log in the collection, including the archived one, how many indicator matches are there — and can a script decide on its own whether the collection needs further investigation?

## Objectives

By the end of this lab, you should be able to:

1. Explain why `for VAR in $(cat file)` is unsafe for general line-by-line reading.
2. Read a file line by line safely using `while IFS= read -r`.
3. Split each line into fields with `IFS=',' read -r` or by whitespace.
4. Detect and remove Windows carriage returns while reading data.
5. Write a `while` loop that repeats based on a condition, with `break` and `continue`.
6. Process the output of `find ... -print0` safely, and avoid the "lost variable in a pipeline" trap.

# Part 1: Prepare Your Lab Directory

From the repository root:

```bash
mkdir lab10
cp -r lab04-data lab10/case
mkdir lab10/intel
cp lab03-data/iocs.txt lab03-data/users.csv lab10/intel/
cd lab10
```

# Part 2: The Problem with `for $(cat file)`

`for VAR in $(cat file)` has two real problems:

1. It **splits on any whitespace**, so an entry like `bad host.example` becomes two separate, wrong items.
2. It reads the **whole file** into one word list before the loop starts, which does not scale to large files.

**Worked example — seeing the split happen.**

```bash
printf 'one two three\nsingle-word-entry\n' > words_test.txt

for WORD in $(cat words_test.txt); do
    echo "Item: [$WORD]"
done
```

You see **four** items, not two lines.

## Exercise 1

1. Create `test_indicators.txt` containing the line `suspicious domain.example`.
2. Write a `for $(cat ...)` loop that prints each "indicator" in it, and confirm it wrongly produces two.
3. Delete `test_indicators.txt` once you have confirmed the problem.

# Part 3: Reading a File Line by Line, Safely

The correct way to process a file **one line at a time** is:

```bash
while IFS= read -r LINE; do
    echo "Line: [$LINE]"
done < intel/iocs.txt
```

- `IFS=` stops `read` trimming leading and trailing spaces from the line.
- `-r` stops `read` treating backslashes as escape characters.
- `< intel/iocs.txt` after `done` feeds the file into the loop's standard input.

Repeat Part 2's test with the safe pattern:

```bash
while IFS= read -r LINE; do
    echo "Line: [$LINE]"
done < words_test.txt
rm words_test.txt
```

This time there are exactly **two** lines, each intact.

Rebuild Lab 9's IOC sweep the safe way. Create `check_iocs.sh`:

```bash
#!/bin/bash

IOC_FILE="intel/iocs.txt"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <logfile>" >&2
    exit 1
fi

LOGFILE=$1

if [ ! -f "$LOGFILE" ]; then
    echo "Error: '$LOGFILE' not found" >&2
    exit 2
fi

MATCHES=0

while IFS= read -r INDICATOR; do
    [ -z "$INDICATOR" ] && continue
    if grep -qwF "$INDICATOR" "$LOGFILE"; then
        echo "MATCH: $INDICATOR"
        MATCHES=$((MATCHES + 1))
    fi
done < "$IOC_FILE"

echo "Total IOC matches in $LOGFILE: $MATCHES"
```

`continue` skips the rest of the current iteration — here, it ignores blank lines in the IOC file. Run it against each of the three logs.

**Worked example — splitting CSV fields as you read.** `read` can split a line into several variables. Setting `IFS=','` **for the `read` command only** makes it split on commas:

```bash
#!/bin/bash

while IFS=',' read -r USERNAME ROLE STATUS DEPT; do
    echo "User: $USERNAME | role: $ROLE | status: $STATUS | dept: [$DEPT]"
done < intel/users.csv
```

Save as `read_csv.sh` and run it. Two things are wrong with the output:

1. The header line (`username,role,status,department`) is printed as if it were a user.
2. Look at the brackets around the department. The closing `]` appears at the **start** of the line, overwriting the text. That is the Windows carriage return (`\r`) at work: the terminal returns to the start of the line before printing `]`.

Fix both:

```bash
#!/bin/bash

FIRST_LINE=1

while IFS=',' read -r USERNAME ROLE STATUS DEPT; do
    if [ "$FIRST_LINE" -eq 1 ]; then
        FIRST_LINE=0
        continue
    fi
    DEPT=${DEPT%$'\r'}
    echo "User: $USERNAME | role: $ROLE | status: $STATUS | dept: [$DEPT]"
done < intel/users.csv
```

- The `FIRST_LINE` flag skips the header with `continue`.
- `${DEPT%$'\r'}` is parameter expansion: it removes a trailing carriage return, if there is one. It does nothing to a value without one, so it is safe to use on any file.

**Worked example — splitting on whitespace.** With the default `IFS`, `read` splits on spaces. The firewall log has four space-separated fields per line:

```text
BLOCK 203.0.113.10 -> 10.0.0.10:22
```

```bash
#!/bin/bash

while read -r ACTION SRC ARROW DST; do
    PORT=${DST##*:}
    echo "$ACTION from $SRC to port $PORT"
done < case/logs/firewall.log
```

Save as `read_firewall.sh` and run it. `${DST##*:}` removes everything up to the last `:`, leaving just the port — the same trick you used for file extensions in Lab 7.

## Exercise 2

1. Run `check_iocs.sh` against all three logs in `case/logs`.
2. Add a second counter for indicators **not** found, and print both totals.
3. Modify the fixed `read_csv.sh` to print only accounts whose `STATUS` is `disabled`.
4. Modify it to print only accounts whose `DEPT` is `Security`. Temporarily remove the `${DEPT%$'\r'}` line. Does it still find `eve`? Why not?
5. Modify `read_firewall.sh` so that it prints only `BLOCK` lines, and ends with a count of blocked connections per destination port. (Hint: a counter variable per port you care about is enough for now, e.g., port number 22, 80, and 443.)
6. Why doesn't `read_firewall.sh` need `IFS=`? What would happen if you **did** write `IFS= read -r ACTION SRC ARROW DST`?

# Part 4: `while` Loops Driven by a Condition

A `while` loop can repeat based on any condition, not just "there is another line".

```bash
#!/bin/bash

COUNT=1

while [ "$COUNT" -le 5 ]; do
    echo "still scanning... (pass $COUNT)"
    COUNT=$((COUNT + 1))
done

echo "scan complete"
```

**Worked example — `break` to stop early.** `break` exits a loop immediately. Stop at the first IOC that matches:

```bash
#!/bin/bash

LOG="case/logs/firewall.log"

while IFS= read -r INDICATOR; do
    if grep -qwF "$INDICATOR" "$LOG"; then
        echo "First match in $LOG: $INDICATOR — stopping search."
        break
    fi
done < intel/iocs.txt

echo "Search finished."
```

Save as `find_first.sh` and run it. When you only need to know "is there at least one match?", stopping early saves work — which matters on large logs.

**Worked example — a retry loop with a limit.** Keep asking until the input is valid, but not forever:

```bash
#!/bin/bash

TARGET=""
ATTEMPTS=0
MAX_ATTEMPTS=3

while [ ! -f "$TARGET" ] && [ "$ATTEMPTS" -lt "$MAX_ATTEMPTS" ]; do
    read -p "Enter a file inside case/ to identify: " TARGET
    TARGET="case/$TARGET"
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ ! -f "$TARGET" ]; then
        echo "  '$TARGET' is not a regular file ($ATTEMPTS/$MAX_ATTEMPTS attempts used)"
    fi
done

if [ -f "$TARGET" ]; then
    echo "$TARGET: $(file -b "$TARGET")"
else
    echo "Too many failed attempts." >&2
    exit 1
fi
```

Save as `retry_limit.sh` and test it with `evidence/suspicious.dat`, and by entering three wrong names in a row. The condition is checked **before** the first `read` too: `TARGET` starts empty, which fails `-f`, so the loop always runs at least once.

## Exercise 3

1. Change `-le` to `-lt` in the counting loop. How many times does it run now?
2. Change `LOG` in `find_first.sh` to each of the three logs in turn, then to `case/nested/archive/old.log`. For which log is there no match at all? What is printed in that case, and how could you improve the message? (Hint: use a variable that is set only when a match is found.)
3. In `retry_limit.sh`, entering `logs` (a directory) is rejected. Which test rejects it?

# Part 5: Processing `find` Output Safely

In Lab 4 you met `find ... -print0 | xargs -0` as the safe way to pass filenames to another command. The same idea works with `while`: `-print0` separates names with a null byte, and `read -d ''` reads up to each null byte.

```bash
find case -type f -name "*.log" -print0 |
while IFS= read -r -d '' LOGFILE; do
    echo "$LOGFILE: $(wc -l < "$LOGFILE") lines"
done
```

Unlike Lab 9's globs, this finds **every** log in the collection, including `case/nested/archive/old.log`, and works even if a filename contains spaces or newlines.

**Worked example — the lost-variable trap.** Try to count the logs with a pipeline:

```bash
#!/bin/bash

COUNT=0
find case -type f -name "*.log" -print0 |
while IFS= read -r -d '' LOGFILE; do
    COUNT=$((COUNT + 1))
    echo "inside the loop: COUNT=$COUNT"
done
echo "after the loop:  COUNT=$COUNT"
```

Save as `lost_count.sh` and run it. Inside the loop `COUNT` goes up to `4`, but afterwards it is back to `0`. Every part of a pipeline runs in its own **subshell** — a separate copy of the shell — so the loop's changes to `COUNT` disappear when that copy finishes.

The fix is **process substitution**, `< <(command)`, which feeds the command's output into the loop without putting the loop in a pipeline:

```bash
#!/bin/bash

COUNT=0
while IFS= read -r -d '' LOGFILE; do
    COUNT=$((COUNT + 1))
done < <(find case -type f -name "*.log" -print0)
echo "after the loop: COUNT=$COUNT"
```

Save as `kept_count.sh` and run it. Read `< <(...)` as "take input from the output of this command". Use this form whenever a loop needs to keep a total.

**Worked example — a list built by a search.** `grep -rlZ` lists the files that contain a match, separated by null bytes, ready for the same loop:

```bash
#!/bin/bash

while IFS= read -r -d '' FILE; do
    echo "$FILE mentions admin ($(grep -c admin "$FILE") line(s))"
done < <(grep -rlZ "admin" case)
```

Save as `admin_files.sh` and run it. One command produces a list, the loop consumes it — the two pieces only need to agree on the separator.

## Exercise 4

1. Run the first `find` loop in this part. How many logs does it find? Which one did Lab 9's `case/logs/*.log` miss?
2. Run `lost_count.sh` and `kept_count.sh` and explain the difference in your own words.
3. Modify `kept_count.sh` to also total the number of lines across every log it finds.
4. Run `admin_files.sh`. Which files mention `admin`?
5. Change `admin_files.sh` so it searches for `password` instead. Which evidence file do you find, apart from the logs?

# Part 6: Common Mistakes and Debugging

| Symptom                                          | Likely cause                                                    | Fix                                                |
| ------------------------------------------------ | --------------------------------------------------------------- | -------------------------------------------------- |
| Lines lose leading spaces or backslashes         | `IFS=` or `-r` missing from `read`                              | Use `while IFS= read -r LINE`                      |
| The last line of a file is skipped               | The file does not end with a newline, so the final `read` fails | `while IFS= read -r LINE \|\| [ -n "$LINE" ]; do`  |
| A comparison on the last CSV field never matches | Windows carriage return at the end of the line                  | `VAR=${VAR%$'\r'}`                                 |
| A counter is `0` after a `cmd \| while ...` loop | The loop ran in a subshell                                      | Use `while ...; done < <(cmd)`                     |
| `read -d ''` loop processes nothing              | `find` was not given `-print0` (or `grep` not given `-Z`)       | Match the separators on both sides                 |
| Loop never ends                                  | The condition never becomes false (e.g. forgot to increment)    | Press Ctrl+C; check the variable changes each pass |

**Worked example — the missing final newline.**

```bash
printf 'first\nsecond\nthird' > no_newline.txt
while IFS= read -r LINE; do echo "[$LINE]"; done < no_newline.txt
while IFS= read -r LINE || [ -n "$LINE" ]; do echo "[$LINE]"; done < no_newline.txt
rm no_newline.txt
```

The first loop silently drops `third`. Files exported from Windows tools and spreadsheets often end without a newline, so the second form is a good habit for any file you did not create yourself.

## Exercise 5

1. Reproduce the missing-final-newline example.
2. Reproduce the lost-counter trap with a different command, e.g. `grep "Accepted" case/logs/auth.log | while read ...`.
3. Reproduce one more row from the table using a broken copy of one of your scripts.

# Part 7: Investigation Challenge

Write a script called `scan_all.sh` (no arguments) that:

1. Uses `find case -type f -name "*.log" -print0` and a `while IFS= read -r -d ''` loop (with process substitution) to visit **every** log in the collection.
2. For **each** log, uses an inner `while IFS= read -r` loop over `intel/iocs.txt` to check every indicator with `grep -qwF`.
3. Uses `break` to stop checking a log as soon as **3** indicators have matched it, and prints a note that the check stopped early.
4. Prints a per-file summary: filename, total lines, failed-login count (`0` if none), and IOC match count.
5. Keeps a running total of IOC matches across all logs, and prints it at the end.
6. Exits with code `0` if no indicator matched anywhere, or code `1` if at least one did — so the exit code alone says whether the collection needs investigating.

Run it and save the output:

```bash
./scan_all.sh > scan_report.txt
echo "Exit code: $?"
```

In `investigation.txt`, record:

1. The final exit code, and whether it matches the report.
2. How many logs were scanned, and their per-file IOC counts.
3. For which logs did the early `break` trigger? Did it cause you to miss a match? How do you know? (Compare with `check_iocs.sh`.)
4. One sentence explaining why a meaningful exit code matters if `scan_all.sh` were run automatically every night, with no one watching the output.
5. 

# Part 8: Concepts and Commands Covered

You should now be comfortable with:

```text
while IFS= read -r VAR; do ... done < file   safe line-by-line reading
while IFS=',' read -r A B C; do ...          splitting fields on commas
while read -r A B C D; do ...                splitting fields on whitespace
${VAR%$'\r'}                                 removing a trailing carriage return
${VAR##*:}                                   keeping text after the last ':'
while [ condition ]; do ... done             condition-based looping
break / continue                             leave the loop / skip to the next pass
find ... -print0 + read -r -d ''             safe processing of any filename
grep -rlZ                                    null-separated list of matching files
done < <(command)                            process substitution (no subshell)
|| [ -n "$LINE" ]                            keep a final line with no newline
```

# Part 9: Commit Your Work

Do **not** modify anything in `case/` or `intel/`.

Commit your scripts (`check_iocs.sh`, `read_csv.sh`, `read_firewall.sh`, `find_first.sh`, `retry_limit.sh`, `lost_count.sh`, `kept_count.sh`, `admin_files.sh`, `scan_all.sh`) along with `scan_report.txt` and `investigation.txt`.

Suggested commit:

```text
Complete Lab 10
```

Push your changes to GitHub.

# End of Lab 10
