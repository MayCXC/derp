envf () {
	if [ $# = 0 ]; then
		set -- "$@" "envf"
	fi
	if [ $# = 1 ]; then
		set -- "$@" "{"
	fi
	if [ $# = 2 ]; then
		set -- "$@" "}"
	fi
	if [ $# = 3 ]; then
		eval "set -- \"\$@\" \${${1}_-\$((0-1))}"
	fi
	if [ $# = 4 ]; then
		set -- "$@" $((${4}+1))
	fi
	if [ $# = 5 ]; then
		eval "$(
			cat <<-EOT
				${1}_=${5}
				${1}_${5} () ${2}
				EOT
			if [ ${5} -gt 0 ]; then
				cat <<-EOT
					${1}_prev="${1}_${4}"
					EOT
			fi
			cat
			if [ ${5} -gt 0 ]; then
				cat <<-EOT
					unset -v -- ${1}_prev
					EOT
			fi
			cat <<-EOT
				${3}
				unset -f -- ${1}
				${1} () ${2}
				${1}_${5} "\$@"
				${3}
				EOT
		)"
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

envf envy <<-'EOT'
	: ${ENV="env.sh"}
	ENV="$(
		envd "$(dirname -- "${0}")"
		realpath -- "${ENV}"
	)"

	: ${ENVS=""}

	ENVSTAIL=$#

	getenvs () {
		ENVSARGS="$*"

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
		unset -v ENVSARGS

		ENVSSPIN=$#
		while [ ${ENVSSPIN} -gt 0 ]; do
			set -- "$@" "$(realpath "${1}")"
			shift
			ENVSSPIN=$((${ENVSSPIN}-1))
		done
		unset -v -- ENVSSPIN

		set -- ${ENVS} "$@"

		ENVS="$*"
	}

	if [ "${IFS-o}" = "${IFS-x}" ]; then
		getenvs "$@"
	else
		IFS=":"
		getenvs "$@"
		unset -v -- IFS
	fi

	ENVSSPIN=$(($#-${ENVSTAIL}))
	while [ ${ENVSSPIN} -gt 0 ]; do
		set -- "$@" "${1}"
		shift
		ENVSSPIN=$((${ENVSSPIN}-1))
	done
	unset -v -- ENVSSPIN

	shift ${ENVSTAIL}
	unset -v -- ENVSTAIL

	export ENV
	export ENVS

	# POSIX User Portability Utilities sh
	exec sh "$@"
	EOT
