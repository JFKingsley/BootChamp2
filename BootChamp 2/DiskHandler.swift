//
//  DiskHandler.swift
//  BootChamp 2
//
//  Created by Jonathan Kingsley on 29/01/2016.
//  Copyright © 2016 JFKingsley. All rights reserved.
//

import Cocoa
import DiskArbitration

class DiskHandler: NSObject {
    let manager: DMManager = DMManager.sharedManager() as! DMManager
    
    func getDisks() -> [BCDisk] {
        var diskList: Array = [BCDisk]()
        
        if let session = DASessionCreate(kCFAllocatorDefault) {
            
            var buf: UnsafeMutablePointer<statfs> = nil
            let count = getmntinfo(&buf, MNT_NOWAIT);
            
            for i in 0...count {
                var bsdRef = buf[Int(i)];
                if (Int32(bsdRef.f_flags) & MNT_LOCAL) == 0 {
                    //Not local drive, skipping
                    continue;
                }
                
                let deviceName = withUnsafePointer(&bsdRef.f_mntfromname,{
                        (ptr) -> String? in
                        let int8Ptr = unsafeBitCast(ptr, UnsafePointer<Int8>.self)
                        return String.fromCString(int8Ptr)
                })
                
                if deviceName == nil {
                    //No device name, skipping
                    continue;
                }
                
                let media = BCDisk()
                
                media.deviceName = deviceName!
                media.disk = DADiskCreateFromBSDName(kCFAllocatorDefault, session, deviceName!)!
                
                
                let desc = DADiskCopyDescription(media.disk!) as Dictionary!
                
                if desc == nil {
                    //No device description, skipping
                    continue;
                }
                
                media.setDescription(desc)
                
                //Time to see how it ticks
                let isBootable = UnsafeMutablePointer<Int8>.alloc(1)
                var operatingSys: AnyObject?
                
                let legacyResult: Int32 = manager.checkLegacyBootabilityForNonOpticalPartition(media.disk!, isLegacyBootable: isBootable, os: &operatingSys)
                
                if legacyResult == 0 && operatingSys != nil {
                    media.isBootable = true
                    media.operatingSystem = String(operatingSys!)
                } else {
                    let uefiResult: Int32 = manager.checkWindowsUEFIBootabilityForNonOpticalPartition(media.disk!, isWindowsUEFIBootable: isBootable, os: &operatingSys)
                    
                    if uefiResult == 0 && operatingSys != nil {
                        media.isBootable = true
                        media.isUEFI = true
                        media.operatingSystem = String(operatingSys!)
                    }
                }
                
                isBootable.dealloc(1)
                
                diskList.append(media)
            }
            
            return diskList
        } else {
            return []
        }
    }
    
    func getWindowsDisks() -> [BCDisk] {
        let disks = self.getDisks()
        var diskList: Array = [BCDisk]()
        
        for disk in disks {
            if disk.operatingSystem == "Windows" {
                diskList.append(disk)
            }
        }
        
        return diskList
    }
    
    func setWindowsBootDisk(disk: BCDisk) -> Bool {
        var isError: Int32 = 0
        let result = UnsafeMutablePointer<Int8>.alloc(1)
        
        if disk.isUEFI {
            manager.checkUEFIWindowsBootSupport(result)
            
            if result.memory == 1 {
                isError = manager.setWindowsUEFIDiskForNextOnlyBootPreference(disk.disk!, withDriveHint: nil)
            } else {
                isError = -1
            }
        } else {
            manager.checkLegacyBootSupport(result)
            
            if result.memory == 1 {
                isError = manager.setLegacyDiskForNextOnlyBootPreference(disk.disk!, withDriveHint: nil)
            } else {
                isError = -1
            }
        }
        
        result.dealloc(1)
        
        //let isSetBootError = manager.setDiskForBootPreference(disk.disk!, atFolderLocation: disk.mountPoint, isOS9: false);
        
        return (isError == 0)
    }
    
    func rebootSystem() -> Bool {
        return (self.sendAppleEventToSystem(AEEventID(kAERestart)) == 0)
    }
    
    func sendAppleEventToSystem(eventToSendID: AEEventID) -> OSStatus {
        var targetDesc: AEAddressDesc = AEAddressDesc.init()
        var psn = ProcessSerialNumber(highLongOfPSN: UInt32(0), lowLongOfPSN: UInt32(kSystemProcess))
        var eventReply: AppleEvent = AppleEvent(descriptorType: UInt32(typeNull), dataHandle: nil)
        var eventToSend: AppleEvent = AppleEvent(descriptorType: UInt32(typeNull), dataHandle: nil)
        
        var status: OSErr = AECreateDesc(
                UInt32(typeProcessSerialNumber),
                &psn,
                sizeof(ProcessSerialNumber),
                &targetDesc
        )
        
        if status != 0 {
            return OSStatus.init(integerLiteral: Int32(status))
        }
        
        status = AECreateAppleEvent(
                UInt32(kCoreEventClass),
                eventToSendID,
                &targetDesc,
                AEReturnID(kAutoGenerateReturnID),
                AETransactionID(kAnyTransactionID),
                &eventToSend
        )
        
        AEDisposeDesc(&targetDesc)
        
        if status != 0 {
            return OSStatus.init(integerLiteral: Int32(status))
        }
        
        let osstatus = AESendMessage(
                &eventToSend,
                &eventReply,
                AESendMode(kAENormalPriority),
                kAEDefaultTimeout
        )
        
        AEDisposeDesc(&eventToSend)
        
        if osstatus != 0 {
            return osstatus
        }
        
        AEDisposeDesc(&eventReply)
        
        return osstatus
    }
}