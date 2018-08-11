//
//  OffsetCoordinator.swift
//  OffsetCoordinator
//
//  Created by Vien Van Nguyen on 8/11/18.
//  Copyright © 2018 Vien Van Nguyen. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

fileprivate typealias ContentOffsetParams = (CGPoint, CGPoint, UIScrollView)

open class OffsetCoordinator {
    private var headerView: UIView
    private var menuView: UIView
    private var scrollViews: [UIScrollView]
    
    private var headerTopConstraint: NSLayoutConstraint?
    private var disposeBag = DisposeBag()
    
    public init(headerView: UIView, menuView: UIView, viewControllers: [UIViewController]) {
        self.headerView = headerView
        self.menuView = menuView
        self.scrollViews = []
        
        self.headerTopConstraint = headerView.topLayoutConstraint
        
        let headerHeight = headerView.rx.observe(CGRect.self, #keyPath(UIView.bounds))
            .unwrap()
            .map { $0.height }.distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)
        
        headerHeight
            .subscribe(updateAllContentInset)
            .disposed(by: disposeBag)
        
        for viewController in viewControllers {
            let scrollView = Observable.merge(
                viewController.rx.methodInvoked(#selector(UIViewController.viewDidLoad))
                    .map { _ in return true },
                Observable.just(viewController.isViewLoaded)
                )
                .filter { $0 }
                .map { _ in return viewController.firstScrollView }
                .unwrap()
                .do(onNext: { [weak self] scrollView in
                    self?.scrollViews.append(scrollView)
                })
                .share(replay: 1, scope: .whileConnected)
            
            // Update content inset top of scroll view in view controller
            scrollView.flatMapLatest { $0.rx.reloadCompleted }
                .subscribe(updateContentInset)
                .disposed(by: disposeBag)
            
            scrollView.flatMapLatest { $0.contentOffsetParams(with: headerHeight) }
                .skip(1) // Ignore the first value cause update content inset at the begin
                .subscribe(updateContentOffset)
                .disposed(by: disposeBag)
        }
    }
    
    deinit {
        print("☠️ScrollCoordinator deinit")
    }
    
    // Binder
    private var updateAllContentInset: Binder<CGFloat> {
        return Binder(self) { vc, height in
            vc.headerTopConstraint?.constant = 0
            
            var margin = height
            if #available(iOS 11.0, *) {
                margin -= UIApplication.shared.statusBarFrame.height
            }
            
            vc.scrollViews.forEach {
                $0.stopScroll()
                $0.contentInset.top = max(0, margin)
                $0.scrollIndicatorInsets = $0.contentInset
                $0.contentOffset.y = max($0.contentOffset.y, -height)
            }
        }
    }
    
    private var updateContentInset: Binder<UIScrollView> {
        return Binder(self) { vc, scrollView in
            guard let headerTop = vc.headerTopConstraint?.constant else { return }
            let height = vc.headerView.bounds.height
            var margin = height
            if #available(iOS 11.0, *) {
                margin -= UIApplication.shared.statusBarFrame.height
            }
            scrollView.contentInset.top = max(0, margin)
            scrollView.contentOffset = CGPoint(x: 0, y: -height - headerTop)
            scrollView.scrollIndicatorInsets = scrollView.contentInset
        }
    }
    
    private var updateContentOffset: Binder<ContentOffsetParams> {
        return Binder(self) {vc, params in
            guard let currentHeaderTop = vc.headerTopConstraint?.constant else { return }
            let (previousPoint, currentPoint, currentCollectionView) = params
            let headerHeight = vc.headerView.frame.height
            let menuHeight = vc.menuView.frame.height
            // Calculate new constant of header top constraint
            let contentOffsetDelta = currentPoint.y - previousPoint.y
            let newConstant = min(0, max(currentHeaderTop - contentOffsetDelta, menuHeight - headerHeight))
            // Calculate delta of contentOffset of other UIScrolViews
            let constantDelta = newConstant - currentHeaderTop
            
            let update = {
                vc.headerTopConstraint?.constant = newConstant
                vc.scrollViews
                    .filter { $0 != currentCollectionView }
                    .forEach { $0.contentOffset.y -= constantDelta }
            }
            
            if contentOffsetDelta > 0 { // up
                update()
            } else { // down
                // Hold header on the top
                if -currentPoint.y > menuHeight {
                    update()
                }
            }
        }
    }
}

fileprivate extension UIView {
    var topLayoutConstraint: NSLayoutConstraint? {
        guard let superview = self.superview else { return nil }
        return superview.constraints.filter {
            if let firstView = $0.firstItem as? UIView,
                let secondView = $0.secondItem as? UIView
            {
                return (firstView == self && $0.firstAttribute == .top) ||
                    (secondView == self && $0.secondAttribute == .top)
            }
            return false
            }.first
    }
}

fileprivate extension UIViewController {
    var firstScrollView: UIScrollView? {
        return self.view.subviews.filter { $0 is UIScrollView }.first as? UIScrollView
    }
}

fileprivate extension UIScrollView {
    func contentOffsetParams(with headerHeight: Observable<CGFloat>) -> Observable<ContentOffsetParams> {
        return Observable.deferred {
            let isScrolling = self.rx.isScrolling
            let contentOffset = Observable.combineLatest(self.rx.contentOffset, headerHeight)
                .map { CGPoint(x: $0.0.x , y: max($0.0.y, -$0.1)) } // Prevent bounce down
                .pairwise()
            
            return Observable.combineLatest(contentOffset, isScrolling, Observable.of(self))
                .filter { $0.1 }
                .map { ($0.0.0, $0.0.1, $0.2) }
        }
    }
    
    func stopScroll() {
        self.setContentOffset(self.contentOffset, animated: false)
    }
}

fileprivate extension Reactive where Base: UIScrollView {
    var isScrolling: Observable<Bool> {
        return Observable.merge(
            self.willBeginDragging.map { true },
            self.didEndDragging.filter { !$0 },
            self.didEndDecelerating.map { false }
            )
            .distinctUntilChanged()
    }
    
    var reloadCompleted: Observable<UIScrollView> {
        return self.observeWeakly(CGSize.self, #keyPath(UIScrollView.contentSize), options: [.new])
            .unwrap()
            .distinctUntilChanged()
            .map { _ in return self.base }
    }
}

fileprivate extension ObservableType {
    func nwise(_ n: Int) -> Observable<[E]> {
        return self
            .scan([]) { acc, item in Array((acc + [item]).suffix(n)) }
            .filter { $0.count == n }
    }
    
    func pairwise() -> Observable<(E, E)> {
        return self.nwise(2)
            .map { ($0[0], $0[1]) }
    }
    
    func ternate() -> Observable<(E, E, E)> {
        return self.nwise(3)
            .map { ($0[0], $0[1], $0[2]) }
    }
}

fileprivate extension ObservableType {
    func unwrap<T>() -> Observable<T> where E == T? {
        return self.filter { $0 != nil }.map { $0! }
    }
}
