#import "JJApplicationDelegate.h"

#import "JJLicenseWindow.h"
#import "JJMainMenu.h"
#import "JJMainWindow.h"

NSString* JJApplicationName;
NSString*const UseSafariTechnologyPreviewSetting = @"UseSafariTechnologyPreview";
NSString*const SafariBundleID = @"com.apple.Safari";
NSString*const SafariTechnologyPreviewBundleID = @"com.apple.SafariTechnologyPreview";

@implementation JJApplicationDelegate {
	BOOL _didOpenURLs;
	NSUInteger _urlCount;
	NSWindow* _licenseWindow;
	NSWindow* _mainWindow;
}

#pragma mark Private

-(void)terminateIfNecessary {
	if (_urlCount > 0)
		return;
	
	NSArray<NSWindow*>* windows = [NSApp windows];
	for (NSWindow* window in windows) {
		if ([window isVisible])
			return; // Don't terminate if there are visible windows
	}
	[NSApp terminate:nil];
}

#pragma mark NSApplicationDelegate

-(void)applicationWillFinishLaunching:(nonnull NSNotification *)notification {
	JJApplicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	if (JJApplicationName == nil) {
		NSLog(@"CFBundleName nil!");
		JJApplicationName = @PRODUCT_NAME;
	}
	[JJMainMenu populateMainMenu];
}

-(void)applicationDidFinishLaunching:(nonnull NSNotification*)notification {
	if (_didOpenURLs)
		return;
	
	[self openMainWindow:nil];
}

-(void)applicationDidResignActive:(nonnull NSNotification*)notification {
	[self terminateIfNecessary];
}

-(void)application:(nonnull NSApplication*)application openURLs:(nonnull NSArray<NSURL*>*)urls {
	NSDictionary* options = @{(__bridge NSString*)kAXTrustedCheckOptionPrompt: @YES};
	if (!AXIsProcessTrustedWithOptions((CFDictionaryRef)options))
		return;
	
	_didOpenURLs = YES;
	
	BOOL useSafariTechnologyPreview = [[NSUserDefaults standardUserDefaults] boolForKey:UseSafariTechnologyPreviewSetting];
	NSString* bundleID = useSafariTechnologyPreview ? SafariTechnologyPreviewBundleID : SafariBundleID;
	NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
	NSURL* safariURL = [workspace URLForApplicationWithBundleIdentifier:bundleID];
	if (safariURL == nil) {
		NSAlert* alert = [[NSAlert alloc] init];
		[alert setMessageText:@"URL Opening Error"];
		NSString* informativeText = useSafariTechnologyPreview ? @"Safari Technology Preview cannot be found." : @"Safari cannot be found.";
		[alert setInformativeText:informativeText];
		[alert runModal];
		return;
	}
	
	NSUInteger count = [urls count];
	_urlCount += count;
	BOOL isActive = [NSApp isActive];
	NSWorkspaceOpenConfiguration* configuration1 = [NSWorkspaceOpenConfiguration configuration];
	[configuration1 setActivates:isActive];
	[workspace openApplicationAtURL:safariURL configuration:configuration1 completionHandler:^(NSRunningApplication * _Nullable app1, NSError * _Nullable error1) {
		if (app1 == nil) {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSAlert* alert = [[NSAlert alloc] init];
				[alert setMessageText:@"URL Opening Error"];
				if (error1 != nil) {
					[alert setInformativeText:[error1 localizedDescription]];
				} else {
					NSString* informativeText = useSafariTechnologyPreview ? @"Safari Technology Preview cannot be opened." : @"Safari cannot be opened.";
					[alert setInformativeText:informativeText];
				}
				[alert runModal];
				_urlCount -= count;
			});
		} else {
			NSString* formatString =
			@"tell application \"System Events\"\n\
			tell application process \"%@\"\n\
			repeat while (count menu bars) = 0\n\
			delay 0.1\n\
			end repeat\n\
			end tell\n\
			local restoreold\n\
			set oldapp to first process whose frontmost is true\n\
			tell application process \"%@\"\n\
			set restoreold to not frontmost\n\
			if (restoreold) then\n\
			set frontmost to true\n\
			end if\n\
			click menu item %@ of menu 1 of menu bar item 3 of menu bar 1\n\
			end tell\n\
			if (restoreold) then\n\
			try\n\
			set frontmost of oldapp to true\n\
			end try\n\
			end if\n\
			end tell";
			NSString* menuItem = [@PRODUCT_NAME isEqualToString:@"PrivateWindow"] ? @"2" : @"1";
			NSString* safari = useSafariTechnologyPreview ? @"Safari Technology Preview" : @"Safari";
			NSString* source = [NSString stringWithFormat:formatString, safari, safari, menuItem];
			NSAppleScript* script = [[NSAppleScript alloc] initWithSource:source];
			NSDictionary* errorInfo = nil;
			NSAppleEventDescriptor* descriptor = [script executeAndReturnError:&errorInfo];
			if (descriptor == nil) {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSAlert* alert = [[NSAlert alloc] init];
					[alert setMessageText:@"URL Opening Error"];
					NSString* scriptError = errorInfo[NSAppleScriptErrorMessage];
					if (scriptError != nil) {
						[alert setInformativeText:scriptError];
					} else {
						NSString* informativeText = useSafariTechnologyPreview ? @"System Events could not send keystrokes to Safari Technology Preview." : @"System Events could not send keystrokes to Safari.";
						[alert setInformativeText:informativeText];
					}
					[alert runModal];
					_urlCount -= count;
				});
			} else {
				NSWorkspaceOpenConfiguration* configuration2 = [NSWorkspaceOpenConfiguration configuration];
				[configuration2 setActivates:isActive];
				[[NSWorkspace sharedWorkspace] openURLs:urls withApplicationAtURL:safariURL configuration:configuration2 completionHandler:^(NSRunningApplication * _Nullable app2, NSError * _Nullable error2) {
					dispatch_async(dispatch_get_main_queue(), ^{
						if (error2 != nil) {
							NSAlert* alert = [[NSAlert alloc] init];
							[alert setMessageText:@"URL Opening Error"];
							[alert setInformativeText:[error2 localizedDescription]];
							[alert runModal];
							_urlCount -= count;
						} else {
							_urlCount -= count;
							[self terminateIfNecessary];
						}
					});
				}];
			}
		}
	}];
}

#pragma mark JJApplicationDelegate

-(void)windowWillClose:(nonnull NSNotification*)notification {
	id object = [notification object];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:[notification name] object:object];
	if (object == _licenseWindow)
		_licenseWindow = nil;
	else if (object == _mainWindow)
		_mainWindow = nil;
}

-(void)openLicense:(nullable id)sender {
	if (_licenseWindow != nil) {
		[_licenseWindow makeKeyAndOrderFront:self];
	} else {
		_licenseWindow = [JJLicenseWindow window];
		if (_licenseWindow != nil)
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:_licenseWindow];
	}
}

-(void)openMainWindow:(nullable id)sender {
	if (_mainWindow != nil) {
		[_mainWindow makeKeyAndOrderFront:self];
	} else {
		_mainWindow = [JJMainWindow window];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:_mainWindow];
	}
}

-(void)openWebSite:(nullable id)sender {
	NSURL* url = [NSURL URLWithString:@"https://github.com/lapcat/PrivateWindow"];
	if (url != nil)
		[[NSWorkspace sharedWorkspace] openURL:url];
	else
		NSLog(@"Support URL nil!");
}

@end
