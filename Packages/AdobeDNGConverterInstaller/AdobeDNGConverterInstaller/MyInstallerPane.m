//
//  MyInstallerPane.m
//  AdobeDNGConverterInstaller
//
//  Created by Christoph Clausen on 11.09.18.
//  Copyright © 2018 Dotphoton. All rights reserved.
//

#import "MyInstallerPane.h"

@implementation MyInstallerPane {
    BOOL wantsInstall;
}

- (NSString *)title
{
    return [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"PaneTitle" value:nil table:nil];
}

- (void)didEnterPane:(InstallerSectionDirection)dir {
    [super didEnterPane:dir];
    [self setupInstallView];
    NSLog(@"Adobe found: %d", [self.downloadVC isDNGConverterInstalled]);
    wantsInstall = ![self.downloadVC isDNGConverterInstalled];
    self.nextEnabled = !wantsInstall;
    [self setupButton];
    
}

- (IBAction)installButtonClicked:(id)sender {
    if(wantsInstall) {
        [self showCustomSheet];
    }
}

- (void) setupInstallView {
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    self.downloadVC = [[DNGConverterDownloadViewController alloc] initWithNibName:@"DNGConverterDownloadViewController" bundle:bundle];
    [self.subView addSubview:self.downloadVC.view];
    self.downloadVC.view.frame = self.subView.bounds;
    [self.downloadVC.view setHidden:true];
    
    __weak typeof(self) weakSelf = self;
    self.downloadVC.completionHandler = ^() {
        typeof(self) strongSelf = weakSelf;
        [strongSelf setNextEnabled:true];
        NSColor *green = [NSColor colorWithRed:80.0/255 green:180.0/255 blue:20.0/255 alpha:1.0];
        [strongSelf setButtonColor:green title:@"Installed"];
        NSLog(@"Installation completed.");
    };;
}

- (void)setupButton {
    if (!wantsInstall) {
        NSColor *green = [NSColor colorWithRed:80.0/255 green:180.0/255 blue:20.0/255 alpha:1.0];
        [self setButtonColor:green title:@"Installed"];
    } else {
        NSColor *blue = [NSColor colorWithRed:0.0/255 green:105.0/255 blue:217.0/255 alpha:1.0];
        [self setButtonColor:blue title:@"Download and install"];
    }
}

- (void)setButtonColor:(NSColor *)color title:(NSString *)title {
    
    [self.installButtonBox setFillColor:color];
    [self.installButton setWantsLayer:true];
    [self.installButton.layer setBackgroundColor:color.CGColor];
    
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:title];
    NSUInteger len = [attrTitle length];
    NSRange range = NSMakeRange(0, len);
    [attrTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:18] range:range];
    [attrTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:range];
    [attrTitle setAlignment:NSTextAlignmentCenter range:range];
    [attrTitle fixAttributesInRange:range];
    [self.installButton setAttributedTitle:attrTitle];
}

- (void)showCustomSheet {
    self.licenseWindow = [[AdobeLicenseWindow alloc] initWithWindowNibName:@"AdobeLicenseWindow"];
    
    [self.contentView.window beginSheet:self.licenseWindow.window completionHandler:^(NSModalResponse returnCode) {
        NSLog(@"Return code: %ld", (long)returnCode);
        if(returnCode == NSModalResponseOK) {
            [self.installButton setEnabled:false];
            [self.downloadVC.view setHidden:false];
            [self setButtonColor:NSColor.grayColor title:@"Installing..."];
            
            [self.downloadVC startDownload];
        }
    }];

}

@end
