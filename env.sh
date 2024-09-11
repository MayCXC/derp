. "envy.sh"

envf envy <<-'EOT'
	if [ $# -eq 0 ]; then
		set -- "$@" "."
	fi
	$envy_prev "$@"
	EOT

: ${ENVF="$(basename -- "${ENV}")"}

envf envs <<-'EOT'
	if [ $# -eq 1 ] && [ -d "${1}" ]; then
		set -- "$@" "${PWD}"
		envd "${1}"
		$envs_prev "${ENVF}"
		envd "${2}"
	else
		$envs_prev "$@"
	fi
	EOT

HOME="$(dirname -- "${ENV}")"
export HOME

PS1='$(logname)@$(uname -n) $(pwd) \$ '
PS1=". ${ENV}\n${PS1}"

if [ "${IFS-o}" = "${IFS-x}" ]; then
	set -- ${ENVS}
else
	IFS=":"
	set -- ${ENVS}
	unset -v -- IFS
fi

envs "$@"

while [ $# -gt 0 ]; do
	if [ -d "${1}" ]; then
		PS1=". ${1%"/"}/${ENVF#"/"}\n${PS1}"
	else
		PS1=". ${1}\n${PS1}"
	fi
	shift
done

PS1="\n${PS1}"
export PS1
