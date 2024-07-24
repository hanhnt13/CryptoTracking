//
//  CryptoViewCell.swift
//  CryptoTracking
//
//  Created by admin on 24/7/24.
//

import UIKit
import SVGKit

class CryptoViewCell: UITableViewCell {
    static let reuseID = "cryptoViewCell"
    let cache = Services.shared.cache
    var isSaveCoreData: Bool = false
    var coin: CoinData?
    let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblID: UILabel!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblValue: UILabel!
    
    override func prepareForReuse() {
        lblName.text = nil
        lblID.text = nil
        imgView.image = nil
        lblValue.text = nil
    }
    
    func setup(by data: Coin) {
        lblValue.text = data.price.currencyFormat()
        lblName.text = data.name
        lblID.text = data.symbol
        self.downloadImage(urlString: data.iconURL)
    }
    
    func setup(by asset: CoinData) {
        isSaveCoreData = true
        coin = asset
        lblValue.text = asset.price?.currencyFormat()
        lblName.text = asset.name
        lblID.text = asset.symbol
        if let dataImage = asset.image {
            self.imgView.image = UIImage(data: dataImage)
        } else {
            self.downloadImage(urlString: asset.iconURL ?? "")
        }
    }
    
    func downloadImage(urlString: String) {
        let cacheKey = NSString(string: urlString)
        guard let url = URL(string: urlString)?.deletingPathExtension().appendingPathExtension("png") else {
            return
        }
        
        showLoading()
        if let image = cache.object(forKey: cacheKey) {
            DispatchQueue.main.async {
                self.imgView.image = image
                if self.isSaveCoreData {
                    self.coin?.image = image.pngData()
                    CoreDataManager.shared().save()
                }
                self.hideLoading()
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                    DispatchQueue.main.async {
                        self.hideLoading()
                        if let error = error {
                            print(error)
                            return
                        }
                        if let downloadedImage = UIImage(data: data!) {
                            self.imgView.image = downloadedImage
                            
                        } else if let imageSvg = SVGKImage(data: data!) {
                            self.imgView.image = imageSvg.uiImage
                        }
                        if let image = self.imgView.image {
                            if self.isSaveCoreData {
                                self.coin?.image = image.pngData()
                                CoreDataManager.shared().save()
                            } else {
                                self.cache.setObject(image, forKey: cacheKey)
                            }
                        }
                    }
                }).resume()
            }
        }
    }
    
    func showLoading() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating()
        
        imgView.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerYAnchor.constraint(equalTo: imgView.centerYAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: imgView.centerXAnchor)
        ])
    }
    
    func hideLoading() {
        loadingIndicator.removeFromSuperview()
    }

}
