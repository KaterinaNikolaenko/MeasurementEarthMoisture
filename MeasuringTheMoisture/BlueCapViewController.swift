//
//  BlueCapViewController.swift
//  MeasuringTheMoisture
//
//  Created by Katerina on 09.05.18.
//  Copyright © 2018 Katerina. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreBluetooth

public enum AppError : Error {
    case dataCharactertisticNotFound
    case enabledCharactertisticNotFound
    case updateCharactertisticNotFound
    case serviceNotFound
    case invalidState
    case resetting
    case poweredOff
    case unknown
    case unlikely
}

class BlueCapViewController: UIViewController {

    var peripheral: Peripheral?
    var accelerometerDataCharacteristic: Characteristic?
    let arduinoServiceCBUUID = CBUUID(string: "FFE0") //Device Information = 180A,  FFE0
    let newCharacteristicCBUUID = CBUUID(string: "FFE1")
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let manager = CentralManager(options: [CBCentralManagerOptionRestoreIdentifierKey : "CentralMangerKey" as NSString])
        let manager = CentralManager(options: [CBCentralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.central-manager-documentation" as NSString])
        let stateChangeFuture = manager.whenStateChanges()
        
        let scanFuture = stateChangeFuture.flatMap { state -> FutureStream<Peripheral> in
            switch state {
            case .poweredOn:
                print("central.state is .poweredOn")
//                return manager.startScanning(forServiceUUIDs: [serviceUUID])
                return manager.startScanning(forServiceUUIDs: [self.arduinoServiceCBUUID])
            case .poweredOff:
                print("central.state is .poweredOff")
                throw AppError.poweredOff
            case .unauthorized, .unsupported:
                print("central.state is .unauthorized")
                throw AppError.invalidState
            case .resetting:
                print("central.state is .resetting")
                throw AppError.resetting
            case .unknown:
                print("central.state is .unknown")
                throw AppError.unknown
            }
        }
        
        let connectionFuture = scanFuture.flatMap { [weak manager] discoveredPeripheral  -> FutureStream<Void> in
            manager?.stopScanning()
            self.peripheral = discoveredPeripheral
            return self.peripheral!.connect(connectionTimeout: 10.0)
        }
        
        let discoveryFuture = connectionFuture.flatMap { [weak peripheral] () -> Future<Void> in
            guard let peripheral = self.peripheral else {
                throw AppError.unlikely
            }
            return peripheral.discoverServices([self.arduinoServiceCBUUID])
            }.flatMap { [weak peripheral] () -> Future<Void> in
                guard let _ = self.peripheral, let service = self.peripheral?.services(withUUID: self.arduinoServiceCBUUID)?.first else {
                    throw AppError.serviceNotFound
                }
                return service.discoverCharacteristics([self.newCharacteristicCBUUID])
        }

        let subscriptionFuture = discoveryFuture.flatMap { (service) -> Future<Void> in
            guard let service = self.peripheral?.services(withUUID: self.arduinoServiceCBUUID)?.first else {
                throw AppError.serviceNotFound
            }

            guard let dataCharacteristic = service.characteristics.first else {
                throw AppError.dataCharactertisticNotFound
            }
            
            self.accelerometerDataCharacteristic = dataCharacteristic
            return dataCharacteristic.read(timeout: 1.0)
            }.flatMap { [weak accelerometerDataCharacteristic] () -> Future<Void> in
                guard let accelerometerDataCharacteristic = self.accelerometerDataCharacteristic else {
                    throw AppError.dataCharactertisticNotFound
                }
                return accelerometerDataCharacteristic.startNotifying()
            }.flatMap { [weak accelerometerDataCharacteristic] () -> FutureStream<Data?> in
                guard let accelerometerDataCharacteristic = self.accelerometerDataCharacteristic else {
                    throw AppError.dataCharactertisticNotFound
                }
                return accelerometerDataCharacteristic.receiveNotificationUpdates(capacity: 1)
        }
        subscriptionFuture.onSuccess { data in
            let s = String(data:data!, encoding: .utf8)
             print(s)
            print("test")
        }
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}
