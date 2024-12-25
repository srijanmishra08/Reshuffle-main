import UIKit
import MapKit
import SwiftUI
import SwiftUICore

class CustomCardView: UIView {
    private let frontView: UIView
    private let nameLabel: UILabel
    private let roleLabel: UILabel
    private let atCompanyLabel: UILabel
    private let professionLabel: UILabel
    
    var cardColor: UIColor = UIColor(red: 36/255.0, green: 143/255.0, blue: 152/255.0, alpha: 1.0) {
        didSet {
            updateCardColor()
        }
    }
    
    var businessCard: BusinessCard? {
        didSet {
            updateContent()
        }
    }
    
    override init(frame: CGRect) {
        frontView = UIView()
        nameLabel = UILabel()
        roleLabel = UILabel()
        atCompanyLabel = UILabel()
        professionLabel = UILabel()
        
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        frontView.layer.cornerRadius = 16.0
        frontView.layer.shadowColor = UIColor.black.cgColor
        frontView.layer.shadowOffset = CGSize(width: 0, height: 4)
        frontView.layer.shadowOpacity = 0.15
        frontView.layer.shadowRadius = 8.0
        addSubview(frontView)
        
        nameLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        nameLabel.textAlignment = .left
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 0
        frontView.addSubview(nameLabel)
        
        roleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)  // Made role bold
        roleLabel.textAlignment = .left
        roleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        roleLabel.numberOfLines = 0
        frontView.addSubview(roleLabel)
        
        atCompanyLabel.textAlignment = .left
        atCompanyLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        atCompanyLabel.numberOfLines = 0
        frontView.addSubview(atCompanyLabel)
        
        professionLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        professionLabel.textAlignment = .left
        professionLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        professionLabel.numberOfLines = 0
        frontView.addSubview(professionLabel)
        
        setupConstraints()
        updateCardColor()
    }
    
    private func updateCardColor() {
        frontView.backgroundColor = cardColor
    }
    
    private func setupConstraints() {
        frontView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        atCompanyLabel.translatesAutoresizingMaskIntoConstraints = false
        professionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            frontView.centerXAnchor.constraint(equalTo: centerXAnchor),
            frontView.widthAnchor.constraint(equalToConstant: 300),
            frontView.heightAnchor.constraint(equalToConstant: 200),
            frontView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: frontView.topAnchor, constant: 32),
            nameLabel.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 24),
            nameLabel.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -24),
            
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            roleLabel.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 24),
            roleLabel.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -24),
            
            atCompanyLabel.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 4),
            atCompanyLabel.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 24),
            atCompanyLabel.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -24),
            
            professionLabel.topAnchor.constraint(equalTo: atCompanyLabel.bottomAnchor, constant: 8),
            professionLabel.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 24),
            professionLabel.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -24),
        ])
    }
    
    private func updateContent() {
        guard let businessCard = businessCard else { return }
        
        nameLabel.text = businessCard.name
        roleLabel.text = businessCard.role
        
        // Create attributed string for "at Company" with different weights
        let atCompanyText = NSMutableAttributedString(
            string: "at ",
            attributes: [
                .font: UIFont.systemFont(ofSize: 18, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
        )
        
        let companyText = NSAttributedString(
            string: businessCard.company,
            attributes: [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
        )
        
        atCompanyText.append(companyText)
        atCompanyLabel.attributedText = atCompanyText
        
        professionLabel.text = businessCard.profession
    }
}

struct CustomCardViewPreview: UIViewRepresentable {
    var businessCard: BusinessCard?
    var cardColor: UIColor = UIColor(red: 36/255.0, green: 143/255.0, blue: 152/255.0, alpha: 1.0)
    
    func makeUIView(context: Context) -> UIView {
        let customCardView = CustomCardView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        customCardView.businessCard = businessCard
        customCardView.cardColor = cardColor
        return customCardView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let uiView = uiView as? CustomCardView else { return }
        uiView.businessCard = businessCard
        uiView.cardColor = cardColor
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
            role: "Senior iOS Developer",
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
