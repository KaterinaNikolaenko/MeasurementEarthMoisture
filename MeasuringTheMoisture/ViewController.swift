//
//  ViewController.swift
//  MeasuringTheMoisture
//
//  Created by Katerina on 30.04.18.
//  Copyright © 2018 Katerina. All rights reserved.
//
import Foundation
import UIKit
import CoreBluetooth

class ViewController: UIViewController {

    var centralManager: CBCentralManager!
    
    var arduinoPeripheral: CBPeripheral!
    let arduinoServiceCBUUID = CBUUID(string: "FFE0") //Device Information = 180A,  FFE0
    let newCharacteristicCBUUID = CBUUID(string: "FFE1")
    var sendData = "0"
    var _peripheral: CBPeripheral?
    var _characteristic: CBCharacteristic?
    
    var temperatureArray: [String] = []
    var humidityArray: [String] = []
    var soilArray: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func offAction(_ sender: Any) {
        sendData = "0"
        _peripheral?.writeValue(sendData.data(using: .utf8)!, for: _characteristic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    @IBAction func onAction(_ sender: Any) {
        sendData = "1"
        _peripheral?.writeValue(sendData.data(using: .utf8)!, for: _characteristic!, type: CBCharacteristicWriteType.withResponse)
    }
    
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: nil)
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("-------> Peripheral: ")
        print(peripheral)
        arduinoPeripheral = peripheral
        arduinoPeripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(arduinoPeripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
//        arduinoPeripheral.discoverServices(nil)
        arduinoPeripheral.discoverServices([arduinoServiceCBUUID])
    }
}
extension ViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("-------> Service: ")
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print("-------> Characteristic: ")
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                //                peripheral.readValue(for: characteristic)
            }
            
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
//            if characteristic.properties.contains(.write) {
//                let data = sendData.data(using: .utf8)
//                peripheral.writeValue(data!, for: characteristic, type: CBCharacteristicWriteType.withResponse)
//                _peripheral = peripheral
//                _characteristic = characteristic
//            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case newCharacteristicCBUUID:
            if let str = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) as String? {
              
//                let index1 = str.index(str.startIndex, offsetBy: 1)
//                let valueFromSensor1 = String(str[index1 ..< str.endIndex])
//
//                if str.contains("H") {
//                    humidityArray.append(valueFromSensor1)
//                } else if str.contains("T") {
//                    temperatureArray.append(valueFromSensor1)
//                } else {
//                    soilArray.append(valueFromSensor1)
//                }
                humidityArray.append(str)
                print(str)
            } else {
                print(characteristic.value ?? "no value")
            }
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}

