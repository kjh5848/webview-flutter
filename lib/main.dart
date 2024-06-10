import 'dart:async'; // 비동기 프로그래밍을 위한 패키지
import 'package:flutter/material.dart'; // Flutter UI 라이브러리
import 'package:webview_flutter/webview_flutter.dart'; // WebView 패키지
import 'package:webview_flutter_android/webview_flutter_android.dart'; // Android용 WebView 패키지
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart'; // iOS용 WebView 패키지
import 'navigation_controls.dart';
import 'sample_menu.dart';

void main() => runApp(const MaterialApp(home: WebViewExample())); // 애플리케이션 시작점

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  late final WebViewController _controller; // 웹뷰 컨트롤러 변수

  @override
  void initState() {
    super.initState();

    // 플랫폼에 따라 웹뷰 컨트롤러 생성 파라미터를 설정
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      // iOS용 웹뷰 설정
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true, // 인라인 미디어 재생 허용
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{}, // 사용자 액션이 필요한 미디어 타입 설정
      );
    } else {
      // Android용 웹뷰 설정
      params = const PlatformWebViewControllerCreationParams();
    }

    // 웹뷰 컨트롤러 생성
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    // 웹뷰 컨트롤러 설정
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // 자바스크립트 허용
      ..setBackgroundColor(const Color(0x00000000)) // 배경색 설정
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // 페이지 로딩 진행 상태를 출력
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            // 페이지 로딩 시작 시 출력
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            // 페이지 로딩 완료 시 출력
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            // 페이지 리소스 로딩 오류 시 출력
            debugPrint('''
              Page resource error:
              code: ${error.errorCode}
              description: ${error.description}
              errorType: ${error.errorType}
              isForMainFrame: ${error.isForMainFrame}
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            // 특정 URL로의 네비게이션을 차단
            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
          onHttpError: (HttpResponseError error) {
            // HTTP 오류 처리
            debugPrint('Error occurred on page: ${error.response?.statusCode}');
          },
          onUrlChange: (UrlChange change) {
            // URL 변경 시 출력
            debugPrint('url change to ${change.url}');
          },
          onHttpAuthRequest: (HttpAuthRequest request) {
            // HTTP 인증 요청 처리
            openDialog(request);
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          // 자바스크립트 채널을 통해 받은 메시지 처리
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadRequest(Uri.parse('https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=hagbQ0neJqK_tY4moEfX&redirect_uri=http://localhost:8080/oauth/naver/callback&state=test')); // 웹뷰에 로드할 URL 설정

    // 플랫폼별 추가 설정
    if (controller.platform is AndroidWebViewController) {
      // Android에서 디버깅 허용 및 미디어 재생 설정
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller; // 컨트롤러를 멤버 변수로 설정
  }

  @override
  Widget build(BuildContext context) {
    // 웹뷰 위젯을 반환합니다.
    return Scaffold(
      backgroundColor: Colors.green, // 배경색 설정
      appBar: AppBar(
        title: const Text('Flutter WebView example'),
        // 웹뷰 위에 Flutter 위젯을 표시하기 위한 드롭다운 메뉴
        actions: <Widget>[
          NavigationControls(webViewController: _controller), // 네비게이션 컨트롤
          SampleMenu(webViewController: _controller), // 샘플 메뉴
        ],
      ),
      body: WebViewWidget(controller: _controller), // 웹뷰를 본문으로 설정
      floatingActionButton: favoriteButton(), // 플로팅 액션 버튼
    );
  }

  Widget favoriteButton() {
    // 즐겨찾기 버튼 생성
    return FloatingActionButton(
      onPressed: () async {
        final String? url = await _controller.currentUrl(); // 현재 URL 가져오기
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Favorited $url')), // 즐겨찾기 URL 출력
          );
        }
      },
      child: const Icon(Icons.favorite), // 버튼 아이콘 설정
    );
  }

  Future<void> openDialog(HttpAuthRequest httpRequest) async {
    // HTTP 인증 요청을 처리하기 위한 다이얼로그를 생성합니다.
    final TextEditingController usernameTextController =
        TextEditingController();
    final TextEditingController passwordTextController =
        TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 외부를 클릭해도 닫히지 않도록 설정
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${httpRequest.host}: ${httpRequest.realm ?? '-'}'),
          // 다이얼로그 제목에 요청 호스트와 영역 표시
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // 사용자명 입력 필드
                TextField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  autofocus: true, // 다이얼로그가 열리면 자동으로 포커스
                  controller: usernameTextController,
                ),
                // 비밀번호 입력 필드
                TextField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  controller: passwordTextController,
                  obscureText: true, // 비밀번호 마스킹 처리
                ),
              ],
            ),
          ),
          actions: <Widget>[
            // 취소 버튼
            TextButton(
              onPressed: () {
                httpRequest.onCancel(); // 요청 취소 처리
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const Text('Cancel'),
            ),
            // 인증 버튼
            TextButton(
              onPressed: () {
                httpRequest.onProceed(
                  WebViewCredential(
                    user: usernameTextController.text,
                    password: passwordTextController.text,
                  ),
                ); // 입력된 사용자명과 비밀번호로 인증 처리
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const Text('Authenticate'),
            ),
          ],
        );
      },
    );
  }
}
