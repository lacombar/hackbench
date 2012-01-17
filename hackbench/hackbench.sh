set -e
set -u

die()
{
	echo $*
	exit 1
}

usage()
{
	cat <<EOF
$0 [-f] [-p|-t] [-P|-S] [-n <name>] [-m <max-sample>] TYPE BINARY
    TYPE	One of <light|medium|heavy>
    BINARY	Test binary
    -f		Overwrite existing results
    -p		Run only in \`process' mode
    -t		Run only in \'thread' mode
    -P		Only run with \`pipe'
    -S		Only run with \`socket'
    -n <name>	Name (default: \`uname -sr')
    -m <max>	Number of sample to take for each iteration (default: 10)
EOF
	exit 1
}

# modes
DO_PROCESS=1
DO_THREAD=1

# IPCs
DO_PIPE=1
DO_SOCKET=1

FORCE=0
MAXSAMPLE=10
RUN_NAME="$(uname -sr | sed 's/ /-/')"

while getopts fm:n:ptPS opt; do
	case "${opt}" in
	f)
		FORCE=1
		;;
	m)
		MAXSAMPLE="${OPTARG}"
		;;
	n)
		RUN_NAME="${OPTARG}"
		;;
	p)
		DO_THREAD=0
		;;
	t)
		DO_PROCESS=0
		;;
	P)
		DO_SOCKET=0;
		;;
	S)
		DO_PIPE=0
		;;
	*)
		usage
		;;
	esac
done
shift $(expr ${OPTIND} - 1)

MODES=
[ ${DO_PROCESS} = 1 ] && MODES="process ${MODES}"
[ ${DO_THREAD} = 1 ] && MODES="thread ${MODES}"

IPCS=
[ ${DO_PIPE} = 1 ] && IPCS="pipe ${IPCS}"
[ ${DO_SOCKET} = 1 ] && IPCS="socket ${IPCS}"

[ $# = 2 ] || usage

TYPE="$1"
HACKBENCH="$2"
shift 2

case "${TYPE}" in
	"light")
		NGROUPS="1 5 10 15 20 25 30 35"
		NLOOPS="100 200 300 400 500"
		;;
	"medium")
		NGROUPS="1 5 10 15 20 25 30 35 40 45 50 60 75 90 100"
		NLOOPS="100 200 300 400 500 600 700 800 900 1000"
		;;
	"heavy")
		NGROUPS="1 5 10 15 20 25 30 35 40 45 50 60 70 80 90 100 110 120 130 140 150"
		NLOOPS="100 200 300 400 500 600 700 800 900 1000 1100 1200 1300 1400 1500"
		;;
	"test")
		NGROUPS="1 5"
		NLOOPS="50 100"
		;;
	*)
		echo "unknown platform"
		exit 1
		;;
esac

MAX_NGROUP=${NGROUPS##* }
MAX_NLOOP=${NLOOPS##* }

if [ -e "${RUN_NAME}" ]; then
	if [ ${FORCE} = 1 ]; then
		rm -rf "${RUN_NAME}"
	else
		die "${RUN_NAME}: file exists "
	fi
fi

[ -x "${HACKBENCH}" ] || \
    die "Unable to find program"

mkdir "${RUN_NAME}"
cd "${RUN_NAME}"

for_each_mode()
{
	local _cb="$1"; shift
	local _mode

	for _mode in ${MODES}; do
		MODE=${_mode}
		"${_cb}" "$@"
	done
}

for_each_ipc()
{
	local _cb="$1"; shift
	local _ipc

	for _ipc in ${IPCS}; do
		IPC=${_ipc}
		"${_cb}" "$@"
	done
}

_hackbench()
{
	local _ngroup=$1
	local _nloop=$2

	${HACKBENCH} ${HACKBENCH_ARGS} ${_ngroup} ${MODE} ${_nloop}
}

dry_run()
{

	HACKBENCH_ARGS=
	[ "${IPC}" = "pipe" ] && HACKBENCH_ARGS="-pipe"

	echo "    - ${IPC}/${MODE}"
	_hackbench ${MAX_NGROUP} 1 > /dev/null
}

echo "* Running dry run..."

for_each_ipc \
    for_each_mode \
        dry_run

echo "* Done"

collect_sample()
{
	local _ngroup=$1
	local _nloop=$2
	local  _nsample=0

	while [ ${_nsample} != ${MAXSAMPLE} ]; do
		_sample=$(_hackbench ${_ngroup} ${_nloop} | sed '/:/!d; s/.*: //')
		echo "     - ${_sample}"
		_nsample=$((${_nsample}+1))
		echo -n "." >&2
	done
}

run()
{
	local _ngroup
	local _nloop

	[ "${IPC}" != "${OIPC:-}" ] && echo " ${IPC}:"
	echo "  ${MODE}:"

	for _ngroup in ${NGROUPS}; do
		echo "   ${_ngroup}:"
		echo "Running in \`${MODE}' mode using ${IPC} with ${_ngroup} groups..." >&2
		for _nloop in ${NLOOPS}; do
			echo -n "    ${_nloop} loops " >&2
			echo "    ${_nloop}:"
			collect_sample "${_ngroup}" "${_nloop}"
			echo >&2
		done
	done

	OIPC="${IPC}"
}

{
	echo "results:"
	for_each_ipc \
	    for_each_mode \
	        run
} > results.yml
