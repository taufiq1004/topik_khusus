import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_khusus/homepage.dart'; 
import 'package:topik_khusus/loginpage.dart'; 

// ApiService class for handling HTTP requests with Dio
class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000', // Emulator localhost
    ),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  static final CookieJar cookieJar = CookieJar();

  static Dio get instance {
    _dio.interceptors.clear();
    _dio.interceptors.add(CookieManager(cookieJar));
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ));
    }
    return _dio;
  }
}

// AboutPage widget
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

// Logout function
Future<void> logout(BuildContext context) async {
  try {
    if (kDebugMode) {
      print('Attempting logout...');
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    // Log cookies for debugging
    final cookies = await ApiService.cookieJar.loadForRequest(
      Uri.parse('http://10.0.2.2:3000/logout'),
    );
    if (kDebugMode) {
      print('Cookies sent with logout request: $cookies');
    }

    // Optionally add token if required by backend
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;

    // Send logout request
    if (kDebugMode) {
      print('Sending POST /logout request...');
    }
    final response = await ApiService.instance.post('/logout', options: options);
    if (kDebugMode) {
      print('Logout response: ${response.statusCode} ${response.data}');
    }

    // Close loading indicator
    Navigator.of(context).pop();

    if (response.statusCode == 200) {
      // Clear cookies and shared preferences
      if (kDebugMode) {
        print('Clearing cookies and shared preferences...');
      }
      await ApiService.cookieJar.deleteAll();
      await prefs.clear();

      if (kDebugMode) {
        print('Logout successful');
      }

      // Navigate to LoginPage and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } else {
      if (kDebugMode) {
        print('Logout failed: ${response.statusCode} - ${response.data}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${response.statusMessage}')),
      );
    }
  } on DioException catch (e, stackTrace) {
    // Close loading indicator
    Navigator.of(context).pop();
    String errorMessage = 'Error during logout. Please try again.';
    if (e.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Connection timeout. Please check your network.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Server response timeout. Please try again.';
    } else if (e.type == DioExceptionType.badResponse) {
      if (e.response?.statusCode == 401) {
        errorMessage = 'Session expired. Please login again.';
        // Clear cookies and preferences on 401
        ApiService.cookieJar.deleteAll();
        SharedPreferences.getInstance().then((prefs) => prefs.clear());
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        errorMessage =
            'Server error: ${e.response?.statusCode} ${e.response?.statusMessage}';
      }
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'Unable to connect to the server. Please check your network.';
    } else {
      errorMessage = 'Network error: ${e.message}';
    }
    if (kDebugMode) {
      print('DioException: $e\n'
          'Type: ${e.type}\n'
          'Message: ${e.message}\n'
          'Response: ${e.response?.statusCode} ${e.response?.data}\n'
          'StackTrace: $stackTrace');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  } catch (e, stackTrace) {
    // Close loading indicator
    Navigator.of(context).pop();
    if (kDebugMode) {
      print('Unexpected error: $e\nStackTrace: $stackTrace');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error during logout. Please try again.')),
    );
  }
}

class _AboutPageState extends State<AboutPage> {
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  String? errorMessage;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _checkSession();
    _loadUserDataFromCache();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  // Check session status
  Future<void> _checkSession() async {
    try {
      if (kDebugMode) {
        print('Checking session...');
      }
      final cookies = await ApiService.cookieJar.loadForRequest(
        Uri.parse('http://10.0.2.2:3000'),
      );
      if (kDebugMode) {
        print('Cookies available on AboutPage init: $cookies');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Session check error: $e');
      }
      if (_isMounted) {
        setState(() {
          errorMessage = 'Session expired. Please login again.';
        });
      }
    }
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserDataFromCache() async {
    if (!_isMounted) return;

    setState(() {
      isLoading = true;
      errorMessage = errorMessage ?? null;
    });

    try {
      if (kDebugMode) {
        print('Loading user data from SharedPreferences...');
      }
      final prefs = await SharedPreferences.getInstance();
      final cachedData = {
        'username': prefs.getString('username') ?? 'N/A',
        'email': prefs.getString('email') ?? 'N/A',
        'id_users': prefs.getString('userId') ?? 'N/A',
      };

      if (kDebugMode) {
        print('Cached data: $cachedData');
      }

      if (!_isMounted) return;

      if (cachedData['username'] == 'N/A' || cachedData['email'] == 'N/A') {
        setState(() {
          isLoading = false;
          errorMessage = 'Please login to view your account details';
        });
      } else {
        setState(() {
          userData = cachedData;
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error loading cached data: $e\nStackTrace: $stackTrace');
      }
      if (!_isMounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading profile data';
      });
    }
  }

  // Navigate to LoginPage
  void _goToLogin() {
    if (kDebugMode) {
      print('Navigating to LoginPage...');
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_outlined),
          onPressed: () {
            if (kDebugMode) {
              print('Navigating to HomePage...');
            }
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 73, 54, 40),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'About Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 73, 54, 40),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Column(
                        children: [
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _goToLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                              shape: StadiumBorder(),
                              elevation: 5,
                            ),
                            icon: const Icon(Icons.login, color: Colors.white),
                            label: const Text(
                              'Go to Login',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            _buildInfoRow('Nama:', userData['username'] ?? 'N/A'),
                            const SizedBox(height: 16),
                            _buildInfoRow('Email:', userData['email'] ?? 'N/A'),
                            const SizedBox(height: 16),
                            _buildInfoRow('Password:', '*********'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: Builder(
                      builder: (BuildContext buttonContext) {
                        return ElevatedButton(
                          onPressed: () {
                            if (kDebugMode) {
                              print('Logout button pressed');
                            }
                            logout(buttonContext);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            backgroundColor: const Color.fromARGB(255, 73, 54, 40),
                            foregroundColor: Colors.white,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color.fromARGB(255, 73, 54, 40),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}