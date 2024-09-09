. "${ENVYSH}"
HOME="$(dirname -- "${PWD%"/"}/${ENV#"/"}")"
PS1='$(logname)@$(uname -n) $(pwd) \$ '
envp
