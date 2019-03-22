//
//  AdobeLicenseWindow.m
//  AdobeDNGConverterInstaller
//
//  Created by Christoph Clausen on 12.09.18.
//  Copyright © 2018 Dotphoton. All rights reserved.
//

#import "AdobeLicenseWindow.h"

@interface AdobeLicenseWindow ()

@end

@implementation AdobeLicenseWindow

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (IBAction)agreedClicked:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (IBAction)disagreedClicked:(id)sender {
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

@end
