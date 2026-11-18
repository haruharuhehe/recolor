TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

TWEAK_NAME = recolor
recolor_FILES = Tweak.xm
recolor_CFLAGS = -fobjc-arc -Wall -Wextra
recolor_FRAMEWORKS = Foundation UIKit
# Non-jailbroken route: Esign copies the dylib to Frameworks/ and loads it
# from there, so the id must not point at /Library/MobileSubstrate.
recolor_LDFLAGS = -install_name @executable_path/Frameworks/recolor.dylib

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 ArenaOfValor || true"
