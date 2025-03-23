import CoreBluetooth
import Foundation

protocol BluetoothManagerDelegate: AnyObject {
    func didDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber)
    func didConnectionSuccess(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
}

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    weak var delegate: BluetoothManagerDelegate?  // 代理
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral? // 用于保存连接的外设
    var peripherals: [CBPeripheral] = [] // 用于保存扫描到的设备
    var isScanning: Bool = false // 标记是否正在扫描

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // CBCentralManagerDelegate 方法：监听蓝牙状态
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            switch central.state {
            case .poweredOn:
                print("蓝牙已开启")
                if isScanning {
                    startScanning() // 蓝牙开启时如果正在扫描，则启动扫描
                }
            // 开始扫描周围的设备
            case .poweredOff:
                print("蓝牙已关闭")
            case .resetting:
                print("蓝牙正在重置")
            case .unauthorized:
                print("蓝牙未授权")
            case .unknown:
                print("蓝牙状态未知")
            case .unsupported:
                print("设备不支持蓝牙")
            @unknown default:
                print("未知状态")
            }
        }
         
    }

    // 扫描到设备时调用
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        print("发现设备：\(peripheral)")
        // 从广告数据中获取设备名称
            if let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
                print("new 发现设备：\(deviceName)")
            } else {
                print("发现设备：名称不可用")
            }
        
            
        // 将扫描到的设备保存到 peripherals 数组中
        if !peripherals.contains(peripheral) &&  peripheral.name != nil {
            peripherals.append(peripheral)
        }
        // 通知代理，设备已被发现
        delegate?.didDiscoverPeripheral(peripheral, advertisementData: advertisementData, rssi: rssi)
    }

    // 连接成功时调用
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("连接成功：\(peripheral.name ?? "未知设备")")
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil) // 获取设备的服务
        delegate?.didConnectionSuccess(central, didConnect: peripheral)
    }

    // 连接失败时调用
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接失败：\(error?.localizedDescription ?? "未知错误")")
    }

    // 设备断开连接时调用
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("已断开连接：\(peripheral.name ?? "未知设备")")
        // 可以在这里清除连接的外设
        connectedPeripheral = nil
    }

    // 获取设备的服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("发现服务失败：\(error.localizedDescription)")
            return
        }
        for service in peripheral.services ?? [] {
            print("发现服务：\(service.uuid)")
            // 发现服务后扫描服务的特征
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    // 获取设备的特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("发现特征失败：\(error.localizedDescription)")
            return
        }
        for characteristic in service.characteristics ?? [] {
            print("发现特征：\(characteristic.uuid)")
            // 可以进行读取或写入操作
            peripheral.readValue(for: characteristic)
        }
    }

    // 读取特征值
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("读取数据失败：\(error.localizedDescription)")
            return
        }
        if let value = characteristic.value {
            print("读取到数据：\(value)")
        }
    }

    // 写入特征值
    func writeData(to characteristic: CBCharacteristic, data: Data) {
        if let peripheral = connectedPeripheral {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }

    // 启动扫描
    func startScanning() {
        if !isScanning {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            isScanning = true
            print("开始扫描设备")
        }
    }

    // 暂停扫描
    func stopScanning() {
        if isScanning {
            centralManager.stopScan()
            isScanning = false
            print("暂停扫描设备")
        }
    }
}

