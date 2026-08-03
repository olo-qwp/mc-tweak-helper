#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MCMenuView.h"

// ============================================================
// 安全启动：不使用 %ctor（%ctor 在 TrollStore 注入时容易闪退）
// 改用 +load 方法注册通知，等 app 完全启动后再初始化
// ============================================================

%hook UIApplication

// 在应用启动完成后初始化菜单
// 注意：这个方法是由系统调用的，此时 ObjC 运行时已经完全就绪
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    // 延迟 3 秒初始化，确保 Minecraft 的 UI 完全加载完毕
    // 使用弱引用避免循环引用
    __weak typeof(self) weakSelf = application;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 再次检查 app 是否还在活跃状态
        if (weakSelf) {
            [[MCMenuManager sharedInstance] showMenu];
        }
    });
    
    return result;
}

%end

// ============================================================
// 安全初始化类 - 不使用 %ctor
// 在 dylib 加载时通过 +load 方法注册通知
// ============================================================
@interface MCTweakLoader : NSObject
@end

@implementation MCTweakLoader

+ (void)load {
    // +load 在 dylib 加载时调用，比 %ctor 更安全
    // 此时不要访问 UIKit，只注册通知
    
    __block id observer = nil;
    observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                                  object:nil
                                                                   queue:[NSOperationQueue mainQueue]
                                                              usingBlock:^(NSNotification * _Nonnull note) {
        // app 启动完成，现在可以安全访问 UIKit 了
        // 预创建菜单管理器实例（但不显示）
        [MCMenuManager sharedInstance];
        
        // 移除通知观察者（只执行一次）
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }];
}

@end