class ApiConfig {
  static const String baseUrl = 'https://academy.kainuwa.africa/api/mobile';
  
  static const String login = '$baseUrl/login.php';
  static const String register = '$baseUrl/register.php';
  static const String courses = '$baseUrl/courses.php';
  static const String myCourses = '$baseUrl/my_courses.php';
  static const String courseLessons = '$baseUrl/course_lessons.php';
  static const String saveProgress = '$baseUrl/save_progress.php';
  static const String dashboardData = '$baseUrl/dashboard_data.php';
  static const String userProfile = '$baseUrl/user_profile.php';
  static const String myDownloads = '$baseUrl/my_downloads.php';
  static const String courseDetails = '$baseUrl/course_details.php?slug=';
}
EO


cd ~/kaida_app

cat << 'EOF' > lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://academy.kainuwa.africa/api/mobile';
  
  static const String login = '$baseUrl/login.php';
  static const String register = '$baseUrl/register.php';
  static const String courses = '$baseUrl/courses.php';
  static const String myCourses = '$baseUrl/my_courses.php';
  static const String courseLessons = '$baseUrl/course_lessons.php';
  static const String saveProgress = '$baseUrl/save_progress.php';
  static const String dashboardData = '$baseUrl/dashboard_data.php';
  static const String userProfile = '$baseUrl/user_profile.php';
  static const String myDownloads = '$baseUrl/my_downloads.php';
  static const String courseDetails = '$baseUrl/course_details.php?slug=';
}
