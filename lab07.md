# Lab 7: Decisions in Bash — if, elif, else and Comparisons

## Introduction

Every script you have written so far does the same thing, in the same order, every time it runs. `logstats.sh` used a single `if` to check that a file existed, but that is as far as decision-making went.

This lab covers **decisions**: how a script can behave differently depending on what it finds. You will learn `if` / `elif` / `else`, how to compare strings and numbers correctly (they use *different* operators), and how to use `$?` to react to whether a previous command succeeded.

You will apply these to the collected configuration files and authentication log, and in the challenge you will discover something important about *which* accounts the attackers were trying.

In Lab 8 you will add file tests and apply decisions to searching the logs for specific IPs and usernames.

**Case question for this lab:** which accounts were targeted, and do those accounts still exist?

## Objectives

By the end of this lab, you should be able to:

1. Write `if` / `elif` / `else` chains, including nested ones.
2. Compare strings correctly, using `=`, `!=`, `-z` and `-n`.
3. Compare numbers correctly, using `-eq`, `-ne`, `-gt`, `-lt`, `-ge` and `-le`.
4. Explain why string and numeric comparison operators are not interchangeable.
5. Extract a setting from a `key=value` configuration file and make a decision based on its value.
6. Use `$?` and `if command` to make a decision based on whether a command succeeded.

# Part 1: Prepare Your Lab Directory

From the repository root:

```bash
mkdir lab07
cp -r lab04-data lab07/case
mkdir lab07/intel
cp lab03-data/iocs.txt lab03-data/users.csv lab07/intel/
cd lab07
```

# Part 2: `if` / `elif` / `else`

You have already used a single `if [ -f "$LOGFILE" ]`. Bash supports full `if` / `elif` / `else` chains, letting you check several conditions in order.

Create `classify_size.sh`:

```bash
#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <file>" >&2
    exit 1
fi

FILE=$1
LINES=$(wc -l < "$FILE")

if [ "$LINES" -lt 10 ]; then
    echo "$FILE is SMALL ($LINES lines)"
elif [ "$LINES" -lt 70 ]; then
    echo "$FILE is MEDIUM ($LINES lines)"
else
    echo "$FILE is LARGE ($LINES lines)"
fi
```

Make it executable and test it against each collected log:

```bash
./classify_size.sh case/logs/firewall.log
./classify_size.sh case/logs/auth.log
./classify_size.sh case/logs/access.log
./classify_size.sh case/nested/archive/old.log
```

- Bash checks each condition **in order**, from top to bottom, and runs the first branch whose condition is true.
- `elif` is short for "else if" — you can chain as many as you need.
- `else` is optional and catches anything not matched by an earlier condition.

**Worked example — a longer chain on file extensions.** Conditions do not have to be numeric. Create `classify_ext.sh`:

```bash
#!/bin/bash

FILE=$1
EXT="${FILE##*.}"

if [ "$EXT" = "log" ]; then
    echo "$FILE : log file"
elif [ "$EXT" = "conf" ]; then
    echo "$FILE : configuration file"
elif [ "$EXT" = "txt" ] || [ "$EXT" = "md" ]; then
    echo "$FILE : text document"
elif [ "$EXT" = "sh" ] || [ "$EXT" = "py" ]; then
    echo "$FILE : script"
else
    echo "$FILE : unrecognised extension '$EXT'"
fi
```

Try it against `case/logs/auth.log`, `case/configs/app.conf`, `case/evidence/notes.txt`, `case/scripts/scan.py` and `case/evidence/suspicious.dat`.

`${FILE##*.}` is **parameter expansion**: it removes everything up to and including the last `.`, leaving just the extension. 

Remember from Lab 4 that the extension is only a *claim* about the content. `classify_ext.sh` trusts the name; `file` looks at the content. 

**Worked example — nested `if` statements.** An `if` block can contain another `if` block, for a decision that only makes sense once an outer condition is true:

```bash
#!/bin/bash

FILE=$1

if [ -f "$FILE" ]; then
    echo "$FILE exists."
    LINES=$(wc -l < "$FILE")
    if [ "$LINES" -eq 0 ]; then
        echo "  ...but it has no lines."
    else
        echo "  ...and has $LINES lines."
    fi
else
    echo "$FILE does not exist — skipping the line count entirely."
fi
```

Save as `nested_check.sh`. The inner `if` only runs when the outer one is true — there is no sensible way to count lines in a file that does not exist.

## Exercise 1

1. Run `classify_size.sh` against all four collected `.log` files. Record each result.
2. Add a new tier, `EMPTY`, for a file with `0` lines. Where in the chain must this check go, and why? Test it with `case/evidence/empty.bin`.
3. Store the thresholds (`10` and `70`) in variables `SMALL_LIMIT` and `MEDIUM_LIMIT` near the top of the script. Why is this good practice?
4. Run `classify_ext.sh` against one file from each subdirectory of `case`. Which files end up as "unrecognised"?
5. Run `nested_check.sh` against `case/logs/auth.log`, `case/evidence/empty.bin`, and a name that does not exist.
6. Run `nested_check.sh` on `case/evidence/image.png`. It reports that the image has 2 "lines". A PNG is not a text file, so what is `wc -l` actually counting? (Hint: `wc -l` counts newline bytes.) Why is a line count meaningless for binary files, and why is `wc -c` or `[ -s file ]` a better test for "empty"?

# Part 3: String Comparisons

Strings are compared with `=` (equal) and `!=` (not equal), and tested for emptiness with `-z` (empty) and `-n` (not empty).

Create `account_check.sh`:

```bash
#!/bin/bash

read -p "Enter a username: " USERNAME

if [ -z "$USERNAME" ]; then
    echo "Error: no username entered" >&2
    exit 1
elif [ "$USERNAME" = "root" ]; then
    echo "CRITICAL: root should never accept password logins over SSH"
elif [ "$USERNAME" = "admin" ]; then
    echo "Warning: checking a generic admin account"
elif [ "$USERNAME" != "guest" ]; then
    echo "Checking standard account: $USERNAME"
else
    echo "Guest account — should normally be disabled"
fi
```

Try it with `root`, `admin`, `guest`, `alice` and an empty answer.

**Important:** always double-quote a variable being compared: `[ "$USERNAME" = "admin" ]`, not `[ $USERNAME = "admin" ]`. If the variable is empty, the unquoted version breaks the test, because `[ ]` then sees too few arguments.

**Worked example — case sensitivity.** String comparison is **case-sensitive**:

```bash
#!/bin/bash

read -p "Enter yes or no: " ANSWER

if [ "$ANSWER" = "yes" ]; then
    echo "Confirmed."
elif [ "$ANSWER" = "no" ]; then
    echo "Cancelled."
else
    echo "Unrecognised answer: '$ANSWER'"
fi
```

Save as `yes_no.sh` and try `Yes`, `YES` and `yes`. Only `yes` matches. One fix is to convert the input to lowercase before comparing, with `${ANSWER,,}` :

```bash
ANSWER_LOWER="${ANSWER,,}"
if [ "$ANSWER_LOWER" = "yes" ]; then
```

**Worked example — reading a setting from a configuration file.** The files in `case/configs` use a `key=value` format. You can extract a value with `grep` and `cut`:

```bash
grep '^debug=' case/configs/app.conf
grep '^debug=' case/configs/app.conf | cut -d'=' -f2
```

`^debug=` anchors the match to the start of the line, so a line such as `nodebug=1` would not match. `cut -d'=' -f2` keeps everything after the `=`.

Create `debug_check.sh`:

```bash
#!/bin/bash

CONF=$1
DEBUG=$(grep '^debug=' "$CONF" | cut -d'=' -f2)

if [ -z "$DEBUG" ]; then
    echo "$CONF: no debug setting"
elif [ "$DEBUG" = "true" ]; then
    echo "$CONF: WARNING - debug mode is ON"
elif [ "$DEBUG" = "false" ]; then
    echo "$CONF: debug mode is off"
else
    echo "$CONF: unexpected debug value '$DEBUG'"
fi
```

Run it against every configuration file in the collection:

```bash
./debug_check.sh case/configs/app.conf
./debug_check.sh case/configs/server.conf
./debug_check.sh case/configs/backup.conf
./debug_check.sh case/backups/config.old
```

Debug mode in production is a common security weakness: it often exposes stack traces, internal paths and sometimes credentials in error pages.

## Exercise 2

1. Run `account_check.sh` with `root`, `admin`, `guest`, `alice` and nothing at all. Record each result.
2. Temporarily remove the quotes around `$USERNAME` in the first test and press Enter without typing anything. What error do you get?
3. Run `yes_no.sh` with `Yes`. Then add the `${ANSWER,,}` fix and confirm `Yes`, `YES` and `yes` are all accepted.
4. Which configuration file has debug mode on? Is it a live configuration or a backup? Why might an old configuration with debug enabled still matter during an investigation?
5. Adapt `debug_check.sh` into `tls_check.sh`, which reports whether `tls=true` is set. Run it on all four configuration files. Which ones do not mention TLS at all?
6. Change `debug_check.sh` so it also accepts `True`, `TRUE` and `yes` as "on".

# Part 4: Numeric Comparisons

Numbers use a **different** set of operators from strings.

| Operator | Meaning                  |
| -------- | ------------------------ |
| `-eq`    | equal                    |
| `-ne`    | not equal                |
| `-gt`    | greater than             |
| `-lt`    | less than                |
| `-ge`    | greater than or equal to |
| `-le`    | less than or equal to    |

Create `risk_level.sh`:

```bash
#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <failed_attempt_count>" >&2
    exit 1
fi

COUNT=$1

if [ "$COUNT" -eq 0 ]; then
    echo "Risk: NONE (no failed attempts)"
elif [ "$COUNT" -lt 5 ]; then
    echo "Risk: LOW ($COUNT failed attempts)"
elif [ "$COUNT" -lt 15 ]; then
    echo "Risk: MEDIUM ($COUNT failed attempts)"
else
    echo "Risk: HIGH ($COUNT failed attempts)"
fi
```

Test it:

```bash
./risk_level.sh 0
./risk_level.sh 3
./risk_level.sh 10
./risk_level.sh 40
```

Now feed it real counts, using command substitution to calculate each one:

```bash
./risk_level.sh $(grep -c "from 203.0.113.10 " case/logs/auth.log)
./risk_level.sh $(grep -c "from 198.51.100.77 " case/logs/auth.log)
./risk_level.sh $(grep -c "Failed password for admin " case/logs/auth.log)
```

The trailing space in `"from 203.0.113.10 "` stops the pattern also matching a longer address such as `203.0.113.100`. 

**Worked example — the text-versus-number trap.**

```bash
#!/bin/bash

A="10"
B="9"

echo "Using = (text comparison):"
if [ "$A" = "$B" ]; then echo "  equal"; else echo "  not equal"; fi

echo "Using -gt (numeric comparison):"
if [ "$A" -gt "$B" ]; then echo "  $A is greater than $B"; else echo "  $A is not greater than $B"; fi

echo "Using \\> (text ordering):"
if [ "$A" \> "$B" ]; then echo "  '$A' sorts after '$B'"; else echo "  '$A' sorts before '$B'"; fi
```

Save as `text_vs_number.sh` and run it. As **text**, `"10"` sorts *before* `"9"`, because comparison is character by character and `1` comes before `9`. This is why Bash has separate operators for numbers.

**Worked example — checking a port number.** Ports below 1024 are **privileged**: on Linux, only root can listen on them. Create `port_check.sh`:

```bash
#!/bin/bash

CONF=$1
PORT=$(grep '^port=' "$CONF" | cut -d'=' -f2)

if [ -z "$PORT" ]; then
    echo "$CONF: no port configured"
elif [ "$PORT" -lt 1024 ]; then
    echo "$CONF: port $PORT is privileged (below 1024)"
else
    echo "$CONF: port $PORT is unprivileged"
fi
```

Run it against `case/configs/app.conf`, `case/configs/server.conf`, `case/configs/backup.conf` and `case/config-old.txt`.

## Exercise 3

1. Run `risk_level.sh` with the failed-attempt count for each of the five attacking IPs (`203.0.113.10`, `198.51.100.24`, `198.51.100.77`, `203.0.113.200`, `203.0.113.15`). Record each risk level.
2. What error do you get if you run `./risk_level.sh abc`? Why?
3. Add a `CRITICAL` tier for 30 or more failed attempts. Where must it go in the chain?
4. Run `text_vs_number.sh` and write one sentence explaining each of the three outputs.
5. Run `port_check.sh` on `case/config-old.txt` and `case/config-new.txt`. The port changed between the two versions. Is the new port privileged? Is it a standard port for a particular protocol?
6. What happens if you run `port_check.sh` on a file where the value is `port=https`? Modify the script to print a clear message instead of an error when `PORT` is not a number. (Hint: `grep -q '^[0-9]*$'` on `echo "$PORT"`.)

# Part 5: Using `$?` to Make Decisions

Every command sets `$?` when it finishes. You can test `$?`, or — more idiomatically — test the command itself.

Both of these do the same thing:

```bash
# Explicit $? check
grep -q "^eve," intel/users.csv
if [ $? -eq 0 ]; then
    echo "eve is a current account"
fi
```

```bash
# Idiomatic direct test (preferred)
if grep -q "^eve," intel/users.csv; then
    echo "eve is a current account"
fi
```

- `grep -q` prints nothing and just sets an exit code: `0` if it found a match, `1` if not.
- `$?` always reflects the **most recently finished** command, so check it immediately.

**Worked example — two sources of truth.** The collection contains an old copy of the user list in `case/backups/users.old`. Look at both:

```bash
cat intel/users.csv
cat case/backups/users.old
```

The two lists have a different format: `users.csv` has one account per line with a header and four comma-separated fields; `users.old` has one bare username per line. So the searches must differ:

```bash
grep -q "^admin," intel/users.csv        # username followed by a comma
grep -qx "admin" case/backups/users.old   # -x: the WHOLE line must match
```

Create `account_source.sh`:

```bash
#!/bin/bash

USERNAME=$1

if grep -q "^$USERNAME," intel/users.csv; then
    echo "$USERNAME: CURRENT account"
elif grep -qx "$USERNAME" case/backups/users.old; then
    echo "$USERNAME: LEGACY account (only in the old backup list)"
else
    echo "$USERNAME: UNKNOWN account (in neither list)"
fi
```

Try it with `alice`, `admin`, `root`, `backup`, `oracle` and `guest`.

**Worked example — `if grep -q` with nested decisions.**

```bash
#!/bin/bash

LOG="case/logs/auth.log"

if grep -q "Failed password" "$LOG"; then
    if grep -q "Accepted password" "$LOG"; then
        echo "$LOG contains both failed and accepted logins."
    else
        echo "$LOG contains only failed logins."
    fi
else
    echo "$LOG contains no failed login attempts."
fi
```

Save as `login_mix.sh` and run it.

## Exercise 4

1. Write a script that uses `grep -q "sqlmap" case/logs/access.log` directly in an `if` to print `Scanning tool activity detected` or `No scanning tool activity`.
2. Rewrite it using an explicit `$?` check and confirm it behaves identically.
3. Put an `echo` between the `grep -q` and the `$?` check. What happens, and why?
4. Run `account_source.sh` for every username that appears in a `Failed password` line (Lab 3, Part 10 gives you the list). Record which category each falls into.
5. Why does `account_source.sh` need `-x` for `users.old` but a trailing comma for `users.csv`? What would go wrong with `grep -q "admin" case/backups/users.old` if the file also contained `sysadmin`?

# Part 6: Common Mistakes and Debugging

| Symptom                                                                   | Likely cause                                                            | Fix                                                                    |
| ------------------------------------------------------------------------- | ----------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `[: too many arguments`                                                   | An unquoted variable containing spaces, or empty                        | Quote the variable: `[ "$VAR" = "x" ]`                                 |
| `[: -eq: unary operator expected` or `integer expression expected`        | A variable used with a numeric operator was empty or not a number       | `echo "[$VAR]"` to see what it really holds                            |
| A string comparison never matches, even though the values "look" the same | Hidden whitespace, a case mismatch, or a Windows carriage return (`\r`) | `echo "[$VAR]"` or `echo "$VAR" \| cat -A` to reveal hidden characters |
| An `elif` branch never runs                                               | An earlier, broader condition already matched                           | Order conditions from most specific to least specific                  |
| Numbers compare "backwards"                                               | `=` or `\>` was used instead of `-eq` / `-gt`                           | Use numeric operators for numbers                                      |
| `grep` finds a username inside a longer one                               | The pattern was not anchored                                            | Use `^name,`, `-x` or `-w` as appropriate                              |

**Worked example — order matters.** This script has a bug: the middle branch can never run.

```bash
#!/bin/bash

COUNT=$1

if [ "$COUNT" -ge 0 ]; then
    echo "Non-negative"
elif [ "$COUNT" -ge 10 ]; then
    echo "At least 10"
else
    echo "Negative"
fi
```

Save as `order_bug.sh` and run it with `10`. You see `Non-negative`, because `-ge 0` is already true for `10`. Fix it by checking `-ge 10` first.



## Exercise 5

1. Reproduce at least two rows from the table using broken copies of your scripts.
2. Fix `order_bug.sh` and confirm `10`, `5` and `-3` produce the intended messages.
3. Produce the carriage-return problem and fix it. Why is this kind of bug hard to spot by eye?

# Part 7: Investigation Challenge

Write a script called `validate_login.sh` that:

1. Reads a username with `read -p`.
2. If the username is empty, prints an error to standard error and exits with code `1`.
3. Decides where the account comes from, reusing `account_source.sh`'s logic:
   
   - **CURRENT**: in `intel/users.csv` — also print its role and status;
   
   - **LEGACY**: only in `case/backups/users.old`;
   
   - **UNKNOWN**: in neither.
4. Counts the failed and accepted logins for that username in `case/logs/auth.log` (match `"Failed password for $USERNAME "` and `"Accepted password for $USERNAME "`, with the trailing space).
5. Classifies the failed count with the `risk_level.sh` thresholds.
6. Prints a specific warning for each of these situations:
   
   - a **disabled** current account has *any* accepted login;
   
   - a **legacy** or **unknown** account was targeted by failed logins (the attacker is guessing account names);
   
   - a **current** account has accepted logins **and** appears in `case/evidence/passwords.txt` (use `grep -q "^$USERNAME:"`).
7. Exits with `0` for a current account, `2` for a legacy account and `3` for an unknown account.

Run it at least for `alice`, `bob`, `eve`, `david`, `admin`, `root`, `backup`, `oracle` and `nobody`. Record every run, with its exit code, in `investigation.txt`, then answer:

1. Which targeted usernames are **current** accounts? What does your answer suggest about how the attacker chose which names to try?
2. Which targeted names are **legacy** accounts found only in the old backup? If those accounts still existed on the server, which would be most dangerous, and why?
3. Were any accepted logins seen for a disabled account, or from an external (non-`192.168.`) address? What does that tell you — and what does it *not* prove?
4. Which accounts have both plaintext credentials on the workstation and successful logins? From how many different internal addresses did each log in (`grep "Accepted password for alice "`)? Why is that combination worth reporting?

# Part 8: Concepts and Commands Covered

You should now be comfortable with:

```text
if / elif / else            conditional branching
nested if                   an if block inside another if block
= != -z -n                  string comparisons
${VAR,,}                    lowercasing a value (Bash-specific)
${FILE##*.}                 extracting a file extension
-eq -ne -gt -lt -ge -le     integer comparisons
[ A ] || [ B ]              either test may succeed
$?                          exit code of the last command
if grep -q ...              testing a command directly
grep '^key=' | cut -d= -f2  reading a key=value setting
grep -x                     whole-line match
tr -d '\r'                  removing Windows carriage returns
```

# Part 9: Commit Your Work

Do **not** modify anything in `case/` or `intel/`.

Commit your scripts (`classify_size.sh`, `classify_ext.sh`, `nested_check.sh`, `account_check.sh`, `yes_no.sh`, `debug_check.sh`, `tls_check.sh`, `risk_level.sh`, `text_vs_number.sh`, `port_check.sh`, `account_source.sh`, `login_mix.sh`, `order_bug.sh`, `validate_login.sh`) and `investigation.txt`.

Suggested commit:

```text
Complete Lab 7
```

Push your changes to GitHub.



# End of Lab 7
