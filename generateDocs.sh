#!/bin/bash

#
# Jazzy home page https://github.com/realm/jazzy
#
# Install Jazzy as gem
# 
# [sudo] gem install jazzy
#

jazzy --clean --sdk iphoneos -x -workspace,Example/ScreenMeetSDK.xcworkspace,-scheme,ScreenMeetSDK,-arch,arm64 --module ScreenMeetSDK --min-acl public

