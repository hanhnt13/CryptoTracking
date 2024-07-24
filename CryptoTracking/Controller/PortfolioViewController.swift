//
//  PortfolioViewController.swift
//  CryptoTracking
//
//  Created by admin on 18/6/24.
//

import UIKit

class PortfolioViewController: BaseViewController {
    @IBOutlet weak var lblCurrentBalance: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblChange: UILabel!
    @IBOutlet weak var chartView: Chart!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorViewChart: UIActivityIndicatorView!
    @IBOutlet weak var lblTotal: UILabel!
    
    private var data: [CoinData] = []
    private var refreshControl = UIRefreshControl()
    var changeHistory: String = ""
    var arrayHistory: [Double] = []
    let coreDataManager = CoreDataManager.shared()
    let service = Services.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
        
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CryptoViewCell", bundle: nil), forCellReuseIdentifier: CryptoViewCell.reuseID)
    }
    
    @objc func refresh(_ sender: AnyObject) {
        refreshControl.beginRefreshing()
        service.getAllCoins { response, error in
            self.dismissLoadingView()
            self.refreshControl.endRefreshing()
            
            self.coreDataManager.fetchedData(self)
            if let coins = self.coreDataManager.fetchedData?.fetchedObjects, coins.count > 0 {
                let dispatcher = DispatchGroup()
                coins.forEach { coinData in
                    dispatcher.enter()
                    self.getHistoryCoin(uuid: coinData.uuid ?? "") { string in
                        coinData.priceHistory = string
                        dispatcher.leave()
                    }
                }
                
                dispatcher.notify(queue: .main) {
                    self.coreDataManager.save()
                    self.loadData()
                }
            } else {
                self.loadData()
            }
        }
    }
    
    func loadData() {
        showLoadingView()
        activityIndicatorViewChart.startAnimating()
        coreDataManager.fetchedData(self)
        if let coins = coreDataManager.fetchedData?.fetchedObjects {
            dismissLoadingView()
            data = coins
            var listCurrent: [Coin] = []
            for coin in Services.shared.allCoins {
                if coins.contains(where: {$0.symbol == coin.symbol}) {
                    listCurrent.append(coin)
                }
            }
            
            var balance = 0.0
            var priceBalance = 0.0
            var totalBuy = 0.0
            arrayHistory = []
            coins.forEach { coinData in
                if let number = coinData.number?.convertToDouble, let priceHistory = coinData.priceHistory, !priceHistory.isEmpty {
                    let arrayPrice = priceHistory.components(separatedBy: ",").compactMap{Double($0)}
                    if arrayHistory.count > 0 {
                        for index in  0...arrayHistory.count - 1 {
                            let abc1 = arrayHistory[index]
                            let abc2 = arrayPrice[index] * number
                            arrayHistory[index] = abc1 + abc2
                        }
                    } else {
                        arrayPrice.forEach { price in
                            arrayHistory.append(price * number)
                        }
                    }
                    priceBalance += coinData.price?.convertToDouble ?? 0.0
                    if let coinCurrent = listCurrent.first(where: { $0.uuid == coinData.uuid}) {
                        let total = number * coinCurrent.price.convertToDouble
                        balance = balance + total
                        totalBuy += number * (coinData.price?.convertToDouble ?? 0.0)
                    }
                }
            }
            
            var priceCurrent = 0.0
            listCurrent.forEach { coinData in
                priceCurrent += coinData.price.convertToDouble
            }
            lblPrice.text = "\(balance)".currencyFormat()
            lblTotal.text = "Total buy: " + "\(totalBuy)".currencyFormat()
            changeHistory = "\(((priceCurrent - priceBalance) / priceBalance) * 100)"
            updateChange(for: lblChange, percentage: changeHistory)
            setupChartView()
            activityIndicatorViewChart.stopAnimating()
            tableView.reloadData()
        }
    }
    
    private func getHistoryCoin(uuid: String, completion:@escaping (String) -> Void) {
        Services.shared.getCoinHistory(uuid: uuid, type: .oneDay) { response, error in
            self.dismissLoadingView()
            let stringArray = response?.data?.history?.map{$0.price ?? ""}.joined(separator: ",")
            completion(stringArray ?? "")
        }
    }
    
    private func setupChartView() {
        chartView.removeAllSeries()
        chartView.reloadInputViews()
        var data:[Double] = []
        for i in arrayHistory {
            data.append(i)
        }
        addChartSeries(data)
    }
    
    private func addChartSeries(_ data: [Double]) {
        let series = ChartSeries(data)

        series.area = true
        
        if Double(changeHistory)! > 0 {
            series.color = ChartColors.blueColor()
        }
        else {
            series.color = ChartColors.redColor()
        }
        chartView.add(series)
        chartView.xLabels = []
    }
    
    @IBAction func didTapAddNewCoin(_ sender: Any) {
        guard Services.shared.allCoins.isEmpty else {
            showLoadingView()
            Services.shared.getAllCoins { response, error in
                self.dismissLoadingView()
                guard let _ = response else {
                    self.showError()
                    return
                }
                self.showAddNewCoin()
            }

            return
        }
        
        showAddNewCoin()
    }
    
    func showAddNewCoin() {
        guard let vc = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "AddNewCoinViewController") as? AddNewCoinViewController else {
            return
        }
        vc.delegate = self
        self.present(UINavigationController(rootViewController: vc), animated: true)
    }
}

extension PortfolioViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CryptoViewCell.reuseID, for: indexPath) as? CryptoViewCell  else {
            fatalError()
        }
        let coinData = self.data[indexPath.row]
        cell.setup(by: coinData)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return true
    }

    private func tableView(tableView: UITableView!, commitEditingStyle editingStyle:   UITableViewCell.EditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        if (editingStyle == .delete) {
            tableView.beginUpdates()
            tableView.deselectRow(at: indexPath as IndexPath, animated: true)
            tableView.endUpdates()

        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, sourceView, completionHandler) in
            let coin = self.data[indexPath.row]
            CoreDataManager.shared().delete(coin: coin)
            tableView.beginUpdates()
            self.data.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            self.loadData()
            completionHandler(true)
        }

        let swipeActionConfig = UISwipeActionsConfiguration(actions: [delete])
        swipeActionConfig.performsFirstActionWithFullSwipe = false
        return swipeActionConfig
    }
}

extension PortfolioViewController: AddNewCoinViewControllerDelegate {
    func reloadData() {
        loadData()
    }
}

