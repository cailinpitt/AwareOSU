=begin
	Created by Cailin Pitt on 2/13/2016
	
	Ruby script to perform analytics on crimes AwareOSU reports every month.
=end

# Mail sends out information
require 'mail'
# GChart uses the Google Chart API to visualize crime data
require 'gchart'
=begin
	Main function
=end
def main
	offCampusArray = IO.readlines('/home/pi/Documents/AwareOSU/offcampusbatch.txt')
	onCampusArray = IO.readlines('/home/pi/Documents/AwareOSU/oncampusbatch.txt')

	offcrimes = offCampusCrimeOccurances(offCampusArray)
	oncrimes = onCampusCrimeOccurances(onCampusArray)
	offcrimelocationshash = offCampusCrimeLocations(offCampusArray)
	oncrimelocationshash = onCampusCrimeLocations(onCampusArray)
	offcampusdatehash = offCampusFrequencyByDate(offCampusArray)
	oncampusdatehash = onCampusFrequencyByDate(onCampusArray)
	# Parse data
	
	offCrimeDescriptions = Array.new
	offCrimeNumbers = Array.new
	totalOffCrimes = offcrimes.values.inject(:+)
	offcrimes.each do |key, value|
		  offCrimeDescriptions.push key.to_s + " #{(100.0 * value.to_i / totalOffCrimes).round}%"
		  offCrimeNumbers.push value.to_i
	end
	# Get percentage of off campus crime types
	
	onCrimeDescriptions = Array.new
	onCrimeNumbers = Array.new
	totalOnCrimes = oncrimes.values.inject(:+)
	oncrimes.each do |key, value|
		onCrimeDescriptions.push key.to_s + " #{(100.0 * value.to_i / totalOnCrimes).round}%"
		onCrimeNumbers.push value.to_i
	end
	# Get percentage of on campus crime types
	
	offCrimeLocations = Array.new
	offCrimeLocationNumbers = Array.new
	totalOffCrimeLocations = offcrimelocationshash.values.inject(:+)
	offcrimelocationshash.each do |key, value|
		offCrimeLocations.push key.to_s.sub('dis', "District ") + " #{(100.0 * value.to_i / totalOffCrimeLocations).round}%"
		offCrimeLocationNumbers.push value.to_i
	end
	# Get locations of off campus crimes by district
	
	onCrimeLocations = Array.new
	onCrimeLocationNumbers = Array.new
	totalOnCrimeLocations = oncrimelocationshash.values.inject(:+)
	oncrimelocationshash.each do |key, value|
		onCrimeLocations.push key.to_s + " #{(100.0 * value.to_i / totalOnCrimeLocations).round}%"
		onCrimeLocationNumbers.push value.to_i
	end
	# Get locations of on campus crimes
	
	offCrimeDates = Array.new
	offCrimeFreq = Array.new
	i = 0
	offcampusdatehash = offcampusdatehash.sort_by{ |k, v| v }.reverse.to_h
	offcampusdatehash.each do |key, value|
		if i < 5
			offCrimeDates.push key.to_s + " (#{value.to_i})"
			offCrimeFreq.push value.to_i
		end
		i += 1
	end
	# Get top five off campus days with the most crimes
	
	onCrimeDates = Array.new
	onCrimeFreq = Array.new
	i = 0
	oncampusdatehash = oncampusdatehash.sort_by{ |k, v| v }.reverse.to_h
	oncampusdatehash.each do |key, value|
		if i < 5
			onCrimeDates.push key.to_s + " (#{value.to_i})"
			onCrimeFreq.push value.to_i
		end
		i += 1
	end
	# Get top five off campus days with the most crimes

	htmlString = "<h1>Analytics for the month of #{(Time.now - (3600 * 24)).strftime("%B")}</h1><br>"
	htmlString += "<p>For the month of #{(Time.now - (3600 * 24)).strftime("%B")}, AwareOSU reported <b>#{totalOffCrimes} off campus crimes</b> and <b>#{totalOnCrimes} on campus crimes</b>, for a total of <b>#{totalOffCrimes + totalOnCrimes} crimes</b>.</p><br>"
	htmlString += "<br><hr>"
	htmlString += "<h2>Crime Occurances</h2>"
	htmlString += "<center>" + Gchart.pie(:data => offCrimeNumbers, :title => 'Off Campus Crime Occurences', :format => 'image_tag', :labels => offCrimeDescriptions, :size => '785x380',  :theme => :thirty7signals) + "</center>"
	htmlString += "<br>"
	htmlString += "<center>" + Gchart.pie(:data => onCrimeNumbers, :title => 'On Campus Crime Occurences', :format => 'image_tag', :labels => onCrimeDescriptions, :size => '785x380',  :theme => :thirty7signals) + "</center>"
	htmlString += "<br><br><hr>"
	htmlString += "<h2>Crime Locations</h2>"
	htmlString += "<center>" + Gchart.pie(:data => offCrimeLocationNumbers, :title => 'Off Campus Crime Locations (By District)', :format => 'image_tag', :labels => offCrimeLocations, :size => '785x380',  :theme => :thirty7signals) + "</center>"
	htmlString += "<center>" + Gchart.pie(:data => onCrimeLocationNumbers, :title => 'On Campus Crime Locations', :format => 'image_tag', :labels => onCrimeLocations, :size => '785x380',  :theme => :thirty7signals) + "</center>"
	htmlString += "<br><br><hr>"
	htmlString += "<h2>Top Five Busiest Days</h2>"
	htmlString += "<p>For <b>off campus crimes</b>, #{offcampusdatehash.max_by{ |k,v| v }[0]} had the most crimes (#{offcampusdatehash.max_by{ |k,v| v }[1]}) reported in the month of #{(Time.now - (3600 * 24)).strftime("%B")}. For <b>on campus crimes</b>, #{oncampusdatehash.max_by{ |k,v| v }[0]} had the most crimes reported (#{oncampusdatehash.max_by{ |k,v| v }[1]}).</p><br>"
	htmlString += "<center>" + Gchart.line(:data => offCrimeFreq, :title => 'Off Campus dates', :format => 'image_tag', :labels => offCrimeDates, :bar_width_and_spacing => 25, :size => '700x200', :line_colors => 'bb0000') + "</center>"
	htmlString += "<br><center>" + Gchart.line(:data => onCrimeFreq, :title => 'On Campus dates', :format => 'image_tag', :labels => onCrimeDates, :bar_width_and_spacing => 25, :size => '700x200', :line_colors => 'bb0000') + "</center>"
	# Piece together HTML email based on data

	createCSVFiles()
	# Export data into CSV file
	
	sendEmail(htmlString)
	# Send Analytics email
end

=begin
	Get number of occurances of each off campus crime
=end
def offCampusCrimeOccurances(offCampusArray)
	offCrimeTypes = Array.new
	
	i = 0
	while i < offCampusArray.length
		offCampusArray[i + 1] = offCampusArray[i + 1].split '-'
		# Split crime type
		for k in 0...offCampusArray.length
			if offCampusArray[i + 1][k] != nil
				offCampusArray[i + 1][k].strip!
			end
		end
		# Clean up formatting
		
		if offCampusArray[i + 1].map(&:upcase).include? "ATTEMPT"
			offCrimeTypes.push offCampusArray[i + 1][1].delete("\n") + " - Attempt"
		else
			offCrimeTypes.push offCampusArray[i + 1][1].delete("\n")
		end
		# Distinguish between committed crime and attempted crime
		i += 4
	end

	offcrimes = Hash.new 0
	offCrimeTypes.each {|v| offcrimes[v] += 1}
	# Calculate frequency
	
	return offcrimes
end

=begin
	Get number of occurances of each on campus crime
=end
def onCampusCrimeOccurances(onCampusArray)
	onCrimeTypes = Array.new
	
	i = 0
	while i < onCampusArray.length
		onCrimeTypes.push onCampusArray[i + 1].delete("\n").strip
		
		i += 3
	end
	
	oncrimes = Hash.new 0
	onCrimeTypes.each {|v| oncrimes[v] += 1}
	# Calculate frequency
	
	return oncrimes
end

=begin
	Get locations of each off campus crime by district
=end
def offCampusCrimeLocations(offCampusArray)
	offCrimeLoc = Array.new
	i = 0
	while i < offCampusArray.length
		offCrimeLoc.push offCampusArray[i + 3].delete("\n").strip
		i += 4
	end
	
	offcrimes = Hash.new 0
	offCrimeLoc.each {|v| offcrimes[v] += 1}
	# Calculate frequency
	
	return offcrimes
end


=begin
	Get locations of each on campus crime
=end
def onCampusCrimeLocations(onCampusArray)
	onCrimeTypes = Array.new
	
	i = 0
	while i < onCampusArray.length
		onCrimeTypes.push onCampusArray[i + 2].delete("\n").strip
		
		i += 3
	end
	
	oncrimes = Hash.new 0
	onCrimeTypes.each {|v| oncrimes[v] += 1}
	# Calculate frequency
	
	return oncrimes
end

=begin
	Get number of off campus crimes per day
=end
def offCampusFrequencyByDate(offCampusArray)
	offCrimeDates = Array.new
	
	i = 0
	while i < offCampusArray.length
		offCampusArray[i].strip!.delete("\n")
		# Clean up formatting
		
		offCrimeDates.push offCampusArray[i]
		i += 4
	end

	offdates = Hash.new 0
	offCrimeDates.each {|v| offdates[v] += 1}
	# Calculate frequency
	
	return offdates
end

=begin
	Get number of on campus crimes per day
=end
def onCampusFrequencyByDate(onCampusArray)
	onCrimeDates = Array.new
	
	i = 0
	while i < onCampusArray.length - 1
		onCampusArray[i].strip!.delete("\n")
		# Clean up formatting
		onCrimeDates.push onCampusArray[i]
		i += 3
	end

	ondates = Hash.new 0
	onCrimeDates.each {|v| ondates[v] += 1}
	
	return ondates
end

=begin
	Create CSV files
=end
def createCSVFiles()
	onCSV = File.open("/home/pi/Documents/AwareOSU/OnCampus_#{(Time.now - (3600 * 24)).strftime("%B")}.csv", "w")
	offCSV = File.open("/home/pi/Documents/AwareOSU/OffCampus_#{(Time.now - (3600 * 24)).strftime("%B")}.csv", "w")
	
	offCampus = IO.readlines('/home/pi/Documents/AwareOSU/offcampusbatch.txt')
	onCampus = IO.readlines('/home/pi/Documents/AwareOSU/oncampusbatch.txt')
	# Open files
	
	onCSV.puts "Date,CrimeType,Location"
	offCSV.puts "Date,CrimeType,Address,District"
	# Print CSV headings

	i = 0
	while i < offCampus.length
		offCSV.puts offCampus[i].strip! + "," + offCampus[i + 1].strip!+ "," + offCampus[i + 2].strip! + "," + offCampus[i + 3].strip!
		# Clean up formatting, print to CSV file
		i += 4
	end
	
	i = 0
	while i < onCampus.length
		onCSV.puts onCampus[i].strip!.delete("\n") + "," + onCampus[i + 1].strip!.delete("\n") + "," + onCampus[i + 2].strip!.delete("\n")
		# Clean up formatting, print to CSV file
		i += 3
	end
	
	onCSV.close
	offCSV.close
	# Close files
end

=begin
	Send analytics email to subscribers
=end
def sendEmail(htmlString)
	#passArray = IO.readlines('/home/pi/Documents/p')
	
	options = {	:address => "smtp.gmail.com",
							:port => 587,
							:user_name => 'awareosu',
							:password => passArray[0].delete!("\n"),
							:authentication => 'plain',
							:enable_starttls_auto	=> true  }

	Mail.defaults do
		delivery_method :smtp, options
	end
	# Set up mail options, authenticate


	mail = Mail.new({
		:to => 'cailinpitt1@gmail.com',
		:from => 'awareosu@gmail.com',
		:subject => "AwareOSU - #{(Time.now - (3600 * 24)).strftime("%B")} Analytics"
	});
	# Initialize email
	
	mail.attachments['AwareOSULogo.png'] = File.read('images/AwareOSULogo.png')
	pic = mail.attachments['AwareOSULogo.png']
	
	mail.add_file("OnCampus_#{(Time.now - (3600 * 24)).strftime("%B")}.csv")
	mail.add_file("OffCampus_#{(Time.now - (3600 * 24)).strftime("%B")}.csv")
	# Attach CSV files
	
	html_part = Mail::Part.new do
		 content_type 'text/html; charset=UTF-8'
		 body "<center><img src='cid:#{pic.cid}'></center>" + htmlString + "<br><br><br><p>Best,</p><p>AwareOSU</p><br><p>P.S. <a href='http://cailinpitt.github.io/AwareOSU/definitions'>Confused about the meaning of a crime?</a></p><p>Please visit this <a href='http://goo.gl/forms/n3q6D53TT3'>link</a> to subscribe/unsubscribe.</p>"
	end
	# Insert email body into mail object
	
	mail.html_part  = html_part
	mail.deliver!
	# Deliver email
end

main #Call main to start script
