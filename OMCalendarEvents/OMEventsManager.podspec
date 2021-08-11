Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = '12.0'
s.name = "OMEventsManager"
s.summary = "OMEventsManager lets a user manage events."

s.version = "0.0.2"

s.license = { :type => "MIT", :file => "LICENSE" }

s.author = { "Ostap Marchenko" => "ostapmarchenko@gmail.com" }

s.homepage = "https://github.com/OSTAPMARCHENKO/OMCalendarEvents"

s.source = { :git => "https://github.com/OSTAPMARCHENKO/OMCalendarEvents.git",
             :tag => "#{s.version}" }

s.framework = "UIKit"
s.dependency 'GoogleAPIClientForREST/Calendar'
s.dependency 'GoogleSignIn', '~> 5.0'

s.source_files = "OMEventsManager/**/*.{h,m,swift}"

s.swift_version = "5.0"

s.static_framework = true

s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'}
s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'}

end
