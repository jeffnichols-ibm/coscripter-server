# (C) Copyright IBM Corp. 2010

class Procedure < ActiveRecord::Base
    belongs_to :person
    has_many :tags
    has_many :procedure_views
    has_many :procedure_executes
    has_many :procedure_comments
    has_many :usage_logs
    has_one  :best_bet, :dependent => :destroy
    has_many :changes
    has_and_belongs_to_many :favorite_scripts,
      :class_name => "Person",
      :join_table => "favorite_scripts",
      :foreign_key => "procedure_id",
      :association_foreign_key => "person_id",
      :uniq => true
    has_and_belongs_to_many :scratch_space_tables
    has_and_belongs_to_many :members , 
	      :class_name => "Person",
	      :join_table => "procedure_memberships", 
	      :foreign_key => "procedure_id", 
	      :association_foreign_key =>"person_id",
	      :uniq => true 

    # for the "recent" view
    def self.by_modification
	find(:all,
	    :order => 'modified_at desc')
    end

    # Find procedures referencing a particular url
    def self.byurl(url)
		# TODO: truncate url and search for toplevel domain too
		base_url = URI.parse(url)
		if not base_url.path.nil?
			   base_url.path = ""
			end
		@ret = find(:all, 
			:conditions => self.keyword_conditions([url],
			cols=['body']),
			:order => 'modified_at desc')
			# also search on pure hostname alone
			if not base_url.host.nil?
			  @ret += find(:all,
				  :conditions => self.keyword_conditions([base_url.host],
					  cols=['body']),
				  :order => 'modified_at desc')
			end
			# return only unique matching scripts
		@ret.uniq
    end

    # ----------------------------------------------------------------------
    # For the _procview page
    def clean_tags
        clean_tags_set = SortedSet.new
        for tag in self.tags
            clean_tags_set.add(tag.clean_name)
        end
        clean_tags_set
    end


    def executors
      Person.find(:all,:select=> "distinct people.id,people.name",:joins=>"inner join procedure_executes on procedure_executes.person_id = people.id",:conditions => ["procedure_executes.procedure_id=?",id]).collect{|p| p.name}.join(',')
    end

    def related_via_views
	# find me the top 3 procedures that people view that have also viewed this procedure
 	also_viewed_procedures = Procedure.find_by_sql("select procedures.* from procedures inner join procedure_views on procedures.id = procedure_views.procedure_id where procedure_views.person_id in (select distinct people.id from people inner join procedure_views on people.id=procedure_views.person_id where procedure_views.procedure_id=#{self.id} and procedure_views.person_id not in (select id from administrators)) group by procedures.id order by count(procedure_views.id)  desc limit 3")
	return also_viewed_procedures 

    end

    def related_via_modifications
        # find me the top 3 procedures that people modified that have also modified this procedure
        also_modified_procedures = Procedure.find_by_sql("select procedures.*,count(changes.id) as changed from procedures inner join changes on procedures.id = changes.procedure_id where changes.person_id in (select distinct people.id from people inner join changes on people.id=changes.person_id where changes.procedure_id=#{self.id} and changes.person_id not in (select id from administrators)) group by procedures.id order by count(changes.id)  desc limit 3")
        return also_modified_procedures 

    end

    def related_via_executions
      also_executed_procedures = Procedure.find_by_sql("select procedures.title,count(procedure_executes.id) as executed from procedures inner join procedure_executes on procedures.id = procedure_executes.procedure_id where procedure_executes.person_id in (select distinct people.id from people inner join procedure_executes on people.id=procedure_executes.person_id where procedure_executes.procedure_id=131 and procedure_executes.person_id not in (select id from administrators)) group by procedures.id order by count(procedure_executes.id)  desc limit 3")
      return also_executed_procedures
    end
    # ----------------------------------------------------------------------
    # Set title if it's blank
    def before_save
	if self.title == "" or self.title.nil?
	    self.title = '(no title)'
	end
	if self.body.nil?
	    self.body = ''
	end
    end

    # ----------------------------------------------------------------------
    # Fulltext search
    # From http://wiki.rubyonrails.org/rails/pages/FullTextSearch

      # Takes a list of keywords, and optionally a list of column
      # names, and returns an array that can be used as the :conditions
      # argument in a normal Rails "find" call. We don't have to
      # worry about sanitization -- the "find" will handle all that.
      def self.keyword_conditions(keywords, cols = ['title', 'body'],
	connector = "AND")
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
        # and concatenate them with a logical connector (default AND).
        ["(" +conditions.join(") #{connector} (") + ")"] + cond_args
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
        logger.info("Search condition: <#{condition}>")

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

      # Takes a list of keywords as argument
      def self.find_approximate(keywords)
        if keywords.class == Array
          searchterm = keywords.join(" ")
        elsif keywords.class == String
          searchterm = keywords
        else
          raise RuntimeError, "Keywords type not recognized"
        end
        find(:all, :conditions => ["match(title,body) against (?)",
          searchterm])
#        condition = keyword_conditions(keywords, cols = ['title', 'body'],
#          connector = "OR")
#        find_all(condition)
      end

    def salient_words
      text = "#{self.title} #{self.body}"
      # tokenize and lowercase
      words = text.split(/[^\w][^\w]*/).collect{ |w| w.downcase }
      # remove short words
      words = words.delete_if { |w| w.length < 3 }
      # remove duplicates
      words = words & words
      # remove stopwords
      stopwords = ['click', 'you', 'the', 'if', 'link', 'window',
        'button', 'textbox', 'field', 'listbox', 'select', 'enter', 'your',
        'into', 'check', 'radio', 'and', 'how', 'to', 'in', 'of', 'this',
        'that', 'have']
      words.delete_if { |w| stopwords.include? w }
    end

    # ----------------------------------------------------------------------
    # For the stats page

    def distinct_views
	viewers = {}
	for view in self.procedure_views
	    viewers[view.person_id] = 1
	end
	viewers.length
    end

    def distinct_runs
      runners = ProcedureExecute.find_by_sql("select distinct person_id from procedure_executes where procedure_id=#{self.id}")
      runners.length
    end

  def num_steps
    return self.steps.length
  end

  def steps
    if self.body.nil?
      return [] 
    end
    body = self.body.strip
    index = body.index('*')
    if index.nil?
      return []
    end
    body = "\n" + body + "\n"
    slopsteps = body.split("\n*")
    slopsteps.delete_at(0)
    slopsteps = slopsteps.collect{|s| 
		i = s.index("\n")
		if not i.nil?
			s = s.slice(0, i)
		end
		s = s.strip
		s
	}
    return slopsteps
  end
  
  def self.procedures_sorted_by(sortorder='usage',page=1,per_page=20)
    case sortorder
    when 'usage'
      find_options = {:order=>"last_executed_at DESC",:include=>:person}
    when 'created'
      find_options = {:order=>"procedures.created_at DESC",:include=>:person}
    when 'modified'
      find_options = {:order=>"modified_at DESC",:include=>:person}
    when 'creator'
      find_options = {:joins => "inner join people on people.id = procedures.person_id",:order=>"people.name",:include=>:person}
    when 'favorite'
      find_options = {:joins => "inner join favorite_scripts on procedures.id = favorite_scripts.procedure_id",:include=>:person , :group => "procedures.id", :order => "count(procedures.id) DESC"}
    when 'popularity'
      find_options = {:order=>"popularity DESC",:include=>:person}
    end
    if per_page == "all"
      per_page == -1 
    end

    if per_page.to_i == -1 
      procedures = Procedure.find(:all,find_options)
    else
      find_options[:per_page] = per_page
      find_options[:page] = page
      procedures = Procedure.paginate(:all,find_options)
    end
    return procedures
  end

    def first_execution
      return self.created_at
    end

    def most_recent_execution
      return self.last_executed_at
    end
    # ----------------------------------------------------------------------
    # Sort order
    def most_recent_usage
      if self.last_executed_at.nil? 
	return self.modified_at
      else
        return [self.modified_at, self.last_executed_at].max
      end
    end

    # ----------------------------------------------------------------------
    # For private pages
    # Intended usage:
    #    Procedure.with_privacy(session[:user_id]) {
    #       ... code in controller to find procedures ...
    #    }
    def self.with_privacy(person_id = nil)
      if person_id.nil?
        person = nil
      else
        person = Person.find(person_id)
      end
      if person.nil?
        scope = { :find => { :conditions => ["procedures.private = false"] } }
      else
         scope = { 
	   :find => { 
	     :select => "DISTINCT procedures.*",
	     :joins => "LEFT OUTER JOIN procedure_memberships ON procedure_memberships.procedure_id = procedures.id ",
	     :conditions => [
                "(procedures.private = false or procedures.person_id = ? or procedure_memberships.person_id = ?)", person_id, person_id ] } }
      end
      Procedure.with_scope(scope) { yield }
    end

    # Return a sorted array of [procedure, # times run] for all the
    # procedures that were run in the past week
    def self.run_in_last_week(person = nil)
      with_privacy(person) {
        e = ProcedureExecute.find(:all, :conditions => ["executed_at > ?",
          Time.now.utc - 1.week])
        # delete any executes for procedures that no longer exist
        e = e.delete_if {|prex| prex.procedure.nil?}
        procs = {}
        procs.default = 0
        e.each { |prex| procs[prex.procedure] += 1}
        procs = procs.sort { |x, y| y[1] <=> x[1] }
        return procs
      }
    end

end
