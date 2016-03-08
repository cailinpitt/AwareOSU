#!/usr/bin/env ruby
=begin
	Created by Cailin Pitt on 10/15/2015
	Edited by Will Sloan on 1/12/2016

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


yesterday = (Time.now - (3600 * 24)).strftime("%m/%d/%Y")
yesterdayWithDay = (Time.now - (3600 * 24)).strftime("%A, %m/%d/%Y")
# Get yesterday's date

agent = Mechanize.new
agent.open_timeout = 60
agent.read_timeout = 60
# Initialize new Mechanize agent

agent.user_agent_alias = "Mac Safari"
# Chose Safari because I like Macs

retries = 3
# If website is down, we'll retry visiting it three times.

mapURL = ""
crimeNum = 0

begin
	page = agent.get "http://www.columbuspolice.org/reports/SearchLocation?loc=zon4"
	# Try to direct to Columbus PD report website
rescue
	if retries > 0
		retries -= 1
		sleep 5
		retry
	else
		puts "The Columbus Police Department's website is currently down. Be sure to check back later"
		# Report that there were no off-campus crimes for this date
		# Else, write that website was down, move on to on-campus crimes
	end
	# If loading Columbus PD website fails, try two more times
else # Else it loaded, continue with execution of script

	# Tell website we want to search for all crimes in zone 4 that occurred yesterday
	search_form = page.form_with :id => "ctl01"
	search_form.field_with(:name => "ctl00$MainContent$startdate").value = yesterday
	search_form.field_with(:name => "ctl00$MainContent$enddate").value = yesterday
	button = search_form.button_with(:type => "submit")

	# Page containing the information we want to sift through.
	search_results = agent.submit(search_form, button)

	# We use this span class to figure out if there are crimes for the specified date or not.
	resultPage = Nokogiri::HTML(search_results.body)
	errors = resultPage.css("span[class='ErrorLabel']")

	# Declare variables
	crimeTable = ""
	crimeNum = 0

	if errors.text.to_s.eql? "Your search produced no records."
		puts "No off-campus crimes for #{yesterdayWithDay}"
		# Case where there aren't any crimes for zone 4 on the CPD web portal.
		# Most likely due to program running before crimes have been uploaded to CPD web portal or CPD forgetting to upload crimes
		# (which did happen on 10/26/2015).

	else
		# Else, crimes have occured :(
		# Parse HTML to get crimes, send to email list.
		crimeTable = resultPage.css("table[class='mGrid']")
		crimeInfo = crimeTable.css('td')
		crimeReportNumbers = crimeTable.css('tr')

		# Get crime information
		crimeNum = crimeInfo.length
		i = 0
		j = 0
		linkIndex = 1

		while ((i < crimeNum) && (i < 145)) do
			report = '';
			for j in 11...crimeReportNumbers[linkIndex]["onclick"].length - 1
				char = '' + crimeReportNumbers[linkIndex]["onclick"][j]
				report += char
			end
			# This loop takes care of setting up the links to each individual crime's page, where more information is listed.
			puts "New Crime"
			puts "Offense: #{crimeInfo[i + 1].text}"
			puts "Victim: #{crimeInfo[i + 2].text}"
			puts "Location: #{crimeInfo[i + 4].text}"
			puts "Report Number #{report}"
			puts "End Crime\n"

			i += 5
			linkIndex += 1
		end

		# Crimes are retrieved from a table seperated by pages. Each page holds 29 crimes.
		# JavaScript is used for pagination, and since Mechanize/Nokogiri cannot interact with JS (only HTML),
		# the program can only retrieve the first 29 crimes (hence i < 145 [Each crime has 5 fields, 5 * 29 = 145])
		# Until I figure out how to deal with pagination, we will only return the first 29 crimes.
		# We rarely have more than 29 crimes, so this is a rare case, however it's something I still want to take care of.
	end
end


page = agent.get "http://www.ps.ohio-state.edu/police/daily_log/view.php?date=yesterday"
campusPage = Nokogiri::HTML(page.body)
crimeTable = campusPage.css("table[width='680']")
crimesFromTable = crimeTable.css("td[class='log']")
numberOfOSUCrimes = crimesFromTable.length/8
# Visit OSU PD's web log, get number of crimes committed on campus the previous day

if numberOfOSUCrimes == 0
	puts "No on campus crimes for #{yesterdayWithDay}"

else
	#Else there were crimes, extract and add to resuls
	puts "#{numberOfOSUCrimes} on campus crimes"

	i = 0
	while i < crimesFromTable.length do

		puts "Report Number: #{crimesFromTable[i].text}"
		puts "Incident Type: #{crimesFromTable[i + 5].text}"
		puts "Location: #{crimesFromTable[i + 6].text}"
		puts "Description: #{crimesFromTable[i + 7].text}"
		i += 8
	end

end
