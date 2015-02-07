//
//  AppDelegate.h
//  SBCentral
//
//  Created by Darka on 04/11/14.
//  Copyright (c) 2014 Darka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RFCommComunication.h"


@interface AppDelegate :NSObject <NSApplicationDelegate,ReceivedMessageDelegate> {
    IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusItem;
}

@property (strong,nonatomic)RFCommComunication *rfCommComunication;

@property (weak) IBOutlet NSMenuItem *SBXmenuElement;
@property (weak) IBOutlet NSMenuItem *musicMenuElement;
@property (weak) IBOutlet NSMenuItem *movieMenuElement;
@property (weak) IBOutlet NSMenuItem *gameMenuElement;

//sbx profile
- (IBAction)seMusicProfile:(id)sender;
- (IBAction)setMovieProfile:(id)sender;
- (IBAction)setGameProfile:(id)sender;

//first menu
- (IBAction)connectClick:(id)sender;
- (IBAction)update:(id)sender;
- (IBAction)quit:(id)sender;
- (IBAction)changeSBX:(id)sender;
@end

