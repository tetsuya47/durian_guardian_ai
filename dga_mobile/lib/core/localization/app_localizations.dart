import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('vi'));

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [
    Locale('vi'),
    Locale('en'),
  ];

  static final Map<String, Map<String, String>> _translations = {
    'vi': {
      'success': 'Thành công',
      'error': 'Lỗi',
      'loading': 'Đang tải...',
      'retry': 'Thử lại',
      'cancel': 'Hủy',
      'save': 'Lưu',
      'search': 'Tìm kiếm',
      'next': 'Tiếp theo',
      'skip': 'Bỏ qua',
      'start': 'Bắt đầu',
      'continueText': 'Tiếp tục',
      'close': 'Đóng',
      // Navigation
      'dashboard': 'Tổng quan',
      'diseaseDetection': 'Chẩn đoán bệnh',
      'recommendation': 'Khuyến nghị AI',
      'history': 'Lịch sử',
      'profile': 'Hồ sơ',
      'settings': 'Cài đặt',
      // Onboarding
      'onboardingTitle1': 'AI Chẩn Đoán Bệnh Lá',
      'onboardingDesc1': 'Chụp ảnh lá sầu riêng để phát hiện sớm các loại nấm bệnh, sâu hại chỉ trong vài giây bằng công nghệ AI tiên tiến.',
      'onboardingTitle2': 'Dự Báo Thời Tiết',
      'onboardingDesc2': 'Cung cấp các thông số thời tiết nông nghiệp chuyên sâu như nhiệt độ, độ ẩm và lượng mưa trực tiếp tại vườn của bạn.',
      'onboardingTitle3': 'Khuyến Nghị Chăm Sóc',
      'onboardingDesc3': 'Nhận các khuyến nghị chi tiết từ các chuyên gia nông nghiệp hàng đầu về bón phân, phun thuốc và tưới nước.',
      // Auth
      'login': 'Đăng nhập',
      'logout': 'Đăng xuất',
      'email': 'Email',
      'password': 'Mật khẩu',
      'rememberMe': 'Ghi nhớ đăng nhập',
      'forgotPassword': 'Quên mật khẩu',
      'loginWithGuest': 'Tiếp tục với chế độ khách',
      'invalidEmail': 'Email không hợp lệ',
      'emptyPassword': 'Mật khẩu không được để trống',
      'loginFailed': 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin!',
      // Forgot Password
      'forgotPasswordTitle': 'Khôi phục mật khẩu',
      'forgotPasswordDesc': 'Nhập email của bạn để nhận liên kết khôi phục mật khẩu.',
      'sendRequest': 'Gửi yêu cầu',
      'forgotPasswordSuccessTitle': 'Yêu cầu đã được gửi',
      'forgotPasswordSuccessDesc': 'Chúng tôi đã gửi liên kết khôi phục mật khẩu tới email của bạn. Vui lòng kiểm tra hộp thư.',
      'emailRequired': 'Vui lòng nhập email',
    },
    'en': {
      'success': 'Success',
      'error': 'Error',
      'loading': 'Loading...',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'save': 'Save',
      'search': 'Search',
      'next': 'Next',
      'skip': 'Skip',
      'start': 'Start',
      'continueText': 'Continue',
      'close': 'Close',
      // Navigation
      'dashboard': 'Dashboard',
      'diseaseDetection': 'Leaf Scan',
      'recommendation': 'AI Advisory',
      'history': 'History',
      'profile': 'Profile',
      'settings': 'Settings',
      // Onboarding
      'onboardingTitle1': 'AI Leaf Diagnosis',
      'onboardingDesc1': 'Snap a photo of durian leaves to instantly detect fungus diseases and crop threats via advanced AI computer vision.',
      'onboardingTitle2': 'Agricultural Weather',
      'onboardingDesc2': 'Provides specialized agricultural weather telemetry like temp, humidity and rainfall directly at your orchard.',
      'onboardingTitle3': 'Smart Care Advisory',
      'onboardingDesc3': 'Receive expert recommendations on fertilization, watering schedules, and bio-fungicides directly customized for you.',
      // Auth
      'login': 'Log In',
      'logout': 'Log Out',
      'email': 'Email Address',
      'password': 'Password',
      'rememberMe': 'Remember Me',
      'forgotPassword': 'Forgot Password?',
      'loginWithGuest': 'Continue as Guest',
      'invalidEmail': 'Invalid email address format',
      'emptyPassword': 'Password cannot be empty',
      'loginFailed': 'Authentication failed. Please verify credentials!',
      // Forgot Password
      'forgotPasswordTitle': 'Password Recovery',
      'forgotPasswordDesc': 'Enter your registered email to receive a secure password recovery link.',
      'sendRequest': 'Send Request',
      'forgotPasswordSuccessTitle': 'Request Dispatched',
      'forgotPasswordSuccessDesc': 'We have dispatched a password recovery link to your inbox. Please check your emails.',
      'emailRequired': 'Email field is required',
    }
  };

  String translate(String key) {
    return _translations[locale.languageCode]?[key] ?? key;
  }
}

final translationProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations(locale);
});
