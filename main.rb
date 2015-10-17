=begin
	TODO: Code cleanup (make classes)
	Created by Cailin Pitt on 10/15/2015
=end

# Mechanize gets the website and transforms into HTML file.
require 'mechanize'
# Nokogiri gets the website data that could be read later on.
require 'nokogiri'
# Mail sends out information
require 'mail'

def main
	yesterday = (Time.now - (3600 * 24)).strftime("%m/%d/%Y")
	# Get yesterday's date
	agent = Mechanize.new
	# Initialize new Mechanize agent

	# Chose Safari because I like Macs
	agent.user_agent_alias = "Mac Safari" 
		
	# Direct to Columbus PD report website
	page = agent.get "http://www.columbuspolice.org/reports/SearchLocation?loc=zon4"

	search_form = page.form_with :id => "ctl01"
	search_form.field_with(:name => "ctl00$MainContent$startdate").value = yesterday
	search_form.field_with(:name => "ctl00$MainContent$enddate").value = yesterday
	# Searching for all crimes from yesterday

	button = search_form.button_with(:type => "submit")
	# Get button in order to submit search

	search_results = agent.submit(search_form, button)
	# Page containing the information we want to sift through.
	# Time for Nokogiri

	passArray = IO.readlines('../p')
	options = { :address      => "smtp.gmail.com",
            :port                 => 587,
            :user_name            => 'awareosu',
            :password             => passArray[0].delete!("\n"),
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
		messageBody = "Hi. As of #{Time.now}, there are no crimes listed on the Columbus Police Department's website.\nAs always, you can check for crimes around the campus area yourself by visiting:\nhttp://www.columbuspolice.org/reports/SearchLocation?loc=zon4.\n\n\nBest,\n\nAware OSU"
		Mail.deliver do
			     to 'awareosulist@googlegroups.com'
			   from 'awareosu@gmail.com'
			subject 'Aware OSU Digest - No Crimes'
			   body messageBody
		end
		# Case where no crimes have occurred yesterday (very rare for this to occur, and most likely due to program running before crimes have been uploaded to CPD web portal
	else
		# Else, crimes have occured :(
		# Parse HTML to get crimes, send to email list.

		crimeTable = resultPage.css("table[class='mGrid']")
		crimeInfo = crimeTable.css('td')
		crimeReportNumbers = crimeTable.css('tr')
		# Get crime information

		crimeNum = crimeInfo.length
		crimeHTML = '<table style="width:80%;text-align: left;"><tbody><tr><th>CRNumber</th><th>Description</th><th>Location</th><th>Link</th></tr>'
		# Set up table for information
		
	i = 0
	j = 0;
	linkIndex = 1;

		while i < crimeNum do
			report = '';
			for j in 11...crimeReportNumbers[linkIndex]["onclick"].length - 1
				char = '' + crimeReportNumbers[linkIndex]["onclick"][j]
				report += char
			end

			crimeHTML = crimeHTML + '<tr>'
			crimeHTML = crimeHTML + '<td>' + crimeInfo[i].text + '</td>'
			crimeHTML = crimeHTML + '<td>' + crimeInfo[i + 1].text + '</td>'
			crimeHTML = crimeHTML + '<td>' + crimeInfo[i + 4].text + '</td>'
			crimeHTML = crimeHTML + '<td>' + 'http://www.columbuspolice.org/reports/PublicReport?caseID=' + report + '</td>'
			crimeHTML = crimeHTML + '</tr>'
			i += 5
			linkIndex += 1
			# Put information in table
		end
		Mail.deliver do
			     to 'awareosulist@googlegroups.com'
			   from 'awareosu@gmail.com'
			subject "Aware OSU Digest - #{yesterday}"

			html_part do
				 content_type 'text/html; charset=UTF-8'
	  		 body "<h1>#{crimeNum/5} Crimes for #{yesterday}</h1>" + crimeHTML + "</tbody></table><p>Best,</p><p>Aware OSU</p>"
			end
		end
		# Send out crime information to everyone on email list.
	end
end

main
