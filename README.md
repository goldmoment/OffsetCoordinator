# OffsetCoordinator

[![CI Status](https://img.shields.io/travis/viensaigon/OffsetCoordinator.svg?style=flat)](https://travis-ci.org/viensaigon/OffsetCoordinator)
[![Version](https://img.shields.io/cocoapods/v/OffsetCoordinator.svg?style=flat)](https://cocoapods.org/pods/OffsetCoordinator)
[![License](https://img.shields.io/cocoapods/l/OffsetCoordinator.svg?style=flat)](https://cocoapods.org/pods/OffsetCoordinator)
[![Platform](https://img.shields.io/cocoapods/p/OffsetCoordinator.svg?style=flat)](https://cocoapods.org/pods/OffsetCoordinator)

## Example
![alt tag](https://thumbs.gfycat.com/CluelessInconsequentialCranefly-size_restricted.gif)  [[Youtube]](https://youtu.be/GtFF23LTa84)

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
Swift 4.0, iOS >= 10.0
Dependence: RxSwift, RxCocoa

## Installation

OffsetCoordinator is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'OffsetCoordinator'
```

## Usage

Create multiple tab viewcontrollers by UIPageViewController or any libs.

```swift
self.offsetCoordinator = OffsetCoordinator(headerView: self.headerView,
                                           menuView: self.menuView,
                                           viewControllers: self.viewControllers)
```

## Author
goldmoment, nguyenvanvienqn@gmail.com
fb/goldmoment
tw/goldmoment

## License

OffsetCoordinator is available under the MIT license. See the LICENSE file for more info.
