# (C) Copyright IBM Corp. 2010

require 'pp'

class Person < ActiveRecord::Base
	has_many :procedures
	has_many :procedure_views
	has_many :procedure_executes
	has_many :procedure_comments
	has_many :changes
	has_many :usage_logs
	has_one  :administrator
	has_many :user_datas
	has_and_belongs_to_many :favorite_scripts,
	    :class_name => "Procedure",
	    :join_table => "favorite_scripts",
	    :association_foreign_key => "procedure_id",
	    :foreign_key => "person_id",
	    :uniq => true
	has_many :wishes
	has_many :wish_comments
	has_and_belongs_to_many :friends,
		:class_name => "Person",
		:join_table => "friends_people",
		:association_foreign_key => "friend_id",
		:foreign_key => "person_id",
		:uniq => true
		
	has_and_belongs_to_many :procedure_memberships, 
		:class_name => "Procedure",
		:join_table => "procedure_memberships", 
		:foreign_key => :person_id, 
		:association_foreign_key =>"procedure_id",
		:uniq => true 

	# for the search box ... find someone whose name or email matches the
	# query
	def self.search_by_term(query)
		wildcard_query = '%' + query + '%'
		# For internal users, profile_id is the e-mail address. There's no 
		# way for external users to search for e-mail addresses, which is good.
		find(:all,
			:conditions => ['name like ? or profile_id like ?',
			wildcard_query, wildcard_query])
	end

	# return list of all people ordered by number of procedures created
	def self.most_popular(find_options = {:page=>1} )
                find_options.merge({})
		ret = paginate(:all,find_options)
		#ret.delete_if { |x| x.procedures.length == 0 }
		#ret.sort { |x, y| y.procedures.length <=> x.procedures.length }
	end

	def email
		$profile.email_by_person(self)
	end

	# This one is expensive on the WI profile
	def self.find_by_email(email)
		$profile.person_by_email(email)
	end

	# Does one lookup if using WI profile, partially expensive
	def self.profile_id_for_email(email)
		$profile.profile_id_for_email(email)
	end

	# Create a new Person object given their email address
	def self.new_by_email(email,displayname=nil)
		creator = Person.new
		if displayname.nil?
			creator.name = $profile.name_for_email(email) 
		else
			creator.name = displayname
		end
		creator.profile_id = Person.profile_id_for_email(email)
		creator.save
		creator
	end
	
	# Create a new Person object given their profile_id
	def self.new_by_profile_id(profile_id,displayname=nil)
		creator = Person.new
		if displayname.nil?
			creator.name = $profile.name_for_email(email) 
		else
			creator.name = displayname
		end
		creator.profile_id = profile_id
		creator.save
		creator
	end

	def all_procedure_comments
		comments = []
		self.procedures.each { |p|
			comments = comments + p.procedure_comments
		}
		comments.sort { |x, y|
			y.updated_at <=> x.updated_at
		}
	end

	def update_friends
	  network = []
	  network.uniq!
	  self.friends = network 
	end

	# this will update selected peoples friends from the social network
	# providers, use like this:
	# Person.update_friends(:all, :conditions=>["last_active_at>?","2009-01-10 00:00:00"])
	def self.update_friends(*args)
	  people = Person.find *args
	  people.each{|p| p.update_friends }
	end

	# Returns a hash with three keys: created, executed, and modified
	# Each key value is an array of NetworkActivity instances
	def social_network_activity(options = {})
		days = (options[:days].nil?)?1:options[:days]
		limit = (options[:limit].nil?)?15:options[:limit]
		if options[:social_network].nil?
		  sn = social_network
		  if not options[:include_self].nil? and options[:include_self]
			  sn << self
		  end
		else
		  sn = options[:social_network]
		end

		ids = sn.collect{|f| f.id}
		network_activity = { :executed=>[],:created=>[],:modified=>[]} 
		if ids.length == 0 
		  return network_activity
		end 
		procedure_executions = ProcedureExecute.find(   
			:all,
			:select => "*,count(id) as reps",
			:conditions => ["procedure_executes.person_id in (?)",ids],
			:include => [:procedure,:person],
			:order => "procedure_executes.executed_at desc",
			:group => "procedure_executes.person_id,procedure_executes.procedure_id,date(procedure_executes.executed_at)",
			:limit => limit)

		procedure_executions.each { |pe|
			# Ignore executions of procedures that no longer exist
			if not pe.procedure.nil?
				network_activity[:executed] << NetworkActivity.new(
					pe.executed_at,
					pe.person,
					"ran",
					(pe.procedure.private) ? nil : pe.procedure,pe.attributes['reps'])
					# logger.info("reps: #{pe.attributes['reps']}")
			end
		}

		procedure_creations = Procedure.find(
			:all,
			:conditions =>[ "procedures.person_id in (?)",ids],
			:include => [:person],
			:order => "procedures.created_at desc",
			:limit => limit)

		procedure_creations.each { |pc|
			network_activity[:created]<< NetworkActivity.new(pc.created_at, pc.person,
				"created" , (pc.private) ? nil : pc)
		}

		procedure_modifications = Change.find(
			:all,
			:select => "*,count(id) as reps",
			:conditions => ["changes.person_id in (?) ",ids],
			:include => [:person,:procedure],
			:group => "changes.person_id,changes.procedure_id,date(changes.modified_at)",
			:order => "changes.modified_at desc",
			:limit => limit)

		procedure_modifications.each{ |pm|
			# Ignore changes to procedures that have been deleted
			if not pm.procedure.nil?
				network_activity[:modified]<< NetworkActivity.new(
					pm.modified_at , pm.person, "modified" ,
					(pm.procedure.private) ? nil : pm.procedure,pm.attributes['reps'])
			end
		}

		return network_activity
	end

	# Returns a hash with three keys: created, executed, and modified
	# Each key value is an array of NetworkActivity instances
	def social_network_activity_recent(startdate)
#		start = startdate.strftime('%Y-%m-%d %H:%M:%S')
		sn = social_network
		ids = sn.collect{|f| f.id}.join(',')
		network_activity = { :executed=>[],:created=>[],:modified=>[]} 
		if ids.length == 0 
		  return network_activity
		end 

		procedure_executions = ProcedureExecute.find(   
			:all,
			:conditions =>["person_id in (?) and executed_at >= ? ",ids,startdate],
			:group => "person_id,procedure_id,date(executed_at)"
			)

		procedure_executions.each { |pe|
			# Ignore executions of procedures that no longer exist
			if not pe.procedure.nil? and not pe.procedure.private?
				network_activity[:executed] << NetworkActivity.new(
					pe.executed_at,
					pe.person,
					"ran",
					pe.procedure,
					1)
			end
		}

		procedure_creations = Procedure.find(
			:all,
			:conditions => ["procedures.person_id in (?) and created_at >= ?",ids,startdate]
			)
		procedure_creations.each { |pc|
			network_activity[:created]<< NetworkActivity.new(pc.created_at, pc.person,
				"created" , (pc.private) ? nil : pc)
		}

		procedure_modifications = Change.find(
			:all,
			:conditions => ["person_id in (?) and modified_at >= ?",ids,startdate],
			:group => "person_id,procedure_id,date(modified_at)"
			)
		procedure_modifications.each{ |pm|
			# Ignore changes to procedures that have been deleted
			if not pm.procedure.nil?
				network_activity[:modified]<< NetworkActivity.new(
					pm.modified_at , pm.person, "modified" ,
					(pm.procedure.private) ? nil : pm.procedure,
					1)
			end
		}

		return network_activity
	end

	# Returns a list of wishes made by people in your social network since
	# the specified startdate (or use nil if you want all)
	def social_network_wishes(startdate = nil)
		sn = social_network
		if sn.length == 0
			return []
		end
		ids = sn.collect{|f| f.id}.join(',')
		if not startdate.nil?
			conditions = ["wishes.person_id in (?) and wishes.created_at >= ?",ids,startdate]
		else
			conditions = ["wishes.person_id in (?)",ids]
		end
		wishes = Wish.find(   
			:all,
			:conditions => conditions,
			:order => "created_at asc"
			)
		return wishes
	end

	# Return comments made to your scripts after the specified date, or
	# followups to your comments not made by you
	def recent_procedure_comments(startdate = nil)
		condition = "procedures.person_id=? and not procedure_comments.person_id=?"
		args = [self.id, self.id]
		if not startdate.nil?
			condition += " and updated_at >= ? "
			args += [startdate]
		end
		comments = ProcedureComment.find(:all,
			:select => "procedure_comments.*",
			:joins =>"inner join procedures on procedures.id = procedure_comments.procedure_id",
			:conditions => [condition] + args)
		recent_comments = self.procedure_comments
		if not startdate.nil?
		       recent_comments.delete_if { |c| c.updated_at < startdate }
		end

		followups = []
		for comment in recent_comments
			if not comment.procedure.nil? and not comment.person.nil?
				followups += ProcedureComment.find(:all,
					:conditions => ["procedure_id = ? and updated_at > ? and not person_id = ? and not person_id = ?", comment.procedure.id ,comment.updated_at,comment.person.id,self.id]
				)
			end
		end
		comments = comments + followups
		comments.sort { |x, y| y.updated_at <=> y.updated_at }
		return comments
	end

	# Return modifications to this person's scripts made by other people
	# since the specified date.  If the same person modified a script more
	# than once, only report it once.
	def recent_script_modifications(startdate)
		mods = []
		self.procedures.each { |p|
			p.changes.each { |c|
				if c.person != self and c.modified_at >= startdate
					found = false
					for mod in mods
						if c.person == mod.person and
							c.procedure == mod.procedure
							found = true
						end
					end
					if not found
						mods = mods + [c]
					end
				end
			}
		}
		return mods
	end

	# Return instances of other people running one of my scripts.  If the
	# same person ran a script more than once in this timeframe, only
	# report it once.
	def recent_script_runs(startdate)
		runs = []
		self.procedures.each { |p|
			p.procedure_executes.each { |e|
				if e.person != self and e.executed_at >= startdate
					found = false
					for run in runs
						if e.person == run.person and
							e.procedure == run.procedure
							found = true
						end
					end
					if not found
						runs = runs + [e]
					end
				end
			}
		}
		runs = runs.sort { |x, y| y.executed_at <=> x.executed_at }
		return runs
	end

	def get_newsletter_data(period)
        # Set up variables that can be referenced in the mail template
        activities = self.social_network_activity_recent(period.days.ago)
		created = make_aggregate_list(activities[:created])
		executed = make_aggregate_list(activities[:executed])
		modifications = self.recent_script_modifications(period.days.ago)
		wishes = self.social_network_wishes(period.days.ago)
		comments = self.recent_procedure_comments(period.days.ago)
		runs = self.recent_script_runs(period.days.ago)

		if created.length > 0 or executed.length > 0 or
			modifications.length > 0 or wishes.length > 0 or
			comments.length > 0 or runs.length > 0
			data = { :person => self,
				:period => period,    # how many days between newsletters
				:created => created,
				:executed => executed,
				:modifications => modifications,
				:wishes => wishes,
				:comments => comments,
				:runs => runs
				}
		else
			data = nil
		end
		return data
	end

	# Compute the set of scripts run by others in my organization
	def organizational_scripts
			return []
	end

	private
	def make_aggregate_list(origlist)
		ret = {}
		origlist.each { |a|
			if not a.procedure.nil?
				if ret.include?(a.person)
					if not ret[a.person].include?(a.procedure)
						ret[a.person] += [a.procedure]
					end
				else
					ret[a.person] = [a.procedure]
				end
			end
		}
		return ret
	end

end
