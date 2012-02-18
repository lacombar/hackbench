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
@basedir = ARGV[0]
@targetdir = ARGV[1]

def do_diff(ipc, mode)
	base_fname = "#{@basedir}/data/#{ipc}-#{mode}"
	target_fname = "#{@targetdir}/data/#{ipc}-#{mode}"

	base = File.open(base_fname)
	target = File.open(target_fname)

	output_fname = "#{@targetdir}/data/#{ipc}-#{mode}-normalized"
	output = File.open(output_fname, "w")

	base.each_line { |line|
		tline = target.gets
		
		avg_runtime = (tline.split[7].to_f / line.split[7].to_f) - 1
		avg_runtime = 0.0 if avg_runtime.nan? or avg_runtime.infinite?

		variance = (tline.split[8].to_f / line.split[8].to_f) - 1
		variance = 0.0 if variance.nan? or variance.infinite?

		stddev = (tline.split[9].to_f / line.split[9].to_f) - 1
		stddev = 0.0 if stddev.nan? or stddev.infinite?

		output.write "#{line.split[0]} #{line.split[1]} %.3f %.3f %.3f\n" %
		    [ avg_runtime, variance, stddev ]
	}
end

def do_mode(ipc)
	[ "process", "thread" ].each { |mode|
		do_diff(ipc, mode)
	}
end

def do_ipc()
	[ "pipe", "socket" ].each { |ipc|
		do_mode(ipc)
	}
end

do_ipc()

