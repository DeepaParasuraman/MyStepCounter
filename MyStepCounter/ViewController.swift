//
//  ViewController.swift
//  MyStepCounter
//
//  Created by MACNO on 05/08/2023.
//

import UIKit
import CoreMotion
import HealthKit

class ViewController: UIViewController {

    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    
    let healthStore = HKHealthStore()
    
    @IBOutlet weak var myStepsLbl: UILabel!
    @IBOutlet weak var currentStepsLbl: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        if(ValueAlreadyExist(key: lastCount)){}
        else
        {
            setUserDefault(value: 0, key: lastCount)
        }
        self.checkNotifyPermissions(step: 0)
        
//        if CMPedometer.isStepCountingAvailable() {
//            pedometer.startUpdates(from: Date()) { pedometerData, error in
//                guard let pedometerData = pedometerData, error == nil else { return }
//                DispatchQueue.main.async {
//                    print(pedometerData.numberOfSteps.intValue)
//                    self.currentStepsLbl.text = "Current Steps : \(pedometerData.numberOfSteps.intValue)"
//
//                }
//            }
//        }
        
        pedometer.startUpdates(from: Date(), withHandler: { (pedometerData, error) in
            if let pedData = pedometerData{
                self.currentStepsLbl.text = "Current Steps:\(pedData.numberOfSteps)"
            } else {
                print("no steps")
            }
        })

    }
    
    override func viewWillAppear(_ animated: Bool) {
        let healthKitTypes: Set = [ HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)! ]
        // Check for Authorization
        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { (bool, error) in
            if (bool) {
                // Authorization Successful
                self.getSteps { (result) in
                    DispatchQueue.main.async {
                        let stepCount = String(Int(result))
                        self.myStepsLbl.text = "Todays Total Steps : " + String(stepCount)
                        print("hereeee",Int(result))
                        setUserDefault(value: Int(result), key: totalSteps)
                        self.setResult(mySteps: Int(result))
                    }
                }
            } // end if
        }
    }
    func setResult(mySteps:Int)
    {
        let last_count = getUserDefault(key: lastCount)!
        print("last_count",last_count)
        print("mySteps",mySteps)
        if(mySteps>last_count)
        {
            let m = mySteps / 20
            print("mmm",m)
            let notifyCount = m * 20
            print("notifyCount",notifyCount)
            if(last_count < notifyCount)
            {
                setUserDefault(value: notifyCount, key: lastCount)
                self.checkNotifyPermissions(step: mySteps)
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
                    self.displayNotification(step: getUserDefault(key: totalSteps)!)
                }
            case .denied:
                return
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert,.sound]) {didAllow, error in
                    if didAllow {
                        if(step>0)
                        {
                            self.displayNotification(step: getUserDefault(key: totalSteps)!)
                        }
                    }
                }
            default:
                return
            }
        })
    }
    
    func displayNotification(step:Int){
        let identifier = "step_counter_notification"
        let title = "Step Counter"
        let body = "Your steps count for today is \(step) steps"
        
//        let hour = 1
//        let minute = 1
//
//        let calendar = Calendar.current
//        var dateComponents = DateComponents(calendar: calendar,timeZone: TimeZone.current)
//        dateComponents.hour = hour
//        dateComponents.minute = minute
    
        let notificationCenter = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.add(request)
    }
    
    func getSteps(completion: @escaping (Double) -> Void) {
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
            
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(quantityType: type,
                                               quantitySamplePredicate: nil,
                                               options: [.cumulativeSum],
                                               anchorDate: startOfDay,
                                               intervalComponents: interval)
        
        query.initialResultsHandler = { _, result, error in
                var resultCount = 0.0
                result!.enumerateStatistics(from: startOfDay, to: now) { statistics, _ in

                if let sum = statistics.sumQuantity() {
                    // Get steps (they are of double type)
                    resultCount = sum.doubleValue(for: HKUnit.count())
                } // end if

                // Return
                DispatchQueue.main.async {
                    completion(resultCount)
                }
            }
        }
        
        query.statisticsUpdateHandler = {
            query, statistics, statisticsCollection, error in

            // If new statistics are available
            if let sum = statistics?.sumQuantity() {
                let resultCount = sum.doubleValue(for: HKUnit.count())
                // Return
                DispatchQueue.main.async {
                    completion(resultCount)
                }
            } // end if
        }
        healthStore.execute(query)
    }
}

