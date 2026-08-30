#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint entra_external_id.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'entra_external_id'
  s.version          = '0.0.1'
  s.summary          = 'Flutter bridge for Microsoft Entra External ID Native Authentication using the official MSAL Android and iOS SDKs.'
  s.description      = <<-DESC
Flutter bridge for Microsoft Entra External ID Native Authentication using the official MSAL Android and iOS SDKs.
                       DESC
  s.homepage         = 'https://github.com/Wreos/entra_external_id'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Aleksandr Lozhkovoi'
  s.source           = { :path => '.' }
  s.source_files = 'entra_external_id/Sources/entra_external_id/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '17.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'entra_external_id_privacy' => ['entra_external_id/Sources/entra_external_id/PrivacyInfo.xcprivacy']}
end
