<p align="center">
 <a href = "http://cailinpitt.github.io/AwareOSU/">
  <img src = "https://raw.githubusercontent.com/CailinPitt/AwareOSUAndroid/master/Images/AwareOSULogo.png" alt = "Logo" title = "Main site" />
 </a>
</p>

# Background
OSU students (well, college students in general) enjoy being safe. Whenever a crime occurs on campus that has a continuing safety threat, OSU sends every student and staff an email briefly explaining the crime. However, OSU doesn't send crime alerts for all crimes that occur *on and around* campus (where many students live). The reality is that we live in a dangerous world, and we want to be aware of what is happening around us.

# Features
Program runs once every day (using a CRON job), webscrapes the [Columbus Police Department's unofficial web report portal](http://www.columbuspolice.org/reports/) (to find off-campus crimes committed in zone 4, more on zone 4 later) and the [OSU Police department's daily log system](http://www.ps.ohio-state.edu/police/daily_log/view.php?date=yesterday), finds the previous days crimes, and emails the list of crimes to a Google Group of users who signed up for the service.

# Great overview. What is the code actually doing?
This Ruby program utilizes three great gems, Mechanize, Nokogiri, and Mail. This program visits the CPD web portal and OSU PD online log system (listed above) using Mechanize, parses the HTML of the search page containing all crimes committed yesterday using Nokogiri, and sends the information out in a HTML table using Mail.

# Images
#### Email from AwareOSU
![Email from AwareOSU (Map)](https://raw.githubusercontent.com/CailinPitt/AwareOSU/master/images/fullEmail1.PNG)
![Email from AwareOSU](https://raw.githubusercontent.com/CailinPitt/AwareOSU/master/images/fullEmail2.PNG)
---

#### Looks good on mobile too
<img src="https://raw.githubusercontent.com/CailinPitt/AwareOSU/master/images/image1.PNG" alt="Mobile" width="250" height="445"/>

---

#### Say hi to the Raspberry Pi that runs AwareOSU every morning!
![Raspberry Pi](https://raw.githubusercontent.com/CailinPitt/AwareOSU/master/images/pi.png)

---
#### Off-campus crime information is pulled from parts of Zone 4 (Districts 30, 33, 34, 40, 41, 42, 43, 44, 50, and 53), visualized here
![Zone 4](https://raw.githubusercontent.com/CailinPitt/AwareOSU/master/images/zone4.PNG)

# Why are some crimes listed multiple times?
For example:

![Sometimes you may see crimes listed multiple times in a digest](https://raw.githubusercontent.com/CailinPitt/AwareOSU/master/images/repeat.PNG)

This is because some crimes may have multiple victims, as seen on the Columbus Police Department's web portal:
![Multiple crimes](https://raw.githubusercontent.com/CailinPitt/AwareOSU/master/images/repeat1.PNG)

Currently, victim names aren't included in the digest. Even though this is publically accessible information, I'm not sure how comfortable people would feel with names being emailed to the 400+ AwareOSU users.

# What does the shell script do?
My Pi sometimes runs into an issue where it has trouble staying connected to the Internet while using an ethernet connection. It will say that it has a connection, but in actuality I cannot access the internet. This seems to be a semi-common problem among Pis, and this also causes problems for AwareOSU since it can't access the internet if there isn't a connection. This script resets the ethernet connection every morning one minute before AwareOSU is scheduled to run, ensuring that the Pi has a valid, working internet connection.

# Goals
1. Develop AwareOSU mobile applications for Android and iOS.
  * AwareOSU for Android has been released! Download it [here](https://play.google.com/store/apps/details?id=awareosu.example.cailin.awareosu).

# How to sign up
Visit the [AwareOSU Google form](http://goo.gl/forms/Oy5kZ4xHbX) to sign-up for either a daily or weekly delivery option.

# Milestones
* 01/13/2016 - AwareOSU has 800 users.

* 01/09/2016 - [AwareOSU for Android is released](https://play.google.com/store/apps/details?id=awareosu.example.cailin.awareosu).

* 12/18/2015 - [Development of AwareOSU for Android begins](https://github.com/CailinPitt/AwareOSUAndroid).

* 12/10/2015 - AwareOSU now has a weekly delivery option, in addition to a daily delivery option.

* 12/03/2015 - AwareOSU has 700 users.

* 12/01/2015 - AwareOSU now includes static Google Maps so users can visualize where crimes occurred.

* 11/25/2015 - AwareOSU has 600 users.

* 11/24/2015 - AwareOSU has 500 users.

* 10/27/2015 - AwareOSU has 400 users (note that 10/27/2015 was the day OSU recieved an online threat).

* 10/27/2015 - AwareOSU has 300 users.

* 10/27/2015 - AwareOSU has 200 users.

* 10/24/2015 - AwareOSU is now running from a Raspberry Pi! What does this mean? Basically, this means that AwareOSU is just about fully automated. The only thing I do now is add emails to the Google Group of people who have subscribed, and the Pi uses a CRON job to run Aware OSU every morning at 10:15.

* 10/22/2015 - Program now searches and retrieves on-campus crimes, in addition to off-campus crimes. 

* 10/17/2015 - AwareOSU has 100 users.

* 10/17/2015 - Apparently Google only lets users send out a max of 100 emails/day, so the awareosu@gmail.com account got suspended for a day. From now on, I will be using a Google Group to mass email everyone who signed up through the Google Form. For future software engineers: this is why we test every aspect of our code.

* 10/16/2015 - AwareOSU is released.

# Press
* [1870 Magazine](http://1870now.com/safe-and-sound-osu-student-designs-crime-notification-service/)
* [The Lantern](http://thelantern.com/2015/12/ohio-state-student-creates-crime-awareness-email-service/)
* [NBC4](http://nbc4i.com/2015/11/24/osu-student-creates-computer-program-to-track-crimes-in-and-around-campus/)
* [The Columbus Dispatch](http://www.dispatch.com/content/stories/local/2015/11/24/app-gathers-osu-area-cop-reports.html)
* [Lantern TV](https://youtu.be/MAaY5FkLQqI?t=1m51s)
* [Students for Concealed Carry](http://concealedcampus.org/2015/10/students-for-concealed-carry-applauds-student-led-crime-awareness-initiative/)

# Disclaimer
[Crimes listed on CPD's web portal is not representative of all crimes that have occurred](http://www.columbuspolice.org/reports/About).
