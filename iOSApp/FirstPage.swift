import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore
//tab bar code
struct FirstPage: View {
    @State private var selectedTab = 0
    @StateObject private var userDataViewModel = UserDataViewModel()
    @State private var user = BusinessCard(id: UUID(), name: "", profession: "", email: "", company: "", role: "", description: "", phoneNumber: "", whatsapp: "", address: "", website: "", linkedIn: "", instagram: "", xHandle: "", region: MKCoordinateRegion(center: CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)),
                                           trackingMode: .follow)
    var body: some View {
        TabView(selection: $selectedTab) {
            
                NextView()
                .tabItem {
                    Image(systemName: "map")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 30)
                        .padding(.top)
                    Text("Explore")
                }
                .tag(0)
            
            MyCards()
                .environmentObject(userDataViewModel)
                .tabItem {
                    Image(systemName: "creditcard")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 30)
                        .padding(.top)
                    Text("My Cards")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 30)
                        .padding(.top)
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.black)
    }
}


struct FirstPage_Previews: PreviewProvider {
    static var previews: some View {
        FirstPage()
    }
}
