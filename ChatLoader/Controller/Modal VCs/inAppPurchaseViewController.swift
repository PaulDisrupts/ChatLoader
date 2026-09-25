//
//  inAppPurchaseViewController.swift
//  ChatLoader
//
//  Created by Paul Whiten on 27/5/26.
//
//  Used for in-app purchases
//
//  Usage:
//      - initalise from a ViewController
//      - set the delegate: protocolDataChanged? as the ViewController
//      - wrap this class in a UINavigationController
//      - present the UINavigationController from the delegate ViewContoller
//      - note: ensure to update Helper.upgradeProductIdentifier with the correct product identifiers
//

import UIKit
import StoreKit

class inAppPurchaseViewController: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    //MARK: class variables
    var delegate: protocolDataChanged?
    
    var productsArray: Array<SKProduct?> = []
    var transactionInProgress: Bool = false
    var localPrice: String?
    
    let labelHeight: CGFloat = 80
    let imageHeight: CGFloat = 400
    let spacer: CGFloat = 8
    
    var inAppPurchaseImages = ["ChatLoader_logo_1024.png",
                               "ChatShots 180x180_Icon.png",
                               "ChatPDF logo 180x180.png"]
    
    let imageDuration: TimeInterval = 3  //seconds to show each image
    
    
    //MARK: lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.systemGroupedBackground
        self.isModalInPresentation = true
        
        SKPaymentQueue.default().add(self)
        requestProductInfo()
        
        localPrice = "Loading price..."
        
        navigationItem.title = "Purchase to share PDFs"
        let purchaseButton = UIBarButtonItem(title: "\(localPrice!)", style: .plain, target: self, action: #selector(self.confirmPurchase))
        purchaseButton.tintColor = Helper.app.colorPrimary
        
        if #available(iOS 26.0, *) {
            purchaseButton.style = .prominent
        }
        
        self.navigationItem.rightBarButtonItems = [purchaseButton]
        
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.buttonClose))
        closeButton.tintColor = Helper.app.colorPrimary
        self.navigationItem.leftBarButtonItem = closeButton
        

        var inAppPurchaseImagesArray:[UIImage] = []
        for image in inAppPurchaseImages {
            inAppPurchaseImagesArray.append(UIImage(named: image)!)
        }
        
        let labelDescription = UILabel()
        labelDescription.text = "One time puchase allows you to share all your PDFs - to WhatsApp, Messages, social media, email or any other app"
        labelDescription.numberOfLines = 0
        labelDescription.textColor = .darkGray
        labelDescription.font = .italicSystemFont(ofSize: 17)
        labelDescription.textAlignment = .left
        labelDescription.sizeToFit()
        labelDescription.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(labelDescription)
        
        
        let imageView = UIImageView(image: UIImage.animatedImage(with: inAppPurchaseImagesArray, duration: imageDuration))
        imageView.contentMode = .scaleAspectFit
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 1, height: 2)
        imageView.layer.shadowOpacity = 0.7
        imageView.layer.shadowRadius = spacer/3
        imageView.layer.masksToBounds = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(imageView)
        
        
        NSLayoutConstraint.activate([
            labelDescription.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            
            labelDescription.leadingAnchor.constraint(equalTo: self.view.readableContentGuide.leadingAnchor, constant: 2*spacer),
            labelDescription.trailingAnchor.constraint(equalTo: self.view.readableContentGuide.trailingAnchor, constant: -2*spacer),
            
            
            imageView.topAnchor.constraint(equalTo: labelDescription.topAnchor, constant: labelHeight),
            imageView.bottomAnchor.constraint(equalTo: self.view.readableContentGuide.bottomAnchor),
            
            imageView.leadingAnchor.constraint(equalTo: self.view.readableContentGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.view.readableContentGuide.trailingAnchor),
        ])
    }
    
    
    //MARK: class functions
    @objc func buttonClose() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @objc func confirmPurchase() {
        //user selects to make/restore a purchase; only options for message = "purchase" and "restore"
        
        //prevent multiple SKPaymentQueue calls
        if transactionInProgress {
            return
        }
        
        if SKPaymentQueue.canMakePayments() && (self.productsArray.count > 0) {

            print("inAppPurchaseViewController:confirmPurchase: About to purchase: \(String(describing: self.productsArray[0]))")
            
            let payment = SKPayment(product: self.productsArray[0]!)
            SKPaymentQueue.default().add(payment)
            self.transactionInProgress = true
            
        } else {
            print("inAppPurchaseViewController:confirmPurchase: cannot make payments")
            
            cancelledInApp(userCancelled: false)
        }
    }
    
    
    func requestProductInfo() {
        print("func requestProductInfo() {")
        
        if SKPaymentQueue.canMakePayments() {
            
            let productIdentifiers = NSSet(array: [Helper.app.upgradeProductIdentifier])
            let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String>)

            productRequest.delegate = self
            productRequest.start()
        
        } else {
            print("Cannot perform In App Purchases.")
        }
    }
    
    
    func cancelledInApp(userCancelled:Bool) {
             
         print("func cancelledInApp(userCancelled:Bool) { \(userCancelled)")
         
        if !userCancelled {
            //issue with App Store purchase (as opposed to user selecting "Cancel" from inAppPurchaseUIAlert)
            
            let alertTitle = "Purchase not made"
            let msg = "Please try again later"
            
            //inform user on outcome
            let alertController = UIAlertController(title: alertTitle, message: msg, preferredStyle: .alert)
            
            let actionOK = UIAlertAction(title: "OK", style: .cancel) { (action) in
//                self.dismiss(animated: true)    //will dismiss the entire navigation controller and all view controllers currently sitting inside its stack
            }
            actionOK.setValue(Helper.app.colorPrimary, forKey: "titleTextColor")
            
            alertController.addAction(actionOK)
            
            self.present(alertController, animated: true)
        }
     }
    
    
    func didPurchaseItem(_ success:Bool, restored:Bool) {
        
        print("func didPurchaseItem(_ success:Bool, restored:Bool): \(success), \(restored)")
        
        if success {
            
            //set the non-consumable purchase
            Helper.app.inAppPurchaseSuccessful()

            //update the user on successful purchase
            let alertController = UIAlertController(title: "Purchase successful!", message: nil, preferredStyle: .alert)
            
            let actionOK = UIAlertAction(title: "Done", style: .default) { (action) in
                self.dismiss(animated: true) {
                    //will dismiss the entire navigation controller and all view controllers currently sitting inside its stack
                    self.delegate?.protocolDataChanged_inAppPurchase(message: "success")
                }
            }
            
            actionOK.setValue(Helper.app.colorPrimary, forKey: "titleTextColor")
            alertController.addAction(actionOK)
            
            self.present(alertController, animated: true) {}
            
        }
        else { //if success
            
            //update the user on unsuccessful purchase
            self.cancelledInApp(userCancelled: false)
        }
    }
    
    
    //MARK: SKProductsRequestDelegate
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        if response.invalidProductIdentifiers.count != 0 {
            print("WARNING: \(response.invalidProductIdentifiers.description)")
            
            Task {
                if let purchaseButton = self.navigationItem.rightBarButtonItem, (localPrice != nil) {
                    purchaseButton.title = "Unavailable"
                }
            }
        }
        
        //confirm product details
        if response.products.count != 0 {
            
            for product in response.products {
                
                if let tempP = product as SKProduct? {
                    
                    self.productsArray.append(tempP)
                    
                    print(tempP.localizedTitle)
                    print(tempP.localizedDescription)
                    print(tempP.productIdentifier)
                    print(tempP.price)
                    print(tempP.priceLocale)
                    
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.locale = tempP.priceLocale
                    localPrice = formatter.string(from: tempP.price)!
                    
                    Task {
                        if let purchaseButton = self.navigationItem.rightBarButtonItem, (localPrice != nil) {
                            purchaseButton.title = "\(localPrice!)"
                        }
                    }
                } //if let tempP = product as SKProduct?
            } //for product in response.products
            
        } //if response.products.count != 0
        else {
            print("ERROR: func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!); no products found")
        }
    }
    
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        // user cancels logging into iTunes when attempting to restore
        
        print("func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {")
            
        transactionInProgress = false
        self.didPurchaseItem(false, restored: false)
    }
        
        
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!): \(transactions.count)")
                
        
        for transaction in transactions {
            
            switch transaction.transactionState {
                
            case SKPaymentTransactionState.purchasing:
                print("SKPaymentTransactionState.purchasing")
                
                
            case SKPaymentTransactionState.purchased:
                
                print("SKPaymentTransactionState.purchased")
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                self.didPurchaseItem(true, restored: false)
                //Apple API gives confirmation message
                
                
            case SKPaymentTransactionState.restored:
                
                print("SKPaymentTransactionState.restored")
                print("transaction.originalTransaction: \(String(describing: transaction.original))")
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                self.didPurchaseItem(true, restored: true)
                
                
            case SKPaymentTransactionState.failed:
                
                print("SKPaymentTransactionState.failed");
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                self.didPurchaseItem(false, restored: false)
                
                
            default:
                print("SKPaymentTransactionState default: \(transaction.transactionState.rawValue)");
            }
        }
    }
    
}
