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
require 'yaml'
require 'ministat'

def parse_results(results)
	results.keys.each { |ipc|
		modes=results[ipc]
		modes.keys.sort.each { |mode|
			output_name = "#{@outdir}/data/#{ipc}-#{mode}"
			output = File.open(output_name, "w")

			nloop_output_mode = "w"

			ngroups = modes[mode]
			ngroups.keys.sort.each { |ngroup|
				nloops = ngroups[ngroup]
				nloops.keys.sort.each { |nloop|
					nloop_output_name = "#{output_name}.#{nloop}"
					nloop_output = File.open(nloop_output_name, nloop_output_mode)

					s = MiniStat::Data.new(nloops[nloop])

					line = "#{ngroup} #{nloop} #{s}\n"

					output.write line
					nloop_output.write line
					nloop_output.close
				}
				nloop_output_mode = "a+"
			}
			output.close
		}
	}
	return
end

@basedir = ARGV[0]
if @basedir.nil?
	@basedir = "."
end

@outdir = ENV['O']
if @outdir.nil?
	@outdir = "."
end

@data = YAML.load(File.open("#{@basedir}/results.yml")).to_hash

@data.each_pair { |k, v|
	if k == "results"
		parse_results(v)
	end
}
