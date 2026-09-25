//
//  modalUIPageViewController.swift
//  ChatLoader
//
//  Created by Paul Whiten on 24/9/26.
//  Copyright © 2026 Paul Michael Whiten. All rights reserved.
//
//  Used as a UIPageViewController
//
//  Usage:
//      - initalise from a ViewController
//      - wrap this class in a UINavigationController
//      - present the UINavigationController from the initialising ViewContoller
//


import Foundation
import UIKit

class modalPageViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    //MARK: class variables
    private var pageController: UIPageViewController?
    private var currentIndex: Int = 0
    
    var appNames: [String] = ["ChatLoader",
                              "ChatShots",
                              "ChatPDF",
                               "ChatMerge"]

    //MARK: lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set the page view indicator
        let pageViewIndicatorControl = UIPageControl.appearance()
        pageViewIndicatorControl.pageIndicatorTintColor = .lightGray
        pageViewIndicatorControl.currentPageIndicatorTintColor = Helper.app.colorPrimary
        
        self.setupPagVieweController()
    }
    
    
    //MARK: class functions
    private func setupPagVieweController() {
        
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.title = "More ChatTools apps"
        
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.buttonClose))
        closeButton.tintColor = Helper.app.colorPrimary
        self.navigationItem.leftBarButtonItem = closeButton
        
        self.pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.pageController?.dataSource = self
        self.pageController?.delegate = self
        
        self.pageController?.view.backgroundColor = .clear
        self.addChild(self.pageController!)
        self.view.addSubview(self.pageController!.view)
        
        
        pageController?.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pageController?.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            pageController?.view.bottomAnchor.constraint(equalTo: self.view.readableContentGuide.bottomAnchor),
            
            pageController?.view.leadingAnchor.constraint(equalTo: self.view.readableContentGuide.leadingAnchor),
            pageController?.view.trailingAnchor.constraint(equalTo: self.view.readableContentGuide.trailingAnchor),
        ] as! [NSLayoutConstraint])
        
        
        let firstVC = appDetailsViewController()
        firstVC.pageIndex = self.currentIndex
        
        
        self.pageController?.setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        
        self.pageController?.didMove(toParent: self)
    }
    
    
    @objc func buttonClose() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: pageviewcontroller delegate
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let currentVC = viewController as? appDetailsViewController else {
            return nil
        }
        
        var index = currentVC.pageIndex
        
        if index == 0 {
            return nil
        }
        
        index -= 1
        
        let vc = appDetailsViewController()
        vc.pageIndex = index
        
        return vc
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let currentVC = viewController as? appDetailsViewController else {
            return nil
        }
        
        var index = currentVC.pageIndex
        
        if index >= self.appNames.count - 1 {
            return nil
        }
        
        index += 1
        
        let vc = appDetailsViewController()
        vc.pageIndex = index
        
        return vc
    }
    
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.appNames.count
    }
    
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return self.currentIndex
    }
    
}

