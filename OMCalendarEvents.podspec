Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = '12.0'
s.name = "OMCalendarEvents"
s.summary = "Manage your events in IOS and Google calendars"

s.version = "0.0.6"

s.license = { :type => "MIT", :file => "LICENSE" }

s.author = { "Ostap Marchenko" => "ostapmarchenko@gmail.com" }

s.homepage = "https://github.com/OSTAPMARCHENKO/OMCalendarEvents"

s.source = { :git => "https://github.com/OSTAPMARCHENKO/OMCalendarEvents.git",
             :tag => "#{s.version}" }

s.framework = "UIKit"
s.dependency 'GoogleAPIClientForREST/Calendar'
s.dependency 'GoogleSignIn', '~> 5.0'

s.source_files = "OMCalendarEvents/**/*.{h,m,swift}"

s.swift_version = "5.0"

s.static_framework = true

s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'}
s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'}

end
