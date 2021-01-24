Pod::Spec.new do |s|
	s.name = 'Defaults'
	s.version = '4.1.0'
	s.summary = 'Swifty and modern UserDefaults'
	s.license = 'MIT'
	s.homepage = 'https://github.com/sindresorhus/Defaults'
	s.social_media_url = 'https://twitter.com/sindresorhus'
	s.authors = { 'Sindre Sorhus' => 'sindresorhus@gmail.com' }
	s.source = { :git => 'https://github.com/sindresorhus/Defaults.git', :tag => "v#{s.version}" }
	s.source_files = 'Sources/**/*.swift'
	s.swift_version = '5.3'
	s.macos.deployment_target = '10.12'
	s.ios.deployment_target = '10.0'
	s.tvos.deployment_target = '10.0'
	s.watchos.deployment_target = '3.0'
end
