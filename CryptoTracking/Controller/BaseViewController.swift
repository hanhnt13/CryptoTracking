//
//  BaseViewController.swift
//  CryptoTracking
//
//  Created by admin on 28/6/24.
//

import UIKit

class BaseViewController: UIViewController {
    
    fileprivate var containerView: UIView!
    
    func showLoadingView() {
        containerView = UIView(frame: view.bounds)
        view.addSubview(containerView)
        
        containerView.backgroundColor = .systemBackground
        containerView.alpha = 0
        
        UIView.animate(withDuration: 0.25) {
            self.containerView.alpha = 0.8
        }
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        containerView.addSubview(activityIndicator)
        containerView.bringSubviewToFront(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
        
        activityIndicator.startAnimating()
    }
    
    func dismissLoadingView() {
        DispatchQueue.main.async {
            if (self.containerView != nil) {
                self.containerView.removeFromSuperview()
                self.containerView = nil
            }
        }
    }
    
    func updateChange(for label: UILabel, percentage: String?) {
        guard let a = percentage, let doubleValue = Double(a), !doubleValue.isNaN else {
            label.text = ""
            return
        }
        var arrow: String = ""
        if doubleValue < 0 {
            label.textColor = .red
            arrow = "\u{2193}"
        }
        else {
            label.textColor = .systemGreen
            arrow = "\u{2191}"
        }
        label.text = arrow + String(format: "%.2f", doubleValue) + "%"
    }
    
    func showError(message: String? = nil) {
        let alertVC = UIAlertController(title: "Something's Wrong!", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true)
    }
}
