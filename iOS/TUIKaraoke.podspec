Pod::Spec.new do |spec|
  spec.name         = 'TUIKaraoke'
  spec.version      = '1.0.0'
  spec.platform     = :ios
  spec.ios.deployment_target = '13.0'
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.homepage     = 'https://cloud.tencent.com/document/product/269/3794'
  spec.documentation_url = 'https://cloud.tencent.com/document/product/269/9147'
  spec.authors      = 'tencent video cloud'
  spec.summary      = 'TUIKaraoke'
  spec.xcconfig     = { 'VALID_ARCHS' => 'armv7 arm64 x86_64' }
  spec.swift_version = '5.0'

  spec.dependency 'TXAppBasic'
  spec.dependency 'TUICore'
#  Swift第三方库
  spec.dependency 'Alamofire'
  spec.dependency 'SnapKit'
  spec.dependency 'Toast-Swift'
  spec.dependency 'Kingfisher', '<= 6.3.1'
 
#  OC第三方库
  spec.dependency 'MJExtension'
  spec.dependency 'MJRefresh'
  
  
  spec.requires_arc = true
  spec.static_framework = true
  spec.source = { :path => './' }
  spec.source_files = 'Source/**/*.{h,m,mm,swift}', 'Source/*.{h,m,mm,swift}'
  spec.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
 
  spec.default_subspec = 'TRTC'
  spec.subspec 'TRTC' do |trtc|
    trtc.dependency 'TXLiteAVSDK_TRTC'
    framework_path="../SDK/TXLiteAVSDK_TRTC.framework"
    trtc.pod_target_xcconfig={
        'HEADER_SEARCH_PATHS'=>["$(PODS_TARGET_SRCROOT)/../#{framework_path}/Headers"]
    }
    trtc.source_files = 'Source/localized/**/*.{h,m,mm,swift}', 'Source/model/**/*.{h,m,mm,swift}', 'Source/Category/**/*.{h,m,mm,swift}', 'Source/ui/**/*.{h,m,mm,swift}', 'Source/TUIKaraokeKit_TRTC/*.{h,m,mm,swift}','Source/TUIGiftKit/*.{h,m,mm,swift}'
    trtc.ios.framework = ['AVFoundation', 'Accelerate']
    trtc.library = 'c++', 'resolv'
    trtc.resource_bundles = {
     'TUIKaraokeKitBundle' => ['Resources/Localized/**/*.strings','Resources/*.xcassets', 'Resources/*.gif', 'Resources/*.mp3', 'Resources/*.vtt']
    }
  end
 
  spec.subspec 'Enterprise' do |enterprise|
    enterprise.dependency 'TXLiteAVSDK_Enterprise'
    enterprise.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '${PODS_TARGET_SRCROOT}/../../SDK/TXLiteAVSDK_Enterprise.framework/Headers/'}
    enterprise.source_files = 'Source/localized/**/*.{h,m,mm,swift}', 'Source/model/**/*.{h,m,mm,swift}', 'Source/Category/**/*.{h,m,mm,swift}', 'Source/ui/**/*.{h,m,mm,swift}', 'Source/TUIKaraokeKit_Enterprise/*.{h,m,mm,swift}','Source/TUIGiftKit/*.{h,m,mm,swift}'
    enterprise.ios.framework = ['AVFoundation', 'Accelerate', 'AssetsLibrary']
    enterprise.library = 'c++', 'resolv', 'sqlite3'
    enterprise.resource_bundles = {
      'TUIKaraokeKitBundle' => ['Resources/Localized/**/*.strings','Resources/*.xcassets', 'Resources/*.gif', 'Resources/*.mp3', 'Resources/*.vtt']
    }
  end
  
  spec.subspec 'Professional' do |professional|
    professional.dependency 'TXLiteAVSDK_Professional'
    professional.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '${PODS_TARGET_SRCROOT}/../../SDK/TXLiteAVSDK_Professional.framework/Headers/'}
    professional.source_files = 'Source/localized/**/*.{h,m,mm,swift}', 'Source/model/**/*.{h,m,mm,swift}', 'Source/Category/**/*.{h,m,mm,swift}', 'Source/ui/**/*.{h,m,mm,swift}', 'Source/TUIKaraokeKit_Professional/*.{h,m,mm,swift}','Source/TUIGiftKit/*.{h,m,mm,swift}'
    professional.ios.framework = ['AVFoundation', 'Accelerate', 'AssetsLibrary']
    professional.library = 'c++', 'resolv', 'sqlite3'
    professional.resource_bundles = {
      'TUIKaraokeKitBundle' => ['Resources/Localized/**/*.strings','Resources/*.xcassets', 'Resources/*.gif', 'Resources/*.mp3', 'Resources/*.vtt']
    }
  end
end

