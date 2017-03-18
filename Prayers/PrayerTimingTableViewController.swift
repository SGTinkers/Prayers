//
//  PrayerTimingTableViewController.swift
//  Prayers
//
//  Created by Muhd Mirza on 3/3/17.
//  Copyright © 2017 muhdmirzamz. All rights reserved.
//

import UIKit
import UserNotifications

class PrayerTimingTableViewController: UITableViewController {

	var prayerStringArray: [String] = []
	var prayerDateArray: [Date] = []
	
	let dateFormatter = DateFormatter()
	let today = Date()
	let notification = UNUserNotificationCenter.current()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// remove all notifications on launch
		notification.removeAllPendingNotificationRequests()
		notification.removeAllDeliveredNotifications()
		
		// json parsing
		let path = Bundle.main.path(forResource: "2017", ofType: "json")
		let url = NSURL.init(fileURLWithPath: path!)
		if let data = NSData.init(contentsOf: url as URL) {
			do {
				let json = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as? [[[String: Any]]]
				
				var notifCounter = 0
				
				for monthIterator in json! { // [[String: Any]]
					for dayIterator in monthIterator { // [String: Any]
						if let timesArray = dayIterator["times"] as? [String] {
							for time in timesArray {
								// ios only allows 64 notifications at one time
								if notifCounter < 64 {
									if let date = self.getDateFrom(dateString: time) {
										if today.compare(date) == ComparisonResult.orderedSame || today.compare(date) == ComparisonResult.orderedAscending {
											self.prayerStringArray.append(time)
											
											// craft a date by using date components
											var dc = DateComponents()
											dc.year = Calendar.autoupdatingCurrent.component(.year, from: date)
											dc.month = Calendar.autoupdatingCurrent.component(.month, from: date)
											dc.day = Calendar.autoupdatingCurrent.component(.day, from: date)
											dc.hour = Calendar.autoupdatingCurrent.component(.hour, from: date)
											dc.minute = Calendar.autoupdatingCurrent.component(.minute, from: date)
											
											let localDate = Calendar.autoupdatingCurrent.date(from: dc)
											
											// queue date for notifications
											// every notification is now from this array
											self.prayerDateArray.append(localDate!)
											
											notifCounter += 1
										}
									}
								}
							}
						}
					}
				}
			} catch {
				print(error)
			}
		}
		
		// setup next notifications
		for date in self.prayerDateArray {
			// find its index
			if let indexOfDateObject = self.prayerDateArray.index(of: date) {
				let dateForNotification = self.prayerDateArray[indexOfDateObject]
				
				print(Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day, .hour, .minute], from: dateForNotification))
				print(Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day, .hour, .minute], from: today))
				
				// break down into date components
				let dateComponents = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day, .hour, .minute], from: dateForNotification)
				
				// setup notification trigger
				let notificationTrigger = UNCalendarNotificationTrigger.init(dateMatching: dateComponents, repeats: false)
				// setup notification content
				let notificationContent = UNMutableNotificationContent()
				notificationContent.title = "It's prayers time"
				notificationContent.body = "Time to pray"
				notificationContent.sound = UNNotificationSound.default()
				
				// add notification trigger and content to notification request
				let request = UNNotificationRequest.init(identifier: "Prayers\(indexOfDateObject)", content: notificationContent, trigger: notificationTrigger)
				
				// add the request
				notification.add(request, withCompletionHandler: { (error) in
					if let error = error {
						print("Oh no.. this is the error: \(error)")
					}
				})
			}
		}
		
		self.notification.getPendingNotificationRequests { (request: [UNNotificationRequest]) in
			let alert = UIAlertController.init(title: "Hello", message: "You have \(request.count) notifications lined up", preferredStyle: .alert)
			let ok = UIAlertAction.init(title: "OK", style: .default, handler: nil)
			alert.addAction(ok)
			self.present(alert, animated: true, completion: nil)
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.prayerStringArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        // Configure the cell...
		let dateString = self.prayerStringArray[indexPath.row]
		
		let localDateString = self.getLocalDateString(from: dateString)
		
		cell.textLabel?.text = localDateString
		
        return cell
    }
	
	// helper functions
	func getLocalDateString(from dateString: String) -> String {
		// setup a UTC formatted dateFormatter
		self.dateFormatter.timeZone = TimeZone.init(abbreviation: "UTC")
		self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		
		// get the date object
		if let date = self.dateFormatter.date(from: dateString) {
			// setup a current time zone formatted dateFormatter
			dateFormatter.timeZone = TimeZone.autoupdatingCurrent
			dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
			
			// get the string
			return self.dateFormatter.string(from: date)
		} else {
			print("Error")
		}
		
		return "Error"
	}
	
	func getDateFrom(dateString: String) -> Date? {
		// setup a UTC formatted dateFormatter
		dateFormatter.timeZone = TimeZone.init(abbreviation: "UTC")
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		
		// get the date
		return dateFormatter.date(from: dateString)
	}

}
