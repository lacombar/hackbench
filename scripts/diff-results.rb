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

[ "process", "thread" ].each { |type|
	base_fname = "#{@basedir}/data/#{type}"
	target_fname = "#{@targetdir}/data/#{type}"

	base = File.open(base_fname)
	target = File.open(target_fname)

	output_fname = "#{@targetdir}/data/#{type}-normalized"
	output = File.open(output_fname, "w")

	base.each_line { |line|
		tline = target.gets
		output.write "#{line.split[0]} #{line.split[1]} %.3f\n" % (tline.split[7].to_f / line.split[7].to_f)
	}
}

