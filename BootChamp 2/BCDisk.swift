//
//  BCDisk.swift
//  BootChamp 2
//
//  Created by Jonathan Kingsley on 29/01/2016.
//  Copyright © 2016 JFKingsley. All rights reserved.
//

import Cocoa

class BCDisk: NSObject {
    var name: String
    var deviceName: String
    var disk: DADiskRef?
    var desc: Dictionary<NSObject, AnyObject>?
    var isBootable: Bool
    var isUEFI: Bool
    var mountPoint: String!
    var operatingSystem: String!
    var filesystemType: String!
    
    override init() {
        name = ""
        deviceName = ""
        disk = nil
        desc = nil
        isBootable = false
        isUEFI = false
        mountPoint = ""
        operatingSystem = ""
        filesystemType = ""
    }
    
    func setDescription(desc: Dictionary<NSObject, AnyObject> ) {
        self.desc = desc
        self.name = desc["DAVolumeName"] as! String
        if desc["DAVolumePath"] != nil {
            self.mountPoint = (desc["DAVolumePath"] as! NSURL).path!
        }
        self.filesystemType = desc["DAVolumeKind"] as! String
    }
}
