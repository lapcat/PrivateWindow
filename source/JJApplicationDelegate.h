@import Cocoa;

@interface JJApplicationDelegate:NSObject<NSApplicationDelegate>
-(void)openLicense:(nullable id)sender;
-(void)openMainWindow:(nullable id)sender;
-(void)openWebSite:(nullable id)sender;
@end

extern NSString*_Null_unspecified JJApplicationName;
extern NSString*_Nonnull const UseSafariMenuItemSetting;
extern NSString*_Nonnull const UseSafariTechnologyPreviewSetting;
extern NSString*_Nonnull const SafariBundleID;
extern NSString*_Nonnull const SafariTechnologyPreviewBundleID;
