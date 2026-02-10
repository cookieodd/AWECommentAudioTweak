# 评论区语音hook，能下能换，就是玩儿
# @cookieodd | github.com/cookieodd | t.me/cookieodd

ARCHS = arm64
TARGET := iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = AWECommentAudioTweak

AWECommentAudioTweak_FILES = Tweak/Tweak.x \
	Tweak/AWECADownloadManager.m \
	Tweak/AWECAAudioReplacer.m \
	Tweak/AWECAAudioPickerController.m \
	Tweak/AWECAUtils.m

AWECommentAudioTweak_CFLAGS = -fobjc-arc
AWECommentAudioTweak_LDFLAGS = -Xlinker -not_for_dyld_shared_cache
AWECommentAudioTweak_FRAMEWORKS = UIKit Foundation AVFoundation CoreAudio UniformTypeIdentifiers
AWECommentAudioTweak_LIBRARIES = objc

include $(THEOS_MAKE_PATH)/library.mk
