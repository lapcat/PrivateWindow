#import "JJMainWindow.h"

@implementation JJMainWindow

static const CGFloat JJMainWindowMargin = 15.0;

+(void)acessibilitySettings:(nullable id)sender {
	NSDictionary* options = @{(__bridge NSString*)kAXTrustedCheckOptionPrompt: @YES};
	AXIsProcessTrustedWithOptions((CFDictionaryRef)options);
}

+(void)popUpAction:(nonnull NSPopUpButton*)popUp {
	NSMenuItem* selectedItem = [popUp selectedItem];
	if (selectedItem == nil)
		return;
	NSString* title = [selectedItem title];
	[[NSUserDefaults standardUserDefaults] setObject:title forKey:UseSafariMenuItemSetting];
}

+(void)toggleBrowser:(nonnull NSButton*)sender {
	NSInteger tag = [sender tag];
	BOOL useSafariTechnologyPreview = tag == 1;
	[[NSUserDefaults standardUserDefaults] setBool:useSafariTechnologyPreview forKey:UseSafariTechnologyPreviewSetting];
}

+(nonnull NSWindow*)window {
	NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
	NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0.0, 0.0, 600.0, 300.0) styleMask:style backing:NSBackingStoreBuffered defer:YES];
	[window setAutorecalculatesKeyViewLoop:YES];
	[window setExcludedFromWindowsMenu:YES];
	[window setReleasedWhenClosed:NO]; // Necessary under ARC to avoid a crash.
	[window setTabbingMode:NSWindowTabbingModeDisallowed];
	[window setTitle:JJApplicationName];
	NSView* contentView = [window contentView];
	
	NSMutableArray<NSLayoutConstraint*>* constraints = [NSMutableArray array];
	
	NSString* windowType = [JJApplicationName isEqualToString:@"PrivateWindow"] ? @"private" : @"non-private";
	NSString* intro = [NSString stringWithFormat:@"%@ opens URLs in a %@ window in your selected web browser and then quits.\nYou can set %@ as your default web brower in System Settings > Desktop & Dock.", JJApplicationName, windowType, JJApplicationName];
	NSTextField* label = [NSTextField wrappingLabelWithString:intro];
	[label setContentCompressionResistancePriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationHorizontal];
	[label setTranslatesAutoresizingMaskIntoConstraints:NO];
	[contentView addSubview:label];
	[constraints addObject:[[label topAnchor] constraintEqualToAnchor:[contentView topAnchor] constant:JJMainWindowMargin]];
	[constraints addObject:[[label leadingAnchor] constraintEqualToAnchor:[contentView leadingAnchor] constant:JJMainWindowMargin]];
	[constraints addObject:[[contentView trailingAnchor] constraintEqualToAnchor:[label trailingAnchor] constant:JJMainWindowMargin]];
	
	NSFont* font = [label font];
	
	NSLayoutYAxisAnchor* bottomAnchor = [label bottomAnchor];
	
	if (!AXIsProcessTrusted()) {
		NSString* trustString = [NSString stringWithFormat:@"You need to enable %@ in System Settings > Privacy & Security > Accessibility.", JJApplicationName];
		NSTextField* trustLabel = [NSTextField labelWithString:trustString];
		[trustLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
		[contentView addSubview:trustLabel];
		[constraints addObject:[[trustLabel topAnchor] constraintEqualToAnchor:bottomAnchor constant:JJMainWindowMargin]];
		[constraints addObject:[[trustLabel leadingAnchor] constraintEqualToAnchor:[label leadingAnchor]]];
		
		NSButton* trustButton = [[NSButton alloc] init];
		[trustButton setButtonType:NSButtonTypeMomentaryLight];
		[trustButton setBezelStyle:NSBezelStyleRounded];
		[trustButton setTitle:NSLocalizedString(@"Open Accessibility Settings", nil)];
		[trustButton setAction:@selector(acessibilitySettings:)];
		[trustButton setTarget:self];
		[trustButton setTranslatesAutoresizingMaskIntoConstraints:NO];
		[contentView addSubview:trustButton];
		[constraints addObject:[[trustButton topAnchor] constraintEqualToAnchor:[trustLabel bottomAnchor] constant:5.0]];
		[constraints addObject:[[trustButton leadingAnchor] constraintEqualToAnchor:[trustLabel leadingAnchor]]];
		[window setDefaultButtonCell:[trustButton cell]];
		[window setInitialFirstResponder:trustButton];
		bottomAnchor = [trustButton bottomAnchor];
	}
	
	BOOL useSafariTechnologyPreview = [[NSUserDefaults standardUserDefaults] boolForKey:UseSafariTechnologyPreviewSetting];
	if (useSafariTechnologyPreview || [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:SafariTechnologyPreviewBundleID] != nil) {
		NSTextField* browserLabel = [NSTextField labelWithString:@"Web Browser:"];
		[browserLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
		[contentView addSubview:browserLabel];
		[constraints addObject:[[browserLabel topAnchor] constraintEqualToAnchor:bottomAnchor constant:JJMainWindowMargin * 2.0]];
		[constraints addObject:[[browserLabel leadingAnchor] constraintEqualToAnchor:[label leadingAnchor]]];
		
		bottomAnchor = [browserLabel bottomAnchor];
		
		NSButton* safariButton = [NSButton radioButtonWithTitle:@"Safari" target:self action:@selector(toggleBrowser:)];
		[safariButton setTag:0];
		[safariButton setFont:font];
		[safariButton setTranslatesAutoresizingMaskIntoConstraints:NO];
		[contentView addSubview:safariButton];
		[constraints addObject:[[safariButton lastBaselineAnchor] constraintEqualToAnchor:[browserLabel lastBaselineAnchor]]];
		[constraints addObject:[[safariButton leadingAnchor] constraintEqualToAnchor:[browserLabel trailingAnchor] constant:5.0]];
		
		NSButton* stpButton = [NSButton radioButtonWithTitle:@"Safari Technology Preview" target:self action:@selector(toggleBrowser:)];
		[stpButton setTag:1];
		[stpButton setFont:font];
		[stpButton setTranslatesAutoresizingMaskIntoConstraints:NO];
		[contentView addSubview:stpButton];
		[constraints addObject:[[stpButton lastBaselineAnchor] constraintEqualToAnchor:[browserLabel lastBaselineAnchor]]];
		[constraints addObject:[[stpButton leadingAnchor] constraintEqualToAnchor:[safariButton trailingAnchor] constant:5.0]];
		
		if (useSafariTechnologyPreview) {
			[stpButton setState:NSControlStateValueOn];
			[safariButton setState:NSControlStateValueOff];
		} else {
			[stpButton setState:NSControlStateValueOff];
			[safariButton setState:NSControlStateValueOn];
		}
	}

	NSTextField* popUpLabel = [NSTextField labelWithString:@"Safari File menu item:"];
	[popUpLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
	[contentView addSubview:popUpLabel];
	[constraints addObject:[[popUpLabel topAnchor] constraintEqualToAnchor:bottomAnchor constant:JJMainWindowMargin * 2.0]];
	[constraints addObject:[[popUpLabel leadingAnchor] constraintEqualToAnchor:[label leadingAnchor]]];
	
	NSPopUpButton * popUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect( 0.0, 0.0, 150.0, 16.0 ) pullsDown:NO];
	[popUp setFont:font];
	[popUp setAction:@selector(popUpAction:)];
	[popUp setTarget:self];
	[popUp setTranslatesAutoresizingMaskIntoConstraints:NO];
	[popUp addItemsWithTitles:@[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10"]];
	NSString* menuItemTitle = [[NSUserDefaults standardUserDefaults] stringForKey:UseSafariMenuItemSetting];
	[popUp selectItemWithTitle:menuItemTitle];
	[contentView addSubview:popUp];
	[constraints addObject:[[popUp leadingAnchor] constraintEqualToAnchor:[popUpLabel trailingAnchor] constant:5.0]];
	[constraints addObject:[[popUp lastBaselineAnchor] constraintEqualToAnchor:[popUpLabel lastBaselineAnchor]]];
	
	NSTextField* popUpInstructions = [NSTextField labelWithString:@"By default, item 1 in the Safari File menu is New Window, and item 2 is New Private Window.\nHowever, Safari Profiles add items to the menu. Select the menu item that you want to use."];
	[popUpInstructions setTranslatesAutoresizingMaskIntoConstraints:NO];
	[contentView addSubview:popUpInstructions];
	[constraints addObject:[[popUpInstructions topAnchor] constraintEqualToAnchor:[popUp bottomAnchor] constant:10.0]];
	[constraints addObject:[[popUpInstructions leadingAnchor] constraintEqualToAnchor:[label leadingAnchor]]];
	
	NSImage* screenshot1 = [NSImage imageNamed:@"FileDefault"];
	NSImageView* imageView1 = [[NSImageView alloc] init];
	[imageView1 setImage:screenshot1];
	[imageView1 setTranslatesAutoresizingMaskIntoConstraints:NO];
	[contentView addSubview:imageView1];
	[constraints addObject:[[imageView1 topAnchor] constraintEqualToAnchor:[popUpInstructions bottomAnchor] constant:10.0]];
	[constraints addObject:[[imageView1 leadingAnchor] constraintEqualToAnchor:[label leadingAnchor]]];
	
	NSImage* screenshot2 = [NSImage imageNamed:@"FileProfiles"];
	NSImageView* imageView2 = [[NSImageView alloc] init];
	[imageView2 setImage:screenshot2];
	[imageView2 setTranslatesAutoresizingMaskIntoConstraints:NO];
	[contentView addSubview:imageView2];
	[constraints addObject:[[imageView2 topAnchor] constraintEqualToAnchor:[imageView1 topAnchor]]];
	[constraints addObject:[[imageView2 leadingAnchor] constraintEqualToAnchor:[imageView1 trailingAnchor] constant:JJMainWindowMargin]];
	
	[constraints addObject:[[contentView bottomAnchor] constraintEqualToAnchor:[imageView2 bottomAnchor] constant:JJMainWindowMargin]];
	[NSLayoutConstraint activateConstraints:constraints];
	
	[window makeKeyAndOrderFront:nil];
	[window center]; // Wait until after makeKeyAndOrderFront so the window sizes properly first
	
	return window;
}

@end
