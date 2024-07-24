//
//  AddNewCoinViewController.swift
//  CryptoTracking
//
//  Created by admin on 24/7/24.
//

import Foundation
import UIKit

protocol AddNewCoinViewControllerDelegate: AnyObject {
    func reloadData()
}

class AddNewCoinViewController: BaseViewController, UITextFieldDelegate, UIPickerViewDelegate {
    @IBOutlet weak var numberCoinTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var coinLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    
    weak var delegate: AddNewCoinViewControllerDelegate?
    private var pickerData: [Coin]?
    private var coin: Coin?
    let service = Services.shared
    let coreDataManager = CoreDataManager.shared()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        coreDataManager.fetchedData(self)
        setupView()
    }
    
    private func getHistoryCoin(uuid: String, completion:@escaping (String) -> Void) {
        service.getCoinHistory(uuid: uuid, type: .oneDay) { response, error in
            self.dismissLoadingView()
            let stringArray = response?.data?.history?.map{$0.price ?? ""}.joined(separator: ",")
            completion(stringArray ?? "")
        }
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func didTapSave(_ sender: Any) {
        if self.numberCoinTextField.text?.isEmpty ?? true{
            self.showError(message: "Invalid Number")
            return
        }
        self.showLoadingView()
        getHistoryCoin(uuid: self.coin?.uuid ?? "") { priceHistory in
            let coins = self.coreDataManager.fetchedCoin(uuid: self.coin?.uuid ?? "", symbol: self.coin?.symbol ?? "")
            if let coinData = coins.first {
                let sum = (Int(coinData.number ?? "") ?? 0) + (Int(self.numberCoinTextField.text ?? "") ?? 0)
                coinData.number = "\(sum)"
                
                let price = ((Double(coinData.price ?? "") ?? 0.0) + (self.priceTextField.text?.removeCurencyFormat() ?? 0.0)) / 2
                coinData.price = "\(price)"
                coinData.priceHistory = priceHistory
            } else {
                let coinData = CoinData(context: self.coreDataManager.viewContext)
                coinData.symbol = self.coin?.symbol ?? ""
                coinData.uuid = self.coin?.uuid ?? ""
                coinData.name = self.coin?.name ?? ""
                coinData.price = "\(self.priceTextField.text?.removeCurencyFormat() ?? 0.0)"
                coinData.number = self.numberCoinTextField.text
                coinData.iconURL = self.coin?.iconURL ?? ""
                coinData.priceHistory = priceHistory
            }
            self.dismissLoadingView()
            self.coreDataManager.save()
            self.dismiss(animated: true)
            self.delegate?.reloadData()
        }
    }
    
    private func setupView() {
        numberCoinTextField.delegate = self
        priceTextField.delegate = self
        pickerView.dataSource = self
        pickerView.delegate = self
        addTapGestureInView()
        pickerData = service.allCoins
        coin = service.allCoins.first
        coinLabel.text = self.coin?.symbol ?? ""
        priceTextField.text = self.coin?.price.currencyFormat()
    }
    
    
    fileprivate func addTapGestureInView() {
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(onHandleTapAction))
        tapGes.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGes)
    }
    
    @objc func onHandleTapAction() {
        view.endEditing(true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        if textField == priceTextField {
            let newString = text.formattedNumber()
            priceTextField.text = newString.convertToCurrencyFormat()
            return false
        } else if textField == numberCoinTextField && text.count > 10 {
            showError(message: "Max number")
            return false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension AddNewCoinViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerData?.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let data = self.pickerData?[row]
        return (data?.symbol ?? "") + "---" + (data?.name ?? "")
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        coin = self.pickerData?[row]
        coinLabel.text = coin?.symbol ?? ""
        priceTextField.text = coin?.price.currencyFormat()
    }
}
