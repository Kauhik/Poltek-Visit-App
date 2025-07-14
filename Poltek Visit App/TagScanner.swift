//
//  TagScanner.swift
//  Poltek Visit App
//
//  Created by Kaushik Manian on 14/7/25.
//

import Foundation
import CoreNFC

final class TagScanner: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    @Published var scannedData: [String] = []
    private var session: NFCTagReaderSession?

    func beginScanning() {
        guard NFCTagReaderSession.readingAvailable else { return }
        session?.invalidate()
        scannedData.removeAll()
        session = NFCTagReaderSession(
            pollingOption: .iso14443,
            delegate: self,
            queue: nil
        )
        session?.alertMessage = "Hold iPhone near tag"
        session?.begin()
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // no-op
    }

    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didInvalidateWithError error: Error
    ) {
        // session ended or error
    }

    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didDetect tags: [NFCTag]
    ) {
        guard let first = tags.first else {
            session.invalidate(errorMessage: "No tag found")
            return
        }
        session.connect(to: first) { error in
            guard error == nil else {
                session.invalidate(errorMessage: "Connection failed")
                return
            }
            switch first {
            case .miFare(let mfTag):
                // read raw UID
                let uid = mfTag.identifier.map { String(format: "%.2hhx", $0) }
                                   .joined()
                DispatchQueue.main.async {
                    self.scannedData.append(uid)
                }
                // then try NDEF if present
                mfTag.queryNDEFStatus { status, _, _ in
                    if status != .notSupported {
                        mfTag.readNDEF { message, error in
                            if let records = message?.records {
                                for record in records {
                                    if let str = String(data: record.payload, encoding: .utf8) {
                                        DispatchQueue.main.async {
                                            self.scannedData.append(str)
                                        }
                                    }
                                }
                            }
                            session.invalidate()
                        }
                    } else {
                        session.invalidate()
                    }
                }
            default:
                session.invalidate(errorMessage: "Unsupported tag")
            }
        }
    }
}
