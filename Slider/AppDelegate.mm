//
//  AppDelegate.m
//  Slider
//
//  Created by Dmitry Volkov on 05.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//



#import "AppDelegate.h"

#import "SongsTableViewController.h"
#import "MessageTableViewController.h"
#import "SelectFilesTableViewController.h"
#import "SelectPathWindowController.h"

#import "CurlHelper.h"
#import "StreamListenerServer.h"
#import "HTMLParser.h"

//#import <tag/fileref.h>
//#import <tag/tstring.h>


AppDelegate* gAppDelegate;

CurlHelper* gCurlHelper = nullptr;

void showMessageBox(const char* title, const char* message)
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:[NSString stringWithFormat:@"%s", title]];
    [alert setInformativeText:[NSString stringWithFormat:@"%s", message]];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}





@interface AppDelegate ()
{
    NSMutableDictionary* partyDictionary;
    CurlHelper curlHelper;
    StreamListenerServer * server;
    
    NSStatusBar* statusBar;
    NSStatusItem* statusItem;
}

@property (weak) IBOutlet NSButton *signInButton;
@property (weak) IBOutlet NSButton *signOutButton;
@property (weak) IBOutlet NSButton *selectDirButton;
@property (weak) IBOutlet NSButton *uploadButton;
@property (weak) IBOutlet NSButton *stickToLeftButton;
@property (weak) IBOutlet NSButton *stickToRightButton;
@property (weak) IBOutlet NSComboBox *partiesComboBox;

@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *loginTextField;
@property (weak) IBOutlet NSSecureTextField *passwordTextField;

@property (weak) IBOutlet NSTextField *tcpPortNumber;

@property (strong) SliderWindowController *sliderWindowController;

@property (strong) SelectPathWindowController* selectPathWindowController;

@property (readwrite) NSThread* messagesThread;


@end


@implementation AppDelegate

@synthesize signInButton;
@synthesize signOutButton;
@synthesize selectDirButton;
@synthesize uploadButton;
@synthesize stickToLeftButton;
@synthesize stickToRightButton;
@synthesize selectPathWindowController;
@synthesize partiesComboBox;
@synthesize currentPartyId;
@synthesize messagesThread;
@synthesize loginTextField;
@synthesize passwordTextField;
@synthesize progressIndicator;

@synthesize tcpPortNumber;

-(void) threadMethod
{
//    NSString* oldMsg;
//    NSString* newMsg;
//   
//    curlHelper.reset();
//    
//    while (![messagesThread isCancelled])
//    {
//        std::string messagesJson = curlHelper.messagesJSON([currentEventId UTF8String]);
//        
//        NSData* jsonData = [NSData dataWithBytes:messagesJson.c_str() length:messagesJson.length()];
//        NSError *error = nil;
//        
//        NSArray *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
//        
//        newMsg = [jsonDictionary lastObject][@"msg"];
//        
//        // It's very primitive way for test new msg, in future it must something checksum
//        if (nil != oldMsg && ![newMsg isEqualToString:oldMsg] && nil != newMsg)
//        {
//            NSLog(@"Message Added");
//            NSUserNotification *notification;
//            notification = [[NSUserNotification alloc] init];
//            notification.title = @"Slider Message";
//            notification.informativeText = newMsg;
//            notification.hasActionButton = YES;
//            notification.soundName = NSUserNotificationDefaultSoundName;
//            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
//            [gMessageTableViewController addNewMessage:newMsg];
//        }
//
//        oldMsg = newMsg;
//
//        std::string requestJSON = curlHelper.requestJSON([currentEventId UTF8String]);
//        [gSongsTableViewController updateSongsList:requestJSON.c_str()];
//        
//        [NSThread sleepForTimeInterval:gTimeOutForEventsWathingThread];
//    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    gAppDelegate = self;
    gCurlHelper = &curlHelper;
    
    [progressIndicator setHidden:YES];
    partiesComboBox.editable = NO;
    partyDictionary = [[NSMutableDictionary alloc] init];
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    [self enableUi:NO];
    
    
    // Init TCP/IP server
    server = StreamListenerServer::serverInstance(9999);
    
    //if (server)
    server->start();

   
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [_sliderWindowController stopSliderThread];
}

- (IBAction)selectDirButtonClicked:(id)sender
{
    selectPathWindowController = [[SelectPathWindowController alloc]
                                  initWithWindowNibName:@"SelectPathWindowController"];
    
    [selectPathWindowController.window makeKeyAndOrderFront:self];
    [self.window orderOut:NULL];
    
    [selectPathWindowController updateExistingSongsCounter];
}

- (IBAction)connectButtonClicked:(id)sender
{
    [progressIndicator setHidden:NO];
    [progressIndicator startAnimation:self];
    
    const char* login = [[loginTextField stringValue] UTF8String];
    const char* pass = [[passwordTextField stringValue] UTF8String];
    
    if (!curlHelper.signIn(login, pass))
    {
        showMessageBox("Unable to login", "Please check your login/password");
        [progressIndicator setHidden:YES];
        [progressIndicator stopAnimation:self];
        return;
    }
    
    [self enableUi:YES];
    
    //--------------------------------------------- Init parties combobox ---------------------------------------------------//
    
    std::string jsonString = curlHelper.partiesJSON();
    NSData* jsonData = [NSData dataWithBytes:jsonString.c_str() length:jsonString.length()];
    NSError *error = nil;
    
    if (!jsonData)
    {
        showMessageBox("JSON parsing error", "Description:Invalid JSON data");
    }
    
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error)
    {
        const char* err = [[error description] UTF8String];
        char msg[1024];
        sprintf(msg, "Description %s", err);
        showMessageBox("JSON parsing error", msg);
    }
    
    for (NSDictionary* dictionaryItem in jsonDictionary)
    {
        NSString* strItem = [NSString stringWithFormat:@"%@ (at %@)",
                             dictionaryItem[@"name"], dictionaryItem[@"location"]];
    
        [partiesComboBox addItemWithObjectValue:strItem];
        [partyDictionary setObject:dictionaryItem[@"id"] forKey:strItem];
        //currentPartyId = dictionaryItem[@"id"];
    }
    
    [partiesComboBox selectItemAtIndex:0];
    currentPartyId = [[ partyDictionary objectForKey:[partiesComboBox objectValueOfSelectedItem] ] stringValue];
    
    //==================================================================================================================//
    
    [progressIndicator setHidden:YES];
    [progressIndicator stopAnimation:self];
}

- (IBAction)uploadButtonClicked:(id)sender
{
    curlHelper.uploadSongs([currentPartyId UTF8String]);
}

- (IBAction)signOut:(id)sender
{
    [messagesThread cancel];
    [self enableUi:NO];
    [partyDictionary removeAllObjects];
    curlHelper.signOut();
}

- (IBAction)sticktoLeftSideButtonPressed:(id)sender
{
    if (!_sliderWindowController)
         _sliderWindowController = [[SliderWindowController alloc] initWithWindowNibName:@"SliderWindow"];
   
    [self stopEventWathingThread];
    [ _sliderWindowController setSide:defLeftSide];
    [_sliderWindowController startSliderThread];
    [self startEventWathingThread];
    [_window orderOut:NULL];
}

- (IBAction)stickToRightSideButtonPressed:(id)sender
{
    if (!_sliderWindowController)
        _sliderWindowController = [[SliderWindowController alloc] initWithWindowNibName:@"SliderWindow"];
    
   // [gTableViewController reloadJSONFile: [_jsonLocalFile stringValue]];
    [self stopEventWathingThread];
    [ _sliderWindowController setSide:defRightSide];
    [_sliderWindowController startSliderThread];
    [self startEventWathingThread];
    [_window orderOut:NULL];
    
}
- (IBAction)partyComboxChanged:(id)sender
{
    currentPartyId = [[ partyDictionary objectForKey:[sender objectValueOfSelectedItem] ] stringValue];
}


- (IBAction)exitButtonPressed:(id)sender
{
    server->stop();
   // delete server;
    [[NSApplication sharedApplication] terminate:nil];
    //exit(0);
}

-(void) closeSlider
{
    [self stopEventWathingThread];
    [self.window orderFrontRegardless];
}

-(void) showNotification:(NSString*) msg
{
    NSUserNotification *notification;
    notification = [[NSUserNotification alloc] init];
    notification.title = @"Server notification";
    notification.informativeText = msg;
    notification.hasActionButton = NO;
    notification.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

-(void) susuccessfullyConnectedClient
{
    // Add you code here
    NSLog(@"susuccessfullyConnectedClientCallback");
}

-(void) connectionHasBeenLost
{
    // Add you code here
    NSLog(@"connectionHasBeenLostCallback");
}


-(void) enableUi:(BOOL)flag
{
    if (flag)
    {
        selectDirButton.enabled = YES;
        //uploadButton.enabled = YES;
        stickToLeftButton.enabled = YES;
        stickToRightButton.enabled = YES;
        partiesComboBox.enabled = YES;
        signInButton.enabled = NO;
        signOutButton.enabled = YES;
        //signOutButton.enabled = NO;
    }
    else
    {
        [partiesComboBox removeAllItems ];
        selectDirButton.enabled = NO;
        //uploadButton.enabled = NO;
        stickToLeftButton.enabled = NO;
        stickToRightButton.enabled = NO;
        partiesComboBox.enabled = NO;
        signOutButton.enabled = NO;
        signInButton.enabled = YES;
        //signOutButton.enabled = YES;
    }
}

-(void) startEventWathingThread
{
    messagesThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMethod) object:nil];
    [messagesThread start];
}

-(void) stopEventWathingThread
{
    [messagesThread cancel];
}

@end
