=begin
	Created by Cailin Pitt on 12/08/2015
	
	Ruby script that webscrapes crime information from the Columbus PD and the OSU PD's online logs and emails it to users in a weekly report.
=end

# Mechanize gets the website and transforms into HTML file.
require 'mechanize'
# Nokogiri gets the website data that could be read later on.
require 'nokogiri'
# Mail sends out information
require 'mail'
# resolv-replace.rb is more for testing, supplies nice error statements in case this script runs into network issues
require 'resolv-replace.rb'

yesterday =(Time.now - (3600 * 24)).strftime("%m/%d/%Y")
yesterdayWithDay = (Time.now - (3600 * 24)).strftime("%A, %m/%d/%Y")
lastFriday = (Time.now - (7 * (3600 * 24))).strftime("%A, %m/%d/%Y")
# Get dates
	
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

options = {	:address      				=> "smtp.gmail.com",
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

crimeHTML = ""
mapURL = ""
crimeTable = ""
crimeNum = 0
# Declare variables

if !File.exist? "/home/pi/Documents/AwareOSU/offcampus.txt"
	offCampus = File.open("/home/pi/Documents/AwareOSU/offcampus.txt", "w")
	offCampus.close
end

if !File.exist? "/home/pi/Documents/AwareOSU/oncampus.txt"
	onCampus = File.open("/home/pi/Documents/AwareOSU/oncampus.txt", "w")
	onCampus.close
end
# If files do not exist, we need to create them

offCampus = File.open("/home/pi/Documents/AwareOSU/offcampus.txt", "a")

if !products.text.to_s.eql? "Your search produced no records."
	# Crimes have occured :(
	# Parse HTML to get crimes, save in textfile.


	# Open off-campus file to dump information into.  
	
	crimeTable = resultPage.css("table[class='mGrid']")
	crimeInfo = crimeTable.css('td')
	crimeReportNumbers = crimeTable.css('tr')
	# Get crime information
	crimeNum = crimeInfo.length
	
	crimeTableInfo = ""
	# Set up variables to hold crime information
	
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
		
		offCampus.puts yesterdayWithDay
		offCampus.puts crimeInfo[i].text
		offCampus.puts crimeInfo[i + 1].text
		offCampus.puts crimeInfo[i + 4].text
		offCampus.puts 'http://www.columbuspolice.org/reports/PublicReport?caseID=' + report
		# Dump off-campus information into textfile.
		
		i += 5
		linkIndex += 1
		# Insert information into table
	end
	# Done getting off-campus info for the day
	
	# Crimes are retrieved from a table seperated by pages. Each page holds 29 crimes.
	# JavaScript is used for pagination, and since Mechanize/Nokogiri cannot interact with JS (only HTML),
	# the program can only retrieve the first 29 crimes (hence i < 145 [Each crime has 5 fields, 5 * 29 = 145])

	# Until I figure out how to deal with pagination, we will only return the first 29 crimes.
	# We rarely have more than 29 crimes, so this is a rare case, however it's something I still want to take care of.

else
	offCampus.puts yesterdayWithDay
	offCampus.puts "-"
	offCampus.puts "-"
	offCampus.puts "-"
	offCampus.puts "No off-campus crimes reported for #{yesterdayWithDay}"
	# Report that there were no off-campus crimes for this date
end
offCampus.close
# Close off-campus text file.

onCampus = File.open("/home/pi/Documents/AwareOSU/oncampus.txt", "a")
# Open file to dump on-campus information into

page = agent.get "http://www.ps.ohio-state.edu/police/daily_log/view.php?date=yesterday"
campusPage = Nokogiri::HTML(page.body)
crimeTable = campusPage.css("table[width='680']")
crimesFromTable = crimeTable.css("td[class='log']")
numberOfOSUCrimes = crimesFromTable.length/8
# Visit OSU PD's web log, get number of crimes committed on campus the previous day

if numberOfOSUCrimes > 0
# There were on-campus crimes today, get information and save to textfile.

i = 0
	while i < crimesFromTable.length do
		onCampus.puts yesterdayWithDay
		onCampus.puts crimesFromTable[i].text
		onCampus.puts crimesFromTable[i + 5].text
		onCampus.puts crimesFromTable[i + 6].text
		onCampus.puts crimesFromTable[i + 7].text
		# Dump information into textfile
		
		i += 8
	end
else
	onCampus.puts yesterdayWithDay
	onCampus.puts "-"
	onCampus.puts "-"
	onCampus.puts "-"
	onCampus.puts "No on-campus crimes reported for #{yesterdayWithDay}"
	# Report that there were no on-campus crimes for this date
end
onCampus.close
# Close onCampus connection

# Now check if yesterday was Friday. We want to send users a digest of crimes from the previous week
if yesterdayWithDay.include? "Friday"
	# Last day of week, time to send digest email.
	
	offCampusArray = IO.readlines('/home/pi/Documents/AwareOSU/offcampus.txt')
	# Read off-campus crime information into Array

	crimeTable = "<h1>#{offCampusArray.length/5} Off-campus crimes for the week of #{yesterdayWithDay}</h1>"
	crimeTable += '<table style="width:80%;text-align: left;" cellpadding="10"><tbody><tr><th>Date</th><th>Report Number</th><th>Incident Type</th><th>Location</th><th>Description</th></tr>'
		# Setup table for on-campus crime information
	
	i = 0
	while i < offCampusArray.length do
		crimeTable += '<tr>'
		crimeTable += '<td>' + offCampusArray[i] + '</td>'
		# Date
		crimeTable += '<td>' + offCampusArray[i + 1] + '</td>'
		# Report Number
		crimeTable += '<td>' + offCampusArray[i + 2] + '</td>'
		# Incident Type
		crimeTable += '<td>' + offCampusArray[i + 3] + '</td>'
		# Location
		crimeTable += '<td>' + offCampusArray[i + 4] + '</td>'
		# Description
		crimeTable += '</tr>'
	
		i += 5
	end
	crimeTable += '</tbody></table><br><br>'
	#End table

	onCampusArray = IO.readlines('/home/pi/Documents/AwareOSU/oncampus.txt')
	# Read on-campus crime information into Array

	crimeTable += "<h1>#{onCampusArray.length/5} On-campus crimes for the week of #{yesterdayWithDay}</h1>"
	crimeTable += '<table style="width:80%;text-align: left;" cellpadding="10"><tbody><tr><th>Date</th><th>Report Number</th><th>Incident Type</th><th>Location</th><th>Description</th></tr>'

	i = 0
	while i < onCampusArray.length do
		crimeTable += '<tr>'
		crimeTable += '<td>' + onCampusArray[i] + '</td>'
		# Date
		crimeTable += '<td>' + onCampusArray[i + 1] + '</td>'
		# Report Number
		crimeTable += '<td>' + onCampusArray[i + 2] + '</td>'
		# Incident Type
		crimeTable += '<td>' + onCampusArray[i + 3] + '</td>'
		# Location
		crimeTable += '<td>' + onCampusArray[i + 4] + '</td>'
		# Descriptions
		crimeTable += '</tr>'
	
		i += 5
	end

	crimeTable += '</tbody></table>'
	#End table

	offCampus = File.open("/home/pi/Documents/AwareOSU/offcampus.txt", "w")
	offCampus.close
	onCampus = File.open("/home/pi/Documents/AwareOSU/oncampus.txt", "w")
	onCampus.close
	# Clear text files, we don't need last week's info anymore
	
	Mail.deliver do
		to 'awareosulist@googlegroups.com'
		from 'awareosu@gmail.com'
		subject "AwareOSU - Digest for #{lastFriday} to #{yesterdayWithDay}"

		html_part do
			 content_type 'text/html; charset=UTF-8'
			 body crimeTable+ '<br><p>Best,</p><p>AwareOSU</p><br><br><p>P.S. Please visit this <a href="http://goo.gl/forms/n3q6D53TT3">link</a> to subscribe/unsubscribe.</p>'
		end
	end
	# Send digest to users
end
