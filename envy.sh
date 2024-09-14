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
				${1}_tail=${4}
				${1}_${4} () ${2}
				EOT
			cat
			cat <<-EOT
				${3}
				EOT
			if [ ${4} -eq 0 ]; then
				cat <<-EOT
					${1} () ${2}
						eval "\$(
							envl ${1}_head <<-EOT_
								${1}_head=\\\${${1}_tail}
								${1}_\\\${${1}_head} "\\\$@"
								EOT_
						)"
					${3}
					${1}_ () ${2}
						eval "\$(
							envl ${1}_head <<-EOT_
								${1}_head=\\\$((\\\${${1}_head}-1))
								${1}_\\\${${1}_head} "\\\$@"
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

envf envs <<-'EOT'
	if [ $# -eq 1 ]; then
		set -- "$@" "${PWD}"
		envd "$(dirname -- "${1}")"
		. "$(basename -- "${1}")"
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

envf envg <<-'EOT'
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
		set -- "$@" "$(realpath "${1}")"
		shift
		ENVSSPIN=$((${ENVSSPIN}-1))
	done

	set -- ${ENVS} "$@"
	ENVS="$*"
	EOT

envf envy <<-'EOT'
	: ${ENV="env.sh"}
	case "${ENV}" in
		(/*);;
		(*)ENV="$(dirname -- "${0}")/${ENV}";;
	esac
	ENV="$(realpath -- "${ENV}")"

	: ${ENVS=""}

	eval "$(
		envl IFS ENVSTAIL ENVSARGS ENVSSPIN <<-'EOT_'
			IFS=":"
			ENVSTAIL=$#
			ENVSARGS="$*"
			envg "$@"

			ENVSSPIN=$(($#-${ENVSTAIL}))
			while [ ${ENVSSPIN} -gt 0 ]; do
				set -- "$@" "${1}"
				shift
				ENVSSPIN=$((${ENVSSPIN}-1))
			done

			shift ${ENVSTAIL}
			EOT_
	)"

	export ENV
	export ENVS
	# POSIX User Portability Utilities sh
	sh "$@"
	EOT
