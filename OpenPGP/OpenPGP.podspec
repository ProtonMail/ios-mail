Pod::Spec.new do |s|
  s.name         = "OpenPGP"
  s.version      = "1.0.1"
  s.summary      = "OpenPGP iOS library for ProtonMail."
  s.description  = "The OpenPGP iOS library for the ProtonMail app."
  s.homepage     = "http://protonmail.ch"
  s.license      = "ProtonMail"
  s.author             = "Yanfeng Zhang"
  s.platform     = :ios, "8.0"
  s.source_files  = "include/OpenPGP/*.h"
  s.public_header_files = "include/OpenPGP/*.h"
  s.header_dir = "OpenPGP"
  s.preserve_path = "libs/libOpenPGP.a"
  s.libraries = "OpenPGP", "z", "bz2"
  s.vendored_library = "libs/libOpenPGP.a"
  s.dependency "OpenSSL"
  s.source = { :git => '.', :commit => '' }
end
