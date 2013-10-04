# (C) Copyright IBM Corp. 2007
class AddTutorialScript < ActiveRecord::Migration
  def self.up
    if Person.find_by_name("CoScripter team").nil?
      p = Person.new
      p.name = "CoScripter team"
      p.description = "The team of people behind the CoScripter project"
      # Should this be an email address?
      p.profile_id = $profile.site_email
      p.save!
    else
      p = Person.find_by_name("CoScripter team")
    end

    s = Procedure.new
    s.person = p
    s.title = "Getting started with CoScripter"
    s.created_at = Time.now
    s.modified_at = Time.now
    s.body = <<EOF
After opening this script in the CoScripter sidebar, the first step below will be highlighted in green.  Click the "Step" button above to run this command.

* go to "www.google.com"

Google's homepage is now shown in the main browser window.  The next step, below, says to click the "Images" link.  Note that the "Images" link is also highlighted in green on the page to the right.  Click step to continue.

* click the "Images" link

The next step is to enter text into the search box.  Note that the search term ("koalas") is highlighted in green on the webpage to the right.  The text is not entered until CoScripter performs that step.  Now click the "Run" button above to automatically run the remaining steps in this script.

* enter "koalas" into the "Search Images" textbox

* click the "Search Images" button

* you click on an image to view (read the text below)

Notice that CoScripter paused on the previous step, and it is highlighted in red.  The word "you" in this step tells CoScripter to stop running the script and wait for you to click on the image you want to see.  Afterwards, you can click "Step" or "Run" to continue.

* click the "Image Results »" link
EOF
    s.save!

    b = BestBet.new
    b.procedure = s
    b.save!
  end

  def self.down
    # ideally we'd delete the things we just added, but I won't bother
  end
end
