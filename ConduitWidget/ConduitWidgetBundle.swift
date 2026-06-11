//
//  ConduitWidgetBundle.swift
//  ConduitWidget
//
//  Created by Siddharth Mahajan on 11/06/26.
//

import WidgetKit
import SwiftUI

@main
struct ConduitWidgetBundle: WidgetBundle {
    var body: some Widget {
        DeploymentWidget()
        ConduitWidgetControl()
    }
}
