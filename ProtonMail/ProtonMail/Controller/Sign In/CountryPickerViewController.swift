//
//  CountryPickerViewController.swift
//  ProtonMail - Created on 3/29/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

protocol CountryPickerViewControllerDelegate {
    func dismissed();
    func apply(_ country : CountryCode);
}

class CountryPickerViewController : UIViewController {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    var delegate : CountryPickerViewControllerDelegate?
    
    fileprivate var countryCodes : [CountryCode] = []
    fileprivate var titleIndex : [String] = [String]()
    fileprivate var indexCache : [String: Int] = [String: Int]()
    
    fileprivate var contryCodeCell : String = "country_code_table_cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4;
        
        tableView.sectionIndexColor = UIColor(hexColorCode: "#9199CB")
        
        titleLabel.text = LocalString._your_country_code
        cancelButton.setTitle(LocalString._general_cancel_button, for: .normal)
        applyButton.setTitle(LocalString._general_apply_button, for: .normal)
        self.prepareSource();
    }
    
    func prepareSource () {
        var country_code : String = ""
        let bundleInstance = Bundle(for: type(of: self))
        if let localFile = bundleInstance.path(forResource: "phone_country_code", ofType: "geojson") {
            if let content = try? String(contentsOfFile:localFile, encoding:String.Encoding.utf8) {
                country_code = content
            }
        }
        
        let parsedObject: Any? = try! JSONSerialization.jsonObject(with: country_code.data(using: String.Encoding.utf8, allowLossyConversion: false)!, options: JSONSerialization.ReadingOptions.allowFragments) as Any?
        if let objects = parsedObject as? [[String : Any]] {
            countryCodes = CountryCode.getCountryCodes(objects)
        }
        countryCodes.sort(by: { (v1, v2) -> Bool in
            return v1.country_en < v2.country_en
        })
        
        var lastLetter : String = ""
        for (index, value) in countryCodes.enumerated() {
            let firstIndex = value.country_en.index(value.country_en.startIndex, offsetBy: 1)
            let firstString = String(value.country_en[..<firstIndex])
            if firstString != lastLetter {
                lastLetter = firstString
                titleIndex.append(lastLetter)
                indexCache[lastLetter] = index
            }
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    @IBAction func applyAction(_ sender: AnyObject) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            if indexPath.row < countryCodes.count {
                let country = countryCodes[indexPath.row]
                delegate?.apply(country)
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelAction(_ sender: AnyObject) {
        delegate?.dismissed()
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}

// MARK: - UITableViewDataSource
extension CountryPickerViewController: UITableViewDataSource {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let countryCell = tableView.dequeueReusableCell(withIdentifier: self.contryCodeCell,
                                                        for: indexPath) as! CountryCodeTableViewCell
        if indexPath.row < countryCodes.count {
            let country = countryCodes[indexPath.row]
            countryCell.ConfigCell(country, vc: self)
        }
        return countryCell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countryCodes.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.zeroMargin()
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if let selectIndex = indexCache[title] {
            tableView.scrollToRow(at: IndexPath(row: selectIndex, section: 0),
                                  at: UITableView.ScrollPosition.top, animated: true)
        }
        return -1
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return titleIndex;
    }
    
    
}

// MARK: - UITableViewDelegate

extension CountryPickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}





