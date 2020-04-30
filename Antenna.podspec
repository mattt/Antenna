Pod::Spec.new do |s|
  s.name     = 'Antenna'
  s.version  = '2.1.0'
  s.license  = 'MIT'
  s.summary  = 'Extensible Remote Logging for iOS.'
  s.homepage = 'https://github.com/mattt/Antenna'
  s.social_media_url = 'https://twitter.com/mattt'
  s.authors  = { 'Mattt' => 'mattt@me.com' }
  s.source   = { :git => 'https://github.com/mattt/Antenna.git', :tag => '2.1.0' }
  s.source_files = 'Antenna'
  s.requires_arc = true

  s.platform = :ios, '6.0'

  s.dependency 'AFNetworking', '~> 2.4'
end
