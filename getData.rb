=begin
	Created by Cailin Pitt on 02/16/2015
	
	Ruby script that retrieves crime information between days specified by user, then saves information into textfile that can be used by analytics.rb.
=end

# Mechanize gets the website and transforms into HTML file.
require 'mechanize'
# Nokogiri gets the website data that could be read later on.
require 'nokogiri'
# resolv-replace.rb is more for testing, supplies nice error statements in case this script runs into network issues
require 'resolv-replace.rb'

yesterday = (Time.now - (3600 * 24)).strftime("%m/%d/%Y")
# Get dates
	
agent = Mechanize.new
agent.open_timeout = 60
agent.read_timeout = 60
# Initialize new Mechanize agent
# Pi takes a longer time to load web pages, had to increase timeouts in order to avoid socketerrors

agent.user_agent_alias = "Mac Safari" 
# Chose Safari because I like Macs

offCampus = File.open("offcampusdata.txt", "w")
onCampus = File.open("oncampusdata.txt", "w")
# If files do not exist, we need to create them

puts "Enter start date (mm/dd/yyyy):"
startDate = gets.chomp

puts "Enter end date (mm/dd/yyyy):"
endDate = gets.chomp

startTimeObject = Date.parse(startDate)
endDateBound = Date.parse(endDate)
endDateBound += 1

while startTimeObject.strftime("%m/%d/%Y") != endDateBound.strftime("%m/%d/%Y")
	puts startTimeObject.strftime("%m/%d/%Y") + "- Retrieving Off Campus Data"
	websiteDown = false
	retries = 3
	# If website is down, we'll retry visiting it three times.

	districtArray = [ 'dis33', 'dis30', 'dis34', 'dis53', 'dis50', 'dis43', 'dis40', 'dis41', 'dis42', 'dis44' ]
	crimeNumTotal = 0
	# This array contains the districts we want to get crime info from
	
	for i in 0...districtArray.length
		sleep 3
		# Sleep so we aren't persistently bothering the CPD website
		begin
			websiteURL = "http://www.columbuspolice.org/reports/Results?from=datePlaceholder&to=datePlaceholder&loc=locationPlaceholder&types=9"
			websiteURL.gsub!('datePlaceholder', startTimeObject.strftime("%m/%d/%Y")).gsub!('locationPlaceholder', districtArray[i])
			# Insert search info into URL
			page = agent.get websiteURL
			# Try to direct to Columbus PD report website
		rescue
			if retries > 0
				retries -= 1
				sleep 5
				retry
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
	
				k = 0
				j = 0;
				linkIndex = 1;
				# Counters decared
	
				while ((k < crimeNum) && (k < 145)) do
					report = '';
					for j in 11...crimeReportNumbers[linkIndex]["onclick"].length - 1
						char = '' + crimeReportNumbers[linkIndex]["onclick"][j]
						report += char
					end
					# This loop takes care of setting up the links to each individual crime's page, where more information is listed.
	
					offCampus.puts startTimeObject.strftime("%m/%d/%Y")
					offCampus.puts crimeInfo[k + 1].text
					offCampus.puts crimeInfo[k + 4].text
					offCampus.puts districtArray[i]

					k += 5
					linkIndex += 1
					# Insert information into table
				end
				# Done getting off-campus info for the day
		end
	end
	end

	retries = 3

	begin
		page = agent.post('http://dps-web-01.busfin.ohio-state.edu/police/daily_log_2/view.php', {
			"phrase" => "",
			"report_number" => "",
			"from_month" => "" + startTimeObject.strftime("%m"),
			"from_day" => "" + startTimeObject.strftime("%d"),
			"from_year" => "" + startTimeObject.strftime("%Y"),
			"to_month" => "" + startTimeObject.strftime("%m"),
			"to_day" => "" + startTimeObject.strftime("%d"),
			"to_year" => "" + startTimeObject.strftime("%Y"),
			"view_col" => "report_date",
			"view_cending" => "DESC",
			"searching" => "Search"
		})
		# Attempt to reach OSU PD
	rescue
		if retries > 0
			retries -= 1
			sleep 5
			retry
		end
	else
		puts startTimeObject.strftime("%m/%d/%Y") + "- Retrieving On Campus Data"
		campusPage = Nokogiri::HTML(page.body)
		crimeTable = campusPage.css("table[class='log']")
		crimesFromTable = crimeTable.css("td[class='log']")
		numberOfOSUCrimes = crimesFromTable.length/8
		# Visit OSU PD's web log, get number of crimes committed on campus the previous day

		if numberOfOSUCrimes > 0
			# There were on-campus crimes today, get information and save to textfile.
			i = 0
			while i < crimesFromTable.length do
				onCampus.puts startTimeObject.strftime("%m/%d/%Y")
				onCampus.puts crimesFromTable[i + 5].text
				onCampus.puts crimesFromTable[i + 6].text
				# Save crime type and location for analytics

				i += 8
			end
	end
end

	puts startTimeObject.strftime("%m/%d/%Y") + " information gathered."
	startTimeObject += (1)
	sleep 5
end
offCampus.close
onCampus.close
