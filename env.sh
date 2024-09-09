. "${ENVYSH}"
HOME="$(dirname -- "${ENV}")"
PS1='$(logname)@$(uname -n) $(pwd) \$ '
envp
