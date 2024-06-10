

import 'package:flutter/material.dart'; // Flutter UI 라이브러리
import 'package:webview_flutter/webview_flutter.dart'; // WebView 패키지

class NavigationControls extends StatelessWidget {
  const NavigationControls({super.key, required this.webViewController});

  // 웹뷰 컨트롤러를 받아옵니다.
  final WebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // '뒤로 가기' 버튼
        IconButton(
          icon: const Icon(Icons.arrow_back_ios), // 뒤로 가기 아이콘 설정
          onPressed: () async {
            if (await webViewController.canGoBack()) {
              // 이전 페이지로 이동할 수 있는지 확인
              await webViewController.goBack(); // 이전 페이지로 이동
            } else {
              if (context.mounted) {
                // 이동할 수 없으면 알림 메시지 표시
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No back history item')), // 뒤로 갈 페이지가 없음을 알림
                );
              }
            }
          },
        ),
        // '앞으로 가기' 버튼
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios), // 앞으로 가기 아이콘 설정
          onPressed: () async {
            if (await webViewController.canGoForward()) {
              // 다음 페이지로 이동할 수 있는지 확인
              await webViewController.goForward(); // 다음 페이지로 이동
            } else {
              if (context.mounted) {
                // 이동할 수 없으면 알림 메시지 표시
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No forward history item')), // 앞으로 갈 페이지가 없음을 알림
                );
              }
            }
          },
        ),
        // '새로고침' 버튼
        IconButton(
          icon: const Icon(Icons.replay), // 새로고침 아이콘 설정
          onPressed: () => webViewController.reload(), // 현재 페이지 새로고침
        ),
      ],
    );
  }
}
