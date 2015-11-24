//
//  MapViewController.swift
//  CMU-SV-Indoor-Swift
//
//  Created by xxx on 12/2/14.
//  Copyright (c) 2014 CMU-SV. All rights reserved.
//

import UIKit
import Parse
import Bolts

//let marker = GMSMarker()
//let marker1 = GMSMarker()
//let marker2 = GMSMarker()
//let marker3 = GMSMarker()
//let markerfromModal = GMSMarker()


class MapViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GMSMapViewDelegate, GPSPositionerDelegate, IndoorPositionerDelegate, UISearchResultsUpdating, UISearchBarDelegate  {
    
    // MARK: Properties
  
    //ROOM SCHEDULER
    
    @IBOutlet weak var roomScheduler: UIView!
    @IBOutlet weak var peopleSegment: UISegmentedControl!
    @IBOutlet weak var timeSegment: UISegmentedControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    //@IBOutlet weak var roomButton: UIButton!
    var minimumTime: Int!
    var minimumPeople: Int!
    var openRooms: [PFObject]!
    @IBOutlet weak var openRoomsTable: UITableView!
    //END ROOM SCHEDULER
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet var currentBuildingLabel: UILabel!
    @IBOutlet var indoorPositionerStateLabel: UILabel!
    @IBOutlet var indoorOutdoorButton: UIBarButtonItem!
    @IBOutlet var myFloorNumberButton: UIBarButtonItem!
    @IBOutlet var myPositionButton: UIBarButtonItem!
    @IBOutlet var viewFloorNumberButton: UIBarButtonItem!
    @IBOutlet var mapTypeButton: UIBarButtonItem!
    var groundOverlays: [String: GMSGroundOverlay] = [:]
    
    var indoorPositioningTurnedOn = false
    
    var currentIndoorCoordinate = CLLocationCoordinate2DMake(0, 0)
    var currentGPSCoordinate = CLLocationCoordinate2DMake(0, 0)
    var currentHeading = CLLocationDirection(0)
    
    var cameraMode: CameraMode  = .free
    enum CameraMode {
        case free
        case centerPosition
        case centerPositionAndLockHeading
    }
    var settingCameraPosition = false
    
    var myPositionMarker = GMSMarker()
    
    var gpsLocationCircle = GMSCircle(position: CLLocationCoordinate2DMake(0, 0), radius: 1.0)

    var gpsPositioner: GPSPositioner!
    var indoorPositioner: MyIndoorPositioner!
    
    var currentBuilding = Building.None
    var currentFloor = Floor.Floor1
    var currentViewFloor = Floor.Floor1
    
    
    //LOCATION SEARCH
    @IBOutlet weak var modalView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var locations: [PFObject]!
    var locationFromModal: PFObject!
    var markerFromModal = GMSMarker()
    //END LOCATION SEARCH
    
    
    
    // MARK: Functional Methods

    func distanceBetweenPoints(userLocation: CLLocationCoordinate2D, foundLocation: AnyObject) -> Double {
        
        //returns the distance, in meters, between the user's current location and a parse coordinate
        let userLocationCL = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let locationGeoPoint = (foundLocation as? PFGeoPoint)!
        let longVar = locationGeoPoint.longitude as CLLocationDegrees!
        let latVar = locationGeoPoint.latitude as CLLocationDegrees!

        
        print("Distance in meters: \(userLocationCL.distanceFromLocation(CLLocation(latitude: latVar, longitude: longVar)))")
        
        return userLocationCL.distanceFromLocation(CLLocation(latitude: latVar, longitude: longVar))
    }

    
    func showOpenRooms() {
        print("running function : show open rooms")
        var query = PFQuery(className: "rooms")
//        should add query for building being the current building
        // should we only check the current floor?
        query.whereKey("isRoom", equalTo: true)
        query.whereKey("Available_Duration", greaterThanOrEqualTo: minimumTime )
        query.whereKey("Capacity", greaterThanOrEqualTo: minimumPeople)
        query.orderByAscending("Room_Name")
        //** sort by nearness: 
//        probably need if statement to make sure we're getting a user location
//        let userPFGeoPoint = (geoPointWithLatitude: <need var for userlat>, geoPointWithLongitude: <need var for userlong>) as PFGeoPoint
//        query.whereKey("Long_Lat", nearGeoPoint: userPFGeoPoint)
        query.findObjectsInBackgroundWithBlock { (openRooms: [PFObject]?, error: NSError?) -> Void in
            print("got the rooms")
            print(openRooms)
            self.openRooms = openRooms
            self.tableView.reloadData()
        }
//        somewhere, possible before previous call, we need to handle having 0 rooms in query
//        we need to handle
    }
    
    func showLocations() {
        var query = PFQuery(className: "rooms")
        query.orderByAscending("Room_Name")
        query.findObjectsInBackgroundWithBlock { (locations: [PFObject]?, error: NSError?) -> Void in
            print("got the locations")
            print(locations)
            self.locations = locations
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ROOM SEARCH
        roomScheduler.alpha = 0
        modalView.alpha = 0
        minimumTime = 0  
        minimumPeople = 0
        openRooms = []
//        showOpenRooms()
        openRoomsTable.dataSource = self
        openRoomsTable.delegate = self
        openRoomsTable.estimatedRowHeight = 100
        
        
        //END ROOM SEARCH
        

        //INITIALIZING LOCATION SEARCH

        locations = []
        
//        var query = PFQuery(className: "rooms")
//        query.orderByAscending("Room_Name")
//        query.findObjectsInBackgroundWithBlock { (locations: [PFObject]?, error: NSError?) -> Void in
//            print("got the locations")
//            print(locations)
//            self.locations = locations
//            self.tableView.reloadData()
//        }
//        showLocations()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 120
        searchBar.delegate = self
        //END LOCATION SEARCH
        
        
        initializeGoogleMapView()
        initializeFloorplanImages()
        initializePositionMarkersAndCircles()
        initializeGPSAndIndoorPositioners()
        
        
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("checking number of rows")
        if tableView == openRoomsTable {
            let tableView = openRoomsTable
            print("rooms.count = \(openRooms.count)")
            return openRooms.count
            
        } else {
            print("locations.count = \(locations.count)")
            return locations.count
            
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
       
        if tableView == openRoomsTable {
            //let tableView = openRoomsTable
            print("cell for row, table = rooms")
            return setCopyInRoomFinderCell(openRoomsTable, indexPath: indexPath)
        } else {
            print("cell for row, table = all locations")
            return setCopyInLocationCell(tableView, indexPath: indexPath)
        }
    }
    
    
    //REFACTOR FOR LOCATION
    func setCopyInLocationCell (tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("LocationResultsCell") as! LocationResultsCell
        
        var location = locations[indexPath.row]
        
        cell.nameLabel.text = location["Room_Name"] as? String
        
        var roomNumber: String!
        var floorNumber: String!
        var longAddress: String!
        
        
        
        let building = location["Building"] as? String
        
        if building == "SB850C" {
            longAddress = "850 Cherry Ave., SB"
        } else if building == "SB860E" {
            longAddress = "860 Elm Ave., SB"
        } else if building == "SV850C" {
            longAddress = "850 W. California Ave., SV"
        } else if building == "SV850C" {
            longAddress = "840 W. California Ave., SV"
        }
        
        let onFloor = location["Floor"] as? Int
        if onFloor != nil {
            if onFloor == 1 {
                floorNumber = "\(location["Floor"])st floor"
            } else if onFloor == 2 {
                floorNumber = "\(location["Floor"])nd floor"
            } else if onFloor == 3 {
                floorNumber = "\(location["Floor"])rd floor"
            } else {
                floorNumber = "\(location["Floor"])th floor"
            }
        } else if onFloor == nil {
            floorNumber = "Floor N/A"
        }
        
        if location["Room_Num"] != nil {
            roomNumber = location["Room_Num"] as! String!
        } else {
            roomNumber = "(Room # N/A)"
        }
        

        cell.floorNumberLabel.text = "\(roomNumber): \(floorNumber), \(longAddress)"
        cell.buildingsAddressLabel.text = ""
        
        
        
        
        
//          The following was working code. This will need to be deleted once the replacement code (above) is vetted. Thje building address and floor used to be displayed in 3 different labels, but the above code places them all in one label to allow for sentence like structure.
//        if building == "SB850C" {
//            cell.buildingsAddressLabel.text = "850 Cherry Ave., SB"
//        } else if building == "SB860E" {
//            cell.buildingsAddressLabel.text = "860 Elm Ave., SB"
//        } else if building == "SV850C" {
//            cell.buildingsAddressLabel.text = "850 W. California Ave., SV"
//        } else if building == "SV850C" {
//            cell.buildingsAddressLabel.text = "840 W. California Ave., SV"
//        }
//        
//        let onFloor = location["Floor"] as? Int
//        if onFloor != nil {
//            if onFloor == 1 {
//                cell.floorNumberLabel.text = "\(location["Floor"])st Floor, "
//            } else if onFloor == 2 {
//                cell.floorNumberLabel.text = "\(location["Floor"])nd Floor, "
//            } else if onFloor == 3 {
//                cell.floorNumberLabel.text = "\(location["Floor"])rd Floor, "
//            } else {
//                cell.floorNumberLabel.text = "\(location["Floor"])th Floor, "
//            }
//        } else if onFloor == nil {
//            cell.floorNumberLabel.text = "Floor unknown"
//            cell.floorNumberLabel.textColor = UIColor.lightGrayColor()
//        }
        
        let isRoom = location["isRoom"] as! Bool
        let isAvailable = location["Available_now"] as? Int
        let hasCapacity = location["Capacity"] as? Int
        
        // Legend for Available_now: 1 = available, 0 = not available, -1 = not the kind of place you book (restroom, cafeteria, etc)
        
        if isRoom == true {
            cell.locationTypeImageView.image = UIImage(named: "room icon")
            
            if isAvailable != nil && isAvailable == 1 {
                cell.roomAvailabilityLabel.text = "Available Now"
                cell.roomAvailabilityLabel.textColor = UIColor.greenColor()
                cell.roomAvailabilityLabel.alpha = 1
            } else if isAvailable != nil && isAvailable == 0 {
                cell.roomAvailabilityLabel.text = "Not Available"
                cell.roomAvailabilityLabel.textColor = UIColor.redColor()
                cell.roomAvailabilityLabel.alpha = 1
            } else if isAvailable != nil && isAvailable == -1 {
                cell.roomAvailabilityLabel.alpha = 0
            } else {
                cell.roomAvailabilityLabel.text = "Availability Unknown"
                cell.roomAvailabilityLabel.textColor = UIColor.grayColor()
            }
            
            cell.roomCapacityLabel.text = "Capacity: \(location["Capacity"])"
            cell.roomCapacityLabel.alpha = 1
            
        } else {  //if isRoom is false, then we're assuming it's a person. Could there be other types to capture? would we want to return the person's title, if available? any other data for people?
            cell.locationTypeImageView.image = UIImage(named: "person icon")
            if isAvailable == 0 {
                cell.roomAvailabilityLabel.frame.origin.x = 0
                cell.roomAvailabilityLabel.text = "In a meeting"
                cell.roomAvailabilityLabel.textColor = UIColor.redColor()
                cell.roomAvailabilityLabel.alpha = 1
            } else {
                cell.roomAvailabilityLabel.alpha = 0
            }
            cell.roomCapacityLabel.alpha = 0
        }
        
        
        
        print("User's Current Building: \(currentBuildingLabel.text)")
        print("User's Current floor: \(currentFloor)")
        currentFloor = Floor.Floor1

//        //show distance to room/person
//        if currentBuilding == building {
//            print("destination is in this same building")
//            if location["Long_Lat"] != nil {
//                if currentIndoorCoordinate.longitude != 0 && currentIndoorCoordinate.longitude != 0 {
//                    let distance = distanceBetweenPoints(currentIndoorCoordinate, foundLocation: location["Long_Lat"])
//                    cell.distanceLabel.text = "\(distance) meters"
//                } else if currentGPSCoordinate.longitude != 0 && currentGPSCoordinate.longitude != 0  {
//                    let distance = distanceBetweenPoints(currentGPSCoordinate, foundLocation: location["Long_Lat"])
//                    cell.distanceLabel.text = "\(distance) meters"
//                } else {
//                    cell.distanceLabel.text = "GPS error"
//                }
//            } else {
//                cell.distanceLabel.text = "No location in DB"
//            }
//        } else {
//            print("destination is not in this building")
//            cell.distanceLabel.text = "No location in DB"
//        }
        
        return cell
            
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var longVar: Double!
        var latVar: Double!
        var locationGeoPoint: PFGeoPoint
        
        if tableView == openRoomsTable {
            locationFromModal = openRooms[indexPath.row]
        } else {
            locationFromModal = locations[indexPath.row]
        }
        
        locationGeoPoint = (locationFromModal["Long_Lat"] as? PFGeoPoint)!
        longVar = locationGeoPoint.longitude
        longVar = locationGeoPoint.latitude
        
        //        longVar = (locationFromModal["Long"] as? Double!)!
        //        latVar = (locationFromModal["Lat"] as? Double!)!
        
        print("I clicked the row!!!")
        
        if longVar != nil && latVar != nil {
            //Dismiss keyboard on cell selection
            UIApplication.sharedApplication().sendAction("resignFirstResponder", to:nil, from:nil, forEvent:nil)
            
            //make modal disappear
            UIView.animateWithDuration(0.4, animations: {Void in
                self.modalView.alpha = 0
                self.roomScheduler.alpha = 0
            })
            
            // This is the code to use if we were segueing between view controllers
            // self.performSegueWithIdentifier("seguetoMap" , sender: self)
            
            //Set a marker on the map at the selected room location
            markerFromModal.opacity = 1
            //markerFromModal.position = (locationFromModal["Long_Lat"] as? CLLocationCoordinate2D!)!
            markerFromModal.position = CLLocationCoordinate2DMake(longVar, latVar)
            markerFromModal.title = "\(locationFromModal["Room_Name"])"
            markerFromModal.snippet = "Capacity: \(locationFromModal["Capacity"])"
            markerFromModal.map = mapView
            print("\(locationFromModal["Room_Name"])")
        } else {
            print ("Missing Location Data")
            //<we should launch an alert here>
        }
        

    }

    // START SEARCH FUNCTIONS
    
    @IBAction func didPressBackButton(sender: UIButton) {
        
        //make modal disappear>
        UIView.animateWithDuration(0.4, animations: {Void in
            self.modalView.alpha = 0
        })
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchBar.text
        print("Searchbar text: \(searchText)")
        var query = PFQuery(className: "rooms")
        if searchText != nil {
            query.whereKey("Room_Name", matchesRegex: searchText!, modifiers: "i")
        }
        query.orderByAscending("Room_Name")
        query.findObjectsInBackgroundWithBlock { (locations: [PFObject]?, error: NSError?) -> Void in
            print("SEARCHING")
            print(locations)
            self.locations = locations
            self.tableView.reloadData()
        }
        
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
    }
    //END SEARCH FUNCTIONS
    
    
    //START ROOM FINDER
    
    @IBAction func peopleSegDidChange(sender: UISegmentedControl) {
        if peopleSegment.selectedSegmentIndex == 0 {
            minimumPeople = 4
        } else if peopleSegment.selectedSegmentIndex == 1 {
            minimumPeople = 10
        } else if peopleSegment.selectedSegmentIndex == 2 {
            minimumPeople = 11
        }
        print("changed people seg controller")
        showOpenRooms()
    }
    
   
    @IBAction func timeSegDidChange(sender: UISegmentedControl) {
        print("time segment index = \(timeSegment.selectedSegmentIndex)")
            if timeSegment.selectedSegmentIndex == 0 {
                minimumTime = 15
            } else if timeSegment.selectedSegmentIndex == 1 {
                minimumTime = 30
            } else if timeSegment.selectedSegmentIndex == 2 {
                minimumTime = 60
            } else if timeSegment.selectedSegmentIndex == 3 {
                minimumTime = 61
            }
        print("changed time seg controller")
        showOpenRooms()
    }

   
    
    @IBAction func didTapBackFromRoomFinder(sender: UIButton) {
        
        //make modal disappear>
        UIView.animateWithDuration(0.4, animations: {Void in
            self.roomScheduler.alpha = 0
        })
        
    }
    
   
    func setCopyInRoomFinderCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("RoomFinderCell") as! RoomFinderCell
        var openRoom = openRooms[indexPath.row]
        print("DQing openRoomsTable")
        
//        functionality for distance from user's location
//        if we have a user's location, then something like this: let meters = [newLocation distanceFromLocation:oldLocation] as! CLLocationDistance
        
        cell.nameLabel.text = openRoom["Room_Name"] as? String
        
        
        let building = openRoom["Building"] as? String
        
        if building == "SB850C" {
            cell.buildingLabel.text = "850 Cherry Ave., SB"
        } else if building == "SB860E" {
            cell.buildingLabel.text = "860 Elm Ave., SB"
        } else if building == "SV850C" {
            cell.buildingLabel.text = "850 W. California Ave., SV"
        } else if building == "SV850C" {
            cell.buildingLabel.text = "840 W. California Ave., SV"
        }
        
        let onFloor = openRoom["Floor"] as? Int
        if onFloor != nil {
            if onFloor == 1 {
                cell.floorLabel.text = "\(openRoom["Floor"])st Floor, "
            } else if onFloor == 2 {
                cell.floorLabel.text = "\(openRoom["Floor"])nd Floor, "
            } else if onFloor == 3 {
                cell.floorLabel.text = "\(openRoom["Floor"])rd Floor, "
            } else {
                cell.floorLabel.text = "\(openRoom["Floor"])th Floor, "
            }
        } else if onFloor == nil {
            cell.floorLabel.text = "Floor unknown"
            cell.floorLabel.textColor = UIColor.lightGrayColor()
        }
        
        let isRoom = openRoom["isRoom"] as! Bool
        let isAvailable = openRoom["Available_now"] as? Int
        let hasCapacity = openRoom["Capacity"] as? Int
        
        // Available_now: 1 = available, 0 = not available, -1 = not the kind of place you book (restroom, cafeteria, etc)
        
        if isRoom == true {
            
            if isAvailable != nil && isAvailable == 1 {
                cell.availabilityLabel.text = "Available Now"
                cell.availabilityLabel.textColor = UIColor.greenColor()
                cell.availabilityLabel.alpha = 1
            } else if isAvailable != nil && isAvailable == 0 {
                cell.availabilityLabel.text = "Not Available"
                cell.availabilityLabel.textColor = UIColor.redColor()
                cell.availabilityLabel.alpha = 1
            } else if isAvailable != nil && isAvailable == -1 {
                cell.availabilityLabel.alpha = 0
            } else {
                cell.availabilityLabel.text = "Availability Unknown"
                cell.availabilityLabel.textColor = UIColor.grayColor()
            }
            
            cell.capacityLabel.text = "Capacity: \(openRoom["Capacity"])"
            cell.capacityLabel.alpha = 1
            
        }
        
      
        
        return cell
    }
    


    //END ROOM FUNCTIONS
    
    
    
    //START MAP STUFF
    private func initializeGoogleMapView() {
        mapView.settings.compassButton = true
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(INIT_CAM_LAT, longitude: INIT_CAM_LON, zoom: INIT_CAM_ZOOM)
        mapView.camera = camera
        mapView.delegate = self
    }
    
    private func initializeFloorplanImages() {
        let BSB_1f_image: UIImage! = UIImage(named: "Assets/Floorplans/sb-1stfloorplan.png")
        let b23_1f_image: UIImage! = UIImage(named: "Assets/Floorplans/B23-1F.png")
        let b23_2f_image: UIImage! = UIImage(named: "Assets/Floorplans/B23-2F.png")

        let BSB_1f_overlay: GMSGroundOverlay =
            GMSGroundOverlay(position: BSB_COORD, icon: BSB_1f_image, zoomLevel: BSB_SCALE)
        let b23_1f_overlay: GMSGroundOverlay =
            GMSGroundOverlay(position: B23_COORD, icon: b23_1f_image, zoomLevel: B23_SCALE)
        let b23_2f_overlay: GMSGroundOverlay =
            GMSGroundOverlay(position: B23_COORD, icon: b23_2f_image, zoomLevel: B23_SCALE)
        
        BSB_1f_overlay.bearing = BSB_BEARING;
        b23_1f_overlay.bearing = B23_BEARING;
        b23_2f_overlay.bearing = B23_BEARING;
        
        BSB_1f_overlay.map = mapView;
        b23_1f_overlay.map = mapView;
        
        groundOverlays[BSB_1F] = BSB_1f_overlay
        groundOverlays[B23_1F] = b23_1f_overlay
        groundOverlays[B23_2F] = b23_2f_overlay
        
        for buildingInfo in BUILDINGS_ARRAY.values {
            let circle = GMSCircle(position: buildingInfo.coordinate, radius: buildingInfo.range)
            circle.fillColor = UIColor.grayColor().colorWithAlphaComponent(0.15)
            circle.strokeColor = UIColor.whiteColor()
            circle.zIndex = -1
            circle.map = mapView
        }
    

    }
    
    private func initializePositionMarkersAndCircles() {
        myPositionMarker.icon = UIImage(named: "MyPositionMarker@2x.png")
        myPositionMarker.groundAnchor = CGPointMake(0.5, 0.5)
        myPositionMarker.flat = true
        myPositionMarker.rotation = 90
        myPositionMarker.zIndex = 3
        myPositionMarker.map = mapView
        
        gpsLocationCircle.fillColor = blueColor.colorWithAlphaComponent(0.15)
        gpsLocationCircle.strokeWidth = 0
        gpsLocationCircle.zIndex = 1
        gpsLocationCircle.map = mapView
    }
    
    private func initializeGPSAndIndoorPositioners() {
        gpsPositioner = GPSPositioner()
        gpsPositioner.parentViewController = self
        gpsPositioner.delegate = self
        
        indoorPositioner = MyIndoorPositioner()
        indoorPositioner.parentViewController = self
        indoorPositioner.delegate = self
    }

    private func centerCameraToCurrentCoordinate() {
        settingCameraPosition = true
        if indoorPositioningTurnedOn {
            mapView.animateToLocation(currentIndoorCoordinate)
        } else {
            mapView.animateToLocation(currentGPSCoordinate)
        }
    }
    
    private func rotateCameraToCurrentHeading() {
        settingCameraPosition = true
        mapView.animateToBearing(currentHeading)
    }
    
    private func turnOnIndoorPositioning() {
        if currentBuilding != .None {
            indoorPositioningTurnedOn = true
            
            indoorOutdoorButton.tintColor = blueColor
            indoorOutdoorButton.image = UIImage(named: "Indoor.png")
            
            switch currentBuilding {
            case .BuildingSB:
                currentBuildingLabel.text = "BSB"
                currentFloor = Floor.Floor1
                myFloorNumberButton.title = "1F"
                myFloorNumberButton.enabled = false
            default:
                currentBuildingLabel.text = "B23"
                myFloorNumberButton.enabled = true
            }
            
            self.startPositioningWith(newBuilding: currentBuilding, newFloor: currentFloor)
        }
    }
    
    private func turnOffIndoorPositioning() {
        indoorPositioningTurnedOn = false
        
        indoorOutdoorButton.tintColor = darkGreyColor
        indoorOutdoorButton.image = UIImage(named: "Outdoor.png")
        
        self.indoorPositioner.stopPositioning()
    }
    
    private func changedFloorOrBuilding(building building: Building, floor: Floor) {
        shakeDevice()
        
        if building == .None {
            currentBuilding = .None
            
            turnOffIndoorPositioning()
            indoorOutdoorButton.enabled = false
            currentBuildingLabel.text = ""
            
            return
        }
        
        indoorOutdoorButton.enabled = true
        
        switch building {
        case .BuildingSB:
            // Building 19 can only be positioned on 1st floor
            // building has just changed to BuildingSB
            myFloorNumberButton.enabled = false

            currentBuilding = .BuildingSB
            currentFloor = .Floor1
            
            myFloorNumberButton.title = "1F"
            currentBuildingLabel.text = "BSB"
            
            if indoorPositioningTurnedOn {
                startPositioningWith(newBuilding: currentBuilding, newFloor: currentFloor)
            }
        default:
            myFloorNumberButton.enabled = true
            if building != currentBuilding || floor != currentFloor {
                if building != currentBuilding {
                    currentBuilding = building
                    switch building {
                    case .None:
                        currentBuildingLabel.text = ""
                    case .BuildingSB:
                        currentBuildingLabel.text = "BSB"
                    case .Building23:
                        currentBuildingLabel.text = "B23"
                    }
                }
                if floor != currentFloor {
                    currentFloor = floor
                    switch floor {
                    case .Floor1:
                        myFloorNumberButton.title = "1F"
                    case .Floor2:
                        myFloorNumberButton.title = "2F"
                    default:
                        failGracefully("Cannot position with none floor")
                    }
                }
                viewFloor(floor)
                if indoorPositioningTurnedOn {
                    startPositioningWith(newBuilding: building, newFloor: floor)
                }
            }
        }
    }
    
    private func startPositioningWith(newBuilding newBuilding: Building, newFloor: Floor) {
        indoorPositioner.startPositioning(building: newBuilding, floor: newFloor)
    }
    
    private func viewFloor(floor: Floor) {
        if floor == currentFloor {
            viewFloorNumberButton.tintColor = UIColor.blackColor()
        } else {
            viewFloorNumberButton.tintColor = UIColor.redColor()
        }
        
        
        switch floor {
        case .None:
            viewFloorNumberButton.title = "N/A"
            groundOverlays[BSB_1F]!.map = nil
            groundOverlays[B23_1F]!.map = nil
            groundOverlays[B23_2F]!.map = nil
        case .Floor1:
            viewFloorNumberButton.title = "1F"
            groundOverlays[BSB_1F]!.map = self.mapView
            groundOverlays[B23_1F]!.map = self.mapView
            groundOverlays[B23_2F]!.map = nil
        case .Floor2:
            viewFloorNumberButton.title = "2F"
            groundOverlays[BSB_1F]!.map = nil
            groundOverlays[B23_1F]!.map = nil
            groundOverlays[B23_2F]!.map = self.mapView
        default:
            failGracefully("No such floor!")
        }
    }
    
    
    
    // MARK: GMSMapViewDelegate Methods
    
    func mapView(mapView: GMSMapView!, didChangeCameraPosition position: GMSCameraPosition!) {
        if settingCameraPosition == false {
            cameraMode = .free
            myPositionMarker.icon = UIImage(named: "MyPositionMarker.png")
            myPositionButton.image = UIImage(named: "MyPosition.png")
            myPositionButton.tintColor = darkGreyColor
        } else {
        }
    }
    
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition!) {
        mapView.userInteractionEnabled = true
        settingCameraPosition = false;
    }
    
    // MARK: ( Method used to read floorplan image alignment marker coordinates )

    /*
     * When there is a constant bias between indoor position given by IndoorAtlas and real position, 
     * do the following steps to make floorplan adjustments on IndoorAtlas:
     * 
     * 1. Modify func initializeFloorplanImages() and/or related global constants to load flooplan images with alignment markers.
     * 2. Uncomment this function, run it on a simulator (e.g. iPhone 6 Plus) other than a real device.
     * 3. Click the center of any marker on the any floorplan image to read the coordiantes.
     * 4. Adjust the coordiantes on IndoorAtlas server.
     * 5. Recomment this function. Re-modify this app to load original floorplan images without alignment markers.
     */
    
  
    func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        let lattitude = String(format: "%.7f", coordinate.latitude)
        let longitude = String(format: "%.7f", coordinate.longitude)

        print("Tapped at \(lattitude), \(longitude)")
        
    }
    
    
    
    
    // MARK: GPSPositionerDelegate Methods

    func didStartGPSPositioning() {
        print("Did Start GPS Positioning.")
    }
    
    func didStopGPSPositioning() {
        print("Did Stop GPS Positioning.")
    }
    
    func didUpdateLocation(coordinate coordinate: CLLocationCoordinate2D, radius: CLLocationAccuracy) {
        currentGPSCoordinate = coordinate
        
        if !indoorPositioningTurnedOn {
            myPositionMarker.position = coordinate
            
            if cameraMode != .free {
                centerCameraToCurrentCoordinate()
            }
        }
    
        gpsLocationCircle.position = coordinate
        gpsLocationCircle.radius = radius
        

        
        // Determine current building and restart indoor positioning if building change
        var closestDistance = CLLocationDistanceMax
        var closestBuilding: Building!
        for aBuilding in BUILDINGS_ARRAY.keys {
            let distance = distanceInMetersBetween(coordinate, right: BUILDINGS_ARRAY[aBuilding]!.coordinate)
            BUILDINGS_ARRAY[aBuilding]!.distance = distance
            if distance < closestDistance {
                closestDistance = distance
                closestBuilding = aBuilding
            }
        }
        
        let newBuilding =
        closestDistance <= BUILDINGS_ARRAY[closestBuilding]!.range ? closestBuilding : Building.None
        
        if currentBuilding != newBuilding {
            changedFloorOrBuilding(building: newBuilding, floor: currentFloor)
        }
    }
    
    func didUpdateHeading(heading: CLHeading) {
        currentHeading = heading.trueHeading > 0 ? heading.trueHeading: heading.magneticHeading
        
        myPositionMarker.rotation = currentHeading
        
        if cameraMode == .centerPositionAndLockHeading {
            rotateCameraToCurrentHeading()
        }
    }
    
    
    
    // MARK: IndoorPositionerDelegate Methods

    func indoorPositionerStateChanged(state: String) {
        if indoorPositioningTurnedOn {
            indoorPositionerStateLabel.backgroundColor = blueColor.colorWithAlphaComponent(0.8)
            indoorPositionerStateLabel.text = "IDP (On): " + state
        } else {
            indoorPositionerStateLabel.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.8)
            indoorPositionerStateLabel.text = "IDP (Off): " + state
        }
    }
    
    func indoorPositioningStopped() {
        if cameraMode != .free {
            centerCameraToCurrentCoordinate()
        }
    }
    
    func indoorPositionerFailed() {
        turnOffIndoorPositioning()
    }
    
    func indoorPositionChanged(coordinate: CLLocationCoordinate2D, radius: CLLocationAccuracy) {
        currentIndoorCoordinate = coordinate

        if indoorPositioningTurnedOn {
            myPositionMarker.position = coordinate
            
            if cameraMode != .free {
                centerCameraToCurrentCoordinate()
            }
        }
    }

    
    
    // MARK: IBActions
    
    @IBAction func didTapIndoorOutdoorButton(sender: AnyObject) {
        if !indoorPositioningTurnedOn {
            turnOnIndoorPositioning()
        } else {
            turnOffIndoorPositioning()
        }
    }
    
    @IBAction func didTapMyFloorNumberButton(sender: AnyObject) {
        let alertController: UIAlertController = UIAlertController(title: "I am currently on floor:", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        let onFloor1 = UIAlertAction(title: "1F (Ground Floor)", style: UIAlertActionStyle.Default, handler: { [unowned self] (UIAlertAction) in
            
            self.changedFloorOrBuilding(building: self.currentBuilding, floor: Floor.Floor1)
        })
        
        let onFloor2 = UIAlertAction(title: "2F", style: UIAlertActionStyle.Default, handler: { [unowned self] (UIAlertAction) in
            
            self.changedFloorOrBuilding(building: self.currentBuilding, floor: Floor.Floor2)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil)
        
        alertController.addAction(onFloor1)
        alertController.addAction(onFloor2)
        alertController.addAction(cancel)
        
        self.presentViewController(alertController, animated: false, completion: nil)
    }
    
    @IBAction func didTapMyPositionButton(sender: AnyObject) {
        if cameraMode == .free {
            cameraMode = .centerPosition
            myPositionButton.image = UIImage(named: "MyPosition.png")
            myPositionButton.tintColor = blueColor
        
            mapView.userInteractionEnabled = false
            centerCameraToCurrentCoordinate()
        } else if cameraMode == .centerPosition {
            // Disable manual scrolling or roation
            mapView.settings.scrollGestures = false
            mapView.settings.rotateGestures = false
            
            cameraMode = .centerPositionAndLockHeading
            myPositionMarker.icon = UIImage(named: "MyPositionMarkerLockHeading.png")
            myPositionButton.image = UIImage(named: "MyPositionLockHeading.png")
            myPositionButton.tintColor = blueColor
            
            rotateCameraToCurrentHeading()
        } else if cameraMode == .centerPositionAndLockHeading {
            // Enable manual scrolling or roation
            mapView.settings.scrollGestures = true
            mapView.settings.rotateGestures = true
            
            cameraMode = .free
            myPositionMarker.icon = UIImage(named: "MyPositionMarker.png")
            myPositionButton.image = UIImage(named: "MyPosition.png")
            myPositionButton.tintColor = darkGreyColor
        }
    }
    
    @IBAction func didTapViewFloorNumberButton(sender: AnyObject) {
       let alertController: UIAlertController = UIAlertController(title: "View floor:", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        let viewNoFloor = UIAlertAction(title: "None", style: UIAlertActionStyle.Default, handler: {
            [unowned self] (UIAlertAction) in       self.viewFloor(.None)
        })
        
        let viewFloor1 = UIAlertAction(title: "1F", style: UIAlertActionStyle.Default, handler: {
            [unowned self] (UIAlertAction) in       self.viewFloor(.Floor1)
        })
        
        let viewFloor2 = UIAlertAction(title: "2F", style: UIAlertActionStyle.Default, handler: {
            [unowned self] (UIAlertAction) in       self.viewFloor(.Floor2)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)

        alertController.addAction(viewNoFloor)
        alertController.addAction(viewFloor1)
        alertController.addAction(viewFloor2)
        alertController.addAction(cancel)
        
        self.presentViewController(alertController, animated: false, completion: nil)
    }
    
    @IBAction func didTapMapTypeButton(sender: AnyObject) {
        let alertController: UIAlertController = UIAlertController(title: "Map Type:", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        let normalMapType = UIAlertAction(title: "Normal", style: UIAlertActionStyle.Default, handler: { [unowned self] (UIAlertAction) in
            
            self.mapView.mapType = kGMSTypeNormal
            self.mapTypeButton.title = "Normal"
        })
        
        let satelliteMapType = UIAlertAction(title: "Satellite", style: UIAlertActionStyle.Default, handler: { [unowned self] (UIAlertAction) in
            
            self.mapView.mapType = kGMSTypeSatellite
            self.mapTypeButton.title = "Satellite"
        })
        
        let hybridMapType = UIAlertAction(title: "Hybrid", style: UIAlertActionStyle.Default, handler: { [unowned self] (UIAlertAction) in
            
            self.mapView.mapType = kGMSTypeHybrid
            self.mapTypeButton.title = "Hybrid"
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil)
        
        alertController.addAction(normalMapType);
        alertController.addAction(satelliteMapType);
        alertController.addAction(hybridMapType);
        alertController.addAction(cancel);
        
        self.presentViewController(alertController, animated: false, completion: nil)
    }
    
    @IBAction func didTapSearchbutton(sender: AnyObject) {

       //toolbar button toggles display of the modalView (room or person finder) view
        
        if modalView.alpha == 0 {
            UIView.animateWithDuration(0.3, animations: {
                self.modalView.alpha = 1
                self.roomScheduler.alpha = 0
            
            })
            showLocations()
            
        } else {
            UIView.animateWithDuration(0.3, animations: {
                self.modalView.alpha = 0
            })
        }
    }
    
        
    @IBAction func roomSchedulerBtn(sender: AnyObject) {

        //toolbar button toggles display of the roomScheduler view
        
        if roomScheduler.alpha == 0 {
            UIView.animateWithDuration(0.3, animations: {
                self.modalView.alpha = 0
                self.roomScheduler.alpha = 1
            })
            self.roomScheduler.alpha = 1
            showOpenRooms()
        } else {
            UIView.animateWithDuration(0.3, animations: {
                self.roomScheduler.alpha = 0
            })
        }
    }
    
    
 

}
    
    


