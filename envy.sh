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
