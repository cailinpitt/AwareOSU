# Mechanize gets the website and transforms into HTML file.
require 'mechanize'
# Nokogiri gets the website data that could be read later on.
require 'nokogiri'

require 'mail'
def main
	yesterday = (Time.now - (3600 * 24)).strftime("%m/%d/%Y")
	agent = Mechanize.new

	# Chose Safari because I like Macs
	agent.user_agent_alias = "Mac Safari" 
		
	# Direct to Columbus PD report website
	page = agent.get "http://www.columbuspolice.org/reports/SearchLocation?loc=zon4"

	search_form = page.form_with :id => "ctl01"
	search_form.field_with(:name => "ctl00$MainContent$startdate").value = "10/14/2015" #yesterday
	search_form.field_with(:name => "ctl00$MainContent$enddate").value = "10/14/2015" #yesterday
	# Searching for all crimes from yesterday

	button = search_form.button_with(:type => "submit")
	# Get button in order to submit search

	search_results = agent.submit(search_form, button)
	# Page containing the information we want to sift through.
	# Time for Nokogiri

	
	options = { :address      => "smtp.gmail.com",
            :port                 => 587,
            :user_name            => '',
            :password             => '',
            :authentication       => 'plain',
            :enable_starttls_auto => true  }

	Mail.defaults do
	  delivery_method :smtp, options
	end

	# Set up mail stuff

	resultPage = Nokogiri::HTML(search_results.body)
	products = resultPage.css("span[class='ErrorLabel']")
	# We use this span class to figure out if there are crimes for the specified date or not.

	if products.text.to_s.eql? "Your search produced no records."
		messageBody = "Hi. As of #{Time.now}, there are no crimes listed on the Columbus Police Department's website.\nAs always, you can check for crimes around the campus area yourself by visiting:\nhttp://www.columbuspolice.org/reports/SearchLocation?loc=zon4.\n\n\nBest,\n\nAware OSU Student"
		Mail.deliver do
		       to 'cailinpitt1@gmail.com'
		     from 'cailinpitt1@gmail.com'
		  subject 'Aware OSU Student Digest - No Crimes'
		     body messageBody
		end
	else
		# Else, crimes have occured :(
		# Parse HTML to get crimes, send to email list.

		crimeTable = resultPage.css("table[class='mGrid']")
		crimeInfo = crimeTable.css('td')
		puts "0. #{crimeInfo.length}"
		puts "1. #{crimeInfo[0].text}"
		puts "2. #{crimeInfo[1].text}"
	end

	
=begin
	Mail.deliver do
	       to 'cailinpitt1@gmail.com'
	     from 'pitt.35@osu.edu'
	  subject 'Testing Aware OSU Student'
	     body 'hey!'
	end
=end
end

main
