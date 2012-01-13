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

