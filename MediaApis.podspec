swift_version = File.new('.swift-version').read

Pod::Spec.new do |s|
  s.name         = "MediaApis"
  s.version      = "1.0.0"
  s.summary      = "Media Apis"
  s.description  = "Media Apis."

  s.homepage     = "https://github.com/shvets/MediaApis"
  s.authors = { "Alexander Shvets" => "alexander.shvets@gmail.com" }
  s.license      = "MIT"
  s.source = { :git => 'https://github.com/shvets/MediaApis.git', :tag => s.version }

  s.ios.deployment_target = "12.2"
  s.tvos.deployment_target = "12.2"

  s.source_files = "Sources/**/*.swift"
  s.ios.source_files = "Sources/**/*.swift"
  s.tvos.source_files = "Sources/**/*.swift"

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => swift_version }

  s.dependency 'SimpleHttpClient', '~> 1.0.0'
end
