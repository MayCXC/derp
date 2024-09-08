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

envf envs <<-'EOT'
	set -- "${PWD}" "$@"
	while [ $# -gt 1 ]; do
		cd $(dirname -- "${1}")
		if [ -f "${2}" ]; then
			cd $(dirname -- "${2}")
			. $(basename -- "${2}")
		elif [ -d "${2}" ]; then
			cd "${2}"
			. "env.sh"
		fi
		shift
	done
	cd "${1}"
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

	for ENV in "$@"; do
		PS1=". ${ENV}\n${PS1}"
	done
	PS1=$(
		ABSENV="${PWD%"/"}/${ENV#"/"}"
		cd $(dirname -- "${ABSENV}")
		cat <<-EOT_

			. ${PWD}/$(basename -- "${ABSENV}")
			${PS1}
			EOT_
	)
	EOT

envp
