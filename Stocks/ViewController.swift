//
//  ViewController.swift
//  Stocks
//
//  Created by Const. on 01.02.2020.
//  Copyright © 2020 Oleginc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: - UI
    
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    
    @IBOutlet weak var companyLogo: UIImageView!
    
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        requestCompanies()
    }

    // MARK: - Private
    
    private var animateFlag = false
    private var connectionFlag = false
    
    private var companies = [String: String]()
    
    private lazy var reserveCompanies = [
        "Apple": "AAPL",
        "Microsoft": "MSFT",
        "Google": "GOOG",
        "Amazon": "AMZN",
        "Facebook": "FB"
    ]
    
    // MARK: - Requests
    
    private let token = "pk_a9abbb6ddd9e4704a1d6a16c64c38108"
    
    private func requestCompanies() {
        
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/market/collection/list?collectionName=mostactive&token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let data = data,
            (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                self?.connectionFlag = true
                self?.parseCompanies(from: data)
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.connectionFlag = false
                    self?.showError()
                }
            }
        }
        
        dataTask.resume()
        
    }
    
    private func requestStock(for symbol: String) {
        
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)") else {
            return
        }
        
        guard let urlForImage = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(token)") else {
            return
        }
        
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let data = data,
            (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                self?.connectionFlag = true
                self?.parseQuote(from: data)
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.connectionFlag = false
                    self?.showError()
                }
            }
        }
        
        let dataTaskForImage = URLSession.shared.dataTask(with: urlForImage) { [weak self] (data, response, error) in
            if let data = data,
            (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                self?.connectionFlag = true
                self?.parseLogo(from: data)
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.connectionFlag = false
                    self?.showError()
                }
            }
        }
        
        dataTask.resume()
        dataTaskForImage.resume()
    }
    
    // MARK: - Parsing
    
    private func parseCompanies(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let jsonArr = jsonObject as? [Any] else {return print("Invalid JSON")}
            
            for json in jsonArr {
                    guard
                    let curr = json as? [String: Any],
                    let companyName = curr["companyName"] as? String,
                    let companySymbol = curr["symbol"] as? String else {return print("Invalid JSON")}
            
                    companies.updateValue(companySymbol, forKey: companyName)
                    
                }
            
            DispatchQueue.main.async { [weak self] in
                self?.companyPickerView.reloadAllComponents()
                self?.requestQouteUpdate()
            }
            
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func parseQuote(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double else {return print("Invalid JSON")}
            
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyName, companySymbol: companySymbol, price: price, priceChange: priceChange)
            }
            
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func parseLogo(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let imageURL = json["url"] as? String else {return print("Invalid JSON")}
            
            
            guard
                let url = URL(string: imageURL),
                let data = try? Data(contentsOf: url),
                let logo = UIImage(data: data) else {return print("Something wrong with company logo")}
            
            DispatchQueue.main.async { [weak self] in
                self?.setLogo(image: logo)
            }
            
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    // MARK: - Work with UI
    
    private func showError() {
        companyPickerView.reloadAllComponents()
        let alert = UIAlertController(title: "Error", message: "Internet connection failed", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    private func setLogo(image: UIImage) {
        companyLogo.image = image
        if animateFlag {
            animateFlag = false
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    private func displayStockInfo(companyName: String, companySymbol: String, price: Double, priceChange: Double) {
        if animateFlag {
            animateFlag = false
        } else {
            activityIndicator.stopAnimating()
        }
        companyNameLabel.text = companyName
        
        if companyName.count >= 25 {
            companyNameLabel.font = companyNameLabel.font.withSize(12)
        }
        
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "\(priceChange)"
        
        if priceChange > 0 {
            priceChangeLabel.textColor = UIColor.green
        } else if priceChange < 0 {
            priceChangeLabel.textColor = UIColor.red
        }
    }
    
    private func requestQouteUpdate() {
        activityIndicator.startAnimating()
        animateFlag = true
        
        companyNameLabel.text = "-"
        companyNameLabel.font = companyNameLabel.font.withSize(17)
        
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        
        priceChangeLabel.textColor = UIColor.black
        companyLogo.image = UIImage()
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestStock(for: selectedSymbol)
        
    }

}

// MARK: - UIPickerViewDataSource

extension ViewController : UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if connectionFlag {
            return companies.keys.count
        } else {
            return reserveCompanies.keys.count
        }
    }
    
    
}

// MARK: - UIPickerViewDelegate

extension ViewController : UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if connectionFlag {
            return Array(companies.keys)[row]
        } else {
            return Array(reserveCompanies.keys)[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if connectionFlag {
            requestQouteUpdate()
        } else {
            requestCompanies()
        }
    }
}
