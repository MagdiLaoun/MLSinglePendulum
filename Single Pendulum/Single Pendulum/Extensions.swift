//
//  Extensions.swift
//  Single Pendulum
//
//  Created by Magdi Laoun on 27.02.2026.
//

import Foundation
import ORSSerial
extension ORSSerialPort {
  func sendIntData(instruction: UInt8, value: Int32){
    let b0: UInt8 = UInt8(value & 0xFF)
    let b1: UInt8 = UInt8((value >> 8) & 0xFF)
    let b2: UInt8 = UInt8((value >> 16) & 0xFF)
    let b3: UInt8 = UInt8((value >> 24) & 0xFF)
    let bytes: [UInt8] = [instruction, b0, b1, b2, b3]
    self.send(Data(bytes))
  }
  func sendFloatData(instruction: UInt8, value: Float){
    guard instruction != 0xFF else { return }
    var bytes: [UInt8] = (bytesFromFloat(value))
    bytes.insert(instruction, at: 0)
    self.send(Data(bytes))
    func bytesFromFloat(_ value: Float) -> [UInt8] {
      var float = value
      let data = withUnsafeBytes(of: &float) { Data($0) }
      return [UInt8](data)
    }
  }
  static func openSerialPort() -> ORSSerialPort?{
    if let url = ORSSerialPort.availableSerialPorts() {
      print(url)
      if let port = ORSSerialPort(path: url.path) {
        port.baudRate = 115200
        port.parity = .none
        port.numberOfStopBits = 1
        port.usesRTSCTSFlowControl = true
        port.rts = true;
        port.dtr = true;
        port.open()
        print("Port is \(port.isOpen ? "open" : "closed")")
        return port
      }else{
          return nil
      }
    }else{
      print("impossible de trouver url")
      return nil
    }
  }
  static func availableSerialPorts() -> URL? {
    let fileManager = FileManager.default
    let devURL = URL(fileURLWithPath: "/dev")
    do {
      let contents = try fileManager.contentsOfDirectory(at: devURL, includingPropertiesForKeys: nil)
      for url in contents {
        if url.path.contains("usbmodem") || url.path.contains("usbserial") {
          return url
        }
      }
    } catch {
      print("Error reading contents of /dev directory: \(error.localizedDescription)")
      return nil
    }
    return nil
  }
}
