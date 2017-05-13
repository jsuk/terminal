export TARGET = iphone:clang:latest:5.1
include $(THEOS)/makefiles/common.mk

ARCHS = armv7

APPLICATION_NAME = terminal
terminal_FILES = main.m TerminalAppDelegate.m TerminalRootViewController.m
terminal_FRAMEWORKS = UIKit CoreGraphics
terminal_EXTRA_FRAMEWORKS = SubProcess
terminal_LDFLAGS += -v -F./

SUBPROJECTS = VT100 SubProcess

include $(THEOS_MAKE_PATH)/application.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall \"terminal\"" || true
