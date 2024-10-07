. "envy.sh"

envf envs <<-'EOT'
	if [ $# -eq 1 ] && [ -d "${1}" ]; then
		eval "$(
			envw "${1}" <<-'EOT_'
				envs "${ENVN}"
				EOT_
		)"
	else
		envs_ "$@"
	fi
	EOT

envf envy <<-'EOT'
	if [ $# -lt 1 ]; then
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

# todo getopts etc
if ! command -v tac >/dev/null; then
	envf tac <<-'EOT'
		TAC_FLAG_B=
		TAC_FLAG_R=
		TAC_FLAG_S=
		eval "$(
			envl OPTIND OPTARG OPT OPTLONG <<-'EOT_'
				while getopts "brs:-:" OPT; do
					if [ ! "${OPTLONG-o}" = "${OPTLONG-x}" ]; then
						OPT="${OPTLONG}"
						unset OPTLONG
					else
						case "${OPT}" in
							(-*=*) IFS="=" read OPTLONG OPTARG <<EOT__
								${OPT#"-"}
								EOT__
								;;
							(*=*);;
							(-*) OPT="${OPT#"-"}";;
							(*) ;;
						esac
					fi
					if [ "${OPT}" = "-" ]; then
						while IFS="=" read -r OPTLONG OPTARG
						<<EOT__
							${OPTARG#"-"}
							EOT__
					fi
					case "${OPT}" in
						();;
					esac
				done
				EOT_
		)"
		shift $(($OPTIND - 1))
		cat "$@" | {
			while IFS= read -r L; do
				set -- "${L}" "$@"
			done
			printf "%s\n" "$@"
		}
		if [ $# -eq 0 ]; then
			while IFS= read -r L; do
				set -- "${L}" "$@"
			done
			printf "%s\n" "$@"
		else
			cat "$@" | tac
		fi
		EOT
fi

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
