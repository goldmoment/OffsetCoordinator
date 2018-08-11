//
//  ViewController.swift
//  OffsetCoordinator
//
//  Created by vienvn on 08/11/2018.
//  Copyright (c) 2018 vienvn. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import RxGesture
import OffsetCoordinator

class ViewController: UIViewController {
    
    private lazy var pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                               navigationOrientation: .horizontal, options: nil)
    private lazy var currentPage: Int = 0
    
    private lazy var headerView = UIView()
    private lazy var menuView = UIView()
    private var viewControllers: [UIViewController] = []
    
    var offsetCoordinator: OffsetCoordinator?
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        // Header view
        self.view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        headerView.backgroundColor = UIColor.white
        
        headerView.addSubview(menuView)
        menuView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(44 + UIApplication.shared.statusBarFrame.height)
        }
        menuView.backgroundColor = UIColor.purple
        
        let menuText = UILabel()
        menuView.addSubview(menuText)
        menuText.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        menuText.textColor = UIColor.white
        
        let messageLabel = UILabel()
        headerView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.bottom.equalTo(menuView.snp.top).offset(-8)
            make.left.right.equalToSuperview().inset(8)
            make.top.equalTo(UIApplication.shared.statusBarFrame.height + 8)
        }
        messageLabel.numberOfLines = 0
        messageLabel.text = "Object-Oriented design process involves planning of how objects connect and interact to create a part or a complete system. We all used to Model-View-Controller architecture, that defines the controller object that contains the view and the model. Together this composition creates the backbone for an app. Since a few years there has been a lot, I mean a LOT, of blog posts, tutorials, books, conferences about adapting alternate architecture patterns to mobile applications."
        
        // UIPageViewController
        self.view.insertSubview(pageViewController.view, at: 0)
        self.addChildViewController(pageViewController)
        pageViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.didMove(toParentViewController: self)
        
        viewControllers = [ChildViewController(), ChildViewController(), ChildViewController(), ChildViewController()]
        
        pageViewController.setViewControllers([viewControllers[0]], direction: .forward, animated: true)
        if #available(iOS 11.0, *) { } else {
            pageViewController.rx.methodInvoked(#selector(UIPageViewController.viewDidLayoutSubviews))
                .take(1)
                .subscribe(onNext: { [weak self] _ in
                    if let pageScrollView = self?.pageViewController.view.subviews.first as? UIScrollView {
                        pageScrollView.contentOffset.y = 0
                    }
                })
                .disposed(by: disposeBag)
        }
        
        // Collection view
        self.offsetCoordinator = OffsetCoordinator(headerView: self.headerView,
                                                   menuView: self.menuView,
                                                   viewControllers: self.viewControllers)
        
        menuView.rx.tapGesture().when(.ended)
            .subscribe(onNext: { _ in
                if messageLabel.text == "Hello" {
                    messageLabel.text = "Object-Oriented design process involves planning of how objects connect and interact to create a part or a complete system. We all used to Model-View-Controller architecture, that defines the controller object that contains the view and the model. Together this composition creates the backbone for an app. Since a few years there has been a lot, I mean a LOT, of blog posts, tutorials, books, conferences about adapting alternate architecture patterns to mobile applications."
                } else {
                    messageLabel.text = "Hello"
                }
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        print("☠️ViewController deinit")
    }
}

extension ViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let index = viewControllers.index(of: viewController), index - 1 >= 0 {
            return viewControllers[index - 1]
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = viewControllers.index(of: viewController), index + 1 < viewControllers.count {
            return viewControllers[index + 1]
        }
        
        return nil
    }
}
