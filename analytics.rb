=begin
	Created by Cailin Pitt on 2/13/2016
	
	Ruby script to perform analytics on crimes AwareOSU reports every month.
=end

# Mail sends out information
require 'mail'

=begin
	Main function
=end
def main
	#offCampusArray = IO.readlines('/home/pi/Documents/AwareOSU/offcampusbatch.txt')
	#onCampusArray = IO.readlines('/home/pi/Documents/AwareOSU/oncampusbatch.txt')
	offCampusArray = IO.readlines('offbatch.txt')
	onCampusArray = IO.readlines('onbatch.txt')

	offcrimes = offCampusCrimeOccurances(offCampusArray)
	offcrimes.each do |key, value|
		  puts "#{key}:#{value}"
	end
end

=begin
	Get number of occurances of each crime
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

main #Call main to start script
