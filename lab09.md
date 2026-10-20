# Lab 9: for Loops and Repetitive Security Tasks

## Introduction

Every script so far has processed **one** file, or checked **one** IP or username, per run. In Lab 8, Exercise 3.1, you had to run `check_ip.sh` nine times by hand to fill in a three-by-three table.

This is where scripting starts to pay off. In this lab you will use `for` loops to process every log in the collection, sweep every indicator against every log, hash every evidence file, and compare every file's extension with its real content.

**Case question for this lab:** which indicators appear in more than one log, and which evidence files are not what their names claim?

## Objectives

By the end of this lab, you should be able to:

1. Write a `for` loop over a literal list, a glob pattern and a numeric range.
2. Keep running totals and build up results inside a loop.
3. Use nested loops to sweep a list of indicators against several log files.
4. Calculate, save and verify file hashes for integrity checking.
5. Use pattern tests inside a loop to compare a file's extension with its detected type.
6. Recognise and avoid the most common `for`-loop mistakes.

# Part 1: Prepare Your Lab Directory

From the repository root:

```bash
mkdir lab09
cp -r lab04-data lab09/case
mkdir lab09/intel
cp lab03-data/iocs.txt lab03-data/users.csv lab09/intel/
cd lab09
```

# Part 2: Basic `for` Loops

A `for` loop repeats a block of commands once per item in a list.

**Looping over a literal list:**

```bash
#!/bin/bash

for FILE in case/logs/auth.log case/logs/access.log case/logs/firewall.log case/logs/missing.log; do
    echo "Checking $FILE..."
    if [ -f "$FILE" ]; then
        echo "  exists, $(wc -l < "$FILE") lines"
    else
        echo "  MISSING"
    fi
done
```

Save as `check_all_files.sh` and run it.

**Looping over a glob pattern:**

```bash
for LOGFILE in case/logs/*.log; do
    echo "$LOGFILE: $(wc -l < "$LOGFILE") lines"
done
```

**Looping over a numeric range:**

```bash
for i in {1..5}; do
    echo "Attempt $i"
done
```

**Worked example — a running total.** Initialise a variable **before** the loop, and add to it **inside** the loop:

```bash
#!/bin/bash

TOTAL=0

for LOGFILE in case/logs/*.log; do
    COUNT=$(grep -c "Failed password" "$LOGFILE")
    echo "$LOGFILE: $COUNT failed logins"
    TOTAL=$((TOTAL + COUNT))
done

echo "TOTAL: $TOTAL"
```

Save as `failed_totals.sh` and run it.

**Worked example — building a report as you go.**

```bash
#!/bin/bash

REPORT=""

for CONF in case/configs/*.conf; do
    PORT=$(grep '^port=' "$CONF" | cut -d'=' -f2)
    if [ -z "$PORT" ]; then
        PORT="(none)"
    fi
    REPORT="${REPORT}${CONF}: port ${PORT}"$'\n'
done

echo "Configured ports:"
echo "$REPORT"
```

Save as `port_report.sh` and run it. `$'\n'` inserts a real newline character. This pattern — accumulate inside the loop, act on the result afterwards — comes up constantly.

**Worked example — numbering items.**

```bash
#!/bin/bash

INDEX=1
for FILE in case/configs/*.conf case/logs/*.log; do
    echo "File #$INDEX: $FILE"
    INDEX=$((INDEX + 1))
done
```

Save as `numbered_list.sh` and run it.

## Exercise 1

1. Write a loop that prints the number of `Accepted password` lines in every `case/logs/*.log` file.
2. Run `failed_totals.sh`. Does the total equal the count for `auth.log` alone? Why?
3. What is the difference between looping over a literal list and looping over `case/logs/*.log`? What happens to each if a fourth log is added to `case/logs` later?
4. Extend `port_report.sh` so that it also reports `debug` for each file, and includes `case/backups/config.old`.
5. Does `case/logs/*.log` include `case/nested/archive/old.log`? Why not? Write a loop over `case/*/*.log case/*/*/*.log` and compare. 

# Part 3: Sweeping a List of Indicators

In Lab 8 you checked one IP against one log. A `for` loop can check every indicator in `intel/iocs.txt` automatically.

```bash
#!/bin/bash

for INDICATOR in $(cat intel/iocs.txt); do
    if grep -qwF "$INDICATOR" case/logs/auth.log; then
        echo "MATCH   : $INDICATOR found in auth.log"
    else
        echo "no match: $INDICATOR"
    fi
done
```

Save as `sweep_auth.sh` and run it.

**Caution:** `for INDICATOR in $(cat intel/iocs.txt)` splits the file on **whitespace**, not on lines. It works here because every entry is a single word — IPs, domains and hashes never contain spaces. It is not a safe general habit, and you will learn the safe way to read a file line by line in a future Lab.

**Worked example — every indicator against every log (nested loops).**

```bash
#!/bin/bash

for LOGFILE in case/logs/*.log; do
    echo "=== $LOGFILE ==="
    for INDICATOR in $(cat intel/iocs.txt); do
        if grep -qwF "$INDICATOR" "$LOGFILE"; then
            echo "  MATCH: $INDICATOR ($(grep -cwF "$INDICATOR" "$LOGFILE") lines)"
        fi
    done
done
```

Save as `sweep_all.sh` and run it. The **outer** loop visits each log; the **inner** loop tries every indicator. With 3 logs and 7 indicators, the inner `if` runs 21 times. This single script produces the whole table you filled in by hand in Lab 8.

**Worked example — which indicators appear in more than one source?** Swap the loops so that each **indicator** gets its own count of how many logs contain it:

```bash
#!/bin/bash

for INDICATOR in $(cat intel/iocs.txt); do
    SOURCES=0
    WHERE=""
    for LOGFILE in case/logs/*.log; do
        if grep -qwF "$INDICATOR" "$LOGFILE"; then
            SOURCES=$((SOURCES + 1))
            WHERE="$WHERE $(basename "$LOGFILE")"
        fi
    done
    echo "$INDICATOR: seen in $SOURCES log(s):$WHERE"
done
```

Save as `correlate.sh` and run it. An indicator seen in the SSH log, the web log **and** the firewall log is much stronger evidence of a determined attacker than one seen once. `basename` keeps the output short.

**Worked example — reversing the question.** The IOC list is only as good as whoever wrote it. Loop over the addresses that *actually attacked* SSH, and check whether each one is on the list:

```bash
#!/bin/bash

ATTACKERS=$(grep "Failed password" case/logs/auth.log |
    awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | sort -u)

for IP in $ATTACKERS; do
    COUNT=$(grep -c "Failed password.* from $IP " case/logs/auth.log)
    if grep -qxF "$IP" intel/iocs.txt; then
        echo "$IP ($COUNT failures): already in IOC list"
    else
        echo "$IP ($COUNT failures): NOT in IOC list — candidate for new indicator"
    fi
done
```

Save as `ioc_gaps.sh` and run it. `grep -qxF` asks "is there a line in `iocs.txt` that is exactly this address?".

## Exercise 2

1. Run `sweep_auth.sh` and record every IOC that matched `auth.log`.
2. Suppose a line in `iocs.txt` were `malicious host` (with a space). Predict what would go wrong with `for INDICATOR in $(cat intel/iocs.txt)`, and explain why.
3. Run `sweep_all.sh` and compare its output with your table from Lab 8, Exercise 3.1. Do they agree?
4. Run `correlate.sh`. Which indicators were seen in all three logs? Which indicators were seen nowhere, and what kind of indicator are they?
5. Run `ioc_gaps.sh`. Which attacking addresses are missing from the IOC list? Would you add them? What extra evidence would you want first?
6. Write `web_gaps.sh`, a version of `ioc_gaps.sh` for `case/logs/access.log` that loops over every distinct client address (`awk '{print $1}'`). Which web clients are not in the IOC list, and which of them are external?

# Part 4: Hashing Files for Integrity

A common integrity task is calculating a hash of every file, so you can later detect whether any of them changed.

```bash
#!/bin/bash

for FILE in case/evidence/*; do
    if [ -f "$FILE" ]; then
        sha256sum "$FILE"
    fi
done
```

Save this as `hash_evidence.sh`, make it executable, and save a baseline:

```bash
./hash_evidence.sh > baseline_hashes.txt
cat baseline_hashes.txt
```

Now prove that tampering is detected. **Never** tamper with the evidence itself — work on a copy:

```bash
cp -r case/evidence work_evidence
for FILE in work_evidence/*; do sha256sum "$FILE"; done > work_baseline.txt

echo "tampered" >> work_evidence/notes.txt

for FILE in work_evidence/*; do sha256sum "$FILE"; done > work_current.txt
diff work_baseline.txt work_current.txt
```

- `sha256sum` prints a hash and the filename.
- `diff` on two hash listings shows exactly which file changed.
- Notice the redirect `> work_baseline.txt` is placed **after** `done`: it captures the output of the *whole loop*, not just the last iteration.

**Worked example — verifying against a baseline automatically.**

```bash
sha256sum -c work_baseline.txt
```

`sha256sum -c` reports `OK` for every file that still matches and `FAILED` for any that don't. File-integrity-monitoring tools work the same way.

**Worked example — checking hashes against an indicator list.** `intel/iocs.txt` contains one hash indicator:

```bash
grep -E '^[0-9a-f]{32}$' intel/iocs.txt
```

A 32-character hexadecimal value is an **MD5** hash. (This particular one is the MD5 of the harmless EICAR antivirus test file.) Check every evidence file against it:

```bash
#!/bin/bash

for FILE in case/evidence/*; do
    [ -f "$FILE" ] || continue
    HASH=$(md5sum "$FILE" | awk '{print $1}')
    if grep -qxF "$HASH" intel/iocs.txt; then
        echo "KNOWN BAD: $FILE ($HASH)"
    else
        echo "clean    : $FILE"
    fi
done
```

Save as `hash_ioc_check.sh` and run it. `[ -f "$FILE" ] || continue` skips anything that is not a regular file; `continue` jumps straight to the next item in the loop. 

## Exercise 3

1. Run the tampering example and confirm `diff` and `sha256sum -c` both identify `notes.txt`.
2. Why is `sha256sum` more suitable for integrity checking than comparing file sizes with `wc -c`? Design a change to `notes.txt` that would keep its size the same.
3. Run `sha256sum -c baseline_hashes.txt` against the real evidence. Do all files report `OK`? What does that confirm?
4. Look at the hash of `case/evidence/empty.bin` in your baseline. Run `sha256sum /dev/null`. Why are they identical? What does that tell you about hashing empty files?
5. Run `hash_ioc_check.sh`. Did any evidence file match? Why is a hash indicator only useful if the file is *exactly* the same, byte for byte?
6. Delete `work_evidence`, `work_baseline.txt` and `work_current.txt` when you have finished.

# Part 5: Extension Versus Content

In Lab 4 you found that `suspicious.dat` is not what its name suggests. A loop lets you check every file at once.

`[[ ]]` supports glob-style pattern matching:

```bash
#!/bin/bash

for FILE in case/evidence/*; do
    TYPE=$(file -b "$FILE")
    if [[ "$FILE" == *.png ]]; then
        EXPECT="PNG"
    elif [[ "$FILE" == *.zip ]]; then
        EXPECT="Zip"
    elif [[ "$FILE" == *.txt || "$FILE" == *.md ]]; then
        EXPECT="text"
    else
        EXPECT=""
    fi

    if [ -z "$EXPECT" ]; then
        echo "?? $FILE — no expectation for this extension; detected: $TYPE"
    elif [[ "$TYPE" == *"$EXPECT"* ]]; then
        echo "OK $FILE — $TYPE"
    else
        echo "!! $FILE — expected $EXPECT, detected: $TYPE"
    fi
done
```

Save as `magic_check.sh` and run it.

- `[[ "$FILE" == *.png ]]` is true if the name **ends in** `.png`. Do not quote the pattern side, or it is treated as literal text.
- `[[ "$TYPE" == *"$EXPECT"* ]]` is true if the detected type **contains** the expected word.
- `[[ A || B ]]` combines two patterns inside one test.

**Worked example — flagging executable content.** An `ELF` file is a Linux executable program. Whatever its name, an executable hidden in an evidence folder deserves attention:

```bash
#!/bin/bash

for FILE in case/*/*; do
    [ -f "$FILE" ] || continue
    TYPE=$(file -b "$FILE")
    if [[ "$TYPE" == ELF* ]]; then
        echo "EXECUTABLE CONTENT: $FILE ($TYPE)"
    fi
done
```

Save as `find_executables.sh` and run it. Notice it searches every top-level subdirectory of `case`.

## Exercise 4

1. Run `magic_check.sh`. Which files are `OK`, which are `??`, and which (if any) are `!!`?
2. Add expectations for `.bin` and `.dat` so that those files are checked too. What should an empty `.bin` file be reported as?
3. Run `find_executables.sh`. Look at the first bytes of the file it finds with `head -c 4 FILE | od -c`. What are the four "magic bytes" of an ELF file?
4. `file` reports the ELF file as having an "unknown class". What does that suggest — a working program, or a corrupted or deliberately disguised one? Should you ever try to run it to find out?
5. Adapt `magic_check.sh` so that it checks `case/scripts/*` too, expecting `shell script` for `.sh` and `Python` for `.py`. 

# Part 6: Common Mistakes and Debugging

| Symptom                                                  | Likely cause                                                                            | Fix                                                              |
| -------------------------------------------------------- | --------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Loop runs once with the literal text `case/logs/*.xyz`   | No files match the pattern                                                              | Check with `ls` first; guard with `[ -f "$FILE" ] \|\| continue` |
| Loop treats a directory as a file                        | Missing `[ -f "$FILE" ]` guard in a `for FILE in dir/*` loop                            | Add the file-type check                                          |
| A glob misses files in deeper folders                    | `*` does not descend into subdirectories                                                | Add another level (`*/*/*`) or use `find`                        |
| Running total stays at `0`, or resets                    | `TOTAL` was never initialised, or is reset **inside** the loop                          | Set `TOTAL=0` once, before the loop                              |
| `syntax error in expression` when adding a count         | The count variable contains **two** lines, e.g. `0` twice                               | See the worked example below                                     |
| `sha256sum -c` reports every file as `FAILED` or missing | You ran the check from a different directory, so the saved relative paths don't line up | Run the check from the directory where the baseline was created  |

**Worked example — the double-zero bug.** You may see this pattern in scripts online:

```bash
COUNT=$(grep -c "Failed password" case/logs/access.log || echo 0)
echo "[$COUNT]"
```

Run it. `COUNT` contains **two** lines: `0` and `0`. When there are no matches, `grep -c` prints `0` *and* exits with code `1`, so `|| echo 0` runs too and prints a second `0`. Using that value in `$((TOTAL + COUNT))` fails. The fix is to rely on `grep -c`'s own output and simply ignore its exit code:

```bash
COUNT=$(grep -c "Failed password" case/logs/access.log || true)
```

`true` prints nothing and always succeeds. 

**Worked example — the "no matches" glob trap.**

```bash
for FILE in case/logs/*.xyz; do
    echo "Found: $FILE"
done
```

No `.xyz` files exist, yet you see `Found: case/logs/*.xyz`. When a glob matches nothing, Bash leaves it unexpanded, so the loop runs once with the pattern itself. Always guard with `[ -f "$FILE" ]`.

## Exercise 5

1. Reproduce the double-zero bug and its fix.
2. Reproduce the "no matches" trap, then add a guard so that nothing is printed.
3. Reproduce one more row from the table using a broken copy of one of your scripts.

# Part 7: Investigation Challenge

Write a script called `file_survey.sh` (no arguments) that, for **every file** in `case/evidence`, `case/scripts` and `case/logs`:

1. Skips anything that is not a regular file.
2. Prints the file name, its size in bytes, and its detected type (`file -b`).
3. Prints its line count if the detected type contains `text`.
4. Prints its SHA-256 hash.
5. Flags it with `!!` if its extension and detected type disagree (reuse `magic_check.sh`'s logic, including your `.sh`/`.py` expectations).
6. If it is a `.log` file, prints how many of the indicators in `intel/iocs.txt` appear in it.
7. Keeps running counts of files surveyed, files flagged, and total IOC matches, and prints all three at the end.

Run it and save the output:

```bash
./file_survey.sh > file_survey_report.txt
```

Then answer in `investigation.txt`:

1. Which log contains the most **distinct** indicators? Which contains the most indicator **lines**? Why can those two answers differ?
2. Which files were flagged, and why?
3. Which log file in the collection did your survey **not** include, and why did the globs miss it?
4. If a new file `case/logs/vpn.log` were added tomorrow, would `file_survey.sh` need to change? Why or why not?
5. Summarise, in three or four sentences, what the collection now tells you about the attack: which addresses were involved, which services they targeted, and what was found on the workstation.

# Part 8: Concepts and Commands Covered

You should now be comfortable with:

```text
for VAR in a b c; do ... done     looping over a literal list
for VAR in dir/*.ext; do ... done looping over a glob
for i in {1..N}; do ... done      looping over a numeric range
TOTAL=$((TOTAL + N))              a running total
nested for loops                  a loop inside another loop
continue                          skip to the next item
sha256sum / md5sum                calculating a hash
sha256sum -c file                 verifying files against a saved hash list
[[ "$VAR" == pattern ]]           glob-style pattern matching
[[ "$VAR" == *"$SUB"* ]]          "contains" test
grep -qxF "$X" list.txt           exact membership test against a list
cmd || true                       ignoring an expected non-zero exit code
```

# Part 9: Commit Your Work

Do **not** modify anything in `case/` or `intel/`.

Commit your scripts (`check_all_files.sh`, `failed_totals.sh`, `port_report.sh`, `numbered_list.sh`, `sweep_auth.sh`, `sweep_all.sh`, `correlate.sh`, `ioc_gaps.sh`, `web_gaps.sh`, `hash_evidence.sh`, `hash_ioc_check.sh`, `magic_check.sh`, `find_executables.sh`, `file_survey.sh`) along with `baseline_hashes.txt`, `file_survey_report.txt` and `investigation.txt`.

Suggested commit:

```text
Complete Lab 9
```

Push your changes to GitHub.



# End of Lab 9
