#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MCMenuView.h"

// ============================================================
// 纯 Runtime 方案：完全兼容 TrollStore 注入
//
// 关键点：
// 1. 不使用 %hook（%hook 依赖 Cydia Substrate，TrollStore 没有）
// 2. 不使用 %ctor（%ctor 在 dylib 加载时执行，时机太早）
// 3. 使用 +load → 通知 → dispatch_after 三级延迟，确保安全
// ============================================================

@interface MCTweakLoader : NSObject
@end

@implementation MCTweakLoader

+ (void)load {
    // 第一级：+load 在 dylib 加载时由 ObjC 运行时调用
    // 此时只注册通知，不访问任何 UIKit API
    
    __block id observer = nil;
    observer = [[NSNotificationCenter defaultCenter] 
        addObserverForName:UIApplicationDidFinishLaunchingNotification
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification * _Nonnull note) {
        
        // 第二级：UIApplicationDidFinishLaunchingNotification 触发时
        // app 已经启动完成，UIKit 安全可用
        
        // 移除一次性观察者
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        
        // 第三级：再延迟 5 秒，确保 Minecraft 游戏 UI 完全加载
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 
                       (int64_t)(5.0 * NSEC_PER_SEC)), 
                       dispatch_get_main_queue(), ^{
            
            // 最终安全启动菜单
            [[MCMenuManager sharedInstance] showMenu];
        });
    }];
}

@end