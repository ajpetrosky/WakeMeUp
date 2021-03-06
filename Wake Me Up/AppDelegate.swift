//
//  AppDelegate.swift
//  Wake Me Up
//
//  Created by Andrew Petrosky on 4/8/17.
//  Copyright © 2017 edu.upenn.seas.cis195. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UINavigationBar.appearance().barTintColor = UIColor(red: 153/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().isTranslucent = false
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION",
                                                title: "Snooze",
                                                options: UNNotificationActionOptions(rawValue: 0))
        let snoozeCategory = UNNotificationCategory(identifier: "SNOOZABLE",
                                                     actions: [snoozeAction],
                                                     intentIdentifiers: [],
                                                     options: .customDismissAction)
        let genCategory = UNNotificationCategory(identifier: "GENERAL",
                                                 actions: [],
                                                 intentIdentifiers: [],
                                                 options: .customDismissAction)
        center.setNotificationCategories([genCategory, snoozeCategory])
        
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
        return true
    }
    
    // MARK: - Notification center delegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Swift.Void) {
        let id = response.notification.request.identifier
        if id == "check" {
            Messaging.cancelText()
            completionHandler()
            return
        }
        
        let alarm = getAlarm(notification: response.notification)
        let action = response.actionIdentifier
        if action == UNNotificationDefaultActionIdentifier {
            
            let repeats = alarm.value(forKeyPath: "timeRepeat") as! String
            if repeats == "" {
                alarm.setValue(false, forKey: "enabled")
                saveContext()
            }
            
            /////////CHANGE TIME FOR ACTUAL APP, BUT MAKE SHORT FOR DEMOS
            let contactName = alarm.value(forKeyPath: "textContact") as! String
            if contactName !=  "None" {
                let timeTillCheck = 10.0
                AlarmNotifications.checkAwakeNotification(time: timeTillCheck)
                var contactNumber = alarm.value(forKeyPath: "contactNumber") as! String
                contactNumber = "+1" + contactNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: "+1", with: "")
                let textAfter = Double(alarm.value(forKeyPath: "textAfter") as! String)
                let delay = (textAfter! * 60.0) + timeTillCheck
                Messaging.sendText(contactName: contactName, contactNumber: contactNumber, delay: delay)
            }
            
        } else if action == UNNotificationDismissActionIdentifier {
            let snooze = alarm.value(forKey: "snooze") as! Bool
            if snooze {
                AlarmNotifications.setSnoozeNotification(alarm: alarm)
            } else {
                let repeats = alarm.value(forKeyPath: "timeRepeat") as! String
                if repeats == "" {
                    alarm.setValue(false, forKey: "enabled")
                    saveContext()
                }
            }
        }
        completionHandler()
    }
    
    func getAlarm(notification : UNNotification) -> NSManagedObject {
        let managedContext = self.persistentContainer.viewContext
        let startIndex = notification.request.identifier.startIndex
        let index = notification.request.identifier.index(startIndex, offsetBy: notification.request.identifier.characters.count - 1)
        let alarmId = notification.request.identifier.substring(to: index)
        let id = persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: URL(string: alarmId)!)
        let alarm = managedContext.object(with: id!)
        
        return alarm
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Wake_Me_Up")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

