//
//  ContentView.swift
//  ChatGPT
//
//  Created by ST SE on 8/3/2023.
//

import SwiftUI
import WebKit

struct ContentView: View {
    
    // 初始化webView实例
    var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let websiteDataStore = WKWebsiteDataStore.default()
        config.websiteDataStore = websiteDataStore
        let webView = WKWebView(frame: .zero, configuration: config)
        return webView
    }()
    
    // 初始化State存储cookies和lastURL信息
    @State private var cookies: [HTTPCookie] = []
    @State private var lastURL: URL? = nil
    
    var body: some View {
        WebView(webView: webView, cookies: $cookies, lastURL: $lastURL)
            .onAppear(perform: {
                // 如果有上次浏览的URL，恢复到上次浏览位置
                if let lastURL = lastURL {
                    let request = URLRequest(url: lastURL)
                    webView.load(request)
                } else {
                    // 否则打开默认网站
                    let url = URL(string: "https://chat.openai.com")!
                    let request = URLRequest(url: url)
                    webView.load(request)
                }
            })
            .onChange(of: cookies, perform: { _ in
                // 当cookies更新时保存到websiteDataStore中
                webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                    self.cookies = cookies
                }
            })
            .onChange(of: webView.url, perform: { url in
                // 当浏览的URL更新时保存到lastURL中
                lastURL = url
            })
    }
}

// 为了简化 ContentView 中的代码，这里定义了一个 WebView 视图
struct WebView: UIViewRepresentable {
    
    let webView: WKWebView
    @Binding var cookies: [HTTPCookie]
    @Binding var lastURL: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    // 确保所有的网页数据保存在 websiteDataStore 中
    static func dismantleUIView(_ uiView: Self.UIViewType, coordinator: ()) {
        uiView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            uiView.configuration.websiteDataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) {
                    cookies.forEach{ cookies in
                        
                        uiView.configuration.websiteDataStore.httpCookieStore.setCookie(cookies, completionHandler: nil)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
