//
//  HistoryResponse.swift
//  CryptoTracking
//
//  Created by admin on 10/6/24.
//

import Foundation

struct HistoryResponse: Codable {
    let status: String
    let code: String?
    let data: HistoryDataClass?
}

struct HistoryDataClass: Codable {
    let change: String?
    let history: [History]?
}

struct History: Codable {
    let price: String?
    let timestamp: Int?
}

enum Historical: Int {
    case threeHours = 0
    case oneDay
    case sevenDays
    case thirtyDays
    case threeMonths
    case oneYear
    
    var description: String {
        switch self {
        case .threeHours:
            return "3h"
        case .oneDay:
            return "24h"
        case .sevenDays:
            return "7d"
        case .thirtyDays:
            return "30d"
        case .threeMonths:
            return "3m"
        case .oneYear:
            return "1y"
        }
    }
}
