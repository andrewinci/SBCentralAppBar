//
//  AppDelegate.m
//  SBCentral
//
//  Created by Darka on 04/11/14.
//  Copyright (c) 2014 Darka. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

@synthesize SBXmenuElement;
@synthesize musicMenuElement;
@synthesize movieMenuElement;
@synthesize gameMenuElement;



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //execute on a bar
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    NSImage *image=[NSImage imageNamed:@"evoMini"];
    [image setTemplate:YES];
    [statusItem setImage:image];
    [statusItem setHighlightMode:YES];
    //bt part
    RFCommComunication *temp=[[RFCommComunication alloc] init];
    [self setRfCommComunication:temp];
    self.rfCommComunication.delegate=self;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)connectClick:(id)sender {
    [[self rfCommComunication] openConnection];
    [self update:self];
    //run the auto update
    [NSTimer scheduledTimerWithTimeInterval:600.0
                                     target:self
                                   selector:@selector(send:)
                                   userInfo:nil
                                    repeats:YES];
}

- (IBAction)quit:(id)sender {
    [NSApp terminate:self];
}

- (IBAction)changeSBX:(id)sender {
    if([SBXmenuElement state]==1)
       [self send:@"5A2603000100"];
    else
        [self send:@"5A2603000101"];
}

- (IBAction)update:(id)sender {

    //update battery status
    [[self rfCommComunication] send:@"5A270101"];
    //update SBX status
    [[self rfCommComunication] send:@"5A260101"];
    //update SBX profile
    //[[self rfCommComunication] send:@"5A030101"];
}

#pragma mark EnterNumbe Delegate function
-(void)receivedMessage:(NSString *)message
{
    NSLog(message);
    unsigned result = 0;
    NSMutableArray *byteMessage=[[NSMutableArray alloc]init];
    //split the message in the array byte
    for(int i=0; i<=[message length]-2;i+=3){
        [byteMessage addObject:[[message substringFromIndex:i] substringToIndex:2]];[[message substringFromIndex:i] substringToIndex:2];
    }
    
    //check battery status
    if([[byteMessage objectAtIndex:1] isEqual:@"27"] && [[byteMessage objectAtIndex:2] isEqual:@"02"])
    {
    message=[message substringFromIndex:([message length]-3)];
    NSScanner *scanner = [NSScanner scannerWithString:message];
    //[scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&result];
    
    /////update the view
    NSFont *font = [NSFont fontWithName:@"LucidaGrande" size:12.0];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d %%",result] attributes:attrsDictionary];
    
    [statusItem setHighlightMode:YES];
    [statusItem setAttributedTitle:attrString];
    [statusItem setMenu:statusMenu];
    }
    else if ([[byteMessage objectAtIndex:1] isEqual:@"26"] && [[byteMessage objectAtIndex:2] isEqual:@"05"])
    {
        if([[byteMessage objectAtIndex:4] isEqual:@"01"])
            [SBXmenuElement setState:1];
        else [SBXmenuElement setState:0];
    }
    /*else if ([[byteMessage objectAtIndex:1] isEqual:@"1A"] && [[byteMessage objectAtIndex:2] isEqual:@"02"])
    {
        if([[byteMessage objectAtIndex:4] isEqual:@"00"])
        {
            [musicMenuElement setState:1];
            [movieMenuElement setState:0];
            [gameMenuElement setState:0];
        }
        else if([[byteMessage objectAtIndex:4] isEqual:@"01"])
        {
            [musicMenuElement setState:0];
            [movieMenuElement setState:1];
            [gameMenuElement setState:0];
        }
        else
        {
            [musicMenuElement setState:0];
            [movieMenuElement setState:0];
            [gameMenuElement setState:1];
        }
    }*/
}
-(void)send:(NSString*)message{
    [[self rfCommComunication] send:message];
    [self update:self];
}
- (IBAction)seMusicProfile:(id)sender {
    [self send:@"5A1A03000000"];
}

- (IBAction)setMovieProfile:(id)sender {
    [self send:@"5A1A03000001"];
    
}

- (IBAction)setGameProfile:(id)sender {
    [self send:@"5A1A03000002"];
    
}
@end
