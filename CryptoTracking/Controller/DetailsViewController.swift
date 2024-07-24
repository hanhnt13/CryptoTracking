//
//  DetailsViewController.swift
//  CryptoTracking
//
//  Created by admin on 11/6/24.
//

import UIKit

class DetailsViewController: BaseViewController {
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblPriceChanged: UILabel!
    @IBOutlet weak var lblSymbol: UILabel!
    @IBOutlet weak var chartView: Chart!
    @IBOutlet weak var lblMarketCap: UILabel!
    @IBOutlet weak var lblVolume: UILabel!
    @IBOutlet weak var lblAllTimeHigh: UILabel!
    @IBOutlet weak var lblRank: UILabel!
    @IBOutlet weak var lblNumberOfMarket: UILabel!
    @IBOutlet var historicalButons: [UIButton]!
    let service = Services.shared
    
    var singleCoinId: String = ""
    var currencyId: String?
    var coin: Coin!
    var historyArray: [History]? = []
    var changeHistory: String = ""
    var coinHistory: Historical = .oneDay
    var coinDetail: CoinDetail?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationTitleView()
        setupDefaultDisplay()
        getHistory()
    }
    
    func getHistory() {
        self.showLoadingView()
        let dispatcher = DispatchGroup()
        dispatcher.enter()
        service.getCoinHistory(uuid: coin.uuid, type: coinHistory) { response, error in
            self.historyArray = response?.data?.history
            dispatcher.leave()
        }
        
        dispatcher.enter()
        service.getCoinDetail(uuid: coin.uuid) { response, error in
            self.coinDetail = response?.data.coin
            dispatcher.leave()
        }
        
        dispatcher.notify(queue: .main) {
            self.dismissLoadingView()
            if self.historyArray?.isEmpty ?? true || self.coinDetail == nil {
                self.showError(message: "Invalid response from the server, please try again later.")
            }
            self.reloadChart()
        }
    }
    
    func reloadChart() {
        chartView.removeAllSeries()
        changeHistory = coinDetail?.change ?? "0.00"
        updateChange(for: lblPriceChanged, percentage: changeHistory)
        setupChartView()
        setupView()
    }
    
    private func setupNavigationTitleView() {
        guard navigationController != nil else {
            return
        }
        
        let view = UIView()
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.text = coin.symbol
        label.sizeToFit()
        label.center = view.center
        label.textAlignment = .center
        view.addSubview(label)
        
        let cacheKey = NSString(string: coin.iconURL)
        if let image = service.cache.object(forKey: cacheKey) {
            let imageView = UIImageView()
            imageView.image = image
            let imageAspect = image.size.width/image.size.height
            imageView.frame = CGRect(x: label.frame.origin.x - label.frame.size.height * imageAspect - 5,
                                     y: label.frame.origin.y,
                                     width: label.frame.size.height * imageAspect,
                                     height: label.frame.size.height)
            imageView.contentMode = .scaleAspectFit
            view.addSubview(imageView)
        }
        
        navigationItem.titleView = view
        view.sizeToFit()
    }
    
    private func setupChartView() {
        var data:[Double] = []
        if let historyArray = historyArray?.reversed() {
            for i in historyArray {
                data.append(Double(i.price ?? "0.0")!)
            }
            addChartSeries(data)
        }
    }
    
    private func setupDefaultDisplay() {
        lblSymbol.text = coin.name
        updateChange(for: lblPriceChanged, percentage: coin.change)
        lblPrice.text = coin.price.currencyFormat()
        lblMarketCap.text = "Market Cap: " + (coin.marketCap.priceFormat())
        lblVolume.text = "Volume: " + coin.the24HVolume.priceFormat()
        lblAllTimeHigh.text = "All Time High: N/A "
        lblRank.text = "Rank: \(coin.rank)"
        lblNumberOfMarket.text = "Number of market: N/A "
        historicalButons.forEach {
            $0.tintColor = $0.tag == coinHistory.rawValue ? .blue : .gray
        }
    }
    
    private func setupView() {
        guard let coinDetail = coinDetail else {
            return
        }
        updateChange(for: lblPriceChanged, percentage: coinDetail.change)
        lblPrice.text = coinDetail.price.currencyFormat()
        lblMarketCap.text = "Market Cap: " + coinDetail.marketCap.priceFormat()
        lblVolume.text = "Volume: " + coinDetail.the24HVolume.priceFormat()
        lblAllTimeHigh.text = "All Time High: " + coinDetail.allTimeHigh.price.currencyFormat()
        lblRank.text = "Rank: \(coinDetail.rank)"
        lblNumberOfMarket.text = "Number of market: " +  String(coinDetail.numberOfMarkets)
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
    
    func updateHistory() {
        if coinDetail == nil {
            getHistory()
        } else {
            showLoadingView()
            Services.shared.getCoinHistory(uuid: coin.uuid, type: coinHistory) { response, error in
                self.dismissLoadingView()
                guard let response = response else {
                    self.showError(message: "Invalid response from the server, please try again later")
                    return
                }
                
                if response.code == "RATE_LIMIT_EXCEEDED" {
                    self.showError(message:"You've reached the API request limit. Generate a free API key: https://developers.coinranking.com/create-account")
                    return
                }
                
                self.historyArray = response.data?.history
                self.reloadChart()
            }
        }
    }
    
    @IBAction func boxTouched(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            coinHistory = .threeHours
        case 1:
            coinHistory = .oneDay
        case 2:
            coinHistory = .sevenDays
        case 3:
            coinHistory = .thirtyDays
        case 4:
            coinHistory = .threeMonths
        case 5:
            coinHistory = .oneYear
        default:
            break
        }
        historicalButons.forEach {
            $0.tintColor = $0 == sender ? .blue : .gray
        }
        updateHistory()
    }
    
    @IBAction func didTapThreeHours(_ sender: Any) {
        coinHistory = .threeHours
        updateHistory()
    }
    
    @IBAction func didTapOneDay(_ sender: Any) {
        coinHistory = .oneDay
        updateHistory()
    }
    @IBAction func didTapSevenDays(_ sender: Any) {
        coinHistory = .sevenDays
        updateHistory()
    }
    @IBAction func didTapThirtyDays(_ sender: Any) {
        coinHistory = .thirtyDays
        updateHistory()
    }
    @IBAction func didTapThreeMonths(_ sender: Any) {
        coinHistory = .threeMonths
        updateHistory()
    }
    @IBAction func didTapOneYear(_ sender: Any) {
        coinHistory = .oneYear
        updateHistory()
    }

}
