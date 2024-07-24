//
//  CoinResponse.swift
//  CryptoTracking
//
//  Created by admin on 10/6/24.
//

import Foundation
struct CoinDetailResponse: Codable {
    let status: String
    let data: CoinDetailData
}

struct CoinDetailData: Codable {
    let coin: CoinDetail
}

struct CoinDetail: Codable {
    let uuid, symbol, name: String
    let coinDescription: String?
    let color: String?
    let iconURL: String
    let websiteURL: String?
    let links: [Link]
    let supply: Supply
    let numberOfMarkets, numberOfExchanges: Int
    let the24HVolume, marketCap, price, btcPrice: String
    let change: String?
    let rank: Int
    let sparkline: [String?]
    let allTimeHigh: AllTimeHigh
    let coinrankingURL: String
    let tier: Int
    let lowVolume: Bool
    
    enum CodingKeys: String, CodingKey {
        case uuid, symbol, name
        case coinDescription = "description"
        case color
        case iconURL = "iconUrl"
        case websiteURL = "websiteUrl"
        case links, supply, numberOfMarkets, numberOfExchanges
        case the24HVolume = "24hVolume"
        case marketCap, price, btcPrice, change, rank, sparkline, allTimeHigh
        case coinrankingURL = "coinrankingUrl"
        case tier, lowVolume
    }
}

struct AllTimeHigh: Codable {
    let price: String
    let timestamp: Int
}

struct Link: Codable {
    let name, type: String
    let url: String
}

struct Supply: Codable {
    let confirmed: Bool
    let total, circulating: String?
}

