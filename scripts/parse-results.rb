require 'yaml'
require 'ministat'

def parse_results(results)
	results.keys.each { |ipc|
		modes=results[ipc]
		modes.keys.sort.each { |mode|
			output_name = "#{@basedir}/data/#{ipc}-#{mode}"
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

@data = YAML.load(File.open("#{@basedir}/results.yml")).to_hash

@data.each_pair { |k, v|
	if k == "results"
		parse_results(v)
	end
}
