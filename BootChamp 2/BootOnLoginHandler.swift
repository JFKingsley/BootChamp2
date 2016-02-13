//
//  BootOnLogin.swift
//  BootChamp 2
//
//  Created by Jonathan Kingsley on 29/01/2016.
//  Copyright © 2016 JFKingsley. All rights reserved.
//

import Cocoa

class BootOnLoginHandler: NSObject {
    func applicationIsInStartUpItems() -> Bool {
        return itemReferencesInLoginItems().existingReference != nil
    }
    
    func toggleLaunchAtStartup() {
        let itemReferences = itemReferencesInLoginItems()
        let shouldBeToggled = (itemReferences.existingReference == nil)
        let loginItemsRef = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
            nil
            ).takeRetainedValue() as LSSharedFileListRef?
        
        if loginItemsRef != nil {
            if shouldBeToggled {
                if let appUrl: CFURLRef = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath) {
                    LSSharedFileListInsertItemURL(loginItemsRef, itemReferences.lastReference, nil, nil, appUrl, nil, nil)
                    print("Application was added to login items")
                }
            } else {
                if let itemRef = itemReferences.existingReference {
                    LSSharedFileListItemRemove(loginItemsRef,itemRef);
                    print("Application was removed from login items")
                }
            }
        }
    }
    
    func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItemRef?, lastReference: LSSharedFileListItemRef?) {
        let itemUrl = UnsafeMutablePointer<Unmanaged<CFURL>?>.alloc(1)
        
        let appUrl = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath)
            let loginItemsRef = LSSharedFileListCreate(
                nil,
                kLSSharedFileListSessionLoginItems.takeRetainedValue(),
                nil
                ).takeRetainedValue() as LSSharedFileListRef?
            
            if loginItemsRef != nil {
                let loginItems = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as NSArray
                
                if(loginItems.count > 0) {
                    let lastItemRef = loginItems.lastObject as! LSSharedFileListItemRef
                    
                    for var i = 0; i < loginItems.count; ++i {
                        let currentItemRef = loginItems.objectAtIndex(i) as! LSSharedFileListItemRef
                        
                        if LSSharedFileListItemResolve(currentItemRef, 0, itemUrl, nil) == noErr {
                            if let urlRef: NSURL = itemUrl.memory?.takeRetainedValue() {
                                if urlRef.isEqual(appUrl) {
                                    return (currentItemRef, lastItemRef)
                                }
                            }
                        }
                        else {
                            print("Unknown login application")
                        }
                    }
                    // The application was not found in the startup list
                    return (nil, lastItemRef)
                    
                } else  {
                    let addatstart: LSSharedFileListItemRef = kLSSharedFileListItemBeforeFirst.takeRetainedValue()
                    return(nil,addatstart)
                }
            }
        
        return (nil, nil)
    }
    
}
