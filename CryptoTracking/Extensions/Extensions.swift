//
//  NumberFormatterExtension.swift
//  CryptoTracking
//
//  Created by admin on 10/6/24.
//

import Foundation

extension NSNumber {
    func currencyFormat() -> String? {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en-US")
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .currency
        return formatter.string(from: self)
    }
}

extension String {
    func currencyFormat() -> String {
        let number = NSNumber(value: Double(self) ?? 0)
        return number.currencyFormat() ?? "$0"
    }
    
    var convertToDouble: Double {
        Double(self) ?? 0.0
    }
    
    func priceFormat() -> String {
        let price = self.convertToDouble
        let thousand = price / 1000
        let million = price / 1000000
        let billion = price / 1000000000

        if billion >= 1.0 {
            return "\(round(billion*10)/10) Billion"
        } else if million >= 1.0 {
            return "\(round(million*10)/10) Million"
        } else if thousand >= 1.0 {
            return ("\(round(thousand*10/10)) K")
        } else {
            return "\(Int(price))"
        }
    }
    
    func removeCurencyFormat() -> Double {
        let formatter = NumberFormatter()
        let locale = Locale(identifier: "en-US")
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencySymbol = locale.currencySymbol
        formatter.decimalSeparator = locale.groupingSeparator
        return formatter.number(from: self)?.doubleValue ?? 0.00
    }
    
    func convertToCurrencyFormat() -> String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .decimal
        currencyFormatter.locale = .current
        let number = NSNumber(value: Double(self) ?? 0)
        if let currency = currencyFormatter.string(from: number) {
            return "$" + currency
        }
        return "$0"
    }
    
    func formattedNumber() -> String {
        let numbersOnlyEquivalent = replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression, range: nil)
        return numbersOnlyEquivalent.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}
