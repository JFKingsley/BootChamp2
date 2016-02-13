//
//  StatusMenuController.swift
//  BootChamp 2
//
//  Created by Jonathan Kingsley on 29/01/2016.
//  Copyright © 2016 JFKingsley. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!
    
    @IBOutlet weak var restartItem: NSMenuItem!
    @IBOutlet weak var preferencesItem: NSMenuItem!
    @IBOutlet weak var launchAtLoginItem: NSMenuItem!
    @IBOutlet weak var checkUpdatesItem: NSMenuItem!
    @IBOutlet weak var aboutItem: NSMenuItem!
    @IBOutlet weak var quitItem: NSMenuItem!
    
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    let bootLogin = BootOnLoginHandler()
    let diskHandler = DiskHandler()
    
    override func awakeFromNib() {
        let icon = NSImage(named: "StatusIcon")
        let disks = diskHandler.getWindowsDisks()
        
        
        //Localize Strings
        restartItem.title = String(format: NSLocalizedString("Restart into %@", comment: ""), (disks.count >= 1 ? disks[0].operatingSystem : "N/A"))
        preferencesItem.title = NSLocalizedString("Preferences", comment: "")
        launchAtLoginItem.title = NSLocalizedString("Launch at Startup", comment: "")
        checkUpdatesItem.title = NSLocalizedString("Check for Updates…", comment: "")
        aboutItem.title = NSLocalizedString("About BootChamp 2", comment: "")
        quitItem.title = NSLocalizedString("Quit", comment: "")
        //End localizing strings
        
        launchAtLoginItem.state = (bootLogin.applicationIsInStartUpItems() ? NSOnState : NSOffState)
        
        if disks.count < 1 {
            let alert = NSAlert()
            alert.messageText = "Warning"
            alert.alertStyle = NSAlertStyle.WarningAlertStyle
            alert.informativeText = NSLocalizedString("BootChamp was unable to find a Windows volume", comment: "")
            alert.addButtonWithTitle("OK")
            
            alert.runModal()
            
            restartItem.enabled = false
            statusItem.image = icon
            statusItem.menu = statusMenu
            
            
            return;
        }
        
        restartItem.target = self
        restartItem.action = Selector("restartToWindowsClicked:")
        restartItem.submenu = nil
        restartItem.representedObject = disks[0]
        
        if disks.count > 1 {
            let submenu = NSMenu()
            
            for disk in disks {
                let item = NSMenuItem(title: disk.name, action: Selector("restartToWindowsClicked:"), keyEquivalent: "")
                
                item.target = self
                item.representedObject = disk
                
                submenu.addItem(item)
            }
            
            restartItem.target = nil
            restartItem.action = nil
            restartItem.submenu = submenu
            restartItem.representedObject = nil
        } else if disks[0].isUEFI {
            restartItem.title = String(format: NSLocalizedString("Restart into %@", comment: ""), disks[0].operatingSystem + " (EFI)")
        }
        
        statusItem.image = icon
        statusItem.menu = statusMenu
    }
    
    func restartToWindowsClicked(sender: AnyObject) {
        let setDiskResult = diskHandler.setWindowsBootDisk(sender.representedObject as! BCDisk)
        
        if !setDiskResult {
            let alert = NSAlert()
            alert.messageText = "Warning"
            alert.alertStyle = NSAlertStyle.WarningAlertStyle
            alert.informativeText = NSLocalizedString("BootChamp 2 was unable to set your Windows volume as the temporary startup disk", comment: "")
            alert.addButtonWithTitle("OK")
            
            alert.runModal()
            
            return;
        }
        
        let restartResult = diskHandler.rebootSystem()
        
        if !restartResult {
            let alert = NSAlert()
            alert.messageText = "Warning"
            alert.alertStyle = NSAlertStyle.WarningAlertStyle
            alert.informativeText = NSLocalizedString("BootChamp 2 was unable to restart your computer", comment: "")
            alert.addButtonWithTitle("OK")
            
            alert.runModal()
            
            return;
        }
    }
    
    @IBAction func launchAtStartupClicked(sender: AnyObject) {
        bootLogin.toggleLaunchAtStartup()
        
        launchAtLoginItem.state = (bootLogin.applicationIsInStartUpItems() ? NSOnState : NSOffState)
    }
    
    @IBAction func aboutClicked(sender: AnyObject) {
        NSApp.activateIgnoringOtherApps(true);
        NSApp.orderFrontStandardAboutPanel(sender);
    }
    
    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }
}