Pod::Spec.new do |s|
  s.name             = "Concorde"
  s.version          = "0.0.1"
  s.summary          = "Download and decode progressive JPEGs easily."
  s.homepage         = "https://github.com/contentful-labs/Concorde/"
  s.social_media_url = 'https://twitter.com/contentful'

  s.license = {
    :type => 'MIT',
    :file => 'LICENSE'
  }

  s.authors      = { "Boris Bügling" => "boris@buegling.com" }
  s.source       = { :git => "https://github.com/contentful-labs/Concorde.git",
                     :tag => s.version.to_s }
  s.requires_arc = true

  s.source_files         = 'Code/*.{h,m}', 'vendor/libjpeg-turbo/include/*'
  s.public_header_files  = 'Code/CCBufferedImageDecoder.h'
  s.vendored_libraries   = 'vendor/libjpeg-turbo/lib/libturbojpeg.a'

  s.ios.deployment_target     = '6.0'
  s.ios.frameworks            = 'UIKit'
  s.osx.deployment_target     = '10.8'
end
