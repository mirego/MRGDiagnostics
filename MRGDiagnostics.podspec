Pod::Spec.new do |s|
  s.name         = "MRGDiagnostics"
  s.version      = "0.3.0"
  s.summary      = "iOS Framework that offers you an easy way to add a diagnostics view to your project."
  s.homepage     = "https://github.com/mirego/MRGDiagnostics"
  s.license      = 'BSD 3-Clause'
  s.author       = { 'Mirego, Inc.' => 'info@mirego.com' }
  s.source       = { :git => "https://github.com/mirego/MRGDiagnostics.git", :tag => "#{s.version}" }
  s.source_files = "MRGDiagnostics", "MRGDiagnostics/**/*.swift"
  s.resources    = ["MRGDiagnostics/Resources/*.lproj"]
  s.requires_arc = true

  s.platform     = :ios, "8.0"
  s.swift_version = '5.0'
end
