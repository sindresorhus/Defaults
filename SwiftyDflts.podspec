Pod::Spec.new do |s|
s.name = "Defaults"
s.version = "0.2.2"
s.summary = "Swifty and modern UserDefaults"
s.description = <<-DESC

Strongly typed: You declare the type and default value upfront.
Codable support: You can store any Codable value, like an enum.
Debuggable: The data is stored as JSON-serialized values.
Lightweight: It's only ~100 lines of code.

DESC

s.homepage     = "https://github.com/sindresorhus/Defaults"
s.license = { :type => "MIT", :file => "license" }
s.author = { "Sindre Sorhus" => "sindresorhus@gmail.com" }
s.social_media_url = "https://twitter.com/sindresorhus"
s.swift_version = "4.1"
s.ios.deployment_target = "9.0"
s.tvos.deployment_target = "9.0"
s.osx.deployment_target = "10.10"
s.watchos.deployment_target = "2.0"
s.source = { :git => "https://github.com/sindresorhus/Defaults.git", :tag => s.version }
s.source_files =["Sources/*.swift"]
s.requires_arc = true
end
