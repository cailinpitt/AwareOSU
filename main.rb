=begin
	TODO: Code cleanup (make classes)
	Created by Cailin Pitt on 10/15/2015
	
	Ruby script that webscrapes crime information from the Columbus PD and the OSU PD's online logs and emails it to users.
=end

# Mechanize gets the website and transforms into HTML file.
require 'mechanize'
# Nokogiri gets the website data that could be read later on.
require 'nokogiri'
# Mail sends out information
require 'mail'
# resolv-replace.rb is more for testing, supplies nice error statements in case this script runs into network issues
require 'resolv-replace.rb'

def main
	yesterday = (Time.now - (3600 * 24)).strftime("%m/%d/%Y")
	yesterdayWithDay = (Time.now - (3600 * 24)).strftime("%A, %m/%d/%Y")
	# Get yesterday's date
	
	agent = Mechanize.new
	agent.open_timeout = 60
	agent.read_timeout = 60
	# Initialize new Mechanize agent
	# Pi takes a longer time to load web pages, had to increase timeouts in order to avoid socketerrors

	agent.user_agent_alias = "Mac Safari" 
	# Chose Safari because I like Macs
	
	page = agent.get "http://www.columbuspolice.org/reports/SearchLocation?loc=zon4"
	# Direct to Columbus PD report website

	search_form = page.form_with :id => "ctl01"
	search_form.field_with(:name => "ctl00$MainContent$startdate").value = yesterday
	search_form.field_with(:name => "ctl00$MainContent$enddate").value = yesterday
	# Tell website we want to search for all crimes in zone 4 that occurred yesterday

	button = search_form.button_with(:type => "submit")
	# Get submit button in order to submit search

	search_results = agent.submit(search_form, button)
	# Page containing the information we want to sift through.

	# search_results contains off-campus crime information. Time to use Nokogiri!

	passArray = IO.readlines('/home/pi/Documents/p')

	options = { :address      => "smtp.gmail.com",
            :port                 => 587,
            :user_name            => 'awareosu',
            :password             => passArray[0].delete!("\n"),
            :authentication       => 'plain',
            :enable_starttls_auto => true  }

	Mail.defaults do
	  delivery_method :smtp, options
	end
	# Set up mail options, authenticate

	resultPage = Nokogiri::HTML(search_results.body)
	products = resultPage.css("span[class='ErrorLabel']")
	# We use this span class to figure out if there are crimes for the specified date or not.
	
	noCrimes = false;

	if products.text.to_s.eql? "Your search produced no records."
		crimeHTML = "<h1>0 Off-campus crimes for #{yesterdayWithDay}</h1>"
		crimeHTML += '<p>This is either due to no crimes occuring off-campus, or the Columbus Police Department forgetting to upload crime information.</p><p>Please be sure to check <a href="http://www.columbuspolice.org/reports/SearchLocation?loc=zon4">the CPD web portal</a> later today or tomorrow for any updates.</p>'
		# Case where there aren't any crimes for zone 4 on the CPD web portal.
		# Most likely due to program running before crimes have been uploaded to CPD web portal or CPD forgetting to upload crimes (which did happen on 10/26/2015).

		noCrimes = true;
		# Set boolean noCrimes to true
		
	else
		# Else, crimes have occured :(
		# Parse HTML to get crimes, send to email list.

		crimeTable = resultPage.css("table[class='mGrid']")
		crimeInfo = crimeTable.css('td')
		crimeReportNumbers = crimeTable.css('tr')
		# Get crime information

		crimeNum = crimeInfo.length
		crimeHTML = "<h1>#{crimeNum/5} Off-campus crimes for #{yesterdayWithDay}</h1>"
		crimeHTML = crimeHTML + '<table style="width:80%;text-align: left;"><tbody><tr><th>CRNumber</th><th>Description</th><th>Location</th><th>Link</th></tr>'
		# Set up table for information
		
		i = 0
		j = 0;
		linkIndex = 1;
		# Counters decared
		
		while ((i < crimeNum) && (i < 145)) do
			report = '';
			for j in 11...crimeReportNumbers[linkIndex]["onclick"].length - 1
				char = '' + crimeReportNumbers[linkIndex]["onclick"][j]
				report += char
			end
			# This loop takes care of setting up the links to each individual crime's page, where more information is listed.
			
			crimeHTML = crimeHTML + '<tr>'
			crimeHTML = crimeHTML + '<td>' + crimeInfo[i].text + '</td>'
			crimeHTML = crimeHTML + '<td>' + crimeInfo[i + 1].text + '</td>'
			crimeHTML = crimeHTML + '<td>' + crimeInfo[i + 4].text + '</td>'
			crimeHTML = crimeHTML + '<td>' + 'http://www.columbuspolice.org/reports/PublicReport?caseID=' + report + '</td>'
			crimeHTML = crimeHTML + '</tr>'
			i += 5
			linkIndex += 1
			# Insert information into table
		end
		
		# Crimes are retrieved from a table seperated by pages. Each page holds 29 crimes.
		# JavaScript is used for pagination, and since Mechanize/Nokogiri cannot interact with JS (only HTML),
		# the program can only retrieve the first 29 crimes (hence i < 145 [Each crime has 5 fields, 5 * 29 = 145])

		# Until I figure out how to deal with pagination, we will only return the first 29 crimes.
		# We rarely have more than 29 crimes, so this is a rare case, however it's something I still want to take care of.
	end

	page = agent.get "http://www.ps.ohio-state.edu/police/daily_log/view.php?date=yesterday"
	campusPage = Nokogiri::HTML(page.body)
	crimeTable = campusPage.css("table[width='680']")
	crimesFromTable = crimeTable.css("td[class='log']")
	numberOfOSUCrimes = crimesFromTable.length/8
	# Visit OSU PD's web log, get number of crimes committed on campus the previous day

	crimeHTML = crimeHTML + "<br><br></tbody></table>"
	crimeHTML = crimeHTML + "<h1>#{numberOfOSUCrimes} On-campus crimes for #{yesterdayWithDay}</h1>"
	crimeHTML = crimeHTML + '<table style="width:80%;text-align: left;"><tbody><tr><th>Report Number</th><th>Incident Type</th><th>Location</th><th>Description</th></tr>'
	# Setup table for on-campus crime information
		
	i = 0
	while i < crimesFromTable.length do
		crimeHTML = crimeHTML + '<tr>'
		crimeHTML = crimeHTML + '<td>' + crimesFromTable[i].text + '</td>'
		crimeHTML = crimeHTML + '<td>' + crimesFromTable[i + 5].text + '</td>'
		crimeHTML = crimeHTML + '<td>' + crimesFromTable[i + 6].text + '</td>'
		crimeHTML = crimeHTML + '<td>' + crimesFromTable[i + 7].text + '</td>'
		crimeHTML = crimeHTML + '</tr>'
		i += 8
	end
		# Insert on-campus crime information into table

	if !noCrimes
		Mail.deliver do
			to 'awareosulist@googlegroups.com'
			from 'awareosu@gmail.com'
			subject "AwareOSU Digest - #{yesterday}"

			html_part do
				 content_type 'text/html; charset=UTF-8'
				 body crimeHTML + '</tbody></table><br><p>Best,</p><p>AwareOSU</p><br><br><p>P.S. You can visit this <a href="http://goo.gl/forms/n3q6D53TT3">link</a> for subscription options.</p>'
			end
		end
	# Case where there were off-campus crimes

	else
		Mail.deliver do
			to 'awareosulist@googlegroups.com'
			from 'awareosu@gmail.com'
			subject "AwareOSU Digest - No Crimes On #{yesterday}"

			html_part do
			 content_type 'text/html; charset=UTF-8'
			 body crimeHTML + '<br><p>Best,</p><p>AwareOSU</p><br><br><p>P.S. You can visit this <a href="http://goo.gl/forms/n3q6D53TT3">link</a> for subscription options.</p>'
			end
		end
	end
	# Case where there were no off-campus crimes
end

main #Call main function
