# Aware OSU
Be aware of crimes around the campus area.

# Background
OSU students (well, college students in general) enjoy being safe. Whenever a crime occures on campus (ex. sexual assult, robbery), OSU sends every student and staff an email breifly explaining the crime. However, OSU doesn't send crime alerts for crimes that occur *around* campus (where many students live). The reality is that we live in a dangerous world, and we want to be aware of what is happening around us.

# Features
* Program runs once every day (using a CRON job), webscrapes the [Columbus Police Department's unofficial web report portal](http://www.columbuspolice.org/reports/), finds the previous days crimes, and emails the list of crimes to specified users.

# Great overview. What is the code actually doing?
* This program utilizes three great gems, Mechanize, Nokogiri, and Mail. This program visits the CPD web portal (listed above) using Mechanize, parses the HTML of the search page containg all crimes committed yesterday using Nokogiri, and send the information out in a HTML table using Mail.

# Images
![Email from Aware OSU](https://raw.githubusercontent.com/CailinPitt/AwareOSU/master/images/email.PNG)

# Goals
1. Develop Android App (no current plans for iPhone because it's $100/year to be an iOS developer, poor college student problems)
2. Make this more automatic (I currently have to manually add emails to send information to)
3. Get Raspberry Pi and run program on there (my computer isn't always on at 9:00 AM everyday for CRON job to run)
4. Possibly setup text message integration. I imagine this program texting you the number of crimes that have occurred from the previous day. I'm on the fence as to whether this is a useful feature
5. Create GitHub page to make app more inviting

# How to sign up
* Visit the [Aware OSU Google form](http://goo.gl/forms/Oy5kZ4xHbX) to sign-up.
