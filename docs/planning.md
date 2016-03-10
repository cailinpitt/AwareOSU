# Planning Document for AwareOSU
## Database Schema
- Unique ID (key)
- Arrest/Report #
- Offense
- Victim Name
- Location
- Date Reported
- On Campus (Flag)
Notes: Do we want to include Victim Name in the data collection?

## Process for iOS App:
1. User requests data for a specific day
2. iOS Device makes secure API call to central data server
3. Central Data server checks database and returns JSON object based on parameters of request
4. iOS Devices processes JSON and presents results in a view
5. If an element is selected, iOS device opens a Safari WebView so user can learn more about the crime

## Process for Scraping:
1. On a specified time interval, Scraping Server will refresh its data for the past _n_ days.
2. After scraping, Scraping Server will process the data and commit it to the Central Data server.


## On-Device Scraping vs Remote Server Approach:
- High Latency for processing of data on device
- Computer necessary to process data (battery)
- Over entire user base, massive duplication of computation
- Easier for developers (can use language of choice instead of Swift)
