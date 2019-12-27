# export TARGET = iphone:11.1:9.0
export TARGET = iphone:clang:11.2:9.0
export ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

# Relevant folders
PROJECT_SRC = TBTweakViewController/TBTweakViewController/Classes
PODS_ROOT = TBTweakViewController/Pods
MK_DIR = $(PODS_ROOT)/MirrorKit/MirrorKit

# Swizzle sources and all dependency sources
MY_SOURCES =     $(wildcard $(PROJECT_SRC)/*.m)
MY_SOURCES +=    $(wildcard $(PROJECT_SRC)/*.S)
EXT_DEPENDS =    $(wildcard $(PODS_ROOT)/Masonry/Masonry/*.m)
EXT_DEPENDS +=   $(wildcard $(PODS_ROOT)/TBAlertController/Classes/*.m)
LOCAL_DEPENDS =  $(wildcard $(MK_DIR)/*.m)
LOCAL_DEPENDS += $(wildcard $(MK_DIR)/Classes/*.m)
LOCAL_DEPENDS += $(wildcard $(MK_DIR)/Categories/*.m)
LOCAL_DEPENDS += $(wildcard $(MK_DIR)/Private/*.m)

# Misc flags
INCLUDES =  -I$(PODS_ROOT)/Headers/Public
INCLUDES += -I$(PODS_ROOT)/Headers/Public/MirrorKit
INCLUDES += -I$(PROJECT_SRC)
IGNORED_WARNINGS =  -Wno-missing-braces -Wno-ambiguous-macro
IGNORED_WARNINGS += -Wno-objc-property-no-attribute -Wno-\#warnings
IGNORED_WARNINGS += -Wno-unused-command-line-argument -Wno-deprecated-declarations
POORLY_EMITTED_WARNINGS = -Wno-incomplete-implementation -Wno-incompatible-pointer-types

TWEAK_NAME = Swizzle
$(TWEAK_NAME)_FILES = $(MY_SOURCES) $(EXT_DEPENDS) $(LOCAL_DEPENDS) Tweak.xm
$(TWEAK_NAME)_FRAMEWORKS = UIKit
$(TWEAK_NAME)_CFLAGS += $(INCLUDES) $(IGNORED_WARNINGS) -fobjc-arc
$(TWEAK_NAME)_CFLAGS += $(POORLY_EMITTED_WARNINGS)
$(TWEAK_NAME)_EXTRA_FRAMEWORKS += Cephei

include $(THEOS_MAKE_PATH)/tweak.mk

before-stage::
	find . -name ".DS_Store" -delete

after-install::
	install.exec "killall -9 SpringBoard"


print-%  : ; @echo $* = $($*)

SUBPROJECTS += Prefs
include $(THEOS_MAKE_PATH)/aggregate.mk