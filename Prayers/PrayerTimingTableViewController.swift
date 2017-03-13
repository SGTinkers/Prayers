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
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// remove all notifications on launch
		let notification = UNUserNotificationCenter.current()
		notification.removeAllPendingNotificationRequests()
		notification.removeAllDeliveredNotifications()
		
		// json parsing
		let path = Bundle.main.path(forResource: "2017", ofType: "json")
		
		let monthValue = Calendar.autoupdatingCurrent.component(.month, from: today)
		
		let url = NSURL.init(fileURLWithPath: path!)
		if let data = NSData.init(contentsOf: url as URL) {
			do {
				let json = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as? [[[String: Any]]]
				
				for month in json! { // [[String: Any]]
					for day in month { // [String: Any]
						if let timesArray = day["times"] as? [String] {
							for time in timesArray {
								if let date = self.getDateFrom(dateString: time) {
									let monthValueToCompare = Calendar.autoupdatingCurrent.component(.month, from: date)
									
									if monthValue == monthValueToCompare {
										// conversion for cell text is done later
										dateFormatter.timeZone = TimeZone.init(abbreviation: "UTC")
										dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.sssZ"
										self.prayerStringArray.append(time)
										
										if let defaultDate = self.dateFormatter.date(from: time) {
											// conversion for date object is done here
										
//											print("Date object (UTC): \(defaultDate)")

											var dc = DateComponents()
											dc.year = Calendar.autoupdatingCurrent.component(.year, from: defaultDate)
											dc.month = Calendar.autoupdatingCurrent.component(.month, from: defaultDate)
											dc.day = Calendar.autoupdatingCurrent.component(.day, from: defaultDate)
											dc.hour = Calendar.autoupdatingCurrent.component(.hour, from: defaultDate)
											dc.minute = Calendar.autoupdatingCurrent.component(.minute, from: defaultDate)
											
											let localDate = Calendar.autoupdatingCurrent.date(from: dc)
											
//											let timezoneOffset = 60 * 60 * 8 // +8h
//											
//											let localDate = defaultDate.addingTimeInterval(TimeInterval(timezoneOffset))
//											print("Date object (UTC +8): \(localDate)")
											
											// queue date for notifications
											self.prayerDateArray.append(localDate!)
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
			let todayDay = Calendar.autoupdatingCurrent.component(.day, from: today)
			let dayToCompare = Calendar.autoupdatingCurrent.component(.day, from: date)
			
			let todayHour = Calendar.autoupdatingCurrent.component(.hour, from: today)
			let hourToCompare = Calendar.autoupdatingCurrent.component(.hour, from: date)
			
			// if one of the date object has the same date as today
			if todayDay == dayToCompare {
				// find the hour of the day that has not passed
				if todayHour < hourToCompare {
					// find its index
					if let indexOfDateObject = self.prayerDateArray.index(of: date) {
						let dateForNotification = self.prayerDateArray[indexOfDateObject]
						
						print(Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day, .hour, .minute], from: dateForNotification))
						print(Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day, .hour, .minute], from: today))
						
						let newDateComponents = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day, .hour, .minute], from: dateForNotification)
						
						let notificationTrigger = UNCalendarNotificationTrigger.init(dateMatching: newDateComponents, repeats: false)
						let notificationContent = UNMutableNotificationContent()
						notificationContent.title = "This is a title"
						notificationContent.body = "Time to pray"
						notificationContent.sound = UNNotificationSound.default()
						
						let request = UNNotificationRequest.init(identifier: "Prayers", content: notificationContent, trigger: notificationTrigger)
						notification.add(request, withCompletionHandler: { (error) in
							if let error = error {
								print("Oh no.. this is the error: \(error)")
							}
						})
						
						let alert = UIAlertController.init(title: "Hello", message: "Next alert is at \(newDateComponents)", preferredStyle: .alert)
						let ok = UIAlertAction.init(title: "OK", style: .default, handler: nil)
						alert.addAction(ok)
						self.present(alert, animated: true, completion: nil)
						
						break
					}
				}
			}
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
		
		let newDateString = self.getLocalDateStringFrom(dateString: dateString)
		
		cell.textLabel?.text = newDateString
		

        return cell
    }
	
	func getLocalDateStringFrom(dateString: String) -> String {
		dateFormatter.timeZone = TimeZone.init(abbreviation: "UTC")
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		if let date = self.dateFormatter.date(from: dateString) {
			dateFormatter.timeZone = TimeZone.autoupdatingCurrent
			dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

			return self.dateFormatter.string(from: date)
		} else {
			print("Error")
		}
		
		return "Error"
	}
	
	func getDateFrom(dateString: String) -> Date? {
		dateFormatter.timeZone = TimeZone.init(abbreviation: "UTC")
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		return dateFormatter.date(from: dateString)
	}

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
