envt () {
	while [ $# -gt 0 ]; do
		printf '%s' "${1}" | od -A n -b -v | xargs -E '' printf '\\0%s'
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
		eval 'set -- "${'"${1}"'-o}" "${'"${1}"'-x}" "$@"'
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

envf () {
	while [ $# -gt 0 ]; do
		if [ $# -lt 1 ] || [ -z "${1}" ]; then
			set -- "$@" "envf"
		fi
		if [ $# -lt 2 ] || [ -z "${2}" ]; then
			set -- "$@" "{"
		fi
		if [ $# -lt 3 ] || [ -z "${3}" ]; then
			set -- "$@" "}"
		fi
		if [ $# -lt 4 ] || [ -z "${4}" ]; then
			eval 'set -- ${'"${1}_tail"'-o} ${'"${1}_tail"'-x} "$@"'
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
									EOT_
								return \$?
							)"
						${3}
						${1}_ () ${2}
							eval "\$(
								envl ${1}_head <<-'EOT_'
									${1}_head=\$((\${${1}_head}-1))
									${1}_\${${1}_head} "\$@"
									EOT_
								return \$?
							)"
						${3}
						EOT
				fi
			)"
		fi
		shift 4
	done
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

envw () {
	while [ $# -gt 0 ]; do
		cat <<-EOT
			envd "\$(envr '$(envt "${1}")')"
			EOT
		shift
	done
	cat
	cat <<-EOT
		envd "\$(envr '$(envt "${PWD}")')"
		EOT
}

envf envg <<-'EOT'
	if [ $# -lt 1 ]; then
		set -- "$@" "envg"
	fi

	envf "$@"

	envf "${1}" "{" "}" <<-EOT_
		eval "\$(
			envw "\$(envr '$(envt "${PWD}")')" <<-'EOT__'
				${1}_ "\$@"
				EOT__
		)"
		EOT_
	EOT

envf envs <<-'EOT'
	if [ $# -eq 1 ]; then
		eval "$(
			envw "$(dirname -- "${1}")" <<-'EOT_'
				. "./$(basename -- "${1}")"

				set -- $? "$@"
				if [ ${1} -ne 0 ]; then
					exit ${1}
				fi
				EOT_
		)"
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
		ENVSHEAD="$(
			if [ -d "${1}" ]; then
				envd "${1}"
				realpath -- "${ENVN}"
			else
				realpath -- "${1}"
			fi
		)"

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
		envl ENVN ENV ENVS <<-'EOT_'
			: ${ENVN="env.sh"}
			: ${ENV="${ENVN}"}
			: ${ENVS=""}

			ENV="$(
				envd "$(dirname -- "${0}")"

				if [ -d "${ENV}" ]; then
					envd "${ENV}"
					realpath -- "${ENVN}"
				else
					realpath -- "${ENV}"
				fi
			)"

			set -- $? "$@"
			if [ ${1} -ne 0 ]; then
				return ${1}
			fi
			shift

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
			ENVN="${ENVN}" ENV="${ENV}" ENVS="${ENVS}" sh "$@"
			EOT_
	)"
	EOT

envf envz <<-'EOT'
	eval "$(
		envl OPTS <<-'EOT_'
			OPTS="$*"

			set --
			eval "$(
				set +o | while read -r S O N; do
					cat <<-EOT__
						set -- "\$@" "\$(envr '$(envt "${O}")')" "\$(envr '$(envt "${N}")')"
						EOT__
				done
			)"

			set -- "$@" ${OPTS}
			EOT_
	)"

	# POSIX User Portability Utilities sh
	exec sh "$@"
	EOT
