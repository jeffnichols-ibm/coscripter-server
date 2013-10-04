Install CoScripter wiki server on a new machine
Created: August 21, 2006
Last modified: March 20, 2009
by Tessa Lau

This is for a development copy of the server.

1. Start by fetching all the software needed, which includes Ruby, Rails, MySQL, and Subversion.

On Ubuntu:
apt-get install mysql-server mysql-client ruby1.8 ruby1.8-dev ruby libmysql-ruby libldap-ruby1.8 libjson-ruby libxml-ruby libopenssl-ruby libhttp-access2-ruby rdoc rubygems libalgorithm-diff-ruby1.8
Get rails: sudo gem install rails --include-dependencies
Get capistrano: sudo gem install capistrano --include-dependencies
Get rfeedparser: sudo gem install rfeedparser --include-dependencies
Get ruby-json: sudo gem install json --include-dependencies
Get RedCloth: sudo gem install RedCloth --include-dependencies
Get rbtagger: sudo gem install rbtagger
If you build Rails and Ruby from source, you need to also download and install ruby-ldap:
wget http://downloads.sourceforge.net/ruby-ldap/ruby-ldap-0.9.7.tar.gz?modtime=1155098708&big_mirror=0
tar zxvf ruby-ldap-0.9.7.tar.gz
ruby extconf.rb
make
sudo make install
Do not use apt-get — it may get a version that breaks Koalescence.
On Windows:
Install Ruby for Windows (one-click installer) from http://www.ruby-lang.org/en/downloads/
Install Ruby on Rails: open the Command Prompt and type gem install rails --include-dependencies (gem is installed with Ruby).
Install Ruby/LDAP
download http://koala.almaden.ibm.com/wiki/images/5/55/Ldap-0.9.7-mswin32.gem
From the command line, cd to the directory you downloaded the file and type gem install Ldap-0.9.7-mswin32
For other platforms, go to: http://sourceforge.net/project/showfiles.php?group_id=66444
Install RedCloth: gem install RedCloth --include-dependencies. Pick the latest x86-mswin32-60 version. (see http://whytheluckystiff.net/ruby/redcloth/ for more info)
Install JSON Ruby library: gem install json_pure --include-dependencies
Currently, there is no way to install rfeedparser
Install Capistrano: gem install capistrano --include-dependencies
Install MySQL — Windows Essentials from http://www.mysql.org/downloads/
For MySQL version 5.0.51a, the configuration wizard will not run under Windows Vista. Go to http://forums.mysql.com/read.php?11,195569,195569#msg-195569 for instructions on how to fix it.
as you install, make sure MySQL is not setup in strict mode
Install Subversion from http://subversion.tigris.org/project_packages.html#windows
Click “Win32 packages built against Apache 2.0”
pick the latest version ending in -setup.exe
2. Set up MySQL:

mysql -u root -p
Type in the password you entered when you installed MySQL.
mysql> create database koala_development;
mysql> create database koala_production;
mysql> create database koala_test;
mysql> create user koala identified by 'PASSWORD_HERE';
PASSWORD_HERE is not the password you entered when you installed MySQL. Ask a Koala developer for PASSWORD_HERE.
mysql> grant all on koala_development.* to 'koala'@'localhost' identified by 'PASSWORD_HERE';
mysql> grant all on koala_production.* to 'koala'@'localhost' identified by 'PASSWORD_HERE';
mysql> grant all on koala_test.* to 'koala'@'localhost' identified by 'PASSWORD_HERE';
3. Check out the source code. If you don’t need commit privileges, you should be able to check the code out anonymously by not using the —username option in the svn command:

svn checkout —username <your-IIOSB-userid> https://svn.opensource.ibm.com/svn/koala/coscripter-wiki/trunk
Rename the trunk directory to something more meaningful:

mv trunk coscripter-wiki
cd coscripter-wiki
4. Populate the database schemas:

rake migrate
5. Start up the test server, which launches the WEBrick web server running on localhost:3000

./script/server
Point your browser at http://localhost:3000 to see if it worked
