CoScripter Server
=================

CoScripter is a system for recording, automating, and sharing business processes performed in a web browser such as printing photos online, requesting a vacation hold for postal mail, or checking a bank account balance. CoScripter lets you make a recording as you perform a procedure, play it back later automatically, and share it with your friends.

CoScripter consists of two software components, a browser extension that runs in the Firefox browser and a online wiki-style database that stores scripts for later execution. This repository contains the source code for the CoScripter server built using Ruby on Rails. Code for the browser extension can be found [here](http://github.com/jeffnichols-ibm/coscripter-extension).

This version of the server requires Rails 2.3.2 and Ruby 1.8.

Installation Instructions
-------------------------

These instructions were created in 2006 and most recently modified in 2009, so your mileage may vary.

This is for a development copy of the server.

1.	**Start by fetching all the software needed, which includes Ruby, Rails, MySQL, and Subversion.**

	*On Ubuntu:*

	apt-get install mysql-server mysql-client ruby1.8 ruby1.8-dev ruby libmysql-ruby libldap-ruby1.8 libjson-ruby libxml-ruby libopenssl-ruby libhttp-access2-ruby rdoc rubygems libalgorithm-diff-ruby1.8

	Get rails: sudo gem install rails --include-dependencies

	Get capistrano: sudo gem install capistrano --include-dependencies

	Get rfeedparser: sudo gem install rfeedparser --include-dependencies

	Get ruby-json: sudo gem install json --include-dependencies

	Get RedCloth: sudo gem install RedCloth --include-dependencies

	Get rbtagger: sudo gem install rbtagger

	*On Windows:*

	Install Ruby for Windows (one-click installer) from http://www.ruby-lang.org/en/downloads/

	Install Ruby on Rails: open the Command Prompt and type gem install rails --include-dependencies (gem is installed with Ruby).

	Install RedCloth: gem install RedCloth --include-dependencies. Pick the latest x86-mswin32-60 version. (see http://whytheluckystiff.net/ruby/redcloth/ for more info)

	Install JSON Ruby library: gem install json_pure --include-dependencies

	Currently, there is no way to install rfeedparser

	Install Capistrano: gem install capistrano --include-dependencies

	Install MySQL — Windows Essentials from http://www.mysql.org/downloads/

2. 	**Set up MySQL:**

	mysql -u root -p

	Type in the password you entered when you installed MySQL.

	mysql> create database koala_development;

	mysql> create database koala_production;

	mysql> create database koala_test;

	mysql> create user koala identified by 'PASSWORD_HERE';
PASSWORD_HERE is the password specified in the file config/database.yml.

	mysql> grant all on koala_development.* to 'koala'@'localhost' identified by 'PASSWORD_HERE';

	mysql> grant all on koala_production.* to 'koala'@'localhost' identified by 'PASSWORD_HERE';

	mysql> grant all on koala_test.* to 'koala'@'localhost' identified by 'PASSWORD_HERE';

3.	**Check out the source code.**

4. 	**Populate the database schemas:**

	rake migrate

5. 	**Start up the test server, which launches the WEBrick web server running on localhost:3000**

	./script/server

	Point your browser at http://localhost:3000 to see if it worked

License
-------

The CoScripter source is provided as-is under the Mozilla Public License.  This code has not been actively maintained since at least 2012 so your mileage my vary.
