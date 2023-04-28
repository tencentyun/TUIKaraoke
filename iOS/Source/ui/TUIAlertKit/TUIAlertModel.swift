//
//  TUIAlertModel.swift
//  AlertKit
//
//  Created by adams on 2023/2/22.
//

import UIKit

struct TUIAlertModel {
    let titleText: String
    let descText: String
    let cancelButtonText: String?
    let sureButtonText: String?
    
    let cancelButtonAction: (() -> Void)?
    let sureButtonAction: (() -> Void)?
}
