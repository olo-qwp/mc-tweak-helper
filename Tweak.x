#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MCMenuView.h"

%hook UIApplication

// 在应用启动完成后初始化我们的菜单
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    // 延迟初始化，确保 UI 完全加载
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 显示浮动菜单
        [[MCMenuManager sharedInstance] showMenu];
    });
    
    return result;
}

%end

// ============================================================
// 自动收集 - 当物品掉落时自动拾取
// 通过 hook 触摸事件捕获位置
// ============================================================
%hook UIWindow

// 捕获触摸事件，让连点器知道点击位置
- (void)sendEvent:(UIEvent *)event {
    %orig;
    
    // 获取当前活跃的触摸点位置
    // 用于连点器定位
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 注册通知，当连点器启用时更新点击位置
    });
}

%end

// ============================================================
// 构造函数 - 在 dylib 加载时自动执行
// ============================================================
%ctor {
    // 初始化日志
    NSLog(@"[MCTweak] 我的世界辅助工具已加载 ✅");
    
    // 确保在主线程中初始化 UI
    dispatch_async(dispatch_get_main_queue(), ^{
        // 预创建菜单管理器
        [MCMenuManager sharedInstance];
    });
}