//
//  ViewController.swift
//  IOT_Demo
//
//  Created by satoshi_uma on 2025/3/23.
//

import CoreBluetooth
import UIKit

class ViewController: UIViewController {
    var bluetoothManager: BluetoothManager!
    var peripherals: [CBPeripheral] = []

    @IBOutlet var tableView: UITableView!
    @IBOutlet var contentL: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        print("viewDidLoad")

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PeripheralCell")

        // 初始化蓝牙管理器
        bluetoothManager = BluetoothManager()
        bluetoothManager.delegate = self
        //        bluetoothManager.centralManager.delegate = self
    }

    @IBAction func openBluthClick(_ sender: UIButton) {
        bluetoothManager.startScanning()
    }
}

extension ViewController: BluetoothManagerDelegate {
    func didDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        tableView.reloadData()
    }

    func didConnectionSuccess(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        print("连接成功：\(peripheral.name ?? "未知设备")")
        contentL.text = peripheral.name ?? "未知设备"
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    // UITableViewDataSource 方法
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bluetoothManager.peripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeripheralCell", for: indexPath)

        if let peripheral = bluetoothManager.peripherals[safe: indexPath.row] {
            cell.textLabel?.text = peripheral.name ?? "未知设备"
            cell.contentView.backgroundColor = UIColor(red: CGFloat(Double(arc4random_uniform(256)) / 255.0), green: CGFloat(Double(arc4random_uniform(256)) / 255.0), blue: CGFloat(Double(arc4random_uniform(256)) / 255.0), alpha: 1.0)
        }
        return cell
    }

    // UITableViewDelegate 方法：用户选择设备
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alertView = UIAlertController(title: "连接\(bluetoothManager.peripherals[indexPath.row].name ?? "")", message: "", preferredStyle: .alert)
        let alert = UIAlertAction(title: "连接", style: .destructive) { [weak self] _ in
            if let peripheral = self?.bluetoothManager.peripherals[safe: indexPath.row] {
                self?.bluetoothManager.centralManager.connect(peripheral, options: nil)
            }
        }
        let cancleAlert = UIAlertAction(title: "取消", style: .cancel) { _ in
            print("点击取消按钮")
        }
        alertView.addAction(cancleAlert)
        alertView.addAction(alert)
        present(alertView, animated: true, completion: nil)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
