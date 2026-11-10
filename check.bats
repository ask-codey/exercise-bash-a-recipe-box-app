#!/usr/bin/env bats
# Checks your recipes app by running it for real, job by job.
# Every test gives the app a pretend home folder of its own, so your real
# ~/.local/share and ~/.config (and this exercise folder) are never touched.
# Run it from this folder with:  bats check.bats
# You don't need to change this file.

bats_require_minimum_version 1.5.0

setup() {
  script="$BATS_TEST_DIRNAME/recipes"
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  unset XDG_DATA_HOME XDG_CONFIG_HOME NO_COLOR
  data_file="$HOME/.local/share/recipes/recipes.txt"
  config_file="$HOME/.config/recipes/config"
  cd "$BATS_TEST_TMPDIR"
}

# Runs your app with bash, so it doesn't need chmod +x.
recipes() {
  bash "$script" "$@"
}

# Puts made-up recipes in the pretend home's recipe box.
fill_box() {
  mkdir -p "$(dirname "$data_file")"
  printf '%s\n' '25 dinner Taco Tuesday' '5 breakfast Overnight Oats' '45 dinner Slow Cooker Chili' \
    '60 dessert Banana Bread' '20 lunch Tomato Soup' '15 breakfast Blueberry Pancakes' > "$data_file"
}

# Fails with a message when the output isn't exactly what the job asks for.
expect_output() {
  if [[ "$output" != "$1" ]]; then
    echo "$2"
    echo "Expected: $1"
    echo "It printed: $output"
    return 1
  fi
}

# Fails with a message when the exit code isn't the one the job asks for.
expect_status() {
  if [[ "$status" -ne "$1" ]]; then
    echo "$2 (it gave exit code $status)."
    return 1
  fi
}

# Fails when a message the job sends to standard error went anywhere else.
expect_error() {
  if [[ "$stderr" != "$1" ]]; then
    echo "$2"
    echo "Expected on standard error: $1"
    echo "Standard error had: $stderr"
    echo "Standard output had: $output"
    return 1
  fi
}

@test "the app is here and bash can read it" {
  if [[ ! -f "$script" ]]; then
    echo "recipes is missing. Download the exercise again to get it back."
    return 1
  fi
  errors="$(bash -n "$script" 2>&1)" || {
    echo "bash found a mistake in recipes before running it:"
    echo "$errors" | head -n 1
    echo "Look at the line it names. Common causes: a missing fi, done or esac, a missing ;; at the end of a choice, or a missing } at the end of a function."
    return 1
  }
}

@test "1) the first run makes ~/.local/share/recipes/recipes.txt" {
  run recipes list
  if [[ ! -f "$data_file" ]]; then
    echo "After the first run, there should be an empty recipes.txt in ~/.local/share/recipes. Make the folder with mkdir -p and the file with touch, when the file isn't there yet."
    return 1
  fi
}

@test "1) a person's own XDG_DATA_HOME is used" {
  export XDG_DATA_HOME="$BATS_TEST_TMPDIR/my-data"
  run recipes list
  if [[ ! -f "$XDG_DATA_HOME/recipes/recipes.txt" ]]; then
    echo "With XDG_DATA_HOME set, recipes.txt belongs in \$XDG_DATA_HOME/recipes. Use \${XDG_DATA_HOME:-\$HOME/.local/share}."
    return 1
  fi
}

@test "1) the first run doesn't empty a recipe box that has recipes" {
  fill_box
  run recipes list
  if [[ "$(wc -l < "$data_file")" -ne 6 ]]; then
    echo "The recipe box had 6 recipes before the run and doesn't now. Make the file only when it isn't there yet: if [[ ! -f \"\$data_file\" ]]."
    return 1
  fi
}

@test "2) the first run writes the settings file" {
  run recipes list
  if [[ ! -f "$config_file" ]]; then
    echo "After the first run, there should be a settings file at ~/.config/recipes/config."
    return 1
  fi
  if ! grep -qx 'quick_minutes=30' "$config_file"; then
    echo "The settings file should have the line quick_minutes=30. It has:"
    cat "$config_file"
    return 1
  fi
}

@test "2) the settings file's quick_minutes is used by list -q" {
  fill_box
  mkdir -p "$(dirname "$config_file")"
  printf 'quick_minutes=10\n' > "$config_file"
  run recipes list -q
  if [[ "$output" != *"Overnight Oats"* || "$output" == *"Blueberry Pancakes"* || "$output" == *"Tomato Soup"* ]]; then
    echo "With quick_minutes=10 in the settings file, list -q should keep only Overnight Oats (5 minutes). Load the file with source, and compare with \"\$quick_minutes\", not 30."
    echo "It printed: $output"
    return 1
  fi
}

@test "3) no color codes when the output goes to a file or a pipe" {
  if ! grep -Eq -- '-t[[:space:]]+1' "$script" || ! grep -q 'tput' "$script"; then
    echo "Set the colors with tput, inside an if that checks [[ -t 1 ]], so they're used only on a terminal."
    return 1
  fi
  fill_box
  run recipes list
  if [[ "$output" == *$'\e'* ]]; then
    echo "The list went into a pipe, not a terminal, so it should have no color codes. Set bold, green and reset to empty text when [[ -t 1 ]] is false."
    return 1
  fi
  run recipes add 10 lunch "Grilled Cheese"
  if [[ "$output" == *$'\e'* ]]; then
    echo "\"Added\" went into a pipe, not a terminal, so it should have no color codes."
    return 1
  fi
}

@test "3) color on a terminal" {
  if ! script -qec true /dev/null >/dev/null 2>&1; then
    skip "this check needs Linux's script command, to pretend to be a terminal"
  fi
  fill_box
  run env TERM=xterm-256color script -qec "bash '$script' list" /dev/null
  if [[ "$output" != *$'\e'* ]]; then
    echo "On a terminal, the header line should be bold: printf it with \"\$bold\" in front and \"\$reset\" after. Set bold with tput bold when [[ -t 1 ]] is true."
    return 1
  fi
}

@test "4) add saves a recipe and says so" {
  run recipes add 25 dinner "Taco Tuesday"
  expect_output "Added Taco Tuesday." "add should print \"Added NAME.\"" || return 1
  expect_status 0 "add should stop with exit code 0 when it worked" || return 1
  if [[ "$(cat "$data_file" 2>/dev/null)" != "25 dinner Taco Tuesday" ]]; then
    echo "recipes.txt should now hold the line: 25 dinner Taco Tuesday"
    echo "It holds: $(cat "$data_file" 2>/dev/null)"
    return 1
  fi
}

@test "4) add keeps the recipes already there" {
  fill_box
  run recipes add 10 lunch "Grilled Cheese"
  if [[ "$(wc -l < "$data_file")" -ne 7 || "$(tail -n 1 "$data_file")" != "10 lunch Grilled Cheese" ]]; then
    echo "add should put the new recipe at the end of recipes.txt and keep the 6 already there: >> adds, > replaces."
    return 1
  fi
}

@test "4) add with the wrong number of words says how to use it" {
  run --separate-stderr recipes add 10 lunch Grilled Cheese
  expect_error 'recipes: usage: recipes add MINUTES CATEGORY "NAME"' "A name with spaces and no quotes arrives as two words, so add gets four. Check \$# with -ne 3, and die with the usage line." || return 1
  expect_status 2 "Running add wrong should stop with exit code 2" || return 1
  if [[ -s "$data_file" ]]; then
    echo "Nothing should be saved when add was run wrong. Check \$# before you write to the file."
    return 1
  fi
}

@test "4) add refuses minutes that aren't a whole number" {
  for minutes in ten 2.5 -5; do
    run --separate-stderr recipes add "$minutes" dinner "Taco Tuesday"
    expect_error "recipes: minutes must be a whole number, such as 25" "add $minutes should be refused: it isn't a whole number. A case pattern such as *[!0-9]* matches anything with a character that isn't a digit." || return 1
    expect_status 2 "add $minutes should stop with exit code 2" || return 1
  done
  if [[ -s "$data_file" ]]; then
    echo "Nothing should be saved when the minutes aren't a whole number."
    return 1
  fi
}

@test "5) list -c keeps one category" {
  fill_box
  run recipes list -c dinner
  if [[ "$output" != *"Taco Tuesday"* || "$output" != *"Slow Cooker Chili"* || "$output" == *"Banana Bread"* || "$output" == *"Overnight Oats"* ]]; then
    echo "list -c dinner should show only Taco Tuesday and Slow Cooker Chili. The value after -c arrives in \$OPTARG."
    echo "It printed: $output"
    return 1
  fi
}

@test "5) list -q keeps the quick ones" {
  fill_box
  run recipes list -q
  if [[ "$output" != *"Tomato Soup"* || "$output" != *"Overnight Oats"* || "$output" == *"Slow Cooker Chili"* || "$output" == *"Banana Bread"* ]]; then
    echo "list -q should keep the recipes of 30 minutes or less (quick_minutes, from job 2) and leave out Slow Cooker Chili and Banana Bread."
    echo "It printed: $output"
    return 1
  fi
}

@test "5) the options work in any order, and joined" {
  fill_box
  for options in "-q -c breakfast" "-c breakfast -q" "-qc breakfast"; do
    run recipes list $options
    if [[ "$output" != *"Overnight Oats"* || "$output" != *"Blueberry Pancakes"* || "$output" == *"Taco Tuesday"* || "$output" == *"Tomato Soup"* ]]; then
      echo "list $options should show only the two quick breakfasts. Read the options with while getopts, so their order doesn't matter."
      echo "It printed: $output"
      return 1
    fi
  done
}

@test "5) an unknown option says so" {
  fill_box
  run --separate-stderr recipes list -x
  expect_error "recipes: there's no -x option. Try: recipes --help" "Start getopts' letters with a colon, then answer the \\? case with die." || return 1
  expect_status 2 "An unknown option should stop with exit code 2"
}

@test "5) -c with no value says so" {
  fill_box
  run --separate-stderr recipes list -c
  expect_error "recipes: -c needs a value, such as -c dinner" "getopts puts : in your variable when an option's value is missing. Answer that case with die." || return 1
  expect_status 2 "-c with no value should stop with exit code 2"
}

@test "6) an empty recipe box says how to add one" {
  run recipes list
  expect_output 'Your recipe box is empty. Add one with: recipes add MINUTES CATEGORY "NAME"' "With no recipes yet, list should say so. Test the file with ! -s." || return 1
  expect_status 0 "An empty box isn't a mistake, so list should stop with exit code 0"
}

@test "6) list shows a header and the recipes in columns" {
  fill_box
  run recipes list -c breakfast
  expect_output "NAME                   MINUTES  CATEGORY
Overnight Oats               5  breakfast
Blueberry Pancakes          15  breakfast" "list should print a header line, then each recipe with printf '%-22s %7s  %s\\n' (name, minutes, category)." || return 1
  expect_status 0 "list should stop with exit code 0"
}

@test "6) a recipe added with add is listed" {
  run recipes add 10 lunch "Grilled Cheese"
  run recipes list
  if [[ "$output" != *"$(printf '%-22s %7s  %s' 'Grilled Cheese' 10 lunch)"* ]]; then
    echo "After add 10 lunch \"Grilled Cheese\", list should show it in its columns."
    echo "It printed: $output"
    return 1
  fi
}

@test "7) --help and -h show the help page" {
  for option in --help -h; do
    run --separate-stderr recipes "$option"
    if [[ "$output" != "Usage: recipes COMMAND"* ]]; then
      echo "$option should print the help page on standard output: call usage. It printed: $output"
      return 1
    fi
    expect_status 0 "$option should stop with exit code 0: asking for help isn't a mistake" || return 1
  done
}

@test "7) --version shows the version" {
  run recipes --version
  expect_output "recipes 1.0.0" "--version should print the app's name and version." || return 1
  expect_status 0 "--version should stop with exit code 0"
}

@test "7) nothing after the name shows the help page as an error" {
  run --separate-stderr recipes
  if [[ "$stderr" != "Usage: recipes COMMAND"* || -n "$output" ]]; then
    echo "Run with nothing, the app should print the help page on standard error: usage >&2."
    echo "Standard output had: $output"
    return 1
  fi
  expect_status 2 "Run with nothing, the app should stop with exit code 2"
}

@test "7) an unknown command says so" {
  run --separate-stderr recipes cook
  expect_error "recipes: there's no cook command. Try: recipes --help" "A word the case doesn't know should go to a *) choice that dies with this message." || return 1
  expect_status 2 "An unknown command should stop with exit code 2"
}
