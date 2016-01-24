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

yesterday = (Time.now - (3600 * 24)).strftime("%m/%d/%Y")
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

passArray = IO.readlines('/home/pi/Documents/p')

options = {	:address      									=> "smtp.gmail.com",
          					:port		                  					=> 587,
          					:user_name        					=> 'awareosu',
								  	:password          						=> passArray[0].delete!("\n"),
								  	:authentication  					=> 'plain',
								  	:enable_starttls_auto	=> true  }

Mail.defaults do
  delivery_method :smtp, options
end
# Set up mail options, authenticate

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
# Open off campus text file

websiteDown = false
retries = 3
# If website is down, we'll retry visiting it three times.

districtArray = [ 'dis33', 'dis30', 'dis34', 'dis53', 'dis50', 'dis43', 'dis40', 'dis41', 'dis42', 'dis44' ]
crimeNumTotal = 0
# This array contains the districts we want to get crime info from

for i in 0...districtArray.length
	sleep 4
	# Sleep so we aren't persistently bothering the CPD website
	begin
		websiteURL = "http://www.columbuspolice.org/reports/Results?from=datePlaceholder&to=datePlaceholder&loc=locationPlaceholder&types=9"
		websiteURL.gsub!('datePlaceholder', yesterday).gsub!('locationPlaceholder', districtArray[i])
		# Insert search info into URL
		page = agent.get websiteURL
		# Try to direct to Columbus PD report website
	rescue
		if retries > 0
			retries -= 1
			sleep 5
			retry
		else
			websiteDown = true
			offCampus.puts yesterdayWithDay
			offCampus.puts "-"
			offCampus.puts "-"
			offCampus.puts "-"
			offCampus.puts "Columbus PD website was down, unable to retrieve crimes for #{yesterdayWithDay}."
			# Report that there were no off-campus crimes for this date
			# Else, write that website was down, move on to on-campus crimes
			break
		end
		# If loading Columbus PD website fails, try one more time
	else
		# Else it loaded, continue with execution of script

		# page contains off-campus crime information. Time to use Nokogiri!

		resultPage = Nokogiri::HTML(page.body)
		products = resultPage.css("span[class='ErrorLabel']")
		# We use this span class to figure out if there are crimes for the specified date or not.

		crimeHTML = ""
		mapURL = ""
		crimeTable = ""
		crimeNum = 0
		# Declare variables

		if !products.text.to_s.eql? "Your search produced no records."
			crimeTable = resultPage.css("table[class='mGrid']")
			crimeInfo = crimeTable.css('td')
			crimeReportNumbers = crimeTable.css('tr')
			# Get crime information
			crimeNum = crimeInfo.length
			crimeNumTotal += crimeNum / 5
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

			# Until I figure out how to deal with pagination, we will only return the first 29 crimes for each district.
			# We rarely have more than 29 crimes in a district, so this is a rare case, however it's something I still want to take care of.
	end
end
end
if ((crimeNumTotal == 0) && (websiteDown == false))
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

page = agent.get "http://dps-web-01.busfin.ohio-state.edu/police/daily_log_2/view.php?date=yesterday"
campusPage = Nokogiri::HTML(page.body)
crimeTable = campusPage.css("table[class='log']")
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

	crimeTable = '<table style="width:80%;text-align: left;" cellpadding="10"><tbody><tr><th>Date</th><th>Report Number</th><th>Incident Type</th><th>Location</th><th>Description</th></tr>'
		# Setup table for on-campus crime information
	
	i = 0
	offCampusNum = offCampusArray.length / 5
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
	
		if offCampusArray[i + 3].include? "-"
			offCampusNum -= 1
			# Update size
		end
		i += 5
	end
	crimeTable += '</tbody></table><p><a href="http://cailinpitt.github.io/AwareOSU/definitions#off">Confused about the meaning of a crime?</a></p><br><br>'
	#End table

	crimeHTML = "<h1>#{offCampusNum} Off-campus crimes for the week of #{yesterdayWithDay}</h1>" + crimeTable

	onCampusArray = IO.readlines('/home/pi/Documents/AwareOSU/oncampus.txt')
	# Read on-campus crime information into Array

	crimeTable = '<table style="width:80%;text-align: left;" cellpadding="10"><tbody><tr><th>Date</th><th>Report Number</th><th>Incident Type</th><th>Location</th><th>Description</th></tr>'

	onCampusNum = onCampusArray.length / 5
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
	
		if onCampusArray[i + 2].include? "-"
			onCampusNum -= 1
			# Update size
		end
		i += 5
	end

	crimeTable += '</tbody></table><p><a href="http://cailinpitt.github.io/AwareOSU/definitions#on">Confused about the meaning of a crime?</a></p>'
	#End table

	crimeHTML += "<h1>#{onCampusNum} On-campus crimes for the week of #{yesterdayWithDay}</h1>" + crimeTable

	offCampus = File.open("/home/pi/Documents/AwareOSU/offcampus.txt", "w")
	offCampus.close
	onCampus = File.open("/home/pi/Documents/AwareOSU/oncampus.txt", "w")
	onCampus.close
	# Clear text files, we don't need last week's info anymore
	
	Mail.deliver do
		to 'awareosuweekly@googlegroups.com'
		from 'awareosu@gmail.com'
		subject "AwareOSU - Digest for #{lastFriday} to #{yesterdayWithDay}"

		html_part do
			 content_type 'text/html; charset=UTF-8'
			 body crimeHTML+ '<br><p>Best,</p><p>AwareOSU</p><br><br><p>P.S. Please visit this <a href="http://goo.gl/forms/n3q6D53TT3">link</a> to subscribe/unsubscribe.</p>'
		end
	end
	# Send digest to users
end
