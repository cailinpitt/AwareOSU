=begin
	Created by Cailin Pitt on 2/13/2016
	
	Ruby script to perform analytics on crimes that AwareOSU reports on every month.
=end

# Mail sends out information
require 'mail'

offCampusArray = IO.readlines('/home/pi/Documents/AwareOSU/offcampusbatch.txt')
onCampusArray = IO.readlines('/home/pi/Documents/AwareOSU/oncampusbatch.txt')
# Read crime information into Arrays
