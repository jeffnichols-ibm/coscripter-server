# (C) Copyright IBM Corp. 2010

class ProcedureComment < ActiveRecord::Base
    belongs_to :procedure
    belongs_to :person

    # ----------------------------------------------------------------------
    # Fulltext search
    # From http://wiki.rubyonrails.org/rails/pages/FullTextSearch

      # Takes a list of keywords, and optionally a list of column
      # names, and returns an array that can be used as the :conditions
      # argument in a normal Rails "find" call. We don't have to
      # worry about sanitization -- the "find" will handle all that.
      def self.keyword_conditions(keywords, cols = ['title', 'body'])
        conditions = []
        cond_args = [] 

        # If no columns specified, default to using
        # all the columns for this model.
        cols ||= columns.collect{|c| c.name}

        keywords.collect do |keyword|
          kw_cond = []

          cols.collect do |c|
            kw_cond << "#{c} LIKE ?" 
            cond_args << "%#{keyword}%" 
          end

          # Concatenate each condition for this keyword with
          # a logical OR.
          conditions << kw_cond.join(" OR ")
        end

        # Enclose the conditions for each keyword inside parens
        # and concatenate them with a logical AND.
        ["(" +conditions.join(') AND (') + ")"] + cond_args
      end

      # Takes a list of keywords, an optional list of columns, and 
      # order, limit, join arguments for the "find" call --
      # returns all the instances of this model that match.
      # If the columns argument is omitted, all columns are searched.
      def self.find_by_keywords(
          keywords, 
          cols = nil,
          orderings = nil, 
          limit = nil, 
          joins = nil
        )

        condition = keyword_conditions(keywords, cols)

        find(:all, :conditions => condition, :order => orderings,
          :limit => limit, :joins => joins)
      end

      # Behaves like find_by_keyword, but takes a string and splits
      # it into terms (this is only really useful if you augmented this
      # function to split the string more intelligently -- at the 
      # moment it just splits on spaces, but it could be made to respect 
      # quotes and use their contents as phrases, for instance.)
      def self.find_by_text(
          text, 
          cols = nil, 
          orderings = nil, 
          limit = nil, 
          joins = nil
        )
        keywords = text.split(' ')
        find_by_keywords(keywords, cols, orderings, limit, joins)
      end

end
