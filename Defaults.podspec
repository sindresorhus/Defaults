Pod::Spec.new do |s|
s.name = "Defaults"
s.version = "0.2.1"
s.summary = "Swifty and modern UserDefaults"
s.description = <<-DESC

Strongly typed: You declare the type and default value upfront.
Codable support: You can store any Codable value, like an enum.
Debuggable: The data is stored as JSON-serialized values.
Lightweight: It's only ~100 lines of code.

DESC

s.homepage     = "https://github.com/sindresorhus/Defaults"
s.license = { :type => "MIT", :file => "license" }
s.author = { "sindresorhus" => "sindresorhus@gmail.com" }
s.social_media_url = "https://sindresorhus.com"
s.swift_version = "4.0"
s.platform = :ios
s.source = { :git => "https://github.com/sindresorhus/Defaults.git", :tag => s.version }
s.source_files =["Sources/*.swift", "Sources/Defaults.swift"]
s.requires_arc = true
end
