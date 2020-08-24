//
//  ReaderError.swift
//  StreamAudio
//
//  Created by leven on 2020/8/21.
//  Copyright © 2020 leven. All rights reserved.
//

import Foundation
import AudioToolbox


let ReaderReachedEndOfDataError: OSStatus = 932332581
let ReaderNotEnoughDataError: OSStatus = 932332582
let ReaderMissingSourceFormatError: OSStatus = 932332583

public enum ReaderError: LocalizedError {
    case cannotLockQueue
    case converterFailed(OSStatus)
    case failedToCreateDestinationFormat
    case failedToCreatePCMBuffer
    case notEnoughData
    case parserMissingDataFormat
    case reachedEndOfFile
    case unableToCreateConverter(OSStatus)
    public var errorDescription: String? {
        switch self {
        case .cannotLockQueue:
            return "Failed to lock queue"
        case .converterFailed(let status):
            return localizedDescrtiptionFromConverterError(status)
        case .failedToCreateDestinationFormat:
            return "Failed to create a destination format"
        case .failedToCreatePCMBuffer:
            return "Failed to create PCM Buffer for reading data"
        case .notEnoughData:
            return "Not enough data for read-conversation operation"
        case .parserMissingDataFormat:
            return "Parser is missing a valid data format"
        case .reachedEndOfFile:
            return "Reached the end of the file"
        case .unableToCreateConverter(let status):
            return localizedDescrtiptionFromConverterError(status)
        }
    }
    func localizedDescrtiptionFromConverterError(_ status: OSStatus) -> String {
        return ""
    }
}
