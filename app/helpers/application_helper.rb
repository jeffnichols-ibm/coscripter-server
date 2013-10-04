# (C) Copyright IBM Corp. 2010

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

	# Convert any URLs in the text into hyperlinks.
	def linkifyUrls(text)
	if text.nil?
		return nil
	end

	# Find anything that looks like a URL and make it a link
	bareUrlReStr = "(([A-Za-z0-9$_.+!*(),;/?:@&~=-])|%[A-Fa-f0-9]{2}){2,}(#([a-zA-Z0-9][a-zA-Z0-9$_.+!*(),;/?:@&~=%-]*))?([A-Za-z0-9$_+!*();/?:~-]))"
	urlRe = Regexp.new("(^|[ \\s\"])((ftp|http|https|mailto|file):" + bareUrlReStr)
	wwwRe = Regexp.new("(^|[ \\s\"])(www." + bareUrlReStr)
	
	text.gsub!(urlRe, '\1<a href="\2">\2</a>')
	text.gsub!(wwwRe, '\1<a href="http://\2">\2</a>')

	text
	end


	def format_markdown(text)
	if text.nil?
		''
	else
		r = RedCloth.new(text)
			# TL: only use textile to format list items; ignore all other
			# markup
		r.to_html(:block_textile_lists, :block_textile_prefix)
	end
	end

	def pluralize(num, sing, plur)
	if num == 0
		num.to_s + plur
	elsif num == 1
		num.to_s + sing
	else
		num.to_s + plur
	end
	end

	def format_commenttime(t)
		if t.localtime.at_beginning_of_day == Time.now.utc.at_beginning_of_day
			# posted today
			t.strftime('%I:%M %p')
		else
			t.strftime('%b %d %Y')
		end
	end

	def getSnippet(procedure, length)
		body = procedure.body
		if body.nil?
			return ''
		end
		if body.index('*').nil?
			snippet = body.strip
		else
			index = body.index('*')
			if index == 0
			return ''
			else
			snippet = body[0..index-1].strip
			end
		end

		if not length
			length = 200
		end
		return snip(snippet, length)
	end

	def snip(text, length)
		if not length.nil? and length > 0 and text.length > length
			text = text[0..length] + '...'
		end
		return text
	end

	# this also appears in app/controllers/application.rb -- where should
	# it go?
	def is_logged_in?
	  return (not session[:user_id].nil?)
	end


	# convert a number of seconds into a number of hours/days/years
	def formatSeconds(secs)
	  secs = secs.to_i
	  if secs > 60*60*24*365
		return pluralize(secs/(60*60*24*365), " year", " years")
	  elsif secs > 60*60*24*30
		return pluralize(secs/(60*60*24*30), " month", " months")
	  elsif secs > 60*60*24
		return pluralize(secs/(60*60*24), " day", " days")
	  elsif secs > 60*60
		return pluralize(secs/(60*60), " hour", " hours")
	  elsif secs > 60
		return pluralize(secs/60, " minute", " minutes")
	  else
		return pluralize(secs, " second", " seconds")
	  end
	end

	# convert a number of days into a number of weeks/months/years
	def format_days(days)
	  days = days.to_i
	  if days > 365
		return (days/(365)==1?"year":"#{days/(365)} years")
	  elsif days > 30
		return (days/(30)==1?"month":"#{days/(30)} months")
	  elsif days > 6
		return (days/(7)==1?"week":"#{days/(7)} weeks")
	  else
		return pluralize(days, " day", " days")
	  end
	end

	# strip parameters from a uri
	# from http://dev.rubyonrails.org/attachment/ticket/9116
	def strip_params(uri)
	  uri.split(/\?.*/)[0]
	end

	# check that one page is equivalent to another, ignoring params
	# from http://dev.rubyonrails.org/ticket/9116
	def current_page_no_params?(options)
	  url_string = CGI.escapeHTML(url_for(options))
	  request = @controller.request
	  request_uri, url_string = [strip_params(request.request_uri), strip_params(url_string)] 
	  if url_string =~ /^\w+:\/\//
		url_string == "#{request.protocol}#{request.host_with_port}#{request_uri}"
	  else
		url_string == request_uri
	  end
	end

        class CoscripterLinkRenderer < WillPaginate::LinkRenderer
          def url_for(page)
            page_one = page == 1
            unless @url_string and !page_one
              @url_params = {}
              # page links should preserve GET parameters
              stringified_merge @url_params, @template.params if @template.request.get?
              stringified_merge @url_params, @options[:params] if @options[:params]

              if complex = param_name.index(/[^\w-]/)
                page_param = parse_query_parameters("#{param_name}=#{page}")

                stringified_merge @url_params, page_param
              else
                @url_params[param_name] = page_one ? 1 : 2
              end

              url = @template.url_for(@url_params)

              return url if page_one 

              if complex 
                @url_string = url.sub(%r!((?:\?|&amp;)#{CGI.escape param_name}=)#{page}!, '\1@') 
                return url 
              else 
                @url_string = url 
                @url_params[param_name] = 3 
                @template.url_for(@url_params).split(//).each_with_index do |char, i| 
                  if char == '3' and url[i, 1] == '2' 
                    @url_string[i] = '#' # this is the offending line, use to be '@' which collided with our id=cdrews@us.ibm.com parameter
                    break 
                  end 
                end 
              end 
            end 
            # finally! 
            @url_string.sub '#', page.to_s 
          end 
        end

end
