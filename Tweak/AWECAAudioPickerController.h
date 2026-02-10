// 音频选择面板，收藏/导入/浏览一把梭
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import <UIKit/UIKit.h>

@interface AWECAAudioPickerController : UITableViewController <UIDocumentPickerDelegate>

+ (instancetype)shared;

// 弹出选择面板，套个 nav 包一下
- (void)showPickerFromViewController:(UIViewController *)vc;

@end
