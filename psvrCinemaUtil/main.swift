//
//  main.swift
//  psvrCinemaUtil
//
//  Created by Nikita Mordasov on 1/14/18.
//  Copyright © 2018 Nikita Mordasov. All rights reserved.
//

import Foundation
import IOKit.hid

let fileManager = FileManager.init()

var bufferSet: Bool = false
let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)


/*
 // Optional routine to filter out device
if let devicesSet: CFSet = IOHIDManagerCopyDevices(managerIOHIDSender) {
    for deviceItem in (devicesSet as NSSet) {
        
        
        let deviceCurrent: IOHIDDevice = (deviceItem as! IOHIDDevice)
        let propertyString: CFString = __CFStringMakeConstantString(kIOHIDPrimaryUsagePageKey.cString(using: String.Encoding.ascii))
        
        //kIOHIDPrimaryUsagePageKey
        if let result = IOHIDDeviceGetProperty(deviceCurrent, propertyString) {
            
            if (CFGetTypeID(result) == CFNumberGetTypeID()) {
                // this is a valid HID element reference
                let resultPointer = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
                if CFNumberGetValue((result as! CFNumber), CFNumberType.sInt32Type, UnsafeMutableRawPointer(resultPointer)) {
                    device = (deviceItem as! IOHIDDevice)
                    print(resultPointer[0])
                    if resultPointer[0] == 65280 {
                        // THIS IS DEVICE
                        device = (deviceItem as! IOHIDDevice)
                        break
                    }
                }
            }
        }
        
    }
}
*/



// Settings reading
if let file = FileHandle.init(forReadingAtPath: "psvrCinemaUtil.dat") {
    // Try to read
    let data = file.readData(ofLength: 3)
    file.closeFile()
    if data.count == 3 {
        data.copyBytes(to: buffer, count: 3)
        // Read values
        bufferSet = true
    } else {
        try fileManager.removeItem(atPath: "psvrCinemaUtil.dat")
    }
}

if !bufferSet {
    FileHandle.standardError.write("Copyright (C) 2018 Nikita Mordasov. All rights reserved.\n\nThis is psvrCinemaUtil\nRun this util to activate PSVR Rev1 connected by USB to this machine.\n(to re-center: off and on headset visor)".data(using: String.Encoding.ascii)!)
    FileHandle.standardError.write("\n\nEnter Screen Size [min 26 - max 80]\nEnter Value:".data(using: String.Encoding.ascii)!)
    // FileHandle.standardInput.readData(ofLength: 2)
    // ASK FOR INPUT
    buffer[0] = UInt8((String.init(data: FileHandle.standardInput.availableData, encoding: String.Encoding.ascii)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))!)!
    FileHandle.standardError.write("\n\nEnter Brightness Level [min 0 - max 32]\nEnter Value:".data(using: String.Encoding.ascii)!)
    buffer[1] = UInt8((String.init(data: FileHandle.standardInput.availableData, encoding: String.Encoding.ascii)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))!)!
    FileHandle.standardError.write("\n\nEnable Virtual Screen = 1 or Fixed = 0\nEnter Value:".data(using: String.Encoding.ascii)!)
    buffer[2] = UInt8((String.init(data: FileHandle.standardInput.availableData, encoding: String.Encoding.ascii)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))!)!
    FileHandle.standardError.write("\n\nYour settings: \nScreen[26-80]: \(buffer[0])\nBrightness[0-32]: \(buffer[1])\nVirtual screen[0-1]: \(buffer[2])\nSettings will be saved to file psvrCinemaUtil.dat, delete file to start over\n\nEnter 1 to confirm:".data(using: String.Encoding.ascii)!)
    let confirmation: UInt8 = UInt8((String.init(data: FileHandle.standardInput.availableData, encoding: String.Encoding.ascii)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))!)!
    if confirmation != 1 {
        exit(1)
    } else {
        fileManager.createFile(atPath: "psvrCinemaUtil.dat", contents: Data.init(bytes: buffer, count: 3), attributes: nil)
    }
}

// MAKE DATA
// TOTAL MESSAGE OF 64 BYTES
var dataMessage: [UInt8] = [33, // REPORT ID 0x21 = 33
    0, // SEPARATION BIT
    170, // MESSAGE START 0xAA = 170
    16, // SIZE OF MEANINGFUL DATA BELOW IN BYTES
    192*buffer[2], // FIXED VIEW set 0x80 = 128 or VIRTUAL THEATER 0xC0 = 192)
    buffer[0], // Cinematic Screen Size (range from 26=small to 80=large)
    35, // Cinematic Screen Distance (range from 20=near to 50=far)
    0, // IPD 0-41
    0,0,0,0,0,0, // unknown 6 bytes
    buffer[1], // Brightness (range from 0=dim to 32=bright)
    0, // Localized MIC Feedback (range from 0=mute to 5=max)
    0, // Social Screen Resolution in VR mode (0=Auto, 1=1080p, 2=1080i, 3=720p, 4=480p)
    1, // Audio Source in HMD (0=Auto?, 1=HDMI, 2=None??)
    0, // Social Screen Frequency? (0=60Hz, 1=58Hz? Intermittent)
    0, // unknown
    0,0,0,0,0,0,0,0,0,0, // 44 bytes to top up to 64 packet
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0
]

// WELCOME MESSAGE
FileHandle.standardError.write("\nCopyright (C) 2018 Nikita Mordasov. All rights reserved.\n\npsvrCinemaUtil is running:\nCursor can be moved within screen by head movement.\nVR Control Buttons Remapped:\nMute: re-centers view and cursor\nVolume Down: Hold to Enable Cursor Movement\nVolume Up: Click at the Cursor (Single Click Only)\nTo update settings, find and delete psvrCinemaUtil.dat\nCtrl+C to exit (VR will continue to work).\n".data(using: String.Encoding.ascii)!)


// USB MANAGEMENT
//let managerIOHID: IOHIDManager = IOHIDManagerCreate(kCFAllocatorDefault, 0)

/*
 65281
 65280
 */

var deviceSender: IOHIDDevice?
// Matching filter: kIOHIDPrimaryUsagePageKey = 65280
let matchingSenderDictionary: CFDictionary = NSDictionary(dictionary: [kIOHIDVendorIDKey:0x054C,kIOHIDProductIDKey:0x09AF,kIOHIDPrimaryUsagePageKey:0xFF00]) as CFDictionary
// Create manager
let managerIOHIDSender: IOHIDManager = IOHIDManagerCreate(kCFAllocatorDefault, 0)
// Set matching filter
IOHIDManagerSetDeviceMatching(managerIOHIDSender, matchingSenderDictionary)
// Set device connect/disconnect callbacks
IOHIDManagerRegisterDeviceMatchingCallback(managerIOHIDSender, { (inContext: UnsafeMutableRawPointer?, inIOReturn: IOReturn, inSender: UnsafeMutableRawPointer?, inIOHIDDevice: IOHIDDevice) in
    // Connect the device
    deviceSender = inIOHIDDevice
    // Send activation report
    IOHIDDeviceSetReport(inIOHIDDevice, kIOHIDReportTypeOutput, 0x21, dataMessage, 64)
    // Present message
    FileHandle.standardError.write("\nPSVR USB IS CONNECTED\n".data(using: String.Encoding.ascii)!)
}, nil)

IOHIDManagerRegisterDeviceRemovalCallback(managerIOHIDSender, { (inContext: UnsafeMutableRawPointer?, inIOReturn: IOReturn, inSender: UnsafeMutableRawPointer?, inIOHIDDevice: IOHIDDevice) in
    // Nillify device
    deviceSender = nil
    // Present message
    FileHandle.standardError.write("\nWARNING: PSVR USB IS DISCONNECTED\nWAITING FOR PSVR USB CONNECTION...\n".data(using: String.Encoding.ascii)!)
}, nil)

// Enable Sender Manager
IOHIDManagerOpen(managerIOHIDSender, 0)

// Detect device, after manager is open
if let devicesSet: CFSet = IOHIDManagerCopyDevices(managerIOHIDSender) {
    if (devicesSet as NSSet).count == 0 {
        FileHandle.standardError.write("\nWAITING FOR PSVR USB CONNECTION...\n".data(using: String.Encoding.ascii)!)
    }
} else {
    FileHandle.standardError.write("\nWAITING FOR PSVR USB CONNECTION...\n".data(using: String.Encoding.ascii)!)
}
// Put in a run loop to start detecting devices in real time
IOHIDManagerScheduleWithRunLoop(managerIOHIDSender, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)



// RECEIVING
// Matching filter: kIOHIDPrimaryUsagePageKey = 65281
let matchingRecieverDictionary: CFDictionary = NSDictionary(dictionary: [kIOHIDVendorIDKey:0x054C,kIOHIDProductIDKey:0x09AF,kIOHIDPrimaryUsagePageKey:0xFF01]) as CFDictionary
// Create manager
let managerIOHIDReciever: IOHIDManager = IOHIDManagerCreate(kCFAllocatorDefault, 0)
// Register filter
IOHIDManagerSetDeviceMatching(managerIOHIDReciever, matchingRecieverDictionary)

// Common memory pointers to convert 2xUInt8 to Int16
var numberPointerInt16 = UnsafeMutablePointer<Int16>.allocate(capacity: 1)
var numberPointerUInt8: UnsafeMutablePointer<UInt8> = UnsafeMutableRawPointer(numberPointerInt16).assumingMemoryBound(to: UInt8.self)

// Mouse shift dynamic values, summarized Gyro reports
var horizontal: Int = 0
var vartical: Int = 0

// Screen size
let displayBounds: CGRect = CGDisplayBounds(CGMainDisplayID())

// Button status helpers
var buttonVolUp: Bool = false
var buttonVolDown: Bool = false
var buttonMute: Bool = false

// Reduces mouse move calls
var mouseDragSplitter: Bool = true

func cursorPoint(_ horizontal: Int, _ vartical: Int, _ displayBounds: CGRect) -> CGPoint {
    var h = (-CGFloat(horizontal)/600.0) + (displayBounds.width / 2)
    var v = (-CGFloat(vartical)/600.0) + (displayBounds.height / 2)
    h = h < 0 ? 0 : (h > displayBounds.width ? displayBounds.width : h)
    v = v < 0 ? 0 : (v > displayBounds.height ? displayBounds.height : v)
    return CGPoint(x: h, y: v)
}

// Add report block
IOHIDManagerRegisterInputValueCallback(managerIOHIDReciever, { (context: UnsafeMutableRawPointer?, result: IOReturn, sender: UnsafeMutableRawPointer?, value: IOHIDValue) in
    let length = IOHIDValueGetLength(value)
    if length == 64 {
    let pointer: UnsafePointer<UInt8> = IOHIDValueGetBytePtr(value)
        
        let buttonByte: UInt8 = pointer[0]
        let buttonVolUpNow: Bool = buttonByte&2 == 0 ? false : true
        let buttonVolDownNow: Bool = buttonByte&4 == 0 ? false : true
        let buttonMuteNow: Bool = buttonByte&8 == 0 ? false : true
        
        if buttonVolUpNow != buttonVolUp {
            if buttonVolUp {
                let eventMouseUp = CGEvent(mouseEventSource: nil, mouseType: CGEventType.leftMouseUp, mouseCursorPosition: cursorPoint(horizontal, vartical, displayBounds), mouseButton: CGMouseButton.left)
                eventMouseUp?.post(tap: CGEventTapLocation.cgSessionEventTap)
            } else {
                let eventMouseDown = CGEvent(mouseEventSource: nil, mouseType: CGEventType.leftMouseDown, mouseCursorPosition: cursorPoint(horizontal, vartical, displayBounds), mouseButton: CGMouseButton.left)
                eventMouseDown?.post(tap: CGEventTapLocation.cgSessionEventTap)
            }
            buttonVolUp = buttonVolUpNow
        } else if buttonVolDownNow {
            // Continiously calculate cursor from Gyro Data while button pressed
            numberPointerUInt8[0] = pointer[36]
            numberPointerUInt8[1] = pointer[37]
            horizontal = horizontal + Int(numberPointerInt16[0])
            numberPointerUInt8[0] = pointer[38]
            numberPointerUInt8[1] = pointer[39]
            vartical = vartical + Int(numberPointerInt16[0])
            // Calculate and move cursor
            if mouseDragSplitter {
                mouseDragSplitter = false
                let cursorPointVal: CGPoint = cursorPoint(horizontal, vartical, displayBounds)
                let eventMouseDisabled = CGEvent(mouseEventSource: nil, mouseType: CGEventType.tapDisabledByTimeout, mouseCursorPosition: cursorPointVal, mouseButton: CGMouseButton.left)
                let eventMouseMove = CGEvent(mouseEventSource: nil, mouseType: CGEventType.mouseMoved, mouseCursorPosition: cursorPointVal, mouseButton: CGMouseButton.left)
                eventMouseMove?.post(tap: CGEventTapLocation.cghidEventTap)
                eventMouseDisabled?.post(tap: CGEventTapLocation.cghidEventTap)
                //CGWarpMouseCursorPosition(cursorPointVal)
            } else { mouseDragSplitter = true }
        } else if buttonMuteNow != buttonMute {
            if !buttonMute && (deviceSender != nil) {
                // Reset
                // Reset cursor
                horizontal = 0
                vartical = 0
                //CGDisplayMoveCursorToPoint(display, cursorPoint(horizontal, vartical, displayBounds))
                let cursorPointVal: CGPoint = cursorPoint(horizontal, vartical, displayBounds)
                let eventMouseDisabled = CGEvent(mouseEventSource: nil, mouseType: CGEventType.tapDisabledByTimeout, mouseCursorPosition: cursorPointVal, mouseButton: CGMouseButton.left)
                let eventMouseMove = CGEvent(mouseEventSource: nil, mouseType: CGEventType.mouseMoved, mouseCursorPosition: cursorPointVal, mouseButton: CGMouseButton.left)
                eventMouseMove?.post(tap: CGEventTapLocation.cghidEventTap)
                eventMouseDisabled?.post(tap: CGEventTapLocation.cghidEventTap)
                // Switch
                if buffer[0] == 80 { dataMessage[5] = 30 } else { dataMessage[5] = 80 }
                // Send packet
                IOHIDDeviceSetReport(deviceSender!, kIOHIDReportTypeOutput, 0x21, dataMessage, 64)
                // Switch
                dataMessage[5] = buffer[0]
                // Send packet
                IOHIDDeviceSetReport(deviceSender!, kIOHIDReportTypeOutput, 0x21, dataMessage, 64)
            }
            buttonMute = buttonMuteNow
        }
        
        
        }
}, nil)

// Enable Reciever Manager
IOHIDManagerOpen(managerIOHIDReciever, 0)
// Enter to run Loop
IOHIDManagerScheduleWithRunLoop(managerIOHIDReciever, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

// Put program in run loop, to keep running
RunLoop.current.run()

