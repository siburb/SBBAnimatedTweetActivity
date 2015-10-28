Pod::Spec.new do |s|
  s.name             = "SBBAnimatedTweetActivity"
  s.version          = "0.1.3"
  s.summary          = "A UIActivity subclass for posting animated GIF's to Twitter."
 
  s.description      = <<-DESC
			SBBAnimatedTweetActivity is a replacement for the built-in Twitter UIActivity that handles animated images. This is due to the built-in Twitter UIActivity posting a still frame from an animated GIF to Tweets instead of the animated GIF itself.
                       DESC

  s.homepage         = "https://github.com/siburb/SBBAnimatedTweetActivity"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Simon Burbidge" => "simon@whiskmobile.com" }
  s.source           = { :git => "https://github.com/siburb/SBBAnimatedTweetActivity.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/siburb'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'SBBAnimatedTweetActivity' => ['Pod/Assets/*.storyboard', 'Pod/Assets/*.xcassets']
  }

  s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'Accounts', 'Social', 'MobileCoreServices'
  s.dependency 'FLAnimatedImage', '~> 1.0.8'
end
