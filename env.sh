. "envy.sh"

: ${ENVN="$(basename -- "${ENV-"env.sh"}")"}

envf envs <<-'EOT'
	if [ $# -eq 1 ] && [ -d "${1}" ]; then
		set -- "$@" "${PWD}"
		envd "${1}"
		envs "${ENVN}"
		envd "${2}"
	else
		envs_ "$@"
	fi
	EOT

envf envy <<-'EOT'
	if [ $# -eq 0 ]; then
		set -- "$@" "."
	fi
	envy_ "$@"
	EOT

envf envp <<-'EOT'
	PS1='$(logname)@$(uname -n) $(pwd) \$ '
	EOT

envf envp <<-'EOT'
	envp_ "$@"
	PS1=". ${ENV}\n${PS1}"
	while [ $# -gt 0 ]; do
		if [ -d "${1}" ]; then
			PS1=". ${1%"/"}/${ENVN#"/"}\n${PS1}"
		else
			PS1=". ${1}\n${PS1}"
		fi
		shift
	done
	PS1="\n${PS1}"
	EOT

if [ $# -eq 0 ]; then
	eval "$(
		envl IFS <<-'EOT'
			IFS=":"
			set -- ${ENVS}
			EOT
	)"
	envs "$@"
	envp "$@"
	shift $#
fi
