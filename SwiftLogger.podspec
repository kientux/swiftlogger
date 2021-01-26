#
# Be sure to run `pod lib lint SwiftLogger.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftLogger'
  s.version          = '1.0.4'
  s.summary          = 'Logging tool for Swift'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Logging tool for Swift.
                       DESC

  s.homepage         = 'https://git.dktsoft.com:2008/sapo-mobile/swift-logger'
  s.author           = { 'kientux' => 'kiennt@sapo.vn' }
  s.source           = { :git => 'https://git.dktsoft.com:2008/sapo-mobile/swift-logger.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.swift_versions = '5.0'

  s.source_files = 'Sources/**/*.swift'
end
