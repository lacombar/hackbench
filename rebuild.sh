#!/bin/sh
#
# Copyright (c) 2011, 2012 Arnaud Lacombe <lacombar@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

set -e
set -u

die()
{
	[ $# != 0 ] && echo "$*"
	exit 1
}

_list_runs()
{
	local _run

	find "runs" -mindepth 1 -maxdepth 1 -type d | \
	    sort | \
	    while read _run; do
		[ -f "${_run}/results.yml" ] && echo ${_run##*/}
	done
}

list_runs()
{

	if [ -n "${RUNS_OVERRIDE:-}" ]; then
		echo "${RUNS_OVERRIDE}"
		return 0
	fi

	_list_runs "$@"
}

list_results()
{
	local _result

	find "data" -name '*.*' | while read _result; do
		echo ${_result##*/}
	done
}

for_each_run()
{
	local _cb=$1; shift
	local _cwd=$(pwd)
	local _runs=$(list_runs)

	list_runs | while read _run; do
		RUN=${_run}

		cd "runs/${_run}"
		${_cb} "$@"
		cd "${_cwd}"
	done
}

_list_platforms()
{
	local _cwd=$(pwd)
	local _pwd
	local _platform

	_pwd=${_cwd%/*}
	[ "${_pwd##*/}" = "arch" ] || die

	find "." -maxdepth 1 -mindepth 1 -type d | \
	    sort | \
	    while read _platform; do
		echo ${_platform##*/}
	    done
}

list_platforms()
{

	if [ -n "${PLATFORMS_OVERRIDE:-}" ]; then
		echo "${PLATFORMS_OVERRIDE}"
		return 0
	fi

	_list_platforms
}

for_each_platform()
{
	local _cb=$1; shift
	local _platform

	list_platforms | while read _platform; do
		[ -d "${_platform}" ] || \
		    die "${_platform}: no such directory"

		PLATFORM=${_platform}

		local _cwd=$(pwd)

		cd "${_platform}";
		${_cb} "$@"
		cd "${_cwd}"
	done
}

_list_arch()
{
	local _cwd=$(pwd)
	local _arch

	[ "${_cwd##*/}" = "arch" ] || die

	find "." -maxdepth 1 -mindepth 1 -type d | \
	    sort | \
	    while read _arch; do
		echo ${_arch##*/}
	done
}

list_arch()
{

	if [ -n "${ARCHS_OVERRIDE:-}" ]; then
		echo "${ARCHS_OVERRIDE}"
		return 0
	fi

	_list_arch
}

for_each_arch()
{
	local _cb=$1; shift
	local _arch

	cd "arch"

	list_arch | while read _arch; do
		[ -d "${_arch}" ] || \
		    die "${_platform}: no such directory"

		ARCH=${_arch}

		local _cwd=$(pwd)

		cd "${_arch}";
		${_cb} "$@"
		cd "${_cwd}"
	done

	cd ..
}

for_each_ipc()
{
	local _cb=$1; shift
	local _ipc

	for _ipc in pipe socket; do
		${_cb} "$@" ${_ipc}
	done
}

for_each_mode()
{
	local _cb=$1; shift
	local _mode

	for _mode in process thread; do
		${_cb} "$@" ${_mode}
	done
}

find_template()
{
	local _script="$1"
	local _template

	for _template in ${TEMPLATES_DIR}/*; do
		_base=${_template##*/}
		_base=${_base%%.*}

		if [ -z "${_script%%*${_base}*}" ]; then
			echo "${_template}"
			return 0
		fi
	done
}

generate_run_results()
{

	${RESULTS_SCRIPT_INTERPRETER} ${RESULTS_SCRIPT_INTERPRETER_ARGS} \
	    ${RESULTS_SCRIPT} .
}

LT=1
plot_one_candlesticks()
{
	local _data="$1"; shift
	local _title="${1:-}"

	_title="title \"${_title}\""
	echo -n "'${_data}' using 1:4:3:7:6 with candlesticks lt ${LT} lw 1 notitle,"
	echo -n "'${_data}' using 1:5 with point lt ${LT} notitle, "
	echo -n "'${_data}' using 1:8 with lines lt ${LT} ${_title}"
	LT=$((${LT}+1))
}

generate_run_script_by_ipc()
{
	local _nloop="$1"; shift
	local _ipc="$1"
	local _process_data
	local _thread_data
	local _image
	local _script

	_process_data="data/${_ipc}-process.${_nloop}"
	_thread_data="data/${_ipc}-thread.${_nloop}"

	[ -e "${_process_data}" -a -e "${_thread_data}" ] || \
	    return 0

	# generate ...
	_script="scripts/${_ipc}.${_nloop}.gplot"
	_image="images/${_ipc}.${_nloop}.png"

	cat <<EOF > "${_script}"
set terminal png size 800, 300
set ylabel "time (s)"
set xlabel "ngroup"
set boxwidth 1.5 absolute
set key left top vertical Left reverse enhanced
set output '${_image}'
plot \\
EOF
	{
		plot_one_candlesticks "${_process_data}" "Process"
		echo -n ", " >> "${_script}"
		plot_one_candlesticks "${_thread_data}" "Thread"
		LT=1
	} >> "${_script}"
}

generate_run_script_by_mode()
{
	local _nloop="$1"; shift
	local _mode="$1"
	local _pipe_data
	local _socket_data
	local _image
	local _script

	_pipe_data="data/pipe-${_mode}.${_nloop}"
	_socket_data="data/socket-${_mode}.${_nloop}"

	[ -e "${_pipe_data}" -a -e "${_socket_data}" ] || \
	    return 0

	# generate ...
	_script="scripts/${_mode}.${_nloop}.gplot"
	_image="images/${_mode}.${_nloop}.png"

	cat <<EOF > "${_script}"
set terminal png size 800, 300
set ylabel "time (s)"
set xlabel "ngroup"
set boxwidth 1.5 absolute
set key left top vertical Left reverse enhanced
set output '${_image}'
plot \\
EOF
	{
		plot_one_candlesticks "${_pipe_data}" "Pipe"
		echo -n ", " >> "${_script}"
		plot_one_candlesticks "${_socket_data}" "Socket"
		LT=1
	} >> "${_script}"
}

generate_one_run_map()
{
	local _script="$1"
	local _image="$2"
	local _data="$3"
	local _max_ngroup="$4"
	local _max_nloop="$5"
	local _title="$6"

	cat <<EOF > "${_script}"
set xrange [0:${_max_ngroup}]
set yrange [0:${_max_nloop}]
set terminal png size 800, 300
set output '${_image}'
set palette rgbformulae -3,-3,-7
set title "${_title}"
set multiplot
set origin 0,0
set size 0.7,1
plot '${_data}' using 1:2:8 with image notitle
set noxtics
set noytics
set notitle
set origin 0.65,0.5
set size 0.35,0.5
set label 1 "variance" at 0,-150
plot '${_data}' using 1:2:9 with image notitle
set origin 0.65,0.0
set size 0.35,0.5
set label 1 "stddev"
plot '${_data}' using 1:2:10 with image notitle
set nomultiplot
EOF
}

generate_one_normalized_run_map()
{
	local _script="$1"
	local _image="$2"
	local _data="$3"
	local _max_ngroup="$4"
	local _max_nloop="$5"
	local _title="$6"

	cat <<EOF > "${_script}"
set xrange [0:${_max_ngroup}]
set yrange [0:${_max_nloop}]
set terminal png size 800, 300
set output '${_image}'
set palette defined (-1 "#00bb00", -0.5 "#00bb00", 0 "#ffffff", 0.5 "#bb0000", 1 "#bb0000")
set cbrange [-1:1]
set title "${_title}"
set multiplot
set origin 0,0
set size 0.7,1
plot '${_data}' using 1:2:3 with image notitle
set noxtics
set noytics
set notitle
set origin 0.65,0.5
set size 0.35,0.5
set label 1 "variance" at 0,-150
plot '${_data}' using 1:2:4 with image notitle
set origin 0.65,0.0
set size 0.35,0.5
set label 1 "stddev"
plot '${_data}' using 1:2:5 with image notitle
set nomultiplot
EOF
}

generate_run_map()
{
	local _ipc=$1; shift;
	local _mode=$1; shift;
	local _max_ngroup
	local _max_nloop
	local _data
	local _image
	local _script
	local _normalized_script

	_data="data/${_ipc}-${_mode}"
	[ -e "${_data}" ] || return 0

	_script="scripts/${_ipc}-${_mode}.gplot"
	_image="images/${_ipc}-${_mode}.png"
	_title="${RUN} (${_ipc} / ${_mode})"

	_max_ngroup="$(tail -1 "${_data}" | awk '{print $1}')"
	_max_nloop="$(tail -1 "${_data}" | awk '{print $2}')"

	generate_one_run_map "${_script}" "${_image}" "${_data}" \
	    "${_max_ngroup}" "${_max_nloop}" "${_title}"

	_data="data/${_ipc}-${_mode}-normalized"
	[ -e "${_data}" ] || return 0

	_script="scripts/${_ipc}-${_mode}-normalized.gplot"
	_image="images/${_ipc}-${_mode}-normalized.png"

	generate_one_normalized_run_map "${_script}" "${_image}" "${_data}" \
	    "${_max_ngroup}" "${_max_nloop}" "${_title}"

}

generate_run_scripts()
{
	local _image
	local _data
	local _result
	local _script
	local _mode

	list_results | \
	    sed 's/.*\.//' | \
	    sort -u | \
	    while read _nloop; do
		for_each_ipc \
		    generate_run_script_by_ipc "${_nloop}"
	done

	list_results | \
	    sed 's/.*\.//' | \
	    sort -u | \
	    while read _nloop; do
		for_each_mode \
		    generate_run_script_by_mode "${_nloop}"
	done

	for_each_ipc \
	    for_each_mode \
	        generate_run_map
}

plot_run_results()
{
	local _script

	for _script in scripts/*.gplot; do
		gnuplot ${_script}
	done
}

sum_runtime()
{
	local parsed_results=$1

	{
		cat "${parsed_results}" | \
		    awk '{ print $8 }' | \
		    tr '\n' '+'; echo 0
	} | bc
}

compute_mode_runtime()
{
	local _ipc="$1"; shift
	local _mode="$1"

	echo -n "${_mode} ";
	for_each_run \
	    compute_run_time "${_ipc}" "${_mode}"
	echo
}

compute_run_time()
{
	local _ipc="$1"
	local _mode="$2"
	local _data="data/${_ipc}-${_mode}"

	runtime=0
	[ -e "${_data}" ] && runtime=$(sum_runtime "${_data}")
	echo -n "${runtime} "
}

output_runtime_header()
{
	echo -n "${RUN} "
}

generate_runtime_results()
{
	local _ipc="$1"
	local _data="data/${_ipc}-runtime"
	local _script="scripts/runtime-${_ipc}.gplot"
	local _image="images/runtime-${_ipc}.png"
	local _run

	{
		echo -n "_ "
		for_each_run \
		    output_runtime_header "${_ipc}"
		echo


		for_each_mode \
		    compute_mode_runtime "${_ipc}"
	} > "${_data}"

	{
		ncol=$(head -1 "${_data}" | wc -w)
		i=2
		echo "set output '${_image}'"
		echo "plot \\"
		while [ $i -lt $ncol ]; do
			echo "    '${_data}' using $i ti col, \\"; i=$(($i+1))
		done

		echo "    '${_data}' using $ncol:key(1)"
	} > "${_script}"

}

generate_combined_run_result()
{
	local _pwd=$(pwd)
	local _data="${_pwd}/data/$1"

	[ -e "${_data}" ] || return 0

	plot_one_candlesticks "${_data}" "${_run}"
	echo -n ", "
}

generate_combined_results()
{
	local _ipc="$1"
	local _loop_data

	for_each_run list_results | \
	    sort -u |
	    while read _loop_data; do
		local _image="images/combined-${_loop_data}.png"
		local _script="scripts/combined-${_loop_data}.gplot"

		{
			echo "set output '${_image}'"
			echo "plot \\"
		} > "${_script}"

		for_each_run \
		    generate_combined_run_result "${_loop_data}" | \
		        sed 's/..$//' >> "${_script}"
		LT=1
	done
}

plot()
{
	local _script

	for _script in scripts/*.gplot; do
		local _template=$(find_template "${_script}")
		gnuplot ${_template} ${_script}
	done

}

RESULTS_SCRIPT_INTERPRETER="ruby"
RESULTS_SCRIPT_INTERPRETER_ARGS="-I$(pwd)/scripts"
RESULTS_SCRIPT="$(pwd)/scripts/parse-results.rb"

COMBINED_RESULTS_TEMPLATE="$(pwd)/templates/combined-results.gplot"
RUNTIME_RESULTS_TEMPLATE="$(pwd)/templates/runtime.gplot"
TEMPLATES_DIR="$(pwd)/templates"

DO_GENERATE=1
DO_PLOT=1

do_list_platforms()
{
	echo " * ${ARCH}"
	list_platforms
}

do_list_runs()
{

	echo " * ${ARCH} - ${PLATFORM}"
	list_runs
}

list()
{
	case $1 in
	"arch")
		list_arch
		;;
	"platforms")
		for_each_arch \
		    do_list_platforms
		;;
	"runs")
		for_each_arch \
		    for_each_platform \
		        do_list_runs
	esac
}

while getopts A:gl:pP:R: opt
do
	case ${opt} in
	A)
		ARCHS_OVERRIDE="$(echo ${OPTARG} | sed 's/,/ /g')"
		;;
	g)
		DO_PLOT=0
		;;
	l)
		LIST=${OPTARG}
		;;
	p)
		DO_GENERATE=0
		;;
	P)
		PLATFORMS_OVERRIDE="$(echo ${OPTARG} | sed 's/,/ /g')"
		;;
	R)
		RUNS_OVERRIDE="$(echo ${OPTARG} | sed 's/,/ /g')"
		;;
	*)
		usage
		;;
	esac
done
shift $(expr ${OPTIND} - 1)

if [ -n "${LIST:-}" ]; then
	list ${LIST}
	exit
fi

check_directories()
{
	for _dir in images data scripts; do
		[ -e "${_dir}" ] || mkdir "${_dir}"
	done
}

for_each_arch \
    for_each_platform \
        for_each_run \
            check_directories

for_each_arch \
    for_each_platform \
        check_directories

if [ ${DO_GENERATE} = 1 ]; then
	echo "* Generating results ..."
	for_each_arch \
	    for_each_platform \
	        for_each_run \
	            generate_run_results

	echo "* Generating scripts ..."

	for_each_arch \
	    for_each_platform \
	        for_each_run \
	            generate_run_scripts

	for_each_arch \
	    for_each_platform \
	        for_each_ipc \
	            generate_runtime_results

	for_each_arch \
	    for_each_platform \
	        for_each_ipc \
	            generate_combined_results
fi

if [ ${DO_PLOT} = 1 ]; then
	echo "* Plotting ..."

	for_each_arch \
	    for_each_platform \
	        for_each_run \
	            plot

	for_each_arch \
	    for_each_platform \
	        plot
fi
