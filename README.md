# Exercise: A Recipe Box App

Exercise code for the lesson **Exercise: A Recipe Box App** in Bash in Depth on [ask-codey.com](https://www.ask-codey.com).

Finish `recipes`, a complete command-line application written in bash: `recipes add 25 dinner "Taco Tuesday"` saves a recipe, `recipes list -q -c dinner` shows them in tidy columns, `--help` and `--version` answer like any real tool, the recipes are kept where Linux apps keep their data, a settings file says what counts as quick, and the header is bold only on a terminal. A check script runs it for real, job by job, and tells you what's done.

## Before you start

You need a terminal (the Terminal app on a Mac, Ubuntu on Linux or in WSL on Windows) and **bats**, the tool that runs the check. If `bats --version` doesn't print a version yet, install it:

```bash
sudo apt install bats       # Ubuntu, and Ubuntu in WSL
brew install bats-core      # a Mac, with Homebrew
```

**On Windows, unzip or clone this folder inside Ubuntu**, in your Linux home folder (for example `~/terminal-practice/`), not in a Windows folder under `/mnt/c`, so `chmod` works on the script.

## What's here

- `recipes`: the app, with its help page, a `die` function and seven jobs, each a comment saying what to do and exactly what to print. For you to finish.
- `sample-recipes.txt`: eight made-up recipes to try your app on.
- `check.bats`: the check. You don't need to change it.
- `.gitignore`: keeps the `pretend-home/` folder you'll try the app in out of your repo.

## Run it

Open a terminal in this folder (the one with `recipes` in it), let the app run, and open it:

```bash
chmod +x recipes
nano recipes
```

Write your code under each job's comment, save with Ctrl+O and Enter, and quit with Ctrl+X.

To try it without touching your real `~/.local/share` and `~/.config`, point the app at a pretend home inside this folder, for this terminal window only. This works once jobs 1 and 2 use `XDG_DATA_HOME` and `XDG_CONFIG_HOME`:

```bash
export XDG_DATA_HOME="$PWD/pretend-home/data" XDG_CONFIG_HOME="$PWD/pretend-home/config"
./recipes add 25 dinner "Taco Tuesday"
./recipes list
cp sample-recipes.txt pretend-home/data/recipes/recipes.txt
./recipes list -q -c dinner
```

The seven jobs:

1. **Where the recipes live**: `recipes.txt` in `${XDG_DATA_HOME:-$HOME/.local/share}/recipes`, made empty on the first run.
2. **The settings file**: `config` in `${XDG_CONFIG_HOME:-$HOME/.config}/recipes`, written on the first run with `quick_minutes=30`, then loaded with `source`.
3. **Colors, only on a terminal**: `bold`, `green` and `reset` from `tput` when `[[ -t 1 ]]` and `NO_COLOR` is empty; empty text otherwise.
4. **`recipes add MINUTES CATEGORY "NAME"`**: checks it got three words and whole-number minutes, saves the line, and prints `Added NAME.` in green.
5. **`recipes list` options**: `-c CATEGORY` and `-q` with `getopts`, in any order or joined, with messages for an unknown option and a missing value.
6. **`recipes list` output**: a message for an empty box, or a bold header and the recipes in columns.
7. **The commands**: `--help` and `-h`, `--version`, nothing at all, and an unknown word (`add` and `list` are done for you).

## Check your work

From this folder:

```bash
bats check.bats
```

At first most checks fail: that is expected. Each job you finish turns its checks into a ✓. A failing check's message says what it expected, what your app printed, and what to look at. The check gives your app a pretend home folder of its own for every test, so your real files and your `pretend-home/` are never touched.

## The rules

- Keep the app in `recipes`, and keep `usage`, `die` and `version` as they are.
- Print each message exactly as its job gives it: the check compares them word for word.
- Send error messages to standard error with `die` (or `>&2`), and use `getopts` for the options and `printf` for the columns.

## Tips

- Work from job 1 down. The script runs from the top, and the `case` at the bottom picks the job.
- `${XDG_DATA_HOME:-$HOME/.local/share}` is the person's own folder, or the usual one when they haven't set one.
- A `case` pattern such as `*[!0-9]*` matches any word with a character that isn't a digit.
- getopts' letters start with a colon (`":c:q"`), so your script words the errors: `:` for a missing value, `\?` for an unknown option.
- `printf '%-22s %7s  %s\n'` lines up a name on the left in 22 spaces, and the minutes on the right in 7.
- `bats` runs your app with its output going to the check, not a terminal, so it should see no color codes at all.
- On a Mac, the app runs in bash 5 because of its first line, as long as Homebrew's bash comes first on your `PATH`. The check that pretends to be a terminal runs only on Linux, and says it skipped on a Mac.

## Hand it in

When it works, push your solution to a public repo of your own on GitHub, then paste that repo's address into **Submit your exercise** on the lesson page at [ask-codey.com](https://www.ask-codey.com). That's what completes the lesson. The lesson page shows the Git commands, step by step.
