// 音频选择面板，收藏/左滑/目录/关于全在这
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import "AWECAAudioPickerController.h"
#import "AWECADownloadManager.h"
#import "AWECAAudioReplacer.h"
#import "AWECAUtils.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#define kAWECAFavoriteAudios @"AWECAFavoriteAudios"
#define kCellFont [UIFont systemFontOfSize:15]

// SF 图标配置，小号就完事了
#define kSmallIconConfig [UIImageSymbolConfiguration configurationWithPointSize:13 weight:UIImageSymbolWeightRegular]

typedef NS_ENUM(NSInteger, AWECAPickerSection) {
    AWECAPickerSectionFavorites = 0,
    AWECAPickerSectionActions,
    AWECAPickerSectionCount
};

// GitHub 图标 base64 (40x40 圆形，Pillow 裁剪)
static NSString *const kGitHubIconB64 = @"iVBORw0KGgoAAAANSUhEUgAAACgAAAAoCAMAAAC7IEhfAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyhpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDcuMi1jMDAwIDc5LjFiNjVhNzliNCwgMjAyMi8wNi8xMy0yMjowMTowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIzLjUgKE1hY2ludG9zaCkiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6RjY3RkY3MDNGRUU2MTFGMDlERTlEQTVCNjc3OTQ0QkQiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6RjY3RkY3MDRGRUU2MTFGMDlERTlEQTVCNjc3OTQ0QkQiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpGNjdGRjcwMUZFRTYxMUYwOURFOURBNUI2Nzc5NDRCRCIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpGNjdGRjcwMkZFRTYxMUYwOURFOURBNUI2Nzc5NDRCRCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PqHg8+cAAAITUExURf///wAAAPb29vf39/39/ezs7Pn5+fj4+P7+/u/v7wICAvT09AEBAfz8/PX19fDw8PLy8vPz8/r6+vv7++7u7uvr6/Hx8QMDAwgICO3t7QcHBwYGBgQEBOrq6g0NDQwMDBAQEBcXFxYWFgUFBfz7/BkZGRoaGhMTEw4ODunp6Q8PD0NDQz4+PjY2NigoKAkJCRISEvv6+2RkZJOTkxgYGKioqEdHRxQUFAsLC11dXR0dHS0tLWpqakhISOXl5ebm5n5+fhsbG1xcXJubm46Ojqurq0JCQjExMTg4OOfn50BAQDQ0NISEhDk5OR8fHyQkJCcnJxUVFR4eHvTz9OHh4cDAwP38/QoKCisrK4eHh4WFhZmZmeLi4szMzFFRUdzc3Nvb25+fnzo6Os3NzdTU1MjIyBwcHK+vr1tbW8PDw/Dv8EZGRtXV1bu7u8/Pz2dnZ5qamgkICf/+//n4+SAgIFNTU729vcbGxqKioj09PTU1NVRUVJ6eniIiItra2mVlZREREUxMTIODg8nJyYqKijMzM09PT0tLS7S0tI+PjyYmJrq6utLS0lVVVZaWll5eXoCAgE5OTpGRkW5ubjc3N8XFxUFBQSkpKa6urmhoaHBwcOzr7NnZ2aOjo9/f35iYmLy8vFlZWZeXl1dXV3d3d0VFRZSUlL6+vpCQkFBQUFpZWtPT0+Pj46WlpURERDIyMv///wBA+pMAAACxdFJOU///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////ANf0XGQAAAOcSURBVHjadJUFe+NIDIYle0xxHGPsMGO5u6Ut95aZmfGYmZn3mJlv9/h+4mmcZhu3ve95MpmMXksezUiBf3sFqsqYQWJMVSFq6p2v0bogrKu1YI+RsXVIiGLynSfv2Lb71V0/7LkhRlHoboJeHrRTn+EtPbsoQWd9BQTaK4U73eBAPBSfNW/y12AdMhxCTv6dbDEu4mgMCP7ADskuGHLmjg4WQvQVC2IB4ol2lySQpsdA2YsxHjcXcGexIMjx6Dkc0oGyDyHIajUVNmG8+vHsCezRW7MT1Ti+Dmqtxjj40OjoMRinuLgVxPH9uL//0ad/GcLGRQs+4avfQW10FAhkjgzCIxQluExJSx+VeO7Mo2doPN/ELI6kQXYYZdqQXdiI8SwGV0FWOGUYfBRluFDGag4XwSUEVHLoDGI2G+BmkCOCN+j5DB6QyaUKjLyczWEmFW/coyoRqX/O0HoMHwNFZmAoIkXOpbL4I4iKGBHcG4+lMvg+KA8bBDrwBT2I9XkQxFWgMIOpFP4EruLSR4XfMDWMAzKIQlQA74QWB0SHQHDuxuNT2K+sAfk5DE/hbi8ERZAnsFjEvfZaj+w1nCriYJqDjqiq57BQCA59C4nVoDaIrQL2i4x7FBSYxUJfkU7QTkRkw+W+bF8LbwNBcKFGv3/FQqmEcwCW3iPLgI+wRYY9tE7pOWzB1VKxWcjgm0Ra9rIsC+D2QnFkpJX6HizbAHbYYvquWP1ABYOT/Kht37J8i5/2xXrm4ORkfIflWjZVSoJWN2Lq3fYGxE8/fPy+tO77unn95c3nisfLlYMVfAl8P0HFKPsm82bwqSvwHr/k9wsJAp3FB7OZF8bKlbHq0IJh+grdR8M3Tfgrhk3JGaB7/TZopqnB2cpweaxcrlfwAVrwDV4KgqkJ8DziBlC2/Dyu2SYJ8n+3GvX60jXKTUIzxbBmDEtLg70NJz/nO9DzGknNz5WWlqan45c8SGuW0SlXRSMy2Y+NL5/4Zst5OQR3ToxM77uGlxYgaWpKtwEInLRo132ZQ1cgBOfnmvtKuU0SUADhVqdguudRTT2zHXHoD1XzPA+OPFmtbj8N0PY0na00KU4mdVh4ZXDgOTlNoLzzxX9OHQG7nfY6XLftMV2SpLwB819LeZpJSfPCGXDbNFvmVhqpaHK76OSTIZh0FD7jiVndml3dk1bJ0911m72bCL0u66u7Eu7//CtQAzQcmdeDqMgui5r+E2AAhK01mb73SvMAAAAASUVORK5CYII=";

// Telegram 图标 base64 (40x40 圆形，Pillow 裁剪)
static NSString *const kTelegramIconB64 = @"iVBORw0KGgoAAAANSUhEUgAAACgAAAAoCAMAAAC7IEhfAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyhpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDcuMi1jMDAwIDc5LjFiNjVhNzliNCwgMjAyMi8wNi8xMy0yMjowMTowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIzLjUgKE1hY2ludG9zaCkiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6RjY3RkY3MDdGRUU2MTFGMDlERTlEQTVCNjc3OTQ0QkQiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6RjY3RkY3MDhGRUU2MTFGMDlERTlEQTVCNjc3OTQ0QkQiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpGNjdGRjcwNUZFRTYxMUYwOURFOURBNUI2Nzc5NDRCRCIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpGNjdGRjcwNkZFRTYxMUYwOURFOURBNUI2Nzc5NDRCRCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pk7UFeIAAAMAUExURfbu6/z5+VS95QCv5tTq9BnJ9qTa7Sms4v/++hyZ1iKb3OT7/BSa2PT09GjD6Pj4+A2T2luz4Zfl+P7x7BOX1TjH8t3m6wCb37rj8p3J4ZDC3+nq6haW1A+X1e/u7gCx7xet5h6W1vf29hub2wCf3ezq6jXV90Ko3A2Y1u7s6xOZ1gCr5PTz8gCZ3NXe5Cii183c5QCz76nN4Qab2Bay5e38/QCu5gCn4ACN1PDw8LHi8+3s65bW7ACH0P/17gCu7uzs7AC68//59vr9/eL1+gCk3+fw8w3L9Ta15PX8/u3w8vn29QCt6QCy6HzM63LM6wqZ1gCg4fv5+P/8+7TW5zKs3QPE9ACg3ACs5Hq83q/f8gCp6VTB5gCn5QCo4cXh7QGZ2f/68gaZ1hWl3MPW4rzU4gGc2RiW1ACR1gCq49vi5/Py8QCW1vLx8ACu5cTq9u3v8P///FfZ+fj49w2Z1xqV1QGT2QCz6gyr4nbn+cHc6ReV2ITK6QCd2gqb2ACEzwCc2xSe4eLq7vr6+KTq+dTv9wCx6QCV3IHQ7fz7+wCo4gai3Zza8eXr7Q6c2VHE6gCi5P3//2ji+e/v7wCi3QaR2gCQ0hSV2ACw7ACk4/b08wad2QCs5wCm4gCm6AGl3/////39/f7+/vz8/Pv7+////gCj3vr6+vv6+/v7+gid2xiV1BmV1//+/v/+/+709QCP2+Dl6K7q+Cqx5V7d+Ofo6ByW1ovL5jqs4ero6CLC8SrW9/v7/Ai988Lx++7t7Ra777jv+r7p9ff19PX19XrS7sLZ5Uuy3j2l3Umq30K55f78/VzO7/r08v739ACr7E/A6NTg5tr5/ALI9V3D7dDx+NT5++Dx9Nn3/fDx8oK+3qHh8un3+Kvg8qnx/O7u7Nvu8wSm4AaR1AiW1njC42Ky3QmY3hTP9gyY3RmY1vj39wKe3IHA4Oj09gCh4QB+z//9/SS25Qmi5SC77im+7GPK8Pv6+XK54C2h3WXY9eHo6wqz6ebo6uXs7/n5+f///x30GnYAAAEAdFJOU////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////wBT9wclAAAEcElEQVR42mL4jwwWLFq0cOFiIFi4cNGiBShSDMjKMABWhQuwAkyFcKmlntzcpksxVDKgKFtqem+S2nN3d1a1LUI3ClGUMsA8AXT8gkuT3B0NDeXBwDGsaF/hgkVrYZ5igHl20YLCysuG8jPaysHAtw2otoh7KVwlWCEwTBYu5VZztG8DqfAFAyBrhjzrwcIPwJCCKQSru/Zc3gcozwwHILX2ji2Fpz+AVQIVLli48HQh93N7s3JmNODra++4qXDP6YULwAoXdnZ+4Nht7+PLnGeWl5dnxsxsBqKBgJm57fzeqxydnQtBCtetWNHJUWk4hzkPCwCqFG1e2bliHVDhwuX/Cl3C5pihq5kZmMkMMt5HKHjlt4X/GRYs/sfIscVeOy9CWzsTCrS154qrfOw36dKOyGOO3vX2H2PnAoZFS/5x3AmLngNXBQSBug8vWC1dcFQXyDabM+M2Y9CKRQwLl/NztBjGasfBwFxdXYUOF1Dc+esCudpz5p1R+vdtIcPioGKOn9FdceYgEBc3pb3h1N2FkEju1wUJac/78uBV0GKGxfxOTqLzuszN5wNFxcu6+fKBSkxjrq5bsMCjYT5QsCv2t4RSUCfDEn6n9btmms93NV+WU8buB7YzKi3Gc8FE54ra+fNd55vH+rAdASksdrp+YMJ8V1eVBA+2RROByiby1fsBk9KC1lqVZUAwf+Ycm+xXYBOBCl2nqOQcgrgsX/l9D0j9grtlU0DA1TXa5uarlQzLi53cPr+bEq7SwCfhPHHBUn/beiuIjg6LcBBY9i7T5qb3CoYlSufOigaGq4SHZ2QkM/Gx2wZATV7AZKECBOFTAivYvLw7GTqPzEr8Kq6iUltb25BjYVFmEQPLLaEZQLFalSnim+O9DgOD54hOYs+E2tdpUJDwuAaizjk5A8R/3S3OJHZz1kKGhbzZ51gUxFcZQ8HsnPrQ1rUgT+fkgLirXgdub8rWWciw4Eiuzrkrun11ATCQZDsNaOjSKNskIKeuT5e96q/OkQUM///l5p6L/5TQV1KiAQUl0+rVW52P2wJZJX194k/ECrL5gelxca5lth1fuxaPliwcaNg+1p+mISurxcPTvuNYU27uYlBWULK0tOtlb3/JoyWCAI8sRIBcHuXHjZJiBbmvwHlmcfbkyXZVjWWcL2XQwEvOF8/eXOzNzV4Mya78k4EqQxozOF+mp69OTwcTQPTyJafAi0gDMUtLflgBoDR5spxwyI8N1YrbtpXCgCLny6nKtwzE5CyV4CXFwiNycvuFDQQFplYrwsFLAQF1ST2x/ZOPLEQUUgt55fY7MGhKnlSeKjC9es2aNdMFBJRPRKZk/dp/n3chcrG3kNfBer81w0aj7yd/cAHBD/WnUql6G6X3a0LVIQrSV5YO+zVVNXfqpRpJSkoapehlbZTW3G/5CrNoXsIrB1RqraoqvXPr1q1/pFU198vxLsFa2C85YulgrQkEQMLa2tryyBIctQKwAFy8/B//KyUl/n/LlyxErT4AAgwAriZHpO3crJEAAAAASUVORK5CYII=";

@interface AWECAPluginDirBrowserController : UITableViewController
@property (nonatomic, copy) NSString *directoryPath;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *items;
@end

@interface AWECAAudioPickerController ()
@property (nonatomic, strong) NSMutableArray<NSString *> *favorites;
@end

@implementation AWECAAudioPickerController

+ (instancetype)shared {
    return [[AWECAAudioPickerController alloc] initWithStyle:UITableViewStyleInsetGrouped];
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) { [self loadFavorites]; }
    return self;
}

+ (UIImage *)imageFromBase64:(NSString *)b64 size:(CGFloat)sz {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:b64 options:0];
    UIImage *img = [UIImage imageWithData:data];
    if (!img) return nil;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(sz, sz), NO, 0);
    [img drawInRect:CGRectMake(0, 0, sz, sz)];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [result imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

#pragma mark - 弹面板

- (void)showPickerFromViewController:(UIViewController *)vc {
    if (!vc) vc = [AWECAUtils topViewController];
    if (!vc) return;
    AWECAAudioPickerController *picker = [AWECAAudioPickerController shared];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = nav.sheetPresentationController;
        if (sheet) {
            sheet.detents = @[UISheetPresentationControllerDetent.mediumDetent,
                              UISheetPresentationControllerDetent.largeDetent];
            sheet.prefersGrabberVisible = YES;
        }
    }
    [vc presentViewController:nav animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 顶部显示当前替换状态
    AWECAAudioReplacer *replacer = [AWECAAudioReplacer shared];
    if (replacer.enabled && replacer.replacementAudioPath) {
        double dur = [AWECAUtils audioDurationAtPath:replacer.replacementAudioPath];
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = [NSString stringWithFormat:@"当前: %@ (%.0f秒)", replacer.replacementAudioPath.lastPathComponent, dur];
        titleLabel.font = [UIFont systemFontOfSize:13];
        titleLabel.textColor = [UIColor secondaryLabelColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [titleLabel sizeToFit];
        self.navigationItem.titleView = titleLabel;
    }
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
}

- (void)loadFavorites {
    NSArray *saved = [[NSUserDefaults standardUserDefaults] arrayForKey:kAWECAFavoriteAudios];
    self.favorites = saved ? [saved mutableCopy] : [NSMutableArray array];
    NSMutableArray *bad = [NSMutableArray array];
    for (NSString *p in self.favorites)
        if (![[NSFileManager defaultManager] fileExistsAtPath:p]) [bad addObject:p];
    if (bad.count > 0) { [self.favorites removeObjectsInArray:bad]; [self saveFavorites]; }
}

- (void)saveFavorites {
    [[NSUserDefaults standardUserDefaults] setObject:[self.favorites copy] forKey:kAWECAFavoriteAudios];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - 帮助弹窗

- (NSString *)helpTextForActionIndex:(NSInteger)idx {
    switch (idx) {
        case 0: return @"1. 从插件目录中选择音频文件\n2. 添加到收藏列表后可快速切换\n3. 左滑收藏项可移除";
        case 1: return @"1. 从本机文件中选择音频或 zip\n2. 支持多选导入\n3. zip 会自动解压到目标目录";
        case 2: return @"1. 浏览插件沙盒目录的文件和文件夹\n2. 仅显示 .m4a 文件\n3. 点击文件夹可进入子目录";
        default: return @"";
    }
}

- (void)showHelpForIndex:(NSInteger)idx {
    NSArray *names = @[@"添加收藏", @"本机导入", @"插件目录"];
    NSString *title = (idx < (NSInteger)names.count) ? names[idx] : @"";
    NSString *text = [self helpTextForActionIndex:idx];
    UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:text preferredStyle:UIAlertControllerStyleAlert];
    if (text.length > 0) {
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        ps.alignment = NSTextAlignmentLeft;
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:text
            attributes:@{NSParagraphStyleAttributeName: ps, NSFontAttributeName: [UIFont systemFontOfSize:13]}];
        [a setValue:as forKey:@"attributedMessage"];
    }
    [a addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

#pragma mark - 关于作者

- (void)showAboutDialog {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"关于作者" message:nil preferredStyle:UIAlertControllerStyleAlert];

    // 自定义 VC 手搓布局
    UIViewController *contentVC = [[UIViewController alloc] init];
    UIView *container = contentVC.view;

    UIImage *ghIcon = [AWECAAudioPickerController imageFromBase64:kGitHubIconB64 size:20];
    UIImage *tgIcon = [AWECAAudioPickerController imageFromBase64:kTelegramIconB64 size:20];

    // GitHub 按钮
    UIButton *ghBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImageView *ghIV = [[UIImageView alloc] initWithImage:ghIcon];
    ghIV.frame = CGRectMake(0, 0, 20, 20);
    ghIV.contentMode = UIViewContentModeScaleAspectFit;
    UILabel *ghLbl = [[UILabel alloc] init];
    ghLbl.text = @" @cookieodd";
    ghLbl.font = [UIFont systemFontOfSize:15];
    ghLbl.textColor = [UIColor systemBlueColor];
    [ghLbl sizeToFit];
    ghIV.frame = CGRectMake(0, 2, 20, 20);
    ghLbl.frame = CGRectMake(24, 0, ghLbl.frame.size.width, 24);
    [ghBtn addSubview:ghIV];
    [ghBtn addSubview:ghLbl];
    CGFloat ghW = 24 + ghLbl.frame.size.width;
    ghBtn.frame = CGRectMake(0, 8, ghW, 24);
    [ghBtn addTarget:self action:@selector(openGitHub) forControlEvents:UIControlEventTouchUpInside];

    // Telegram 按钮
    UIButton *tgBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImageView *tgIV = [[UIImageView alloc] initWithImage:tgIcon];
    tgIV.frame = CGRectMake(0, 2, 20, 20);
    tgIV.contentMode = UIViewContentModeScaleAspectFit;
    UILabel *tgLbl = [[UILabel alloc] init];
    tgLbl.text = @" @cookieodd";
    tgLbl.font = [UIFont systemFontOfSize:15];
    tgLbl.textColor = [UIColor systemBlueColor];
    [tgLbl sizeToFit];
    tgLbl.frame = CGRectMake(24, 0, tgLbl.frame.size.width, 24);
    [tgBtn addSubview:tgIV];
    [tgBtn addSubview:tgLbl];
    CGFloat tgW = 24 + tgLbl.frame.size.width;
    tgBtn.frame = CGRectMake(0, 40, tgW, 24);
    [tgBtn addTarget:self action:@selector(openTelegram) forControlEvents:UIControlEventTouchUpInside];

    // 居个中
    CGFloat maxW = MAX(ghW, tgW);
    ghBtn.frame = CGRectMake((maxW - ghW) / 2, 8, ghW, 24);
    tgBtn.frame = CGRectMake((maxW - tgW) / 2, 40, tgW, 24);
    [container addSubview:ghBtn];
    [container addSubview:tgBtn];

    contentVC.preferredContentSize = CGSizeMake(maxW, 92);
    [a setValue:contentVC forKey:@"contentViewController"];

    [a addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)openGitHub {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/cookieodd"] options:@{} completionHandler:nil];
}

- (void)openTelegram {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/cookieodd"] options:@{} completionHandler:nil];
}

#pragma mark - 操作行

// 操作列表，有替换就多个关闭按钮
- (NSArray<NSString *> *)actionTitles {
    NSMutableArray *t = [NSMutableArray arrayWithArray:@[@"添加收藏", @"本机导入", @"插件目录", @"关于作者"]];
    if ([AWECAAudioReplacer shared].enabled) [t addObject:@"关闭替换"];
    return t;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return AWECAPickerSectionCount; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == AWECAPickerSectionFavorites) return self.favorites.count;
    if (section == AWECAPickerSectionActions) return [self actionTitles].count;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == AWECAPickerSectionFavorites) return self.favorites.count > 0 ? @"收藏音频" : nil;
    if (section == AWECAPickerSectionActions) return @"操作";
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == AWECAPickerSectionFavorites && self.favorites.count == 0) {
        UILabel *lbl = [[UILabel alloc] init];
        lbl.text = @"暂无收藏音频，可通过下方操作添加";
        lbl.font = [UIFont systemFontOfSize:13];
        lbl.textColor = [UIColor secondaryLabelColor];
        lbl.textAlignment = NSTextAlignmentCenter;
        return lbl;
    }
    return nil;
}

// 间距压一压，紧凑点好看
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == AWECAPickerSectionFavorites && self.favorites.count == 0) return CGFLOAT_MIN;
    return 28;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == AWECAPickerSectionFavorites && self.favorites.count == 0) return 20;
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.textLabel.textColor = nil;
    cell.imageView.image = nil;
    cell.textLabel.font = kCellFont;
    for (UIView *v in cell.contentView.subviews) if (v.tag == 8888) [v removeFromSuperview];

    if (indexPath.section == AWECAPickerSectionFavorites) {
        NSString *path = self.favorites[indexPath.row];
        double dur = [AWECAUtils audioDurationAtPath:path];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%.0f秒)", path.lastPathComponent, dur];
        if ([AWECAAudioReplacer shared].enabled &&
            [path isEqualToString:[AWECAAudioReplacer shared].replacementAudioPath]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else if (indexPath.section == AWECAPickerSectionActions) {
        NSArray *titles = [self actionTitles];
        NSString *title = titles[indexPath.row];
        cell.textLabel.textColor = [UIColor systemBlueColor];

        // 图标 + 文字的统一排版
        NSString *iconName = @"info.circle";
        if ([title isEqualToString:@"关于作者"]) iconName = @"person.circle";
        else if ([title isEqualToString:@"关闭替换"]) iconName = @"xmark.circle";

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.tag = 8888;
        UIImage *iconImg = [UIImage systemImageNamed:iconName withConfiguration:kSmallIconConfig];
        [btn setImage:iconImg forState:UIControlStateNormal];
        btn.frame = CGRectMake(16, 0, 20, 44);
        btn.accessibilityHint = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
        [btn addTarget:self action:@selector(actionIconTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:btn];
        cell.textLabel.text = [NSString stringWithFormat:@"      %@", title];

        if ([title isEqualToString:@"关闭替换"]) {
            cell.textLabel.textColor = [UIColor systemRedColor];
            btn.tintColor = [UIColor systemRedColor];
        }
    }
    return cell;
}

- (void)actionIconTapped:(UIButton *)sender {
    NSInteger idx = [sender.accessibilityHint integerValue];
    NSArray *titles = [self actionTitles];
    if (idx >= (NSInteger)titles.count) return;
    NSString *t = titles[idx];
    // 前3个点图标弹说明，后面的直接触发
    if (idx < 3) {
        [self showHelpForIndex:idx];
    } else if ([t isEqualToString:@"关于作者"]) {
        [self showAboutDialog];
    } else if ([t isEqualToString:@"关闭替换"]) {
        [[AWECAAudioReplacer shared] clearReplacement];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == AWECAPickerSectionFavorites) {
        [self selectAudioAtPath:self.favorites[indexPath.row]];
    } else if (indexPath.section == AWECAPickerSectionActions) {
        NSString *t = [self actionTitles][indexPath.row];
        if ([t isEqualToString:@"添加收藏"]) [self showAddFavoriteOptions];
        else if ([t isEqualToString:@"本机导入"]) [self showDocumentPicker];
        else if ([t isEqualToString:@"插件目录"]) [self pushPluginDirBrowser];
        else if ([t isEqualToString:@"关于作者"]) [self showAboutDialog];
        else if ([t isEqualToString:@"关闭替换"]) {
            [[AWECAAudioReplacer shared] clearReplacement];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == AWECAPickerSectionFavorites;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == AWECAPickerSectionFavorites) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)s forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (s == UITableViewCellEditingStyleDelete && indexPath.section == AWECAPickerSectionFavorites) {
        [self.favorites removeObjectAtIndex:indexPath.row];
        [self saveFavorites];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath { return @"移除"; }
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath { return indexPath.section == AWECAPickerSectionFavorites; }
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)s toIndexPath:(NSIndexPath *)d {
    if (s.section != AWECAPickerSectionFavorites || d.section != AWECAPickerSectionFavorites) return;
    NSString *item = self.favorites[s.row];
    [self.favorites removeObjectAtIndex:s.row];
    [self.favorites insertObject:item atIndex:d.row];
    [self saveFavorites];
}
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)s toProposedIndexPath:(NSIndexPath *)d {
    if (d.section != AWECAPickerSectionFavorites)
        return [NSIndexPath indexPathForRow:(s.row < (NSInteger)self.favorites.count - 1 ? self.favorites.count - 1 : 0) inSection:AWECAPickerSectionFavorites];
    return d;
}

#pragma mark - 选音频

- (void)selectAudioAtPath:(NSString *)path {
    [[AWECAAudioReplacer shared] setReplacementFromPath:path completion:^(BOOL success) {
        if (success) {
            double dur = [AWECAUtils audioDurationAtPath:path];
            [AWECAUtils showToast:[NSString stringWithFormat:@"已选择 (%.0f秒)", dur]];
        }
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 收藏

- (void)showAddFavoriteOptions {
    NSString *dir = [AWECAUtils audioSavePath];
    NSArray *files = [self scanM4aFilesInDirectory:dir];
    if (files.count == 0) { [AWECAUtils showToast:@"插件目录下没有 .m4a 文件"]; return; }

    UIAlertController *s = [UIAlertController alertControllerWithTitle:@"选择要收藏的音频" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *p in files) {
        if ([self.favorites containsObject:p]) continue;
        double dur = [AWECAUtils audioDurationAtPath:p];
        [s addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ (%.0f秒)", p.lastPathComponent, dur]
            style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self.favorites addObject:p]; [self saveFavorites]; [self.tableView reloadData];
            [AWECAUtils showToast:[NSString stringWithFormat:@"已收藏 %@", p.lastPathComponent]];
        }]];
    }
    [s addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    if (s.popoverPresentationController) {
        s.popoverPresentationController.sourceView = self.view;
        s.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0, 0);
    }
    [self presentViewController:s animated:YES completion:nil];
}

- (NSArray<NSString *> *)scanM4aFilesInDirectory:(NSString *)dir {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray *r = [NSMutableArray array];
    NSDirectoryEnumerator *e = [fm enumeratorAtPath:dir];
    NSString *f;
    while ((f = [e nextObject]))
        if ([f.pathExtension.lowercaseString isEqualToString:@"m4a"]) [r addObject:[dir stringByAppendingPathComponent:f]];
    [r sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        return [[fm attributesOfItemAtPath:b error:nil][NSFileModificationDate] compare:[fm attributesOfItemAtPath:a error:nil][NSFileModificationDate]];
    }];
    return r;
}

#pragma mark - 导入

- (void)showDocumentPicker {
    NSArray *types = @[[UTType typeWithIdentifier:@"public.audio"], [UTType typeWithIdentifier:@"com.pkware.zip-archive"]];
    UIDocumentPickerViewController *p = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:types asCopy:YES];
    p.delegate = self; p.allowsMultipleSelection = YES;
    [self presentViewController:p animated:YES completion:nil];
}
- (void)documentPicker:(UIDocumentPickerViewController *)c didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count == 0) return; [self showImportFolderPickerForURLs:urls];
}
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)c {}

- (void)showImportFolderPickerForURLs:(NSArray<NSURL *> *)urls {
    NSString *base = [AWECAUtils audioSavePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *contents = [fm contentsOfDirectoryAtPath:base error:nil];
    NSMutableArray *folders = [NSMutableArray array];
    for (NSString *item in contents) {
        BOOL d = NO; if ([fm fileExistsAtPath:[base stringByAppendingPathComponent:item] isDirectory:&d] && d) [folders addObject:item];
    }
    UIAlertController *pk = [UIAlertController alertControllerWithTitle:@"选择导入位置" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [pk addAction:[UIAlertAction actionWithTitle:@"默认目录" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) { [self importURLs:urls toDirectory:base]; }]];
    for (NSString *fo in folders) {
        [pk addAction:[UIAlertAction actionWithTitle:fo style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) { [self importURLs:urls toDirectory:[base stringByAppendingPathComponent:fo]]; }]];
    }
    [pk addAction:[UIAlertAction actionWithTitle:@"新建文件夹" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        UIAlertController *al = [UIAlertController alertControllerWithTitle:@"新建文件夹" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [al addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"文件夹名称"; }];
        [al addAction:[UIAlertAction actionWithTitle:@"创建" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a2) {
            NSString *n = al.textFields.firstObject.text;
            if (!n.length) { [AWECAUtils showToast:@"文件夹名不能为空"]; return; }
            NSString *nd = [base stringByAppendingPathComponent:n];
            [fm createDirectoryAtPath:nd withIntermediateDirectories:YES attributes:nil error:nil];
            [self importURLs:urls toDirectory:nd];
        }]];
        [al addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:al animated:YES completion:nil];
    }]];
    [pk addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    if (pk.popoverPresentationController) { pk.popoverPresentationController.sourceView = self.view; pk.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0, 0); }
    [self presentViewController:pk animated:YES completion:nil];
}

- (void)importURLs:(NSArray<NSURL *> *)urls toDirectory:(NSString *)dest {
    [[NSFileManager defaultManager] createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:nil];
    NSInteger ic = 0, zc = 0;
    for (NSURL *url in urls) {
        BOOL ac = [url startAccessingSecurityScopedResource];
        if ([url.pathExtension.lowercaseString isEqualToString:@"zip"]) {
            NSError *e = nil;
            if ([AWECAUtils extractZipAtPath:url.path toDirectory:dest error:&e]) zc++;
        } else {
            NSString *dp = [dest stringByAppendingPathComponent:url.lastPathComponent];
            if ([[NSFileManager defaultManager] fileExistsAtPath:dp]) {
                dp = [dest stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%.0f.%@",
                    [url.lastPathComponent stringByDeletingPathExtension], [[NSDate date] timeIntervalSince1970], url.lastPathComponent.pathExtension]];
            }
            NSError *e = nil;
            if ([[NSFileManager defaultManager] copyItemAtURL:url toURL:[NSURL fileURLWithPath:dp] error:&e]) ic++;
        }
        if (ac) [url stopAccessingSecurityScopedResource];
    }
    NSString *msg = @"导入失败";
    if (ic > 0 && zc > 0) msg = [NSString stringWithFormat:@"导入 %ld 个文件，解压 %ld 个 zip", (long)ic, (long)zc];
    else if (ic > 0) msg = [NSString stringWithFormat:@"已导入 %ld 个文件", (long)ic];
    else if (zc > 0) msg = [NSString stringWithFormat:@"已解压 %ld 个 zip", (long)zc];
    [AWECAUtils showToast:msg];
    [self.tableView reloadData];
}

#pragma mark - 目录浏览

- (void)pushPluginDirBrowser {
    AWECAPluginDirBrowserController *b = [[AWECAPluginDirBrowserController alloc] initWithStyle:UITableViewStylePlain];
    b.directoryPath = [AWECAUtils audioSavePath];
    [self.navigationController pushViewController:b animated:YES];
}

@end

// === AWECAPluginDirBrowserController ===

@implementation AWECAPluginDirBrowserController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.directoryPath.lastPathComponent;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"dc"];
    [self loadItems];
}

- (void)loadItems {
    self.items = [NSMutableArray array];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *c = [fm contentsOfDirectoryAtPath:self.directoryPath error:nil];
    NSMutableArray *dirs = [NSMutableArray array], *files = [NSMutableArray array];
    for (NSString *n in c) {
        if ([n hasPrefix:@"."]) continue;
        NSString *fp = [self.directoryPath stringByAppendingPathComponent:n];
        BOOL d = NO; [fm fileExistsAtPath:fp isDirectory:&d];
        if (d) [dirs addObject:@{@"name":n, @"isDir":@YES, @"path":fp}];
        else if ([n.pathExtension.lowercaseString isEqualToString:@"m4a"]) [files addObject:@{@"name":n, @"isDir":@NO, @"path":fp}];
    }
    [dirs sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) { return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]]; }];
    [files sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [[fm attributesOfItemAtPath:b[@"path"] error:nil][NSFileModificationDate] compare:[fm attributesOfItemAtPath:a[@"path"] error:nil][NSFileModificationDate]];
    }];
    [self.items addObjectsFromArray:dirs];
    [self.items addObjectsFromArray:files];
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return self.items.count; }

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"dc" forIndexPath:ip];
    NSDictionary *item = self.items[ip.row];
    c.textLabel.font = kCellFont;
    if ([item[@"isDir"] boolValue]) {
        c.textLabel.text = item[@"name"];
        c.imageView.image = [UIImage systemImageNamed:@"folder"];
        c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        c.textLabel.textColor = nil;
    } else {
        double dur = [AWECAUtils audioDurationAtPath:item[@"path"]];
        c.textLabel.text = [NSString stringWithFormat:@"%@ (%.0f秒)", item[@"name"], dur];
        c.imageView.image = [UIImage systemImageNamed:@"music.note"];
        c.accessoryType = UITableViewCellAccessoryNone;
        c.textLabel.textColor = nil;
    }
    return c;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    NSDictionary *item = self.items[ip.row];
    if ([item[@"isDir"] boolValue]) {
        AWECAPluginDirBrowserController *sub = [[AWECAPluginDirBrowserController alloc] initWithStyle:UITableViewStylePlain];
        sub.directoryPath = item[@"path"];
        [self.navigationController pushViewController:sub animated:YES];
    } else {
        [[AWECAAudioReplacer shared] setReplacementFromPath:item[@"path"] completion:^(BOOL ok) {
            if (ok) { double d = [AWECAUtils audioDurationAtPath:item[@"path"]]; [AWECAUtils showToast:[NSString stringWithFormat:@"已选择 (%.0f秒)", d]]; }
        }];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
