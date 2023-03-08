//
//  ContentView.swift
//  ChatGPT
//
//  Created by ST SE on 8/3/2023.
//

import SwiftUI
import WebKit

struct ContentView: View {
    
    // init .webView 
    var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let websiteDataStore = WKWebsiteDataStore.default()
        config.websiteDataStore = websiteDataStore
        let webView = WKWebView(frame: .zero, configuration: config)
        return webView
    }()
    
    
    @State private var cookies: [HTTPCookie] = []
    @State private var lastURL: URL? = nil
    
    var body: some View {
        WebView(webView: webView, cookies: $cookies, lastURL: $lastURL)
            .onAppear(perform: {
                // view last url
                if let lastURL = lastURL {
                    let request = URLRequest(url: lastURL)
                    webView.load(request)
                } else {
                    // view default web
                    let url = URL(string: "https://chat.openai.com")!
                    let request = URLRequest(url: url)
                    webView.load(request)
                }
            })
            .onChange(of: cookies, perform: { _ in
                // update cookie
                webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                    self.cookies = cookies
                }
            })
            .onChange(of: webView.url, perform: { url in
                // url save to lasturl
                lastURL = url
            })
    }
}

struct WebView: UIViewRepresentable {
    
    let webView: WKWebView
    @Binding var cookies: [HTTPCookie]
    @Binding var lastURL: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
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
