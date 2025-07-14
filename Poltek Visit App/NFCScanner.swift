//
//  NFCScanner.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 14/7/25.
//

import Foundation
import CoreNFC

final class NFCScanner: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var scannedMessages: [String] = []
    private var session: NFCNDEFReaderSession?

    /// Start a new NFC scan session (invalidates any prior session).
    func beginScanning() {
        print(" NFCScanner: beginScanning()")
        guard NFCNDEFReaderSession.readingAvailable else {
            print("NFCScanner: NFC not supported")
            return
        }
        session?.invalidate()
        scannedMessages.removeAll()
        session = NFCNDEFReaderSession(delegate: self,
                                       queue: nil,
                                       invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold iPhone near tag"
        session?.begin()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFCScanner: session invalidated – \(error.localizedDescription)")
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for record in message.records {
                let payloadString: String
                if let str = String(data: record.payload, encoding: .utf8),
                   !str.isEmpty
                {
                    payloadString = str
                } else {
                    payloadString = record.payload.map {
                        String(format: "%.2hhx", $0)
                    }.joined()
                }
                print(" NFCScanner: detected payload -> \(payloadString)")
                DispatchQueue.main.async {
                    self.scannedMessages.append(payloadString)
                }
            }
        }
    }
}
