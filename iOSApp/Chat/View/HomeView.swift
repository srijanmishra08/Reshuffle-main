//
//  HomeView.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 25/02/24.
//


import SwiftUI

struct HomeView: View {
    @State private var isLoading: Bool = true
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                Image("bigchat")
                    .opacity(isLoading ? 0 : 1)
                    .animation(.easeInOut)
                
                if isLoading {
                    LoadingAnimation() 
                }
                
                Image("smallchat")
                    .opacity(isLoading ? 0 : 1)
                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                    .animation(.easeInOut)
            }
            .padding(.bottom, 74)
            
            Spacer()
        }
        .background(Color.white)
        .ignoresSafeArea()
        .onAppear {
        }
    }
}

struct LoadingAnimation: View {
    @State private var rotationAngle: Angle = .degrees(0)
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding(20)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(16)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                            rotationAngle = .degrees(360)
                        }
                    }
                    .rotationEffect(rotationAngle)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
