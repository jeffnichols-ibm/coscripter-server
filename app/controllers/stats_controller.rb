# (C) Copyright IBM Corp. 2010
require 'date'

class StatsController < ApplicationController
    def index
		@numpeople = Person.count
		@numprocs = Procedure.count
			@numprivateprocs = Procedure.count(
			  :conditions => ['private = true'])

		@thisweek = Time.now.at_beginning_of_week
		@created_thisweek = Procedure.count(
			  :conditions => ["created_at > ?", @thisweek])
		@modified_thisweek = Procedure.count(
			  :conditions => ["modified_at > ?", @thisweek])

		@thismonth = Time.now.last_month
		@created_thismonth = Procedure.count(
			  :conditions => ["created_at > ?", @thismonth])
		@modified_thismonth = Procedure.count(
			  :conditions => ["modified_at > ?", @thismonth])

    end

    # Internal notes:
    # Note that we didn't start monitoring the date users got created until
    # 1/24/2007, so this graph doesn't start until 1/24/07.
    # 
    # CoScripter was demoed at ETech on 3/28/07, and we received a lot of
    # press the next day and the following week.  This is what caused the
    # spike in users around that time.
    def growth
      # Calculate number of scripts created over time
      oldest_date = Procedure.find(:first,
        :order => 'created_at asc').created_at
      numchunks = 20
      timespan = (Time.now - oldest_date) / numchunks
      spans = []
      cumprocs = 0
      for i in 0..numchunks-1
        starttime = oldest_date + (i * timespan)
        endtime = starttime + timespan
        procs = Procedure.count(
          :conditions => ["created_at >= ? and created_at < ?",
            starttime, endtime])
        spans += [{
          :xlabel1 => starttime.strftime("%m/%d/%y"),
          :xlabel2 => starttime.strftime("%H:%M"),
          :x => i,
          :y => procs + cumprocs
          }]
        cumprocs += procs
      end

      @scriptgrowth = Barchart.new
      @scriptgrowth.xlabel = "Time"
      @scriptgrowth.ylabel = "# scripts created"
      @scriptgrowth.ymin = 0
      @scriptgrowth.ymax = cumprocs
      @scriptgrowth.spans = spans

      # Calculate number of new visitors over time
      oldest_date = Person.find(:first,
        :order => 'created_at asc').created_at
      numchunks = 20
      timespan = (Time.now - oldest_date) / numchunks

      @usergrowth = Barchart.new
      @usergrowth.xlabel = 'Time'
      @usergrowth.ylabel = '# distinct users'
      @usergrowth.ymin = 0
      @usergrowth.ymax = Person.count
      @usergrowth.spans = []

      cumpeople = 0
      for i in 0..numchunks-1
        starttime = oldest_date + (i*timespan)
        endtime = starttime + timespan
        numpeople = Person.count(
          :conditions => ["created_at >= ? and created_at < ?",
            starttime, endtime])
        @usergrowth.spans += [{
          :xlabel1 => starttime.strftime("%m/%d/%y"),
          :xlabel2 => starttime.strftime("%H:%M"),
          :x => i,
          :y => numpeople + cumpeople
          }]
        cumpeople += numpeople
      end

      # Calculate number of script executions over time
      oldest_date = ProcedureExecute.find(:first, :order => 'executed_at asc').
        executed_at
      numchunks = 20
      timespan = (Time.now - oldest_date) / numchunks

      @rungrowth = Barchart.new
      @rungrowth.xlabel = 'Time'
      @rungrowth.ylabel = '# script runs'
      @rungrowth.ymin = 0
      @rungrowth.ymax = ProcedureExecute.count
      @rungrowth.spans = []

      cumruns = 0
      for i in 0..numchunks-1
        starttime = oldest_date + (i*timespan)
        endtime = starttime + timespan
        numruns = ProcedureExecute.count(
          :conditions => ["executed_at >= ? and executed_at < ?",
            starttime, endtime])
        @rungrowth.spans += [{
          :xlabel1 => starttime.strftime("%m/%d/%y"),
          :xlabel2 => starttime.strftime("%H:%M"),
          :x => i,
          :y => numruns + cumruns
          }]
        cumruns += numruns
      end

      send_data render_to_string, :type => 'application/xml',
        :disposition => "inline"
    end

    def users_by_day
      now = Time.now
      today_ordinal = now.yday
      today_year = now.year
      first_script = Procedure.find(:first, :order => "created_at asc",
        :limit => 1)
      beginning_date = first_script.created_at
      beginning_date = Date::ordinal(beginning_date.year, beginning_date.yday)
      day_begin = Date::ordinal(today_year, today_ordinal)
      day_end = Date::ordinal(today_year, today_ordinal + 1)
      @data = []

      admins = [1, 6, 10, 16, 17, 26, 27, 38, 425, 426, 802, 825, 1511, 1544]

      while day_begin > beginning_date
        script_mods = Change.find(:all, :conditions => [
          "modified_at >= ? and modified_at < ?", day_begin, day_end])
        people = script_mods.map { |x| x.person }
        
        executions = ProcedureExecute.find(:all,
          :conditions => ["executed_at >= ? and executed_at < ?",
            day_begin, day_end])
        people += executions.map { |x| x.person }
        people = people.uniq

        non_admin_people = people.reject { |x| x.nil? || admins.include?(x.id) }
        people = non_admin_people

        @data.push({:numpeople => people.length, :day => day_begin})

        # set to previous day
        day_end = day_begin
        if day_begin.yday == 1
          day_begin = Date::ordinal(day_begin.year - 1, 365)
        else
          day_begin = Date::ordinal(day_begin.year, day_begin.yday - 1)
        end
      end
    end

    def pageviews_by_day
      now = Time.now
      today_ordinal = now.yday
      today_year = now.year
      first_pageview = SiteUsageLog.find(:first, :order => "accessed_at asc",
        :limit => 1)
      beginning_date = first_pageview.accessed_at
      beginning_date = Date::ordinal(beginning_date.year, beginning_date.yday)
      day_begin = Date::ordinal(today_year, today_ordinal)
      day_end = Date::ordinal(today_year, today_ordinal + 1)
      @data = []

      while day_begin > beginning_date
        pageviews = SiteUsageLog.count(
#          :conditions => ['controller="browse" and action="script" and accessed_at >= ? and accessed_at < ?', day_begin, day_end])
          :conditions => ['controller="browse" and accessed_at >= ? and accessed_at < ?', day_begin, day_end])
#        atomviews = SiteUsageLog.count(
#          :conditions => ['controller="atom" and accessed_at >= ? and accessed_at < ?', day_begin, day_end])
        apiviews = SiteUsageLog.count(
          :conditions => ['controller="api" and action!="ping" and accessed_at >= ? and accessed_at < ?', day_begin, day_end])

        @data.push({:scriptviews => pageviews,
#          :atomviews => atomviews,
          :apiviews => apiviews,
          :day => day_begin})

        # set to previous day
        day_end = day_begin
        if day_begin.yday == 1
          day_begin = Date::ordinal(day_begin.year - 1, 365)
        else
          day_begin = Date::ordinal(day_begin.year, day_begin.yday - 1)
        end
      end
    end

	def clicks
		@newsletter = SiteUsageLog.find(:all,
			:conditions => "(uri like \"%?newsletter=true%\" or uri like \"%?source=newsletter%\") and not uri like \"/coscripter/api/byurl%\"",
			:order => "accessed_at asc")

		@sna = SiteUsageLog.find(:all,
			:conditions => "uri like \"%?source=sna\"",
			:order => "accessed_at asc")

		@org = SiteUsageLog.find(:all,
			:conditions => "uri like \"%?source=org\"",
			:order => "accessed_at asc")
	end
end
