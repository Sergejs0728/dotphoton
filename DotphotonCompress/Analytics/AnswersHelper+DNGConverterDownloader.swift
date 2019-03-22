//
//  AnswersHelper+DNGConverterDownloader.swift
//  DotphotonCompress
//
//  Created by Christoph Clausen on 25.07.18.
//  Copyright © 2018 Christoph Clausen. All rights reserved.
//

import Foundation
import Crashlytics

extension AnswersHelper {
    
    func logInstallDNGConverterClicked() {
        Answers.logCustomEvent(withName: "installDNGConverterClicked", customAttributes: nil)
    }
    
    func logInstallDNGConverterDownloadStarted() {
        Answers.logCustomEvent(withName: "installDNGConverterDownloadStarted", customAttributes: nil)
    }
    
    func logInstallDNGConverterDownloadResumed() {
        Answers.logCustomEvent(withName: "installDNGConverterDownloadResumed", customAttributes: nil)
    }
    
    func logInstallDNGConverterDownloadStopped() {
        Answers.logCustomEvent(withName: "installDNGConverterDownloadStopped", customAttributes: nil)
    }
    
    func logInstallDNGConverterInstallationStarted() {
        Answers.logCustomEvent(withName: "installDNGConverterInstallationStarted", customAttributes: nil)
    }
    
    func logInstallDNGConverterInstallationFailed() {
        Answers.logCustomEvent(withName: "installDNGConverterInstallationFailed", customAttributes: nil)
    }
    
    func logInstallDNGConverterInstallationCompleted() {
        Answers.logCustomEvent(withName: "installDNGConverterInstallationCompleted", customAttributes: nil)
    }
    
}
