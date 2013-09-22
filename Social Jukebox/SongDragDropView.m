//
//  SongDragDropView.m
//  Flip
//
//  Created by Mathew Huusko V on 7/30/11.
//  Copyright 2011 Phillips Exeter Academy. All rights reserved.
//

#import "SongDragDropView.h"

@implementation SongDragDropView

NSString *const iTunesPboardType = @"CorePasteboardFlavorType 0x6974756E";
NSString *const iTunesPboardType2 = @"CorePasteboardFlavorType 0x4855666C";

- (id)initWithFrame:(NSRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self registerForDraggedTypes:[NSArray arrayWithObjects:iTunesPboardType, iTunesPboardType2, nil]];
	}
	return self;
}

- (id)init {
	if (self = [super init]) {
		[self registerForDraggedTypes:[NSArray arrayWithObjects:iTunesPboardType, iTunesPboardType2, nil]];
	}
	return self;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo> )sender {
	if ((NSDragOperationGeneric &[sender draggingSourceOperationMask]) == NSDragOperationGeneric) {
		return NSDragOperationGeneric;
	}
	return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo> )sender {
	return TRUE;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo> )sender {
	NSAppleScript *key = [[NSAppleScript alloc] initWithSource:@"tell application \"System Events\" to keystroke \"b\" using {command down, option down}"];
	[NSThread detachNewThreadSelector:@selector(executeAndReturnError:) toTarget:key withObject:nil];
	return TRUE;
}

- (void)concludeDragOperation:(id <NSDraggingInfo> )sender {
}

@end
