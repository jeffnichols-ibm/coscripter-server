#!/usr/bin/ruby
# (C) Copyright IBM Corp. 2010

require 'algorithm/diff'
require 'pp'

DEBUG = false

def debug(s)
	if DEBUG
		if s.class == String
			puts s
		else
			pp(s)
		end
	end
end

def getdiff(l1, l2)
	diff = l1.diff(l2)
	if diff.length == 0
		return l1.zip([' ']*l1.length)
	end

	firstdiff = diff[0][1]

	output = Array.new(l1)
	output = output.zip([' '] * l1.length)
	debug(output)
	debug(diff)

	# Process removed lines first
	for d in diff
		if d[0] == :-
			for i in (0..d[2].length-1)
				debug("Trying to - output[#{d[1]+i}]")
				output[d[1]+i][1] = '-'
			end
		end
	end

	debug(diff)

	# Now process added lines
	for d in diff
		if d[0] == :+
			debug("Trying to + output[#{d[1]}]")
			index = 0
			numlines = 0
			# walk along output, counting non-minus lines, until we reach
			# d[1]
			while numlines < d[1]
				if output[index][1] != '-'
					numlines += 1
					debug("numlines is now #{numlines}")
				end
				index += 1
				debug("index is now #{index}")
			end
			debug("PRE index in output is #{index}")
			while index < output.length && output[index][1] == '-'
				index += 1
			end
			debug("POST index in output is #{index}")
			output[index, 0] = d[2].zip(['+'] * d[2].length)
		end
	end

return output

end

# Main
if $0 == __FILE__
	file1 = ARGV.shift
	file2 = ARGV.shift

	lines1 = open(file1).readlines
	lines2 = open(file2).readlines

	output = getdiff(lines1, lines2)

	for line in output
		puts "#{line[1]}#{line[0]}"
	end
end
