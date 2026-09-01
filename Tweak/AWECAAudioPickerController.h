// 合成与本地面板
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import <UIKit/UIKit.h>

@interface AWECAAudioPickerController : UIViewController <UIDocumentPickerDelegate>

+ (instancetype)shared;

@property (nonatomic, assign) BOOL embeddedInCommentTab;

- (void)showPickerFromViewController:(UIViewController *)vc;

@end
