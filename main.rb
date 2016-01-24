=begin
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

yesterday = (Time.now - (3600 * 24)).strftime("%m/%d/%Y")
yesterdayWithDay = (Time.now - (3600 * 24)).strftime("%A, %m/%d/%Y")
# Get yesterday's date
	
agent = Mechanize.new
agent.open_timeout = 60
agent.read_timeout = 60
# Initialize new Mechanize agent
# Pi takes a longer time to load web pages, increase timeouts in order to avoid socketerrors

agent.user_agent_alias = "Mac Safari" 
# Chose Safari because I like Macs

crimeHTML = ""
# Declare variable to hold crime information

passArray = IO.readlines('/home/pi/Documents/p')

options = { :address      			=> "smtp.gmail.com",
          :port                 => 587,
          :user_name            => 'awareosu',
          :password             => passArray[0].delete!("\n"),
          :authentication       => 'plain',
          :enable_starttls_auto => true  }

Mail.defaults do
  delivery_method :smtp, options
end
# Set up mail options, authenticate

districtArray = [ 'dis33', 'dis30', 'dis34', 'dis53', 'dis50', 'dis43', 'dis40', 'dis41', 'dis42', 'dis44' ]
# This array contains the districts we want to get crime info from

key = passArray[1].delete!("\n")
crimeTableInfo = ""
websiteDown = false
retries = 3
# If website is down, we'll retry visiting it three times.

crimeNumTotal = 0
mapURL = "<img src = 'https://maps.googleapis.com/maps/api/staticmap?zoom=12&center=the+ohio+state+university&size=370x330&scale=2&maptype=roadmap&markers=color:blue%7Clabel:"

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
			crimeHTML += "<h1>0 Off-campus crimes for #{yesterdayWithDay} - Website Down</h1>"
			crimeHTML += '<p>The Columbus Police Department\'s website is currently down.</p><p>Please be sure to check <a href="http://www.columbuspolice.org/reports/SearchLocation">the CPD web portal</a> later today or tomorrow for any updates.</p>'
			break
			# Report that there were no off-campus crimes for this date
			# Else, write that website was down, move on to on-campus crimes
		end
		# If loading Columbus PD website fails, try two more times
	else
		# Else it loaded, continue with execution of script

		# page contains off-campus crime information. Time to use Nokogiri!

		resultPage = Nokogiri::HTML(page.body)
		products = resultPage.css("span[class='ErrorLabel']")
		# We use this span class to figure out if there are crimes for the specified date or not.
		
		if !products.text.to_s.eql? "Your search produced no records."
			crimeTable = ""
			crimeNum = 0
			# Declare variables
			# Parse HTML to get crimes, send to email list.

			crimeTable = resultPage.css("table[class='mGrid']")
			crimeInfo = crimeTable.css('td')
			crimeReportNumbers = crimeTable.css('tr')
			# Get crime information
			
			crimeNum = crimeInfo.length
			crimeNumTotal += crimeNum / 5
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
	
				crimeTableInfo += '<tr>'
				crimeTableInfo += '<td>' + crimeInfo[i].text + '</td>'
				crimeTableInfo += '<td>' + crimeInfo[i + 1].text + '</td>'
				crimeTableInfo += '<td>' + crimeInfo[i + 4].text + '</td>'
				crimeTableInfo += '<td>' + 'http://www.columbuspolice.org/reports/PublicReport?caseID=' + report + '</td>'
				crimeTableInfo += '</tr>'
	
				location = crimeInfo[i + 4].text
				location.delete!("&")
				
				if location.include? " "
					mapURL += "%7C" + location.gsub!(/\s+/, '+') + "+Columbus+Ohio"
				else
					mapURL += "%7C" + location + "+Columbus+Ohio"
				end
				# Clean up location to make it suitable for Google Maps
					
				i += 5
				linkIndex += 1
				# Insert information into table
			end
			# End table

			# Crimes are retrieved from a table seperated by pages. Each page holds 29 crimes.
			# JavaScript is used for pagination, and since Mechanize/Nokogiri cannot interact with JS (only HTML),
			# the program can only retrieve the first 29 crimes (hence i < 145 [Each crime has 5 fields, 5 * 29 = 145])

			# Until I figure out how to deal with pagination, we will only return the first 29 crimes in a district.
			# We rarely have more than 29 crimes in a district, so this is a rare case, however it's something I still want to take care of.
		end
	end
end

if crimeNumTotal > 0
	# Add information to result if there were off-campus crimes
	mapURL += "&maptype=terrain&key=" + key
	crimeHTML += mapURL
	crimeHTML += "<h1>#{crimeNumTotal} Off-campus crimes for #{yesterdayWithDay}</h1>"
	crimeHTML += '<table style="width:80%;text-align: left;" cellpadding="10"><tbody><tr><th>CRNumber</th><th>Description</th><th>Location</th><th>Link</th></tr>'
	crimeHTML += crimeTableInfo
	crimeHTML += '</tbody></table><p><a href="http://cailinpitt.github.io/AwareOSU/definitions#off">Confused about the meaning of a crime?</a></p>'
elsif  ((crimeNumTotal == 0) && (websiteDown == false))
	# No crimes reported for the day we searched
	crimeHTML += "<h1>0 Off-campus crimes for #{yesterdayWithDay}</h1>"
	crimeHTML += '<p>This is either due to no crimes occuring off-campus, or the Columbus Police Department forgetting to upload crime information.</p><p>Please be sure to check <a href="http://www.columbuspolice.org/reports/SearchLocation">the CPD web portal</a> later today or tomorrow for any updates.</p>'
end

websiteDown = false
retries = 3

begin
	page = agent.get "hhttp://dps-web-01.busfin.ohio-state.edu/police/daily_log_2/view.php?date=yesterday"
rescue
	if retries > 0
		retries -= 1
		sleep 5
		retry
	else
		websiteDown = true
		crimeHTML += "<h1>0 On-campus crimes for #{yesterdayWithDay} - Website Down</h1>"
		crimeHTML += '<p>The OSU Police Department\'s website is currently down.</p><p>Please be sure to check <a href="https://dps.osu.edu/daily-crime-log">the OSU PD web portal</a> later today or tomorrow for any updates.</p>'
		# Report that there were no on-campus crimes for this date
		# Else, write that website was down
	end
	else
		campusPage = Nokogiri::HTML(page.body)
		crimeTable = campusPage.css("table[class='log']")
		crimesFromTable = crimeTable.css("td[class='log']")
		numberOfOSUCrimes = crimesFromTable.length/8
		# Visit OSU PD's web log, get number of crimes committed on campus the previous day

		if ((numberOfOSUCrimes == 0) && (websiteDown == false))
			crimeHTML = crimeHTML + "<h1>0 On-campus crimes for #{yesterdayWithDay}</h1>"
			crimeHTML = crimeHTML + '<p>This is either due to no crimes occuring on-campus, or the Ohio State Police Department forgetting to upload crime information.</p><p>Please be sure to check <a href="https://dps.osu.edu/daily-crime-log">the OSU PD web portal</a> later today or tomorrow for any updates.</p>'
	
		else if  numberOfOSUCrimes > 0
			#Else there were crimes, extract and add to result
	
			mapURL = "<img src = 'https://maps.googleapis.com/maps/api/staticmap?zoom=13&center=the+ohio+state+university&size=370x330&scale=2&maptype=roadmap&markers=color:blue%7Clabel:"
			crimeHTML = crimeHTML + "<br><br>"
	
			crimeHTML = crimeHTML + "<h1>#{numberOfOSUCrimes} On-campus crimes for #{yesterdayWithDay}</h1>"
	
			crimeTable = '<table style="width:80%;text-align: left;" cellpadding="10"><tbody><tr><th>Report Number</th><th>Incident Type</th><th>Location</th><th>Description</th></tr>'
			# Setup table for on-campus crime information
	
			i = 0
			while i < crimesFromTable.length do
				crimeTable = crimeTable + '<tr>'
				crimeTable = crimeTable + '<td>' + crimesFromTable[i].text + '</td>'
				crimeTable = crimeTable + '<td>' + crimesFromTable[i + 5].text + '</td>'
				crimeTable = crimeTable + '<td>' + crimesFromTable[i + 6].text + '</td>'
				crimeTable = crimeTable + '<td>' + crimesFromTable[i + 7].text + '</td>'
				crimeTable = crimeTable + '</tr>'
		
				location = crimesFromTable[i + 6].text
				location.delete!("&")
			
				if location.include? " "
					mapURL += "%7C" + location.gsub!(/\s+/, '+') + "+Ohio+State+University+columbus+ohio"
				else
					mapURL += "%7C" + location + "+Ohio+State+University+columbus+ohio"
				end
				# Clean up location to make it suitable for searching
			
				i += 8
			end
			# Insert on-campus crime information into table
			mapURL += "&maptype=terrain&key=" + key
			crimeHTML += mapURL
			crimeHTML += crimeTable
			crimeHTML += '</tbody></table><p><a href="http://cailinpitt.github.io/AwareOSU/definitions#on">Confused about the meaning of a crime?</a></p>'
			# End table
		end
	end
end
Mail.deliver do
	to 'awareosulist@googlegroups.com'
	from 'awareosu@gmail.com'
	subject "AwareOSU - #{yesterdayWithDay}"

	html_part do
		 content_type 'text/html; charset=UTF-8'
		 body crimeHTML + '<br><p>Best,</p><p>AwareOSU</p><br><br><p>P.S. Please visit this <a href="http://goo.gl/forms/n3q6D53TT3">link</a> to subscribe/unsubscribe.</p>'
	end
end
# Send crimes to users
