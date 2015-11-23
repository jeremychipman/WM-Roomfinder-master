//
//  RoomFinderCell.swift
//  CMU-SV-Indoor-Swift
//
//  Created by Jeremy Chipman on 11/16/15.
//  Copyright © 2015 CMU-SV. All rights reserved.
//

import UIKit

class RoomFinderCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var buildingLabel: UILabel!
    
    @IBOutlet weak var floorLabel: UILabel!
    
    @IBOutlet weak var availabilityLabel: UILabel!
    
    @IBOutlet weak var capacityLabel: UILabel!
    
    @IBOutlet weak var distanceLabel: UILabel!
//    @IBOutlet weak var cellButton: UIButton!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
