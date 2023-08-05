//
//  ViewController.swift
//  MyStepCounter
//
//  Created by MACNO on 05/08/2023.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    
    @IBOutlet weak var myStepsLbl: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        if(ValueAlreadyExist(key: lastCount)){}
        else
        {
            setUserDefault(value: 0, key: lastCount)
        }
        self.checkNotifyPermissions(step: 0)
//        activityManager.startActivityUpdates(to: OperationQueue.main) { (activity: CMMotionActivity?) in
//            guard let activity = activity else { return }
//            DispatchQueue.main.async {
//                if activity.stationary {
//                    print("Stationary")
//                } else if activity.walking {
//                    print("Walking")
//                } else if activity.running {
//                    print("Running")
//                } else if activity.automotive {
//                    print("Automotive")
//                }
//            }
//        }
    }
    override func viewDidAppear(_ animated: Bool) {
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { pedometerData, error in
                guard let pedometerData = pedometerData, error == nil else { return }
                DispatchQueue.main.async {
                    print(pedometerData.numberOfSteps.intValue)
                    self.myStepsLbl.text = "My Steps : \(pedometerData.numberOfSteps.intValue)"
                }
                self.setResult(steps: pedometerData.numberOfSteps.intValue)
            }
        }
    }
    func setResult(steps:Int)
    {
        let last_count = getUserDefault(key: lastCount)!
        if(steps>last_count)
        {
            let new_notify_count = last_count + 20
            if(steps > new_notify_count)
            {
                setUserDefault(value: new_notify_count, key: lastCount)
                self.checkNotifyPermissions(step: steps)
            }
        }
    }
    
    func checkNotifyPermissions(step:Int)
    {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings(completionHandler: {
            settings in
            switch settings.authorizationStatus{
            case .authorized:
                if(step>0)
                {
                    self.displayNotification(step: getUserDefault(key: lastCount)!)
                }
            case .denied:
                return
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert,.sound]) {didAllow, error in
                    if didAllow {
                        if(step>0)
                        {
                            self.displayNotification(step: getUserDefault(key: lastCount)!)
                        }
                    }
                }
            default:
                return
            }
        })
    }
    
    func displayNotification(step:Int){
        let identifier = "sptep_counter_notification"
        let title = "Step Counter"
        let body = "Your steps count for today is \(step) steps"
        
        let hour = 00
        let minute = 18
        
        let calendar = Calendar.current
        var dateComponents = DateComponents(calendar: calendar,timeZone: TimeZone.current)
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        
    
        let notificationCenter = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.add(request)
    }
}

