//
//  ContentView.swift
//  iOSApp
//
//  Created by Aditya Majumdar on 12/12/23.

import SwiftUI
import Combine

struct OnboardingScreenView: View {
    let imageName: String
    let title: String
    let description: String
    let isLastScreen: Bool
    let action: () -> Void

    @Binding var isGetStartedActive: Bool
    @Binding var isLoginViewPresented: Bool
    var userData: UserData

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    isLoginViewPresented = true
                }) {
                    Text("Skip")
                        .foregroundColor(.gray)
                        .padding(8)
                }
                .padding(.top, 20)
                .padding(.trailing, 5)
            }

            Image("Reshufflelogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 250, height: 250)
                .foregroundColor(.green)
                .padding(.top, -100)

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 200, maxHeight: 200)
                .padding()

            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)

            Text(description)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .foregroundColor(.gray)

            Spacer()

            if isLastScreen {
                Button(action: {
                    action()
                    isGetStartedActive = true
                    isLoginViewPresented = true
                }) {
                    Text("Let's Get Started")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .padding(.bottom, 60)
            } else {
                Spacer()
                Spacer()
            }
        }
        .padding()
    }
}


struct ContentView: View {
    @State private var currentPage = 0
    @State private var isGetStartedActive = false
    @State private var isLoginViewPresented = false
    @EnvironmentObject private var userData: UserData

    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                OnboardingScreenView(imageName: "card", title: "Create Your Card", description: "Craft a stunning digital business card with Reshuffle.", isLastScreen: false, action: {
                    currentPage += 1
                }, isGetStartedActive: $isGetStartedActive, isLoginViewPresented: $isLoginViewPresented, userData: userData)
                .tag(0)

                OnboardingScreenView(imageName: "qr-code", title: "Share with QR", description: "Share your card effortlessly using QR codes.", isLastScreen: false, action: {
                    currentPage += 1
                }, isGetStartedActive: $isGetStartedActive, isLoginViewPresented: $isLoginViewPresented, userData: userData)
                .tag(1)

                OnboardingScreenView(imageName: "networking", title: "Start Networking", description: "Connect with professionals and explore new opportunities.", isLastScreen: true, action: {
                    currentPage = 0
                }, isGetStartedActive: $isGetStartedActive, isLoginViewPresented: $isLoginViewPresented, userData: userData)
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .gesture(DragGesture().onEnded { value in
                let horizontalAmount = value.translation.width
                let offset = horizontalAmount > 0 ? -1 : 1
                currentPage = (currentPage + offset) % 3
            })

            if isLoginViewPresented {
                LoginView(userData: userData)
                    .navigationBarBackButtonHidden(true)
                    .onDisappear {
                        isLoginViewPresented = false
                    }
            }
        }
    }
}

struct OnboardingPage_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
            .environmentObject(UserData())
    }
}
