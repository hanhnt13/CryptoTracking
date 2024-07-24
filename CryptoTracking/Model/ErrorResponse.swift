//
//  ErrorResponse.swift
//  CryptoTracking
//
//  Created by admin on 10/6/24.
//

import Foundation

struct ErrorResponse: Codable {
    let status, type, message: String
}
