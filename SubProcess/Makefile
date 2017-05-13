include $(THEOS)/makefiles/common.mk

ARCHS = armv7

FRAMEWORK_NAME = SubProcess
SubProcess_FILES = $(wildcard *.m)
SubProcess_FRAMEWORKS = CoreGraphics CoreText QuartzCore UIKit
#SubProcess_CFLAGS = -include ../NewTerm/NewTerm-Prefix.pch -I../headers
SubProcess_CFLAGS = -I../headers
SubProcess_LIBRARIES = curses
SubProcess_INSTALL_PATH = /Applications/terminal.app/Frameworks

include $(THEOS_MAKE_PATH)/framework.mk
