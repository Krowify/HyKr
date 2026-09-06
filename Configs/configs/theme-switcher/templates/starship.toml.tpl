add_newline = true
command_timeout = 1000

format = """
[](fg:{{accent}})[ $os ](bg:{{accent}} fg:{{bg}})[](fg:{{accent}} bg:{{surface}})$directory$git_branch$git_status[](fg:{{surface}})
$character"""

# ---------------- OS ----------------
[os]
disabled = false
style = "bg:{{accent}} fg:{{bg}}"

[os.symbols]
Arch = ""

# ---------------- DIRECTORY ----------------
[directory]
home_symbol = "~"
truncation_length = 3
truncation_symbol = "…/"
style = "bg:{{surface}} fg:{{fg}}"
format = "[ $path ]($style)"

# ---------------- GIT ----------------
[git_branch]
symbol = ""
style = "bg:{{surface}} fg:{{green}}"
format = "[$symbol$branch ]($style)"

[git_status]
conflicted = " "
ahead = " "
behind = " "
diverged = " "
untracked = " "
stashed = " "
modified = " "
staged = " "
renamed = " "
deleted = " "
style = "bg:{{surface}} fg:{{yellow}}"
format = "([$all_status$ahead_behind ]($style))"

# ---------------- PROMPT ----------------
[character]
success_symbol = "[❯](bold fg:{{accent}})"
error_symbol = "[❯](bold fg:{{red}})"

# ---------------- CLEAN ----------------
[package]
disabled = true
[cmd_duration]
disabled = true
