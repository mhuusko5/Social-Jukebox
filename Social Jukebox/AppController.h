#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import "iTunes.h"
#import "NSImage+Additions.h"
#import "FlipTransitionController.h"
#import "WindowViewManager.h"
#import "AttachedPopupWindow.h"
#import "ScrollingTextView.h"
#import "xAuthTwitterEngine.h"
#import "PhFacebook.h"
#import "SNRLastFMEngine.h"
#import "NSString+contains.h"
#import "JSONKit.h"

@interface AppController : NSObject {
@private
    
	IBOutlet NSArrayController *songQueueController;
	NSMutableArray *songQueue;
    
	NSMutableArray *searchResults;
    
	NSImage *noArtwork, *repeatOne, *repeat, *noRepeat, *blackBar, *facebookpic;
    
	xAuthTwitterEngine *twitterEngine;
	BOOL twitterLoggedIn;
    
	PhFacebook *facebookEngine;
	BOOL facebookLoggedIn;
    
	SNRLastFMEngine *lastFmEngine;
	BOOL lastFmLoggedIn;
    
	iTunesApplication *iTunes;
	iTunesPlaylist *musicLibrary;
	NSDistributedNotificationCenter *iTunesNotificationManager;
    
	NSTimer *statsUpdateTimer;
    
	WindowViewManager *windowViewManager;
    
	IBOutlet NSPanel *mainWindow;
	IBOutlet NSView *mainView;
	IBOutlet NSView *mainTransitionView; IBOutlet FlipTransitionController *mainTransitionController;
	IBOutlet NSView *currentView;
	IBOutlet NSView *currentHeaderView;
	IBOutlet ScrollingTextView *currentNameView, *currentArtistView;
	IBOutlet NSImageView *currentArtworkView;
	IBOutlet NSView *nextView;
	IBOutlet NSView *nextHeaderView;
	IBOutlet ScrollingTextView *nextNameView, *nextArtistView;
	IBOutlet NSImageView *nextArtworkView;
    
	IBOutlet AttachedPopupWindow *queueWindow;
	IBOutlet NSView *queueParentView;
	IBOutlet NSView *queueView;
	IBOutlet NSTableView *queueTableView;
	IBOutlet NSView *searchView;
	IBOutlet NSTableView *searchTableView;
    
	IBOutlet AttachedPopupWindow *controlsWindow;
	IBOutlet NSView *controlsParentView;
	IBOutlet NSView *controlsView;
	IBOutlet NSButton *star1, *star2, *star3, *star4, *star5;
	IBOutlet NSButton *playPauseButton, *shuffleButton, *repeatButton;
	IBOutlet NSSlider *volumeSlider;
	IBOutlet NSSlider *songTimeline;
	IBOutlet NSView *socialView;
	IBOutlet NSTabView *socialTabView;
	IBOutlet NSTextField *twitterUsernameField, *twitterPasswordField;
	IBOutlet NSButton *twitterLoginButton, *twitterActivateButton;
	IBOutlet NSTextField *lastFmUsernameField, *lastFmPasswordField;
	IBOutlet NSButton *lastFmLoginButton, *lastFmActivateButton;
	IBOutlet NSImageView *facebookPictureView;
	IBOutlet NSButton *facebookLoginButton, *facebookActivateButton;
	IBOutlet NSTextField *facebookUsernameLabel;
    
	IBOutlet NSButton *leftAnchorButton;
	BOOL showsReflection;
	int childWindowShift;
    
	IBOutlet NSPanel *songsAddedPopupWindow, *songInfoPostedPopupWindow, *playlistAddedPopupWindow, *playlistCopiedPopupWindow;
    
	NSStatusItem *statusBarItem;
	ScrollingTextView *menuBarScrollView;
	IBOutlet NSMenu *statusBarMenu;
	IBOutlet NSMenuItem *statusBarModeButton;
	NSString *displayInStatusBar;
}

@property BOOL twitterLoggedIn;
@property BOOL facebookLoggedIn;
@property BOOL lastFmLoggedIn;

- (id)init;
- (void)awakeFromNib;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData);

- (void)setupStatsUpdateTimer;
- (void)updateStats;
- (void)updateNextSongInfo;
- (void)updateStatusBarStats;
- (void)updateCurrentSongInfo;
- (void)updateBars;
- (void)updateControlsStates;
- (void)playerStateChange:(NSNotification *)notification;

- (IBAction)addToBackFromSelection:(id)outlet;
- (IBAction)addToFrontFromSelection:(id)outlet;
- (IBAction)addToBackFromSearch:(id)outlet;
- (IBAction)generateSearchResults:(id)outlet;
- (IBAction)shuffleQueue:(id)outlet;
- (IBAction)clearQueue:(id)outlet;
- (IBAction)playSelectedSong:(id)outlet;
- (IBAction)playNextInQueue:(id)outlet;
- (IBAction)removeSelectedSong:(id)outlet;
- (void)exportArrayAsPlaylist;
- (IBAction)exportQueueAsPlaylist:(id)outlet;
- (void)copyArrayAsPlaylist;
- (IBAction)copyQueueAsPlaylist:(id)outlet;
- (IBAction)setStatusItemMode:(id)outlet;

- (IBAction)toggleReflection:(id)outlet;
- (IBAction)toggleHeaderViews:(id)outlet;
- (IBAction)flipViews:(id)outlet;
- (IBAction)toggleSearchView:(id)outlet;
- (IBAction)toggleSocialView:(id)outlet;
- (IBAction)toggleControlsWindow:(id)outlet;
- (IBAction)toggleQueueWindow:(id)outlet;
- (void)showPlaylistCopiedNotification;
- (void)showPlaylistAddedNotification;
- (void)showSongsAddedNotification;
- (void)showSongInfoPostedNotification;
- (IBAction)closeAndQuit:(id)outlet;

- (IBAction)playerBack:(id)outlet;
- (IBAction)playerForward:(id)outlet;
- (IBAction)playerPlayPause:(id)outlet;
- (IBAction)adjustPlayerVolume:(id)outlet;
- (IBAction)maxPlayerVolume:(id)outlet;
- (IBAction)minPlayerVolume:(id)outlet;
- (IBAction)togglePlayerRepeat:(id)outlet;
- (IBAction)togglePlayerShuffle:(id)outlet;
- (IBAction)setPlayerPosition:(id)outlet;
- (IBAction)setSongRating:(id)outlet;

- (NSString *)getTinyUrlForName:(NSString *)trackname andArtist:(NSString *)trackartist;
- (NSString *)getItunesUrlForName:(NSString *)trackname andArtist:(NSString *)trackartist;

- (IBAction)bringToSignIn:(id)outlet;
- (IBAction)showLastFmView:(id)outlet;
- (IBAction)lastFmSignIn:(id)outlet;
- (IBAction)lastFmSignOut:(id)outlet;

- (IBAction)showFacebookView:(id)outlet;
- (IBAction)facebookSignIn:(id)outlet;
- (IBAction)facebookSignOut:(id)outlet;
- (void)tokenResult:(NSDictionary *)result;
- (IBAction)postToFacebook:(id)outlet;
- (void)requestResult:(NSDictionary *)result;

- (IBAction)showTwitterView:(id)outlet;
- (IBAction)twitterSignIn:(id)outlet;
- (IBAction)twitterSignOut:(id)outlet;
- (IBAction)twitterPostSong:(id)outlet;
- (void)twitterEngineReceivedAccessToken:(id)sender;
- (void)twitterEngineNotReceivedAccessToken;

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard;
- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo> )info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op;
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo> )info row:(int)to dropOperation:(NSTableViewDropOperation)operation;
- (void)applicationDidBecomeActive:(NSNotification *)aNotification;
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag;
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
@end
