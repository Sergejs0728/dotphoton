//
//  MyInstallerPane.h
//  AdobeDNGConverterInstaller
//
//  Created by Christoph Clausen on 11.09.18.
//  Copyright © 2018 Dotphoton. All rights reserved.
//

#import <InstallerPlugins/InstallerPlugins.h>
#import "AdobeLicenseWindow.h"
#import "AdobeDNGConverterInstaller-Swift.h"

@interface MyInstallerPane : InstallerPane
@property (weak) IBOutlet NSButton *installButton;
@property (strong) AdobeLicenseWindow *licenseWindow;
@property (weak) IBOutlet NSBox *installButtonBox;
@property (weak) IBOutlet NSView *subView;
@property (strong) DNGConverterDownloadViewController *downloadVC;
@end
