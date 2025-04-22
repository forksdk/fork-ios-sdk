//
//  File.swift
//  
//
//  Created by Aleksandras Gaidamausas on 15/08/2024.
//

import Foundation


class GpxParser : NSObject, XMLParserDelegate {

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
        for (attr_key, attr_val) in attributeDict {
            print("Key: \(attr_key), value: \(attr_val)")
        }
    }

}


class GpxWorkoutHelper {
    
    func parseGpxXml(xmlContent: String) {
        
        let data = Data(xmlContent.utf8)
        
        let parser = GpxParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        
        xmlParser.parse()
        
        //        let xml = XML.parse(data)
        //        
        //        // Most of the elements can then easily be retrieved, thanks to dynamic member lookup.
        //        
        //        let gpx = xml.gpx
        //        
        //        let startDate = gpx.metadata.time
        //        let track = gpx.trk
        //        let name = track.name
        //        
        //        // Next is to retrieve the trackpoint data. To do this we first get an array of trackpoint data and then map it to our custom object.
        //        
        //        let trackpoints = track.trkseg.trkpt
        //        let workout = Workout()
        //        workout.locations = trackpoints.map({ point -> TrackPoint in
        //            let longitude = point.attributes["lon"]
        //            let latitude = point.attributes["lat"]
        //            let elevation = point.ele.text
        //            let time = point.time.text
        //            let extensions = point.extensions["gpxtpx:TrackPointExtension"]
        //            let heartRate = extensions["gpxtpx:hr"].text
        //            let cadenece = extensions["gpxtpx:cad"].text
        //            
        //            // Then create the custom object with the above data and return.
        //        })
    }
    
    //func addWorkout(store: ForkStore, workout: GpxWorkout) {
    //    // Grab the start date from the workout, and the end date from the timestamp of the last trackpoint.
    //    let startDate = workout.startDate
    //    let finishDate = workout.trackpoints.last!.timeStamp
    //
    //    // The distance is a bit different as we need to calculate this from the trackpoints. I will pick up on how we calcuate the total distance later.
    //    let totalDistance = HKQuantity(unit: HKUnit.meter(), doubleValue: calculatedTotalDistance)
    //
    //    let hkworkout = HKWorkout(activityType: .running, start: startDate, end: finishTime, workoutEvents: nil, totalEnergyBurned: nil, totalDistance:  totalDistance, device: nil, metadata: nil)
    //    
    //    // Samples will hold a reference to all the sample data that we will later link to our workout.
    //    var samples: [HKQuantitySample] = []
    //    
    //    // We create a routeBuilder object which is an instance of HKWorkoutRouteBuilder. This allows us to create a route from CLLocation data which can then be linked to a workout.
    //    let routeBuilder = HKWorkoutRouteBuilder(healthStore: HKHealthStore(), device: nil)
    //    
    //    // We need to create a reference to store the previous location and previous timestamp, so we can work out the distance between the two.
    //    var previousLocation: CLLocation?
    //    var previousTimeStamp: Date?
    //
    //    // Also need a totalDistance variable to keep track of the total distance. This is the total distance which we added to the HKWorkout when we initalised it.
    //    var totalDistance: Double = 0
    //
    //    workout.trackpoints.forEach({ (trackpoint) in
    //        
    //        // To calcualte the heart rate we first set up the HKQuantity to tell the sample what unit of measurmant this piece of data is.
    //        let heartRateQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: trackpoint.heartRate)
    //        
    //        // We then get the quantity type for heart rate.
    //        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    //        
    //        // Finally create the sample data by passing in the quantity and the type. Notice how the start and end date are the same. This is because our track points are calculated at a single point of time, and the data we get is for that time only.
    //        let heartRateSample = HKQuantitySample(type: heartRateType, quantity: heartRateQuantity, start: trackpoint.timeStamp, end: trackpoint.timeStamp)
    //        
    //        // The sample then gets added to our sample array.
    //        samples.append(heartRateSample)
    //        
    //        
    //        
    //        // We first create the location data by instantiating a CLLocation object by passing in the relevant longitude, latitude, elevation and time data from the track point.
    //        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude:  trackpoint.latitude, longitude: trackpoint.longitude),
    //                                  altitude: trackpoint.elevation,
    //                                  horizontalAccuracy: -1,
    //                                  verticalAccuracy: -1,
    //                                  timestamp: trackpoint.timeStamp
    //        )
    //
    //        // Finally insert the location data to the routeBuilder.
    //        // We can either collect all the location data and add the array at the end, but for simplicity I'm doing it on the individual track points inside the loop.
    //        routeBuilder.insertRouteData([location], completion: { (finish, error) in
    //            print("what")
    //        }
    //                                     
    //                                     // We first unwrap the previous location and timestamp. If they are nil then we don't create any sample data.
    //                                     if let previousLocation = previousLocation, let previousTimeStamp = previousTimeStamp {
    //                                         
    //                                         // Calculate the distance using the previous location and the current one.
    //                                         let distance = location.distance(from: previousLocation)
    //                                         
    //                                         // Update global distance.
    //                                         totalDistance += distance
    //                                         
    //                                         // Create the quantity, which for this sample is in meters.
    //                                         let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: distance)
    //                                         
    //                                         // We then get the quantity type for heart rate.
    //                                         let distanceType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!
    //                                         
    //                                         // This sample is very similar to the heart rate sample. However as this time the data is over two points, we pass separate start and end dates.
    //                                         let distanceSample = HKQuantitySample(type: distanceType, quantity: distanceQuantity, start: previousTimeStamp, end: trackpoint.timeStamp)
    //                                         
    //                                         // Add the sample to array which setup before, which will already contain our heart rate samples.
    //                                         
    //                                         samples.append(distanceSample)
    //                                     }
    //                                     
    //                                     // Finally set the previous values.
    //                                     previousLocation = location
    //                                     previousTimeStamp = trackpoint.timeStamp
    //                                     }
    //    
    //                                     
    //                                     store.save(hkworkout) { (finished, error) in
    //                                       if finished {
    //                                           
    //                                           // We first add the samples to our hkworkout instance.
    //                                           store.add(samples, to: hkworkout, completion: { (finished, error) in })
    //
    //                                           // To store all the location information we just have to finish the routeBuilder and pass in our hkworkout.
    //                                           routeBuilder.finishRoute(with: hkworkout, metadata: nil, completion: { (route, error) in })
    //
    //                                       }
    //                                     }
    //}
    
    
}
