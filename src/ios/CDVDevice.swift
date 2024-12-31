/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

import UIKit

extension UIDevice {
    func modelVersion() -> String? {
        #if targetEnvironment(simulator)
            let platform: String? = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
        #else
            var systemInfo = utsname()
            uname(&systemInfo)
            let mirror = Mirror(reflecting: systemInfo.machine)
            let platform = mirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
        #endif
        
        return platform
    }
}

@objc(CDVDevice)
class CDVDevice: CDVPlugin {
    let userDefaults: UserDefaults = UserDefaults.standard
    static let UUID_KEY: String = "CDVUUID"
    
    func uniqueAppInstanceIdentifier(device: UIDevice?) -> String? {
        // Check user defaults first to maintain backwards compaitibility with previous versions
        // which didn't user identifierForVendor
        var app_uuid: String? = userDefaults.string(forKey: CDVDevice.UUID_KEY)
        if (app_uuid == nil) {
            if (device?.identifierForVendor?.uuidString != nil) {
                app_uuid = device?.identifierForVendor?.uuidString
            } else {
                app_uuid = UUID().uuidString
            }
            
            userDefaults.set(app_uuid, forKey: CDVDevice.UUID_KEY)
            userDefaults.synchronize()
        }
        
        return app_uuid
    }
    
    @objc(getDeviceInfo:)
    func getDeviceInfo(command: CDVInvokedUrlCommand?) {
        let deviceProperties = self.deviceProperties()
        let pluginResult: CDVPluginResult? = CDVPluginResult(status:CDVCommandStatus_OK, messageAs: deviceProperties)
        
        self.commandDelegate.send(pluginResult, callbackId: command?.callbackId)
    }

    func deviceProperties() -> Dictionary<String, Any> {
        let device: UIDevice = UIDevice.current
        
        return [
            "manufacturer": "Apple",
            "model": device.modelVersion() as Any,
            "platform": "iOS",
            "version": device.systemVersion,
            "uuid": uniqueAppInstanceIdentifier(device: device) as Any,
            "isVirtual": isVirtual(),
            "isiOSAppOnMac": isiOSAppOnMac()
        ]
    }
    
    func isVirtual() -> Bool {
        #if targetEnvironment(simulator)
            return true;
        #else
            return false;
        #endif
    }
    
    func isiOSAppOnMac() -> Bool {
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac
        }

        return false
    }
}
