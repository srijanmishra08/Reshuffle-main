import UIKit
import MapKit

class CustomCardView: UIView {

    private let frontView: UIView
    
    private let nameLabel: UILabel
    private let professionLabel: UILabel
    private let companyLabel: UILabel
    private let reshuffleLabel: UILabel
    private let shuffleImageView: UIImageView

    var businessCard: BusinessCard? {
        didSet {
            updateContent()
        }
    }

    override init(frame: CGRect) {
        frontView = UIView()
        nameLabel = UILabel()
        professionLabel = UILabel()
        companyLabel = UILabel()
        shuffleImageView = UIImageView(image: UIImage(systemName: "shuffle"))
        reshuffleLabel = UILabel()

        super.init(frame: frame)
        
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        frontView.backgroundColor = UIColor(red: 36/255.0, green: 143/255.0, blue: 152/255.0, alpha: 1.0)
        
        frontView.layer.cornerRadius = 10.0
        frontView.layer.shadowColor = UIColor.gray.cgColor
        frontView.layer.shadowOffset = CGSize(width: 0, height: 2)
        frontView.layer.shadowOpacity = 0.5
        frontView.layer.shadowRadius = 5.0
        addSubview(frontView)

        nameLabel.font = UIFont.boldSystemFont(ofSize: 30)
        nameLabel.textAlignment = .center
        nameLabel.textColor = UIColor.white
        frontView.addSubview(nameLabel)

        professionLabel.textAlignment = .center
        professionLabel.textColor = UIColor.white
        frontView.addSubview(professionLabel)

        companyLabel.font = UIFont.boldSystemFont(ofSize: 18)
        companyLabel.textAlignment = .center
        companyLabel.textColor = UIColor.white
        frontView.addSubview(companyLabel)
        
        // Add "RESHUFFLE" label
        
        reshuffleLabel.text = "RESHUFFLE"
        reshuffleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        reshuffleLabel.textColor = UIColor.white
        frontView.addSubview(reshuffleLabel)

        // Shuffle image setup
        shuffleImageView.contentMode = .scaleAspectFit
        shuffleImageView.tintColor = .white
        frontView.addSubview(shuffleImageView)

        setupConstraints()
    }


    private func setupConstraints() {
        frontView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            frontView.centerXAnchor.constraint(equalTo: centerXAnchor),
            frontView.widthAnchor.constraint(equalToConstant: 300),
            frontView.heightAnchor.constraint(equalToConstant: 200),
            frontView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        professionLabel.translatesAutoresizingMaskIntoConstraints = false
        companyLabel.translatesAutoresizingMaskIntoConstraints = false
        reshuffleLabel.translatesAutoresizingMaskIntoConstraints = false
        shuffleImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: frontView.centerYAnchor, constant: -50),
            nameLabel.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -16),
            
            professionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            professionLabel.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 16),
            professionLabel.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -16),

            companyLabel.topAnchor.constraint(equalTo: professionLabel.bottomAnchor, constant: 8),
            companyLabel.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 16),
            companyLabel.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -16),
            
            reshuffleLabel.topAnchor.constraint(equalTo: frontView.topAnchor, constant: 16),
            reshuffleLabel.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -16),
                        
            shuffleImageView.bottomAnchor.constraint(equalTo: frontView.bottomAnchor, constant: -16),
            shuffleImageView.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -16),
            shuffleImageView.widthAnchor.constraint(equalToConstant: 30),
            shuffleImageView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func updateContent() {
        guard let businessCard = businessCard else { return }

        nameLabel.text = businessCard.name
        professionLabel.text = businessCard.profession
        companyLabel.text = businessCard.company
    }
}


import SwiftUI

struct CustomCardViewPreview: UIViewRepresentable {
    var businessCard: BusinessCard?

    func makeUIView(context: Context) -> UIView {
        let customCardView = CustomCardView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        customCardView.businessCard = businessCard
        return customCardView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let uiView = uiView as? CustomCardView else { return }
        uiView.businessCard = businessCard
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CustomCardViewPreview(businessCard: BusinessCard(
            id: UUID(),
            name: "John Doe",
            profession: "Software Engineer",
            email: "john.doe@example.com",
            company: "Apple",
            role: "iOS Developer",
            description: "Passionate about creating awesome apps!",
            phoneNumber: "123-456-7890",
            whatsapp: "123-456-7890",
            address: "123 Main St",
            website: "www.johndoe.com",
            linkedIn: "linkedin.com/in/johndoe",
            instagram: "instagram.com/johndoe",
            xHandle: "@johndoe",
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)),
            trackingMode: .follow))
            .previewLayout(.sizeThatFits)
    }
}
