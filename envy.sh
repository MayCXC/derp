envf () {
	if [ $# -eq 1 ]; then
		set -- "${1}" "{" "}"
	fi

	eval "${1}_=\${${1}_-0}"
	eval "$(
		eval "envf_=\${${1}_}"
		cat <<-EOT
			${1}_${envf_} () ${2}
			EOT
		if [ ${envf_} -gt 0 ]; then
			cat <<-EOT
				${1}_prev="${1}_$((envf_-1))"
				EOT
		fi
		cat
		if [ ${envf_} -gt 0 ]; then
			cat <<-EOT
				unset ${1}_prev
				EOT
		fi
		cat <<-EOT
			${3}
			EOT
		cat <<-EOT
			${1} () ${2}
			${1}_${envf_} "\$@"
			${3}
			EOT
	)"
	eval "${1}_=\$((${1}_+1))"
}

envf envd <<-'EOT'
	case "$*" in
		(/*) CDPATH= cd -P -- "$*";;
		(*) CDPATH= cd -P -- "./$*";;
	esac
	EOT

envf envs <<-'EOT'
	set -- "${PWD}" "$@"
	while [ $# -gt 1 ]; do
		envd "$(dirname -- "${1}")"
		if [ -f "${2}" ]; then
			envd "$(dirname -- "${2}")"
			. "$(basename -- "${2}")"
		elif [ -d "${2}" ]; then
			envd "${2}"
			. "env.sh"
		fi
		if [ ! $? ]; then
			exit $?
		fi
		shift
	done
	envd "${1}"
	shift
	EOT

envf envp <<-'EOT'
	if [ "${IFS-o}" = "${IFS-x}" ]; then
		set -- ${ENVS}
	else
		IFS=":"
		set -- ${ENVS}
		unset IFS
	fi

	envs "$@"

	for ENV_ in "${ENV}" "$@"; do
		PS1="$(
			envd "$(dirname -- "${ENV_}")"
			cat <<-EOT_
				. ${PWD}/$(basename -- "${ENV_}")
				${PS1}
				EOT_
		)"
	done

	PS1="$(
		cat <<-EOT_

			${PS1}
			EOT_
	)"
	EOT
