envt () {
	while [ $# -gt 0 ]; do
		printf '%s' "${1}" | od -An -b -v | xargs -E '' printf '\\0%s'
		shift
	done
}

envr () {
	while [ $# -gt 0 ]; do
		printf '%b' "${1}"
		shift
	done
}

envl () {
	cat
	while [ $# -gt 0 ]; do
		eval "set -- \"\${${1}-o}\" \"\${${1}-x}\" \"\$@\""
		if [ "${1}" = "${2}" ]; then
			cat <<-EOT
				${3}="\$(envr '$(envt "${1}")')"
				EOT
		else
			cat <<-EOT
				unset -v -- ${3}
				EOT
		fi
		shift 3
	done
}

envw () {
	while [ $# -gt 0 ]; do
		cat <<-EOT
			envd "\$(envr '$(envt "${1}")')"
			EOT
		shift
	done
	cat
	cat <<-EOT
		envd "\${PWD}"
		EOT
}

envf () {
	if [ $# -lt 1 ]; then
		set -- "$@" "envf"
	fi
	if [ $# -lt 2 ]; then
		set -- "$@" "{"
	fi
	if [ $# -lt 3 ]; then
		set -- "$@" "}"
	fi
	if [ $# -lt 4 ]; then
		eval "set -- \${${1}_tail-o} \${${1}_tail-x} \"\$@\""
		if [ "${1}" = "${2}" ]; then
			set -- "$@" $((${1}+1))
		else
			set -- "$@" 0
		fi
		shift 2
	fi
	if [ $# -ge 4 ]; then
		eval "$(
			cat <<-EOT
				${1}_${4} () ${2}
				EOT
			cat
			cat <<-EOT
				${3}
				${1}_tail=${4}
				EOT
			if [ ${4} -eq 0 ]; then
				cat <<-EOT
					${1} () ${2}
						eval "\$(
							envl ${1}_head <<-'EOT_'
								${1}_head=\${${1}_tail}
								${1}_\${${1}_head} "\$@"
								return \$?
								EOT_
						)"
					${3}
					${1}_ () ${2}
						eval "\$(
							envl ${1}_head <<-'EOT_'
								${1}_head=\$((\${${1}_head}-1))
								${1}_\${${1}_head} "\$@"
								return \$?
								EOT_
						)"
					${3}
					EOT
			fi
		)"
	fi
	shift 4
	if [ $# -gt 0 ]; then
		envf "$@"
	fi
}

envf envd <<-'EOT'
	while [ $# -gt 0 ]; do
		case "${1}" in
			(/*) CDPATH= cd -P -- "${1}";;
			(*) CDPATH= cd -P -- "./${1}";;
		esac
		shift
	done
	EOT

envf envg <<-'EOT'
	if [ $# -lt 1 ]; then
		set -- "$@" "envg"
	fi
	envf "$@"
	envf "${1}" "{" "}" <<-EOT_
		eval "\$(
			envw "${PWD}" <<-'EOT__'
				${1}_ "\$@"
				EOT__
		)"
		EOT_
	EOT

envf envs <<-'EOT'
	if [ $# -eq 1 ]; then
		set -- "$@" "${PWD}"
		envd "$(dirname -- "${1}")"
		. "./$(basename -- "${1}")"
		set -- "$@" $?
		if [ ${3} -ne 0 ]; then
			exit ${3}
		fi
		envd "${2}"
	else
		while [ $# -gt 0 ]; do
			envs "${1}"
			shift
		done
	fi
	EOT

envf enve <<-'EOT'
	while [ $# -gt 0 ]; do
		if [ "${1}" = "--" ]; then
			ENVSTAIL=$#
			shift
			ENVSARGS="$*"
		else
			shift
		fi
	done

	set -- ${ENVSARGS}
	ENVSSPIN=$#
	while [ ${ENVSSPIN} -gt 0 ]; do
		ENVSHEAD="$(realpath -- "${1}")"

		set -- $? "$@"
		if [ ${1} -ne 0 ]; then
			return ${1}
		fi
		shift

		set -- "$@" "${ENVSHEAD}"
		shift

		ENVSSPIN=$((${ENVSSPIN}-1))
	done

	set -- ${ENVS} "$@"
	ENVS="$*"
	EOT

envf envy <<-'EOT'
	eval "$(
		envl ENV ENVS <<-'EOT_'
			: ${ENV="env.sh"}
			ENV="$(
				envd "$(dirname -- "${0}")"
				realpath -- "${ENV}"
			)"

			set -- $? "$@"
			if [ ${1} -ne 0 ]; then
				return ${1}
			fi
			shift

			: ${ENVS=""}

			eval "$(
				envl IFS ENVSTAIL ENVSARGS ENVSSPIN ENVSHEAD <<-'EOT__'
					IFS=":"
					ENVSTAIL=$#
					ENVSARGS="$*"
					enve "$@"

					set -- $? "$@"
					if [ ${1} -ne 0 ]; then
						return ${1}
					fi
					shift

					ENVSSPIN=$(($#-${ENVSTAIL}))
					while [ ${ENVSSPIN} -gt 0 ]; do
						set -- "$@" "${1}"
						shift
						ENVSSPIN=$((${ENVSSPIN}-1))
					done

					shift ${ENVSTAIL}
					EOT__
			)"
			# POSIX User Portability Utilities sh
			ENV="${ENV}" ENVS="${ENVS}" sh "$@"
			EOT_
	)"
	EOT
