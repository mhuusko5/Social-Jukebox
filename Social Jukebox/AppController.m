#import "AppController.h"

@implementation AppController

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@synthesize twitterLoggedIn;
@synthesize facebookLoggedIn;
@synthesize lastFmLoggedIn;

- (id)init {
	NSAppleScript *checkUniversalAccess = [[NSAppleScript alloc] initWithSource:@"tell application \"System Events\"\n if UI elements enabled is false then\n tell me\n activate\n display dialog \"To use Social Jukebox's keyboard shortcuts/hotkeys, Unvisersal Access settings must be enabled in System Preferences; you will be asked to authorize this change now.\"\n end tell\n set UI elements enabled to true\n end if\n end tell"];
	[checkUniversalAccess executeAndReturnError:nil];
    
	self = [super init];
	songQueue = [[NSMutableArray alloc] init];
	searchResults = [[NSMutableArray alloc] init];
	facebookEngine = [[PhFacebook alloc] initWithApplicationID:@"YOURAPPLICATIONID" delegate:self];
	twitterEngine = [xAuthTwitterEngine oAuthTwitterEngineWithDelegate:self];
	windowViewManager = [[WindowViewManager alloc] init];
    
	showsReflection = YES;
	childWindowShift = 0;
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeAndQuit:) name:NSApplicationWillTerminateNotification object:[NSApplication sharedApplication]];
    
	noArtwork = [NSImage imageWithReflection:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"none" ofType:@"png"]] amountReflected:.308];
	repeatOne = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"repeatone" ofType:@"png"]];
	noRepeat = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"norepeat" ofType:@"png"]];
	repeat = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"repeat" ofType:@"png"]];
	blackBar = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"blackBar" ofType:@"png"]];
	facebookpic = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fbnologged" ofType:@"png"]];
    
	if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.iTunes"] count] > 0) {
		iTunes = [SBApplication applicationWithProcessIdentifier:[[[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.iTunes"] objectAtIndex:0] processIdentifier]];
	}
	else {
		[[NSWorkspace sharedWorkspace] launchApplication:@"iTunes"];
		iTunes = [SBApplication applicationWithProcessIdentifier:[[[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.iTunes"] objectAtIndex:0] processIdentifier]];
	}
    
	SBElementArray *sources = [iTunes sources];
	iTunesSource *libsource = nil;
	for (int i = 0; i < [sources count]; i++) {
		if ([(iTunesSource *)[sources objectAtIndex:i] kind] == iTunesESrcLibrary) {
			libsource = [sources objectAtIndex:i];
			break;
		}
	}
	musicLibrary = [[libsource playlists] objectWithName:@"Music"];
    
	return self;
}

- (void)awakeFromNib {
	[self updateNextSongInfo];
	[self updateCurrentSongInfo];
    
	[mainWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[songsAddedPopupWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[playlistAddedPopupWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[songInfoPostedPopupWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    
	mainTransitionController = [[FlipTransitionController alloc] initWithHostView:mainTransitionView frontView:nextView backView:currentView];
	[mainTransitionView addTrackingArea:[[NSTrackingArea alloc] initWithRect:[mainTransitionView bounds] options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil]];
    
	controlsWindow = [[AttachedPopupWindow alloc] initWithView:controlsParentView attachedToPoint:NSMakePoint(0, 0) inWindow:mainWindow onSide:2 atDistance:24];
	queueWindow = [[AttachedPopupWindow alloc] initWithView:queueParentView attachedToPoint:NSMakePoint(0, 0) inWindow:mainWindow onSide:2 atDistance:24];
	[queueParentView addSubview:queueView];
	[queueParentView addTrackingArea:[[NSTrackingArea alloc] initWithRect:[queueParentView bounds] options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil]];
	[controlsParentView addSubview:controlsView];
	[controlsParentView addTrackingArea:[[NSTrackingArea alloc] initWithRect:[controlsParentView bounds] options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil]];
    
	[queueTableView registerForDraggedTypes:[NSArray arrayWithObject:@"NSMutableDictionary"]];
	[queueTableView setDoubleAction:@selector(playSelectedSong:)];
	[queueTableView setTarget:self];
    
	[searchTableView setDoubleAction:@selector(addToBackFromSearch:)];
	[searchTableView setTarget:self];
    
	statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	menuBarScrollView = [[ScrollingTextView alloc] initWithFrame:NSRectFromCGRect(CGRectMake(0, 1, 182, [[NSStatusBar systemStatusBar] thickness]))];
	[menuBarScrollView setFontcolor:[NSColor colorWithDeviceRed:0.112f green:0.112f blue:0.112f alpha:0.95f]];
	[menuBarScrollView setYoffset:3];
	[statusBarItem setView:menuBarScrollView];
	[menuBarScrollView setStatusitem:statusBarItem];
	[statusBarItem setMenu:statusBarMenu];
    
	if ([[NSUserDefaults standardUserDefaults] valueForKey:@"socialJukeboxTwitterUsername"] && [[NSUserDefaults standardUserDefaults] valueForKey:@"socialJukeboxTwitterPassword"]) {
		[twitterUsernameField setStringValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"socialJukeboxTwitterUsername"]];
		[twitterPasswordField setStringValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"socialJukeboxTwitterPassword"]];
	}
    
	if ([[NSUserDefaults standardUserDefaults] valueForKey:@"socialJukeboxLastFmUsername"] && [[NSUserDefaults standardUserDefaults] valueForKey:@"socialJukeboxLastFmPassword"]) {
		[lastFmUsernameField setStringValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"socialJukeboxLastFmUsername"]];
		[lastFmPasswordField setStringValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"socialJukeboxLastFmPassword"]];
	}
    
	if ([[NSUserDefaults standardUserDefaults] valueForKey:@"displayInStatusBar"]) {
		displayInStatusBar = [[NSUserDefaults standardUserDefaults] valueForKey:@"displayInStatusBar"];
	}
	else {
		displayInStatusBar = @"Current";
	}
	if ([displayInStatusBar isEqualToString:@"Next"]) {
		[statusBarModeButton setTitle:@"Show Current Song Info"];
	}
	else {
		[statusBarModeButton setTitle:@"Show Next Song Info"];
	}
    
	[self updateNextSongInfo];
	[self updateCurrentSongInfo];
    
	[self flipViews:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	iTunesNotificationManager = [NSDistributedNotificationCenter defaultCenter];
	[iTunesNotificationManager addObserver:self selector:@selector(playerStateChange:) name:@"com.apple.iTunes.playerInfo" object:nil];
	[NSThread detachNewThreadSelector:@selector(setupStatsUpdateTimer) toTarget:self withObject:nil];
	[NSTimer scheduledTimerWithTimeInterval:1.2 target:self selector:@selector(updateBars) userInfo:nil repeats:YES];
    
	EventHotKeyRef gMyHotKeyRef;
	EventHotKeyID gMyHotKeyID;
	EventTypeSpec eventType;
	eventType.eventClass = kEventClassKeyboard;
	eventType.eventKind = kEventHotKeyPressed;
	InstallApplicationEventHandler(&MyHotKeyHandler, 1, &eventType, self, NULL);
	gMyHotKeyID.signature = 'htk1';
	gMyHotKeyID.id = 1;
	RegisterEventHotKey(kVK_ANSI_B, cmdKey + optionKey, gMyHotKeyID, GetApplicationEventTarget(), 0, &gMyHotKeyRef);
	gMyHotKeyID.signature = 'htk2';
	gMyHotKeyID.id = 2;
	RegisterEventHotKey(kVK_ANSI_F, cmdKey + optionKey, gMyHotKeyID, GetApplicationEventTarget(), 0, &gMyHotKeyRef);
	gMyHotKeyID.signature = 'htk4';
	gMyHotKeyID.id = 4;
	RegisterEventHotKey(kVK_ANSI_N, cmdKey + optionKey, gMyHotKeyID, GetApplicationEventTarget(), 0, &gMyHotKeyRef);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
	EventHotKeyID hkCom;
	GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hkCom), NULL, &hkCom);
	int switcher = hkCom.id;
    
	switch (switcher) {
		case 1:[(id)userData addToBackFromSelection : nil];
			break;
            
		case 2:[(id)userData addToFrontFromSelection : nil];
			break;
            
		case 4:[(id)userData playNextInQueue : nil];
			break;
	}
    
	return noErr;
}

- (void)setupStatsUpdateTimer {
	statsUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:.7 target:self selector:@selector(updateStats) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:statsUpdateTimer forMode:NSEventTrackingRunLoopMode];
	[[NSRunLoop currentRunLoop] run];
}

- (void)updateStats {
	@try {
		NSArray *processes = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.iTunes"];
		if ([processes count] > 0) {
			iTunes = [SBApplication applicationWithProcessIdentifier:[[processes objectAtIndex:0] processIdentifier]];
			if ([iTunes playerState] == iTunesEPlSPlaying && [musicLibrary songRepeat] != iTunesERptOne && [musicLibrary songRepeat] != iTunesERptAll && [musicLibrary shuffle] != YES && [[iTunes currentTrack] duration] - [iTunes playerPosition] <= 2.1) {
				[self playNextInQueue:nil];
			}
			[self updateControlsStates];
		}
		else {
			[NSApp terminate:self];
		}
	}
	@catch (NSException *e)
	{
		[NSThread sleepForTimeInterval:0.1];
	}
}

- (void)updateNextSongInfo {
	if ([songQueue count] < 1) {
		[nextNameView setString:@"Add a song"];
		[nextArtistView setString:@"Add a song"];
		[nextArtworkView setImage:noArtwork];
	}
	else {
		iTunesTrack *track = [songQueue objectAtIndex:0];
		[nextNameView setString:[track name]];
		[nextArtistView setString:[track artist]];
        
		NSImage *artwork = [[NSImage alloc] initWithData:[(iTunesArtwork *)[[[track artworks] get] lastObject] rawData]];
		if (artwork != nil) {
			[nextArtworkView setImage:[NSImage imageWithReflection:artwork amountReflected:.308]];
		}
		else {
			[nextArtworkView setImage:noArtwork];
		}
	}
	[self updateStatusBarStats];
}

- (void)updateStatusBarStats {
	if ([displayInStatusBar isEqualToString:@"Next"]) {
		if ([songQueue count] > 0) {
			NSMutableString *songInfo = [[NSMutableString alloc] init];
			[songInfo appendString:@"Next In Queue: "];
			[songInfo appendString:[[songQueue objectAtIndex:0] name]];
			[songInfo appendString:@" by "];
			[songInfo appendString:[[songQueue objectAtIndex:0] artist]];
			[menuBarScrollView setString:songInfo];
		}
		else {
			[menuBarScrollView setString:@"Next In Queue: Add a song"];
		}
	}
	else {
		if ([iTunes playerState] == iTunesEPlSStopped) {
			[menuBarScrollView setString:@"Now Playing: Music Stopped"];
		}
		else {
			iTunesTrack *track = [iTunes currentTrack];
			NSMutableString *songInfo = [[NSMutableString alloc] init];
			[songInfo appendString:@"Now Playing: "];
			[songInfo appendString:[track name]];
			[songInfo appendString:@" by "];
			[songInfo appendString:[track artist]];
			[menuBarScrollView setString:songInfo];
		}
	}
}

- (void)updateCurrentSongInfo {
	if ([iTunes playerState] == iTunesEPlSStopped) {
		[currentNameView setString:@"Music Stopped"];
		[currentArtistView setString:@"Music Stopped"];
		[currentArtworkView setImage:noArtwork];
	}
	else {
		iTunesTrack *track = [iTunes currentTrack];
		[currentNameView setString:[track name]];
		[currentArtistView setString:[track artist]];
        
		NSImage *artwork = [[NSImage alloc] initWithData:[(iTunesArtwork *)[[[track artworks] get] lastObject] rawData]];
		if (artwork != nil) {
			[currentArtworkView setImage:[NSImage imageWithReflection:artwork amountReflected:.308]];
		}
		else {
			[currentArtworkView setImage:noArtwork];
		}
	}
	[self updateStatusBarStats];
}

- (void)updateBars {
	[volumeSlider setIntegerValue:[iTunes soundVolume]];
    
	if ([iTunes playerState] == iTunesEPlSStopped) {
		[songTimeline setDoubleValue:0.0];
	}
	else {
		[songTimeline setDoubleValue:[iTunes playerPosition] / [[iTunes currentTrack] duration] * 100];
	}
}

- (void)updateControlsStates {
	int rating = (int)[[iTunes currentTrack] rating] / 20;
	switch (rating) {
		case 0:
			[star1 setState:1];
			[star2 setState:1];
			[star3 setState:1];
			[star4 setState:1];
			[star5 setState:1];
			break;
            
		case 1:
			[star1 setState:0];
			[star2 setState:1];
			[star3 setState:1];
			[star4 setState:1];
			[star5 setState:1];
			break;
            
		case 2:
			[star1 setState:0];
			[star2 setState:0];
			[star3 setState:1];
			[star4 setState:1];
			[star5 setState:1];
			break;
            
		case 3:
			[star1 setState:0];
			[star2 setState:0];
			[star3 setState:0];
			[star4 setState:1];
			[star5 setState:1];
			break;
            
		case 4:
			[star1 setState:0];
			[star2 setState:0];
			[star3 setState:0];
			[star4 setState:0];
			[star5 setState:1];
			break;
            
		case 5:
			[star1 setState:0];
			[star2 setState:0];
			[star3 setState:0];
			[star4 setState:0];
			[star5 setState:0];
			break;
	}
    
	if ([iTunes playerState] == iTunesEPlSPlaying) {
		[playPauseButton setState:1];
	}
	else {
		[playPauseButton setState:0];
	}
    
	if ([musicLibrary shuffle] == TRUE) {
		[shuffleButton setState:1];
	}
	else {
		[shuffleButton setState:0];
	}
    
	switch ([musicLibrary songRepeat]) {
		case iTunesERptOff:
			[repeatButton setImage:noRepeat];
			break;
            
		case iTunesERptAll:
			[repeatButton setImage:repeat];
			break;
            
		case iTunesERptOne:
			[repeatButton setImage:repeatOne];
			break;
	}
}

- (void)playerStateChange:(NSNotification *)notification {
	[self updateCurrentSongInfo];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction)addToBackFromSelection:(id)outlet {
	NSString *className = NSStringFromClass([[[[iTunes selection] get] objectAtIndex:0] class]);
	if ([className isEqualToString:@"ITunesTrack"] || [className isEqualToString:@"ITunesSharedTrack"] || [className isEqualToString:@"ITunesFileTrack"] || [className isEqualToString:@"ITunesDeviceTrack"] || [className isEqualToString:@"ITunesAudioCDTrack"]) {
		NSArray *tracks = [[NSArray alloc] initWithArray:[[iTunes selection] get]];
        
		int k = (int)[tracks count];
		for (int i = 0; i < k; i++) {
			[songQueueController insertObject:[tracks objectAtIndex:i] atArrangedObjectIndex:[songQueue count]];
		}
        
		[self updateNextSongInfo];
        
		[self showSongsAddedNotification];
	}
}

- (IBAction)addToFrontFromSelection:(id)outlet {
	NSString *className = NSStringFromClass([[[[iTunes selection] get] objectAtIndex:0] class]);
	if ([className isEqualToString:@"ITunesTrack"] || [className isEqualToString:@"ITunesSharedTrack"] || [className isEqualToString:@"ITunesFileTrack"] || [className isEqualToString:@"ITunesDeviceTrack"] || [className isEqualToString:@"ITunesAudioCDTrack"]) {
		NSArray *tracks = [[NSArray alloc] initWithArray:[[iTunes selection] get]];
        
		int k = (int)[tracks count];
		for (int i = 0; i < k; i++) {
			[songQueueController insertObject:[tracks objectAtIndex:i] atArrangedObjectIndex:0];
		}
        
		[self updateNextSongInfo];
        
		[self showSongsAddedNotification];
	}
}

- (IBAction)addToBackFromSearch:(id)outlet {
	int row = (int)[searchTableView selectedRow];
	if (row >= 0) {
		[songQueueController insertObject:[searchResults objectAtIndex:row] atArrangedObjectIndex:[songQueue count]];
        
		[self updateNextSongInfo];
        
		[self showSongsAddedNotification];
	}
}

- (IBAction)generateSearchResults:(id)outlet {
	[self willChangeValueForKey:@"searchResults"];
	id results = [musicLibrary searchFor:[outlet stringValue] only:iTunesESrAAll];
	NSString *className = NSStringFromClass([results class]);
	if ([className isEqualToString:@"ITunesTrack"]) {
		[searchResults insertObject:results atIndex:0];
	}
	else {
		searchResults = results;
	}
	[self didChangeValueForKey:@"searchResults"];
	[searchTableView reloadData];
}

- (IBAction)shuffleQueue:(id)outlet {
	int count = (int)[songQueue count];
	if (count > 0) {
		static BOOL seeded = NO;
		if (!seeded) {
			seeded = YES;
			srandom((int)time(NULL));
		}
        
		[self willChangeValueForKey:@"songQueue"];
        
		for (int i = 0; i < count; ++i) {
			[songQueue exchangeObjectAtIndex:i withObjectAtIndex:(int)((random() % (count - i)) + i)];
		}
        
		[self didChangeValueForKey:@"songQueue"];
		[queueTableView reloadData];
        
		[self updateNextSongInfo];
	}
}

- (IBAction)clearQueue:(id)outlet {
	int count = ((int)[songQueue count]);
	if (count > 0) {
		for (int i = 0; i < count; i++) {
			[songQueueController removeObjectAtArrangedObjectIndex:0];
		}
		[self updateNextSongInfo];
	}
}

- (IBAction)playSelectedSong:(id)outlet {
	if ([queueTableView selectedRow] >= 0) {
		if ([iTunes playerState] != iTunesEPlSPlaying) {
			[iTunes playpause];
		}
        
		[[songQueue objectAtIndex:[queueTableView selectedRow]] playOnce:FALSE];
		[songQueueController removeObjectAtArrangedObjectIndex:[queueTableView selectedRow]];
        
		[self updateNextSongInfo];
	}
}

- (IBAction)playNextInQueue:(id)outlet {
	if ([iTunes playerState] != iTunesEPlSPlaying) {
		[iTunes playpause];
	}
    
	if ([songQueue count] > 0) {
		[[songQueue objectAtIndex:0] playOnce:FALSE];
        
		[songQueueController removeObjectAtArrangedObjectIndex:0];
        
		[self updateNextSongInfo];
	}
}

- (IBAction)removeSelectedSong:(id)outlet {
	if ([queueTableView selectedRow] >= 0) {
		[songQueueController removeObjectAtArrangedObjectIndex:[queueTableView selectedRow]];
	}
    
	[self updateNextSongInfo];
}

- (void)copyArrayAsPlaylist {
	NSMutableString *playlist = [[NSMutableString alloc] init];
    
	for (int k = 0; k < [songQueue count]; k++) {
		NSString *name = [[songQueue objectAtIndex:k] name];
		NSString *artist = [[songQueue objectAtIndex:k] artist];
		[playlist appendFormat:@"Song: %@ by %@", name, artist];
		NSString *tinyurl = [self getTinyUrlForName:name andArtist:artist];
		if (tinyurl) {
			[playlist appendFormat:@"\nListen: %@", tinyurl];
		}
		NSString *itunesurl = [self getItunesUrlForName:name andArtist:artist];
		if (itunesurl) {
			[playlist appendFormat:@"\nBuy: %@", itunesurl];
		}
		[playlist appendString:@"\n\n"];
	}
	[playlist appendString:@"Playlist shared via Social Jukebox"];
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
	[pasteBoard setString:playlist forType:NSStringPboardType];
	[self showPlaylistCopiedNotification];
}

- (IBAction)copyQueueAsPlaylist:(id)outlet {
	if ([songQueue count] > 0) {
		[NSThread detachNewThreadSelector:@selector(copyArrayAsPlaylist) toTarget:self withObject:nil];
	}
}

- (void)exportArrayAsPlaylist {
	SBElementArray *sources = [iTunes sources];
	iTunesSource *libsource = nil;
	iTunesPlaylist *newpl;
	NSMutableString *playlistname = [[NSMutableString alloc] initWithFormat:@"Social Jukebox Queue starting with "];
	[playlistname appendString:[[songQueue objectAtIndex:0] name]];
	[playlistname appendString:@" by "];
	[playlistname appendString:[[songQueue objectAtIndex:0] artist]];
    
	for (int i = 0; i < [sources count]; i++) {
		if ([(iTunesSource *)[sources objectAtIndex:i] kind] == iTunesESrcLibrary) {
			libsource = [sources objectAtIndex:i];
		}
	}
    
	int found = 0;
	for (int i = 0; i < [[libsource userPlaylists] count]; i++) {
		if ([[[[libsource userPlaylists] objectAtIndex:i] name] isEqualToString:playlistname]) {
			found++;
			if (found == 1) {
				[playlistname appendFormat:[NSString stringWithFormat:@" %d", found + 1]];
			}
			else if (found < 10) {
				[playlistname replaceCharactersInRange:NSMakeRange([playlistname length] - 2, 2) withString:[NSString stringWithFormat:@" %d", found + 1]];
			}
			else if (found < 100) {
				[playlistname replaceCharactersInRange:NSMakeRange([playlistname length] - 3, 3) withString:[NSString stringWithFormat:@" %d", found + 1]];
			}
			else if (found < 1000) {
				[playlistname replaceCharactersInRange:NSMakeRange([playlistname length] - 4, 4) withString:[NSString stringWithFormat:@" %d", found + 1]];
			}
		}
	}
    
	newpl = [[[iTunes classForScriptingClass:@"playlist"] alloc] initWithProperties:[NSDictionary dictionaryWithObject:playlistname forKey:@"name"]];
    
	[[libsource userPlaylists] insertObject:newpl atIndex:0];
    
	for (int k = 0; k < [songQueue count]; k++) {
		[iTunes add:[NSArray arrayWithObject:[(iTunesFileTrack *)[songQueue objectAtIndex:k] location]] to:[[libsource userPlaylists] objectWithName:playlistname]];
	}
    
	[self showPlaylistAddedNotification];
}

- (IBAction)exportQueueAsPlaylist:(id)outlet {
	if ([songQueue count] > 0) {
		[NSThread detachNewThreadSelector:@selector(exportArrayAsPlaylist) toTarget:self withObject:nil];
	}
}

- (IBAction)setStatusItemMode:(id)outlet {
	if ([displayInStatusBar isEqualToString:@"Current"]) {
		displayInStatusBar = @"Next";
		[[NSUserDefaults standardUserDefaults] setValue:@"Next" forKey:@"displayInStatusBar"];
		[statusBarModeButton setTitle:@"Show Current Song Info"];
	}
	else {
		displayInStatusBar = @"Current";
		[[NSUserDefaults standardUserDefaults] setValue:@"Current" forKey:@"displayInStatusBar"];
		[statusBarModeButton setTitle:@"Show Next Song Info"];
	}
    
	[self updateStatusBarStats];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction)toggleReflection:(id)outlet {
	NSRect frame = [mainWindow frame];
	if (showsReflection == YES) {
		frame.origin.y += 56;
		frame.size.height -= 56;
		showsReflection = NO;
		childWindowShift = 56;
	}
	else {
		frame.origin.y -= 56;
		frame.size.height += 56;
		showsReflection = YES;
		childWindowShift = 0;
	}
	[mainWindow setFrame:frame display:YES animate:YES];
}

- (IBAction)toggleHeaderViews:(id)outlet {
	NSRect frame = [mainWindow frame];
	NSRect viewFrame = [mainTransitionView frame];
	if ([currentHeaderView alphaValue] > 0.5 && [nextHeaderView alphaValue] > 0.5) {
		[windowViewManager fadeOutViewInNewThread:currentHeaderView];
		[windowViewManager fadeOutViewInNewThread:nextHeaderView];
		[NSThread sleepForTimeInterval:0.5];
		viewFrame.origin.y += 49;
		[mainTransitionView setFrame:viewFrame];
		frame.size.height -= 49;
		[mainWindow setFrame:frame display:YES animate:NO];
	}
	else {
		viewFrame.origin.y -= 49;
		[mainTransitionView setFrame:viewFrame];
		[windowViewManager fadeInView:currentHeaderView];
		[windowViewManager fadeInView:nextHeaderView];
		frame.size.height += 49;
		[mainWindow setFrame:frame display:YES animate:NO];
	}
}

- (IBAction)flipViews:(id)outlet {
	[mainTransitionController flip:self];
}

- (IBAction)toggleSearchView:(id)outlet {
	[windowViewManager slideBetweenSubview:queueView andSubview:searchView ofSuperview:queueParentView];
}

- (IBAction)toggleSocialView:(id)outlet {
	[windowViewManager slideBetweenSubview:controlsView andSubview:socialView ofSuperview:controlsParentView];
}

- (IBAction)toggleControlsWindow:(id)outlet {
	[controlsWindow setPoint:NSMakePoint(NSMidX([outlet frame]),
	                                     NSMidY([outlet frame]) - childWindowShift) side:0];
	[windowViewManager toggleChildWindow:controlsWindow ofParentWindow:mainWindow withFade:TRUE];
}

- (IBAction)toggleQueueWindow:(id)outlet {
	[queueWindow setPoint:NSMakePoint(NSMidX([outlet frame]),
	                                  NSMidY([outlet frame]) - childWindowShift) side:2];
	[windowViewManager toggleChildWindow:queueWindow ofParentWindow:mainWindow withFade:TRUE];
}

- (void)showPlaylistCopiedNotification {
	[windowViewManager fadeInOutWindowInNewThread:playlistCopiedPopupWindow withDelay:1.9];
}

- (void)showPlaylistAddedNotification {
	[windowViewManager fadeInOutWindowInNewThread:playlistAddedPopupWindow withDelay:1.9];
}

- (void)showSongsAddedNotification {
	[windowViewManager fadeInOutWindowInNewThread:songsAddedPopupWindow withDelay:1.9];
}

- (void)showSongInfoPostedNotification {
	[windowViewManager fadeInOutWindowInNewThread:songInfoPostedPopupWindow withDelay:1.9];
}

- (IBAction)closeAndQuit:(id)outlet {
	[statsUpdateTimer invalidate];
	if ([queueWindow alphaValue] > 0.5) {
		[windowViewManager fadeOutWindow:queueWindow];
	}
	if ([controlsWindow alphaValue] > 0.5) {
		[windowViewManager fadeOutWindow:controlsWindow];
	}
	[windowViewManager fadeOutWindow:mainWindow];
	[NSApp terminate:self];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction)playerBack:(id)outlet {
	[iTunes previousTrack];
}

- (IBAction)playerForward:(id)outlet {
	[iTunes nextTrack];
}

- (IBAction)playerPlayPause:(id)outlet {
	[iTunes playpause];
}

- (IBAction)adjustPlayerVolume:(id)outlet {
	[iTunes setSoundVolume:[outlet integerValue]];
}

- (IBAction)maxPlayerVolume:(id)outlet {
	[volumeSlider setIntValue:100];
	[iTunes setSoundVolume:100];
}

- (IBAction)minPlayerVolume:(id)outlet {
	[volumeSlider setIntValue:0];
	[iTunes setSoundVolume:0];
}

- (IBAction)togglePlayerRepeat:(id)outlet {
	switch ([musicLibrary songRepeat]) {
		case iTunesERptOff:
			[musicLibrary setSongRepeat:iTunesERptAll];
			[repeatButton setImage:repeat];
			break;
            
		case iTunesERptAll:
			[musicLibrary setSongRepeat:iTunesERptOne];
			[repeatButton setImage:repeatOne];
			break;
            
		case iTunesERptOne:
			[musicLibrary setSongRepeat:iTunesERptOff];
			[repeatButton setImage:noRepeat];
			break;
	}
}

- (IBAction)togglePlayerShuffle:(id)outlet {
	if ([musicLibrary shuffle] == FALSE) {
		[musicLibrary setShuffle:TRUE];
		[shuffleButton setState:1];
	}
	else {
		[musicLibrary setShuffle:FALSE];
		[shuffleButton setState:0];
	}
}

- (IBAction)setPlayerPosition:(id)outlet {
	[iTunes setPlayerPosition:([outlet doubleValue] / 100.00) *[[iTunes currentTrack] duration]];
}

- (IBAction)setSongRating:(id)outlet {
	int rating = (int)[outlet tag];
    
	switch (rating) {
		case 1:
			[star1 setState:0];
			[star2 setState:1];
			[star3 setState:1];
			[star4 setState:1];
			[star5 setState:1];
			break;
            
		case 2:
			[star1 setState:0];
			[star2 setState:0];
			[star3 setState:1];
			[star4 setState:1];
			[star5 setState:1];
			break;
            
		case 3:
			[star1 setState:0];
			[star2 setState:0];
			[star3 setState:0];
			[star4 setState:1];
			[star5 setState:1];
			break;
            
		case 4:
			[star1 setState:0];
			[star2 setState:0];
			[star3 setState:0];
			[star4 setState:0];
			[star5 setState:1];
			break;
            
		case 5:
			[star1 setState:0];
			[star2 setState:0];
			[star3 setState:0];
			[star4 setState:0];
			[star5 setState:0];
			break;
	}
    
	[[iTunes currentTrack] setRating:(rating * 20)];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)getTinyUrlForName:(NSString *)trackname andArtist:(NSString *)trackartist {
	NSString *encodedTrack = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)[NSString stringWithFormat: @"%@ %@", trackname, trackartist], NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
	NSURL *trackURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://tinysong.com/a/%@?format=json&key=%@", encodedTrack, @"6b50ed35d46f4fbd5ed5d1e787dad103"]];
	NSData *connData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:trackURL] returningResponse:nil error:nil];
	if (connData != nil) {
		NSString *str = [[NSString alloc] initWithData:connData encoding:NSUTF8StringEncoding];
		if (![str containsString:@"NSF;"] && ![str containsString:@"error"] && ![str containsString:@"[]"]) {
			str = [[str stringByReplacingOccurrencesOfString:@"\\" withString:@""] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
			if (![str isEqualToString:@""]) {
				return str;
			}
		}
	}
    
	return nil;
}

- (NSString *)getItunesUrlForName:(NSString *)trackname andArtist:(NSString *)trackartist {
	NSString *encodedTrack = [[[NSString stringWithFormat:@"%@+%@", [trackname stringByReplacingOccurrencesOfString:@" " withString:@"+"], [trackartist stringByReplacingOccurrencesOfString:@" " withString:@"+"]] stringByReplacingOccurrencesOfString:@"ft." withString:@"feat."] stringByReplacingOccurrencesOfString:@"Ft." withString:@"Feat."];
	NSURL *trackURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/search?term=%@&entity=song&limit=1", encodedTrack]];
	NSData *connData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:trackURL] returningResponse:nil error:nil];
	if (connData != nil) {
		NSDictionary *resultsData = [connData objectFromJSONData];
		if ([[[resultsData objectForKey:@"resultCount"] stringValue] isEqualToString:@"1"]) {
			return [[[[resultsData objectForKey:@"results"] objectAtIndex:0] objectForKey:@"trackViewUrl"] description];
		}
	}
    
	return nil;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction)bringToSignIn:(id)outlet {
	if ([controlsWindow alphaValue] <= .5) {
		[self toggleControlsWindow:leftAnchorButton];
	}
    
	if ([[controlsParentView subviews] containsObject:controlsView]) {
		[self toggleSocialView:nil];
	}
}

- (IBAction)showLastFmView:(id)outlet {
	[lastFmActivateButton setAlphaValue:0.4];
	[facebookActivateButton setAlphaValue:1.0];
	[twitterActivateButton setAlphaValue:1.0];
	[socialTabView selectTabViewItemAtIndex:2];
}

- (IBAction)lastFmSignIn:(id)outlet {
	NSString *lastFmUsername = [lastFmUsernameField stringValue];
	NSString *lastFmPassword = [lastFmPasswordField stringValue];
    
	if ([lastFmUsername isEqualToString:@""] || [lastFmPassword isEqualToString:@""]) {
		return;
	}
	else {
		lastFmEngine = [[SNRLastFMEngine alloc] initWithUsername:lastFmUsername];
		[lastFmEngine retrieveAndStoreSessionKeyWithUsername:lastFmUsername password:lastFmPassword completionHandler: ^(NSError *error) {
		    if (error) {
		        [lastFmUsernameField setStringValue:@"Sign-In Failed"];
		        [lastFmPasswordField setStringValue:@""];
		        [self setLastFmLoggedIn:FALSE];
			}
		    else {
		        [[NSUserDefaults standardUserDefaults] setValue:lastFmUsername forKey:@"socialJukeboxLastFmUsername"];
		        [[NSUserDefaults standardUserDefaults] setValue:lastFmPassword forKey:@"socialJukeboxLastFmPassword"];
                
		        [lastFmUsernameField setEditable:FALSE];
		        [lastFmPasswordField setEditable:FALSE];
		        [lastFmLoginButton setTitle:@"Sign Out"];
		        [lastFmLoginButton setAction:@selector(lastFmSignOut:)];
		        [self setLastFmLoggedIn:TRUE];
			}
		}];
	}
}

- (IBAction)lastFmSignOut:(id)outlet {
	[lastFmEngine release];
    
	[lastFmUsernameField setStringValue:@""];
	[lastFmPasswordField setStringValue:@""];
	[lastFmUsernameField setEditable:TRUE];
	[lastFmPasswordField setEditable:TRUE];
    
	[[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"socialJukeboxLastFmUsername"];
	[[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"socialJukeboxLastFmPassword"];
    
	[lastFmLoginButton setTitle:@"Sign In"];
	[lastFmLoginButton setAction:@selector(lastFmSignIn:)];
	[self setLastFmLoggedIn:FALSE];
}

- (IBAction)lastFmPostSong:(id)outlet {
	if ([iTunes playerState] != iTunesEPlSStopped) {
		[lastFmEngine scrobbleTrackWithName:[[iTunes currentTrack] name] album:[[iTunes currentTrack] album] artist:[[iTunes currentTrack] artist] albumArtist:[[iTunes currentTrack] artist] trackNumber:1 duration:1 timestamp:[[NSDate date] timeIntervalSince1970] completionHandler: ^(NSDictionary *scrobbles, NSError *error) {
		    if (error) {
			}
		}];
		[self showSongInfoPostedNotification];
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction)showFacebookView:(id)outlet {
	[facebookActivateButton setAlphaValue:0.4];
	[lastFmActivateButton setAlphaValue:1.0];
	[twitterActivateButton setAlphaValue:1.0];
	[socialTabView selectTabViewItemAtIndex:1];
}

- (IBAction)facebookSignIn:(id)outlet {
	[facebookEngine getAccessTokenForPermissions:[NSArray arrayWithObjects:@"read_stream", @"export_stream", @"publish_stream", nil] cached:NO];
}

- (IBAction)facebookSignOut:(id)outlet {
	[facebookPictureView setImage:facebookpic];
	[facebookEngine invalidateCachedToken];
	[facebookLoginButton setTitle:@"Sign In"];
	[facebookUsernameLabel setStringValue:@""];
	[facebookLoginButton setAction:@selector(facebookSignIn:)];
	[self setFacebookLoggedIn:FALSE];
}

- (void)tokenResult:(NSDictionary *)result {
	if ([[result valueForKey:@"valid"] boolValue] == TRUE) {
		[facebookLoginButton setTitle:@"Sign Out"];
		[facebookLoginButton setAction:@selector(facebookSignOut:)];
		[self setFacebookLoggedIn:TRUE];
		[facebookEngine sendRequest:@"/me/picture" params:[NSDictionary dictionaryWithObject:@"normal" forKey:@"type"] usePostRequest:FALSE];
		[facebookEngine sendRequest:@"/me/" params:[NSDictionary dictionaryWithObject:@"username" forKey:@"fields"] usePostRequest:FALSE];
	}
}

- (IBAction)postToFacebook:(id)outlet {
	[facebookEngine getAccessTokenForPermissions:[NSArray arrayWithObjects:@"read_stream", @"export_stream", @"publish_stream", nil] cached:NO];
    
	if ([iTunes playerState] != iTunesEPlSStopped) {
		NSString *trackname = [[iTunes currentTrack] name];
		NSString *trackartist = [[iTunes currentTrack] artist];
		NSMutableString *songInfo = [[NSMutableString alloc] init];
		[songInfo appendString:@"Social Jukebox - Listening to... "];
        
		NSString *tinyurl = [self getTinyUrlForName:trackname andArtist:trackartist];
		if (tinyurl) {
			[facebookEngine sendRequest:@"/me/feed" params:[NSDictionary dictionaryWithObjectsAndKeys:songInfo, @"message", tinyurl, @"link", nil] usePostRequest:TRUE];
		}
		else {
			[songInfo appendString:trackname];
			[songInfo appendString:@" by "];
			[songInfo appendString:trackartist];
			[facebookEngine sendRequest:@"/me/feed" params:[NSDictionary dictionaryWithObject:songInfo forKey:@"message"] usePostRequest:TRUE];
		}
	}
}

- (void)requestResult:(NSDictionary *)result {
	NSString *request = [result objectForKey:@"request"];
    
	if ([request isEqualTo:@"/me/picture"]) {
		NSImage *pic = [[NSImage alloc] initWithData:[result objectForKey:@"raw"]];
		[facebookPictureView setImage:pic];
	}
	else if ([request isEqualTo:@"/me/feed"]) {
		[self showSongInfoPostedNotification];
	}
	else if ([request isEqualTo:@"/me/"]) {
		NSString *resultname = [result objectForKey:@"result"];
		NSRange openBracket = [resultname rangeOfString:@":"];
		NSRange closeBracket = [resultname rangeOfString:@","];
		NSRange numberRange = NSMakeRange(openBracket.location + 1, closeBracket.location - openBracket.location - 1);
		NSString *newresultname = [resultname substringWithRange:numberRange];
		numberRange = NSMakeRange(1, [newresultname length] - 2);
		NSString *newnewresultname = [newresultname substringWithRange:numberRange];
        
		[facebookUsernameLabel setStringValue:newnewresultname];
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction)showTwitterView:(id)outlet {
	[twitterActivateButton setAlphaValue:0.4];
	[lastFmActivateButton setAlphaValue:1.0];
	[facebookActivateButton setAlphaValue:1.0];
	[socialTabView selectTabViewItemAtIndex:0];
}

- (IBAction)twitterSignIn:(id)outlet {
	NSString *twitterUsername = [twitterUsernameField stringValue];
	NSString *twitterPassword = [twitterPasswordField stringValue];
    
	if ([twitterUsername isEqualToString:@""] || [twitterPassword isEqualToString:@""]) {
		return;
	}
	else {
		[twitterEngine setUsername:twitterUsername password:twitterPassword];
		[twitterEngine requestAccessToken];
	}
}

- (IBAction)twitterSignOut:(id)outlet {
	[twitterEngine clearAccessToken];
    
	[twitterUsernameField setStringValue:@""];
	[twitterPasswordField setStringValue:@""];
	[twitterUsernameField setEditable:TRUE];
	[twitterPasswordField setEditable:TRUE];
    
	[[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"socialJukeboxTwitterUsername"];
	[[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"socialJukeboxTwitterPassword"];
    
	[twitterLoginButton setTitle:@"Sign In"];
	[twitterLoginButton setAction:@selector(twitterSignIn:)];
	[self setTwitterLoggedIn:FALSE];
}

- (IBAction)twitterPostSong:(id)outlet {
	if ([iTunes playerState] != iTunesEPlSStopped) {
		NSString *trackname = [[iTunes currentTrack] name];
		NSString *trackartist = [[iTunes currentTrack] artist];
		NSMutableString *songInfo = [[NSMutableString alloc] init];
		[songInfo appendString:@"#SocialJukebox - Listening to "];
		[songInfo appendString:trackname];
		[songInfo appendString:@" by "];
		[songInfo appendString:trackartist];
        
		NSString *tinyurl = [self getTinyUrlForName:trackname andArtist:trackartist];
		if (tinyurl) {
			[songInfo appendString:@" - "];
			[songInfo appendString:tinyurl];
		}
        
		[twitterEngine sendUpdate:songInfo];
		[self showSongInfoPostedNotification];
	}
}

- (void)twitterEngineReceivedAccessToken:(id)sender {
	[[NSUserDefaults standardUserDefaults] setValue:[twitterUsernameField stringValue] forKey:@"socialJukeboxTwitterUsername"];
	[[NSUserDefaults standardUserDefaults] setValue:[twitterPasswordField stringValue] forKey:@"socialJukeboxTwitterPassword"];
	[twitterUsernameField setEditable:FALSE];
	[twitterPasswordField setEditable:FALSE];
	[twitterLoginButton setTitle:@"Sign Out"];
	[twitterLoginButton setAction:@selector(twitterSignOut:)];
	[self setTwitterLoggedIn:TRUE];
}

- (void)twitterEngineNotReceivedAccessToken {
	[twitterUsernameField setStringValue:@"Sign-In Failed"];
	[twitterPasswordField setStringValue:@""];
	[self setTwitterLoggedIn:FALSE];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	[pboard declareTypes:[NSArray arrayWithObject:@"NSMutableDictionary"] owner:songQueueController];
	[pboard setData:data forType:@"NSMutableDictionary"];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo> )info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
	return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo> )info row:(int)to dropOperation:(NSTableViewDropOperation)operation {
	NSPasteboard *pboard = [info draggingPasteboard];
	NSData *rowData = [pboard dataForType:@"NSMutableDictionary"];
	NSIndexSet *rowIndexes = [NSKeyedUnarchiver
	                          unarchiveObjectWithData:rowData];
	NSInteger from = [rowIndexes firstIndex];
	NSMutableDictionary *traveller = [[songQueueController arrangedObjects]
	                                  objectAtIndex:from];
	[traveller retain];
	NSInteger length = [[songQueueController arrangedObjects] count];
    
	int i;
	for (i = 0; i <= length; i++) {
		if (i == to) {
			if (from > to) {
				[songQueueController insertObject:traveller atArrangedObjectIndex:to];
				[songQueueController removeObjectAtArrangedObjectIndex:from + 1];
			}
			else {
				[songQueueController insertObject:traveller atArrangedObjectIndex:to];
				[songQueueController removeObjectAtArrangedObjectIndex:from];
			}
		}
	}
    
	[self updateNextSongInfo];
    
	return TRUE;
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
	[mainWindow deminiaturize:self];
	[mainWindow makeKeyAndOrderFront:self];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[mainWindow deminiaturize:self];
	[mainWindow makeKeyAndOrderFront:self];
    
	return NO;
}

- (void)mouseEntered:(NSEvent *)theEvent {
	[mainWindow makeKeyAndOrderFront:self];
}

- (void)mouseExited:(NSEvent *)theEvent {
	//[mainWindow resignKeyWindow];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@end
