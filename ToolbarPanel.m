/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "ToolbarPanel.h"
#import "ToolBarNSWindow.h"
#import "ViewerController.h"
#import "AppController.h"
#import "NSWindow+N2.h"
#import "Notifications.h"

extern BOOL USETOOLBARPANEL;

static 	NSMutableDictionary *associatedScreen = nil;
static int increment = 0;

@implementation ToolbarPanelController

@synthesize viewer;

- (long) fixedHeight {
	//return 90;
    NSRect windowFrame = [NSWindow contentRectForFrameRect:[self.window frame] styleMask:[self.window styleMask]];
    NSRect contentFrame = [[self.window contentView] frame];
    return NSHeight(windowFrame) - NSHeight(contentFrame) + 13;
}

- (long) hiddenHeight {
	return 15;
}

- (long) exposedHeight {
	return [self fixedHeight] - [self hiddenHeight];
}

/*- (void) checkPosition
{
	if( [[NSScreen screens] count] > screen)
	{
		NSPoint o = NSMakePoint([[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.x, [[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.y+[[[NSScreen screens] objectAtIndex: screen] visibleFrame].size.height);
	
//		[[self window] setFrameTopLeftPoint: o];		// fixSize will be called by this function
//		[self fixSize];
	}
}*/

/*- (void) fixSize
{
	NSRect  dstframe;
	NSArray *screens = [NSScreen screens];
	
	if( [screens count] > screen)
	{
		NSRect screenRect = [[screens objectAtIndex: screen] visibleFrame];
		
		dstframe.size.height = [ToolbarPanelController fixedHeight];
		dstframe.size.width = screenRect.size.width;
		dstframe.origin.x = screenRect.origin.x;
		dstframe.origin.y = screenRect.origin.y + screenRect.size.height - dstframe.size.height + [ToolbarPanelController hiddenHeight];
		
		[[self window] setFrame: dstframe display: NO];
	}
}*/

-(void)applicationDidChangeScreenParameters:(NSNotification*)aNotification
{
	if ([[NSScreen screens] count] <= screen)
		return;
	
	NSRect screenRect = [[[NSScreen screens] objectAtIndex:screen] visibleFrame];
	
	NSRect dstframe;
	dstframe.size.height = [self fixedHeight];
	dstframe.size.width = screenRect.size.width;
	dstframe.origin.x = screenRect.origin.x;
	dstframe.origin.y = screenRect.origin.y + screenRect.size.height - dstframe.size.height + [self hiddenHeight];
	
	[[self window] setFrame:dstframe display:YES];
}

- (id)initForScreen: (long) s
{
	screen = s;
	
	if (self = [super initWithWindowNibName:@"ToolbarPanel"])
	{
		toolbar = nil;
		
        emptyToolbar = [[NSToolbar alloc] initWithIdentifier: [NSString stringWithFormat:@"nstoolbar osirix %d", increment++]];
        [emptyToolbar setDelegate: self];
        
        [[self window] setAnimationBehavior: NSWindowAnimationBehaviorNone];
        
        [[self window] setToolbar: emptyToolbar];
        [[self window] setLevel: NSNormalWindowLevel];
        
        [self applicationDidChangeScreenParameters: nil];
        
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangeScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:NSApp];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerWillClose:) name: OsirixCloseViewerNotification object: nil];
		
		if( [AppController hasMacOSXSnowLeopard])
			[[self window] setCollectionBehavior: 1 << 6]; //NSWindowCollectionBehaviorIgnoresCycle
		
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:0];
        
        [self.window safelySetMovable:NO];
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    
	[emptyToolbar release];
	[super dealloc];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		if( [[self window] isVisible] && viewer)
            [[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
	}
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
//    [[self window] setToolbar: emptyToolbar]; for testing the empty toolbar
//    return;
    
	if( [aNotification object] == [self window])
	{
		if( [[self window] isVisible])
		{
			if( [[viewer window] isVisible])
				[[viewer window] makeKeyAndOrderFront: self];
            
            if( viewer)
                [[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
            else
            {
                [self.window orderOut: self];
            }
		}
	}
}

- (void)windowDidResignMain:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		if( [[self window] isVisible] && viewer)
            [[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
	}
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		[[viewer window] makeKeyAndOrderFront: self];
        
		if( [[self window] isVisible] && viewer)
            [[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
        
		return;
	}
	
	if( [(NSWindow*)[aNotification object] level] != NSNormalWindowLevel)
        return;
	
	if( USETOOLBARPANEL == NO)
	{
		[[self window] orderOut:self];
		return;
	}
	
	//[self checkPosition];
	
	if( [[[aNotification object] windowController] isKindOfClass:[ViewerController class]])
	{
		if( [[NSScreen screens] count] > screen)
		{
			if( [[aNotification object] screen] == [[NSScreen screens] objectAtIndex: screen])
			{
				[[viewer window] orderFront: self];
				
				[[self window] orderBack:self];
				[toolbar setVisible:YES];
                
                if( viewer)
                    [[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
				
//				if( [[viewer window] isVisible] == NO)
//				{
//					[[self window] orderBack:self];
//					[[self window] close];
//					NSLog( @"ToolbarPanel.m : [[viewer window] isVisible] == NO -> hide toolbar");
//				}
			}
			else
			{
				[self.window orderOut:self];
			}
		}
	}
	
	[[self window] setFrame:[[self window] frame] display:YES];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects: @"emptyItem", NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier, nil];
};

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects: NSToolbarFlexibleSpaceItemIdentifier, @"emptyItem", NSToolbarFlexibleSpaceItemIdentifier, nil];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
	 
    if ([itemIdent isEqualToString: @"emptyItem"])
    {
        #define HEIGHT 53
        #define WIDTH 600
        
		[toolbarItem setLabel: @""];
         
        NSTextView *txtView = [[[NSTextView alloc] initWithFrame: NSMakeRect( 0, 0, WIDTH, HEIGHT)] autorelease];
         
        [txtView insertText: NSLocalizedString( @"\rSelect a viewer to display the toolbar", nil)];
        [txtView setEditable: NO];
        [txtView setSelectable: NO];
        [txtView setDrawsBackground: NO];
        [txtView setFont: [NSFont systemFontOfSize: 18]];
        [txtView setAlignment: NSCenterTextAlignment];
        
		[toolbarItem setView: txtView];
		[toolbarItem setMinSize: NSMakeSize( WIDTH, HEIGHT)];
		[toolbarItem setMaxSize: NSMakeSize( WIDTH, HEIGHT)];
		[toolbarItem setTarget: nil];
		[toolbarItem setAction: nil];
    }
	else NSLog( @"********** ToolbarPanel.m uh??");
	
	 return [toolbarItem autorelease];
}

- (NSToolbar*) toolbar
{
	return toolbar;
}

- (void) toolbarWillClose :(NSToolbar*) tb
{
	if( toolbar == tb)
	{
//		((ToolBarNSWindow*) [self window]).willClose = YES;
		
		[[self window] orderOut: self];
		
		if( [[self window] screen])
			[associatedScreen setObject: [[self window] screen] forKey: [NSValue valueWithPointer: toolbar]];
		else
			[associatedScreen removeObjectForKey: [NSValue valueWithPointer: toolbar]];
		
		[[self window] setToolbar: emptyToolbar];
//		[[self window] orderOut: self];
		
		[associatedScreen removeObjectForKey: [NSValue valueWithPointer: toolbar]];
		
		[toolbar release];
		toolbar = 0L;
		
        [viewer release];
		viewer = 0L;
		
//		((ToolBarNSWindow*) [self window]).willClose = NO;
	}
}

- (void) viewerWillClose: (NSNotification*) n
{
    if( [n object] == viewer)
    {
        [self setToolbar: nil viewer: nil];
    }
}

- (void) setToolbar :(NSToolbar*) tb viewer:(ViewerController*) v
{
	if( associatedScreen == nil) associatedScreen = [[NSMutableDictionary alloc] init];
	
	if( tb == nil)
		tb = emptyToolbar;
	
	if( tb == toolbar)
	{
        NSDisableScreenUpdates();
        
		if( viewer != nil)
			[[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
	
		if( toolbar)
		{
			if( [associatedScreen objectForKey: [NSValue valueWithPointer: toolbar]] != [[self window] screen])
			{
				if( [[NSScreen screens] count] > 1)
					[[self window] setToolbar: emptyToolbar];
				[[self window] setToolbar: toolbar];
				
				if( [[self window] screen])
					[associatedScreen setObject: [[self window] screen] forKey: [NSValue valueWithPointer: toolbar]];
				else
					[associatedScreen removeObjectForKey: [NSValue valueWithPointer: toolbar]];
			}
		}
		else
            [self.window orderOut: self];
        
        NSEnableScreenUpdates();
        
		return;
	}
	
    [viewer release];
	viewer = [v retain];
	
	if( toolbar != tb)
	{
		[toolbar release];
		toolbar = [tb retain];
		[toolbar setShowsBaselineSeparator: NO];
	}
    
    NSDisableScreenUpdates();
    
	if( toolbar)
	{
		if( [associatedScreen objectForKey: [NSValue valueWithPointer: toolbar]] != [[self window] screen])
		{
			if( [[NSScreen screens] count] > 1)
				[[self window] setToolbar: emptyToolbar];	//To avoid the stupid add an item in customize toolbar.....
				
			if( [[self window] screen])
				[associatedScreen setObject: [[self window] screen] forKey: [NSValue valueWithPointer: toolbar]];
			else
				[associatedScreen removeObjectForKey: [NSValue valueWithPointer: toolbar]];
		}
		
		[[self window] setToolbar: toolbar];
		
		[[self window] setShowsToolbarButton:NO];
		[[[self window] toolbar] setVisible: YES];
		
		
		if( [[viewer window] isKeyWindow])
			[[self window] orderBack: self];
	}
	else
	{
		[self.window orderOut: self];
	}
	
	if( toolbar)
	{
		[self applicationDidChangeScreenParameters:nil];
		
		if( [[viewer window] isKeyWindow])
			[[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
	}
    
    NSEnableScreenUpdates();
}

@end
