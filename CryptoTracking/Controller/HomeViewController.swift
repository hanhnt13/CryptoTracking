//
//  HomeViewController.swift
//  CryptoTracking
//
//  Created by admin on 10/6/24.
//

import UIKit

class HomeViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var data: [Coin] = []
    private var filteredList : [Coin]?
    private var refreshControl = UIRefreshControl()
    private var count = 1
    private var shouldActivateSearchBar = true
    private var searchBar = UISearchBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "CryptoViewCell", bundle: nil), forCellReuseIdentifier: CryptoViewCell.reuseID)
        setupSearchBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        getAllCoins()
    }
    
    func setupSearchBar() {
        searchBar.sizeToFit()
        searchBar.delegate = self
        tableView.tableHeaderView = searchBar
        
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    private func getAllCoins() {
        showLoadingView()
        Services.shared.getAllCoins { response, error in
            self.dismissLoadingView()
            self.refreshControl.endRefreshing()
                                
            guard let response = response else {
                self.showError(message: "Invalid response from the server, please try again later")
                return
            }
            
            self.data = response.data.coins
            self.tableView.reloadData()
        }
    }
    
    @objc func refresh(_ sender: AnyObject) {
        getAllCoins()
    }
}

extension HomeViewController: UISearchBarDelegate {
    @objc func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if !shouldActivateSearchBar {
            shouldActivateSearchBar = true
            return false
        }
        return true
    }
    
    @objc func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    @objc func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.search(text: searchBar.text)
        searchBar.resignFirstResponder()
    }
    
    @objc func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.count == 0 && !searchBar.isFirstResponder) {
            searchBarDidClear(searchBar)
        } else {
            search(text: searchBar.text)
        }
    }
    
    @objc func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    @objc func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarDidClear(_ searchBar: UISearchBar) {
        shouldActivateSearchBar = false
        search(text: "")
    }
    
    func search(text: String?) {
        filteredList = []
        guard let text = searchBar.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            filteredList = nil
            tableView.reloadData()
            return
        }
        
        filteredList = data.filter { coin in
            return coin.description.range(of: text, options: .caseInsensitive) != nil
        }
        
        tableView.reloadData()
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredList?.count ?? data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CryptoViewCell.reuseID, for: indexPath) as? CryptoViewCell  else {
            fatalError()
        }
        let coin = (filteredList ?? self.data)[indexPath.row]
        cell.setup(by: coin)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let vc = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "DetailsViewController") as? DetailsViewController else {
            return
        }
        let coin = (filteredList ?? self.data)[indexPath.row]
        vc.coin = coin
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
