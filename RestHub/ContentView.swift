//
//  ContentView.swift
//  RestHub
//
//  Created by MAC on 08/03/2023.
//
/**While it is possible to subtract the desired hours of sleep from the wake-up time to calculate the ideal bedtime, the actual time a person needs to fall asleep can vary depending on various factors such as caffeine intake, exercise, stress levels, and other lifestyle factors. Therefore, it can be challenging to accurately calculate the ideal bedtime using a simple calculation.
 
 If you desire 6 hours of sleep and want to wake up at 8 am and took 3 cups of coffee, going to bed by 2 am would give you the desired amount of sleep. However, the quality of your sleep may be affected by factors such as caffeine intake, stress levels, and exercise, which can vary from person to person.
 
 In contrast, the app uses a machine learning model to provide personalized recommendations based on various factors that can affect sleep quality. The SleepCalculator model considers the time you need to wake up, your desired amount of sleep, and your daily caffeine intake, among other factors, to predict the ideal bedtime that would give you the best chance of getting quality sleep.

 So, if you input your desired wake-up time of 8 am, your desired amount of sleep of 6 hours, and your daily coffee intake of 3 cups into the app, it would use the SleepCalculator model to predict your ideal bedtime. The prediction would be based on the data from the SleepCalculator model, which would consider your input along with various other factors to provide a more personalized and accurate prediction of your ideal bedtime.**/

import CoreML
import SwiftUI

struct ContentView: View {
    
    @State private var wakeUp = defaultWakeTime
    @State private var sleepAmount = 8.0
    @State private var coffeeAmount = 1
    
    @State private var alerTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date.now
    }
    
    /*
     wihtout the keyword "static",our code would produce The error message "Cannot use instance member 'defaultWakeTime' within property initializer; property initializers run before 'self' is available". this occurs because the defaultWakeTime property is being accessed within the property initializer of @State private var wakeUp. However, the defaultWakeTime property is also an instance property and thus, it is not yet initialized when the property initializer for wakeUp is being executed.
     
     To fix this error, we can make the defaultWakeTime property static, then it will be initialized before any instance of ContentView is created, and therefore, you can access it within the property initializer of wakeUp. Here's an example of how to make defaultWakeTime static:
     
     By making defaultWakeTime static, you can access it within the property initializer of wakeUp because static properties are initialized before any instance of the type is created.
     
     ALTERNATIVE METHOD:
     you can also replace the property initializer for wakeUp with an initializer method that initializes wakeUp to the value returned by defaultWakeTime. Here's an example of how to do that:
     
     struct ContentView: View {
     
     var defaultWakeTime: Date {
     var components = DateComponents()
     components.hour = 7
     components.minute = 0
     return Calendar.current.date(from: components) ?? Date.now
     }
     
     @State private var wakeUp = Date()
     
     init() {
     _wakeUp = State(initialValue: defaultWakeTime)
     }
     
     // The rest of the code...
     }
     
     In this code, the wakeUp property is initialized to a default value of Date(), but then immediately overwritten in the initializer method with the value returned by defaultWakeTime.
     */
    
    
    
    var body: some View {
        NavigationView {
            
            Form {
                Section("When do you want to wake up?"){
                    DatePicker("Please enter a time:", selection: $wakeUp, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                Section("Desired amount of sleep:"){
                    //see this least amount of hours the person expects to sleep
                    Stepper("\(sleepAmount.formatted())hours", value: $sleepAmount, in: 4...12, step: 0.25)
                }
                
                Section ("Daily Coffee Intake"){
                    Stepper(coffeeAmount == 1 ? "1 cup" : "\(coffeeAmount) cups", value: $coffeeAmount, in: 1...20)
                    
                    /*---------------If-you-chose-the-PICKERSTYLE----------------------------------------
                     Picker("Daily Coffee Intake:", selection: $coffeeAmount) { ForEach(1..<21) { value in
                        Text("\(value) \(value == 1 ? "cup" : "cups")")}//wherever your range starts at, we start counting with 0.
                    }//Note:: if you use picker, you'd have to change coffeeAmount to zero and make futher configurations for when the user selects an option. Also you'd need to take out the section title*/
                }
                
            }
            .navigationTitle("RestHub")
            .toolbar{
                Button("Calculate", action: calculateBedTime)
            }
            .alert(alerTitle, isPresented: $showingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    func calculateBedTime(){
        //I do want you to focus on the do/catch blocks, because using Core ML can throw errors in two places: loading the model as seen above, but also when we ask for predictions.
        do {
            let config = MLModelConfiguration()
            let model = try sleepCalculator(configuration: config)
            //That model instance is the thing that reads in all our data, and will output a prediction. The configuration is there in case you need to enable a handful of what are fairly obscure options – perhaps folks working in machine learning full time need these
            
            
            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
            /*In general, the app needs to ensure that the wake-up time is always expressed as the number of seconds from midnight on the same day or the next day, depending on the time of day that the user wants to wake up.
            For example, if you want to wake up at 6 pm on the same day that you're asking for the prediction, you can express the wake-up time as 18 hours multiplied by 60 multiplied by 60, giving 64800 seconds from midnight on the same day.
            if the user selects 6:00 pm the netx day as the wake-up time, the app would need to convert it to the number of seconds from midnight on the next day, which would be 18 hours multiplied by 60 multiplied by 60, giving 64800 seconds.*/
            
            let hour = (components.hour ?? 0) * 60 * 60
            let minute = (components.minute ?? 0) * 60
            
            //converting to double because coreML works with doubles
            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffeeAmount))
            
            //subtracting actualSleep value in seconds from the wakeUp (date) to get back a new date, which is bedTime.
            let bedTime = wakeUp - prediction.actualSleep
            alerTitle =  "Your ideal bedtime is:"
            alertMessage = bedTime.formatted(date: .omitted, time: .shortened)
            
        } catch {
            alerTitle = "Error"
            alertMessage =  "Sorry, there was a problem calculating your bedtime."
        }
        
        showingAlert = true
    }
    //https://www.hackingwithswift.com/books/ios-swiftui/connecting-swiftui-to-core-ml
}
    

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


/* ALTERNATIVE UI
 Form {
                 VStack(alignment: .leading, spacing:0){
                     Text("When do you want to wake up?")
                         .font(.headline)
                     
                     DatePicker("Please enter a time:", selection: $wakeUp, displayedComponents: .hourAndMinute)
                         .labelsHidden()
                 }
                 
                 
                 VStack(alignment: .leading, spacing:0){
                     Text("Desired amount of sleep:")
                         .font(.headline)
                     
                     //see this least amount of hours the person expects to sleep
                     Stepper("\(sleepAmount.formatted())hours", value: $sleepAmount, in: 4...12, step:0.25)
                 }
                 
                 
                 VStack(alignment: .leading, spacing:0){
                     Text("Daily Coffee Intake:")
                         .font(.headline)
                     Stepper(coffeeAmount == 1 ? "1 cup" : "\(coffeeAmount) cups", value: $coffeeAmount, in: 1...20)
                 }
}

 */









//https://www.hackingwithswift.com/100/swiftui/27
