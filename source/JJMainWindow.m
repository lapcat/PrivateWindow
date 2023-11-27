#import "JJMainWindow.h"

@implementation JJMainWindow

static const CGFloat JJMainWindowMargin = 15.0;

+(void)acessibilitySettings:(nullable id)sender {
	NSDictionary* options = @{(__bridge NSString*)kAXTrustedCheckOptionPrompt: @YES};
	AXIsProcessTrustedWithOptions((CFDictionaryRef)options);
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
	[constraints addObject:[[contentView widthAnchor] constraintEqualToConstant:600.0]];
	
	NSString* windowType = [JJApplicationName isEqualToString:@"PrivateWindow"] ? @"private" : @"non-private";
	NSString* intro = [NSString stringWithFormat:@"%@ opens URLs in a %@ window in your selected web browser and then quits.\nYou can set %@ as your default web brower in System Settings > Desktop & Dock.", JJApplicationName, windowType, JJApplicationName];
	NSTextField* label = [NSTextField wrappingLabelWithString:intro];
	[label setTranslatesAutoresizingMaskIntoConstraints:NO];
	[contentView addSubview:label];
	[constraints addObject:[[label topAnchor] constraintEqualToAnchor:[contentView topAnchor] constant:JJMainWindowMargin]];
	[constraints addObject:[[label leadingAnchor] constraintEqualToAnchor:[contentView leadingAnchor] constant:JJMainWindowMargin]];
	
	NSLayoutYAxisAnchor* bottomAnchor = [label bottomAnchor];
	
	BOOL useSafariTechnologyPreview = [[NSUserDefaults standardUserDefaults] boolForKey:UseSafariTechnologyPreviewSetting];
	if (useSafariTechnologyPreview || [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:SafariTechnologyPreviewBundleID] != nil) {
		NSTextField* browserLabel = [[NSTextField alloc] init];
		[browserLabel setBezeled:NO];
		[browserLabel setBordered:NO];
		[browserLabel setDrawsBackground:NO];
		[browserLabel setEditable:NO];
		[browserLabel setLineBreakMode:NSLineBreakByClipping];
		[browserLabel setSelectable:NO];
		[browserLabel setStringValue:@"Web Browser:"];
		[browserLabel setUsesSingleLineMode:YES];
		[browserLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
		[contentView addSubview:browserLabel];
		[constraints addObject:[[browserLabel topAnchor] constraintEqualToAnchor:[label bottomAnchor] constant:JJMainWindowMargin]];
		[constraints addObject:[[browserLabel leadingAnchor] constraintEqualToAnchor:[label leadingAnchor]]];
		
		bottomAnchor = [browserLabel bottomAnchor];
		
		NSFont* font = [browserLabel font];
		
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
	[constraints addObject:[[contentView bottomAnchor] constraintEqualToAnchor:bottomAnchor constant:JJMainWindowMargin]];
	[NSLayoutConstraint activateConstraints:constraints];
	
	[window makeKeyAndOrderFront:nil];
	[window center]; // Wait until after makeKeyAndOrderFront so the window sizes properly first
	
	return window;
}

@end
