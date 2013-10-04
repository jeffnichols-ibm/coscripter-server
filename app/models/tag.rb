# (C) Copyright IBM Corp. 2010

class Tag < ActiveRecord::Base
    belongs_to :procedure
    belongs_to :person

    # for the search box
    def self.find_by_keyword(query)
        if query.class == Array
          words = query
        elsif query.class == String
	  words = query.split(/ +/)
        else
          raise RuntimeError, "Query argument type not recognized"
        end
	results = words.map { |word| find_all_by_clean_name(word) }
	return results.flatten.uniq.map {|tag| tag.procedure}
    end

    # Common code for tags
    # TODO clean_name should be created when raw_name is assigned,
    # and should be read-only
    def self.create_clean_name(raw_tag)
	clean_tag = raw_tag.downcase
	clean_tag.gsub!(/\s|!|#|\$|\%|&|'|\(|\)|\*|\+|,|-|\.|\/|:|;|<|=|>|\?|@|\[|\\|\]|\^|_|`/, "")
	return clean_tag
    end

    # Split raw user input into an array of raw tag names
    def self.split_into_raw_tags(raw_tag_str)
	words = raw_tag_str.split()
	quoted_word_indices = []

	phrase_start_index = -1
	0.upto(words.length - 1) do |word_index|
	    word = words[word_index]
	    0.upto(word.length - 1) do |char_index|
		char = word[char_index, 1]
		if char == '"'
		    if phrase_start_index == -1
			phrase_start_index = word_index
		    else
			if phrase_start_index != word_index
			    quoted_word_indices.push({:from => phrase_start_index, :to => word_index})
			end
			phrase_start_index = -1
		    end
		end
	    end
	end

	(quoted_word_indices.length - 1).downto(0) do |i|
	    words[quoted_word_indices[i][:from]] =
		words[quoted_word_indices[i][:from]] + " " + words[quoted_word_indices[i][:to]]
	    words.slice!(quoted_word_indices[i][:to])
	end

	words.each do |word|
	    word.gsub!(/"/, '')
	end

	return words
    end
end
