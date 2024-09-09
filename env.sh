. "${ENVYSH}"

: ${ENVD="env.sh"}

envf envs <<-'EOT'
	if [ $# -eq 1 ]; then
		if [ -d "${1}" ]; then
			$envs_prev "${1}/${ENVD}"
		else
			$envs_prev "${1}"
		fi
	else
		$envs_prev "$@"
	fi
	EOT

HOME="$(dirname -- "${ENV}")"
PS1='$(logname)@$(uname -n) $(pwd) \$ '
PS1=". ${ENV}\n${PS1}"

if [ "${IFS-o}" = "${IFS-x}" ]; then
	set -- ${ENVS}
else
	IFS=":"
	set -- ${ENVS}
	unset IFS
fi

envs "$@"

while [ $# -gt 0 ]; do
	if [ -d "${1}" ]; then
		PS1=". ${1}/${ENVD}\n${PS1}"
	else
		PS1=". ${1}\n${PS1}"
	fi
	shift
done
PS1="\n${PS1}"
