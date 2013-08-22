#import <Cocoa/Cocoa.h>

/*
 Below are the positions the attached window can be displayed at.
 
 Note that these positions are relative to the point passed to the constructor, 
 e.g. MAPositionBottomRight will put the window below the point and towards the right, 
      MAPositionTop will horizontally center the window above the point, 
      MAPositionRightTop will put the window to the right and above the point, 
 and so on.
 
 You can also pass MAPositionAutomatic (or use an initializer which omits the 'onSide:' 
 argument) and the attached window will try to position itself sensibly, based on 
 available screen-space.
 
 Notes regarding automatically-positioned attached windows:
 
 (a) The window prefers to position itself horizontally centered below the specified point.
     This gives a certain enhanced visual sense of an attachment/relationship.
 
 (b) The window will try to align itself with its parent window (if any); i.e. it will 
     attempt to stay within its parent window's frame if it can.
 
 (c) The algorithm isn't perfect. :) If in doubt, do your own calculations and then 
     explicitly request that the window attach itself to a particular side.
 */

typedef enum _MAWindowPosition {
    // The four primary sides are compatible with the preferredEdge of NSDrawer.
    MAPositionLeft          = NSMinXEdge, // 0
    MAPositionRight         = NSMaxXEdge, // 2
    MAPositionTop           = NSMaxYEdge, // 3
    MAPositionBottom        = NSMinYEdge, // 1
    MAPositionLeftTop       = 4,
    MAPositionLeftBottom    = 5,
    MAPositionRightTop      = 6,
    MAPositionRightBottom   = 7,
    MAPositionTopLeft       = 8,
    MAPositionTopRight      = 9,
    MAPositionBottomLeft    = 10,
    MAPositionBottomRight   = 11,
    MAPositionAutomatic     = 12
} MAWindowPosition;

@interface AttachedPopupWindow : NSPanel {
    Boolean open;
    NSColor *borderColor;
    float borderWidth;
    float viewMargin;
    float arrowBaseWidth;
    float arrowHeight;
    BOOL hasArrow;
    float cornerRadius;
    BOOL drawsRoundCornerBesideArrow;
    
    @private
    NSColor *_MABackgroundColor;
    __weak NSView *_view;
    __weak NSWindow *_window;
    NSPoint _point;
    MAWindowPosition _side;
    float _distance;
    NSRect _viewFrame;
    BOOL _resizing;
}


/*
 Initialization methods
 
 Parameters:
 
 view       The view to display in the attached window. Must not be nil.
 
 point      The point to which the attached window should be attached. If you 
            are also specifying a parent window, the point should be in the 
            coordinate system of that parent window. If you are not specifying 
            a window, the point should be in the screen's coordinate space.
            This value is required.
 
 window     The parent window to attach this one to. Note that no actual 
            relationship is created (particularly, this window is not made 
            a childWindow of the parent window).
            Default: nil.
 
 side       The side of the specified point on which to attach this window.
            Default: MAPositionAutomatic.
 
 distance   How far from the specified point this window should be.
            Default: 0.
 */

- (AttachedPopupWindow *)initWithView:(NSView *)view           // designated initializer
                   attachedToPoint:(NSPoint)point 
                          inWindow:(NSWindow *)window 
                            onSide:(MAWindowPosition)side 
                        atDistance:(float)distance;
- (AttachedPopupWindow *)initWithView:(NSView *)view 
                   attachedToPoint:(NSPoint)point 
                          inWindow:(NSWindow *)window 
                        atDistance:(float)distance;
- (AttachedPopupWindow *)initWithView:(NSView *)view 
                   attachedToPoint:(NSPoint)point 
                            onSide:(MAWindowPosition)side 
                        atDistance:(float)distance;
- (AttachedPopupWindow *)initWithView:(NSView *)view 
                   attachedToPoint:(NSPoint)point 
                        atDistance:(float)distance;
- (AttachedPopupWindow *)initWithView:(NSView *)view 
                   attachedToPoint:(NSPoint)point 
                          inWindow:(NSWindow *)window;
- (AttachedPopupWindow *)initWithView:(NSView *)view 
                   attachedToPoint:(NSPoint)point 
                            onSide:(MAWindowPosition)side;
- (AttachedPopupWindow *)initWithView:(NSView *)view 
                   attachedToPoint:(NSPoint)point;

// Accessor methods
- (void)setPoint:(NSPoint)point side:(MAWindowPosition)side;
- (NSColor *)borderColor;
- (void)setBorderColor:(NSColor *)value;
- (float)borderWidth;
- (void)setBorderWidth:(float)value;                   // See note 1 below.
- (float)viewMargin;
- (void)setViewMargin:(float)value;                    // See note 2 below.
- (float)arrowBaseWidth;
- (void)setArrowBaseWidth:(float)value;                // See note 2 below.
- (float)arrowHeight;
- (void)setArrowHeight:(float)value;                   // See note 2 below.
- (float)hasArrow;
- (void)setHasArrow:(float)value;
- (float)cornerRadius;
- (void)setCornerRadius:(float)value;                  // See note 2 below.
- (float)drawsRoundCornerBesideArrow;                  // See note 3 below.
- (void)setDrawsRoundCornerBesideArrow:(float)value;   // See note 2 below.
- (void)setBackgroundImage:(NSImage *)value;
- (NSColor *)windowBackgroundColor;                    // See note 4 below.
- (void)setBackgroundColor:(NSColor *)value;

@end