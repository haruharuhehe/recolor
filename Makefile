TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

TWEAK_NAME = recolor
recolor_FILES = Tweak.xm
recolor_CFLAGS = -fobjc-arc -Wall -Wextra
recolor_FRAMEWORKS = Foundation UIKit

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 ArenaOfValor || true"
