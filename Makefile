ARCHS = arm64
TARGET = iphone:17.5:14.0
DEBUG = 0
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MCTweak

MCTweak_FILES = Tweak.x MCMenuView.m MCEventSimulator.m
MCTweak_CFLAGS = -fobjc-arc -O2
MCTweak_FRAMEWORKS = UIKit CoreGraphics QuartzCore
MCTweak_PRIVATE_FRAMEWORKS = GraphicsServices BackBoardServices

# 自动注入到 Minecraft 网易版
MCTweak_CFLAGS += -DMC_PACKAGE_NAME=\"com.netease.mc\" -DMC_DISPLAY_NAME=\"Minecraft\"

include $(THEOS_MAKE_PATH)/tweak.mk

# 构建后清理
after-package::
	@echo "============================================"
	@echo " 📦 构建完成!"
	@echo " 产物: $(THEOS_PACKAGE_DIR)/$(PACKAGE_NAME)_$(PACKAGE_VERSION)_iphoneos-arm.deb"
	@echo "============================================"

after-install::
	install.exec "killall -9 Minecraft" || true
	install.exec "killall -9 MinecraftPE" || true