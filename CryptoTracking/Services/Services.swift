//
//  Services.swift
//  CryptoTracking
//
//  Created by admin on 10/6/24.
//

import UIKit

enum CurrencyAPI {
    case getCoins
    case getCoin(String)
    case coinHistory(String)
}

enum SecretAPIKeys {
    static let CoinAPIio = "1ECF60CD-5C10-44AC-9E0F-B7F4867A5133"
    static let CoinrankingAPIKey = "coinranking98dc86bd1e28efd38bf20c9cb2bd5e992a88a64214a10cc3"
}

extension CurrencyAPI {
    
    var urlRequest: URLRequest {
        return URLRequest(url: URL(string: self.urlString)!)
    }
    
    var urlString: String {
        return self.baseURL.appendingPathComponent(self.path).absoluteString.removingPercentEncoding!
    }
    
    var baseURL: URL{
        switch self {
        case .getCoins, .getCoin, .coinHistory:
            return URL(string: "https://api.coinranking.com/v2/")!
        }
    }
    
    var path: String {
        switch self {
        case .getCoins:
            return "coins"
        case .getCoin(let id):
            return "/coin/\(id)"
        case .coinHistory(let id):
            return "/coin/\(id)/history"
        }
    }
}

class Services {
    
    static let shared = Services()
    var currencyUsd: String {
        "yhjMzLPhuIDl"
    }
    let cache = NSCache<NSString, UIImage>()
    public var imageURLViewModel: [String: String] = [:]
    var allCoins: [Coin] = []
    
    func getAllCoins(completion: @escaping (CoinsResponse?, Error?) -> Void) {
        let request = CurrencyAPI.getCoins.urlRequest
        self.getRequest(url: request.url!, responseType: CoinsResponse.self) { response, error in
            if let response = response {
                self.allCoins = response.data.coins
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func getCoinDetail(uuid: String,completion: @escaping (CoinDetailResponse?, Error?) ->Void) {
        let urlComps = URLComponents(string: CurrencyAPI.getCoin(uuid).urlString)!
        self.getRequest(url: urlComps.url!, responseType: CoinDetailResponse.self) { response, error in
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func getCoinHistory(uuid: String, type: Historical, completion: @escaping (HistoryResponse?, Error?) -> Void) {
        var urlComps = URLComponents(string: CurrencyAPI.coinHistory(uuid).urlString)!
        let queryItem = [URLQueryItem(name: "referenceCurrencyUuid", value: currencyUsd ),URLQueryItem(name: "timePeriod", value: type.description)]
        urlComps.queryItems = queryItem
        self.getRequest(url: urlComps.url!, responseType: HistoryResponse.self) { response, error in
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func getRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.addValue(SecretAPIKeys.CoinrankingAPIKey, forHTTPHeaderField: "x-access-token")
        let task = URLSession.shared.dataTask(with: url) {data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(responseType, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
        
}
