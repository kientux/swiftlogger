#
# Be sure to run `pod lib lint SwiftLogger.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Swift-Logger'
  s.version          = '1.1.3'
  s.summary          = 'Logging tool for Swift'
  s.license          = { :type => 'GPL 3.0', :file => 'LICENSE' }

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Logging tool for Swift.
                       DESC

  s.homepage         = 'https://github.com/kientux/swiftlogger'
  s.author           = { 'kientux' => 'ntkien93@gmail.com' }
  s.source           = { :git => 'https://github.com/kientux/swiftlogger.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.swift_versions = '5.0'

  s.source_files = 'Sources/**/*.swift'
end
