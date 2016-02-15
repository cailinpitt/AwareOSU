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
	#offCampusArray = IO.readlines('/home/pi/Documents/AwareOSU/offcampusbatch.txt')
	#onCampusArray = IO.readlines('/home/pi/Documents/AwareOSU/oncampusbatch.txt')
	offCampusArray = IO.readlines('offbatch.txt')
	onCampusArray = IO.readlines('onbatch.txt')

	offcrimes = offCampusCrimeOccurances(offCampusArray)
	oncrimes = onCampusCrimeOccurances(onCampusArray)
	
	offCrimeDescriptions = Array.new
	offCrimeNumbers = Array.new
	totalOffCrimes = offcrimes.values.inject(:+)
	offcrimes.each do |key, value|
		  offCrimeDescriptions.push key.to_s + " #{(100.0 * value.to_i / totalOffCrimes).round}%"
		  offCrimeNumbers.push value.to_i
	end
	
	onCrimeDescriptions = Array.new
	onCrimeNumbers = Array.new
	totalOnCrimes = oncrimes.values.inject(:+)
	oncrimes.each do |key, value|
		onCrimeDescriptions.push key.to_s + " #{(100.0 * value.to_i / totalOnCrimes).round}%"
		onCrimeNumbers.push value.to_i
	end
	
=begin
	oncrimes.each do |key, value|
		  puts "#{key}:#{value}"
	end
=end
	htmlString = "<h3>Crime Occurances</h3>"
	htmlString += Gchart.pie(:data => offCrimeNumbers, :title => 'Off Campus Crime Occurences', :format => 'image_tag', :labels => offCrimeDescriptions, :size => '785x380',  :theme => :thirty7signals)
	htmlString += Gchart.pie(:data => onCrimeNumbers, :title => 'On Campus Crime Occurences', :format => 'image_tag', :labels => onCrimeDescriptions, :size => '785x380',  :theme => :thirty7signals)
	sendEmail(htmlString)
	# Send Analytics email
end

=begin
	Get number of occurances of each off campus crime
=end
def offCampusCrimeOccurances(offCampusArray)
	offCrimeTypes = Array.new
	
	for i in 0...offCampusArray.length
		if i % 2 == 0
			offCampusArray[i] = offCampusArray[i].split '-'
			# Split crime type
			for k in 0...offCampusArray.length
				if offCampusArray[i][k] != nil
					offCampusArray[i][k].strip!
				end
			end
			# Clean up formatting
			
			if offCampusArray[i].map(&:upcase).include? "ATTEMPT"
				offCrimeTypes.push offCampusArray[i][1].delete("\n") + " - Attempt"
			else
				offCrimeTypes.push offCampusArray[i][1].delete("\n")
			end
			# Distinguish between committed crime and attempted crime
		end
	end

	offcrimes = Hash.new 0
	offCrimeTypes.each {|v| offcrimes[v] += 1}
	
	return offcrimes
end

=begin
	Get number of occurances of each on campus crime
=end
def onCampusCrimeOccurances(onCampusArray)
	onCrimeTypes = Array.new
	
	for i in 0...onCampusArray.length
		if i % 2 == 0
			onCrimeTypes.push onCampusArray[i].delete("\n")
		end
	end
	
	oncrimes = Hash.new 0
	onCrimeTypes.each {|v| oncrimes[v] += 1}
	
	return oncrimes
end

def sendEmail(htmlString)
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
		:subject => "AwareOSU - Analytics"
	});
	
	
	mail.attachments['AwareOSULogo.png'] = File.read('images/AwareOSULogo.png')
	pic = mail.attachments['AwareOSULogo.png']
	html_part = Mail::Part.new do
		 content_type 'text/html; charset=UTF-8'
		 body "<center><img src='cid:#{pic.cid}'></center>" + htmlString
	end
	
	mail.html_part  = html_part
	mail.deliver!
end

main #Call main to start script
