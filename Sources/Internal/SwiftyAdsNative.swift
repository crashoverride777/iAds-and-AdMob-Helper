//    The MIT License (MIT)
//
//    Copyright (c) 2015-2021 Dominik Ringler
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import GoogleMobileAds

protocol SwiftyAdsNativeType: AnyObject {
    func load(from viewController: UIViewController,
              adUnitIdType: SwiftyAdsAdUnitIdType,
              count: Int?,
              onReceive: @escaping (GADUnifiedNativeAd) -> Void,
              onError: @escaping (GADRequestError) -> Void)
}

final class SwiftyAdsNative: NSObject {

    // MARK: - Properties

    private let adUnitId: String
    private let request: () -> GADRequest

    private var adLoader: GADAdLoader?
    private var isLoading = false
    
    private var onReceive: ((GADUnifiedNativeAd) -> Void)?
    private var onError: ((GADRequestError) -> Void)?

    // MARK: - Initialization

    init(adUnitId: String, request: @escaping () -> GADRequest) {
        self.adUnitId = adUnitId
        self.request = request
    }
}

// MARK: - SwiftyAdsNativeType

extension SwiftyAdsNative: SwiftyAdsNativeType {

    func load(from viewController: UIViewController,
              adUnitIdType: SwiftyAdsAdUnitIdType,
              count: Int?,
              onReceive: @escaping (GADUnifiedNativeAd) -> Void,
              onError: @escaping (GADRequestError) -> Void) {
        guard !isLoading else { return }
        self.onReceive = onReceive
        self.onError = onError
        isLoading = true

        // Create multiple ad options
        var multipleAdsOptions: [GADMultipleAdsAdLoaderOptions]?
        if let count = count {
            let loaderOptions = GADMultipleAdsAdLoaderOptions()
            loaderOptions.numberOfAds = count
            multipleAdsOptions = [loaderOptions]
        }

        // Set the ad unit id
        var adUnitId = self.adUnitId
        if case .custom(let id) = adUnitIdType {
            adUnitId = id
        }

        // Create GADAdLoader
        adLoader = GADAdLoader(
            adUnitID: adUnitId,
            rootViewController: viewController,
            adTypes: [.unifiedNative],
            options: multipleAdsOptions
        )

        // Set the GADAdLoader delegate
        adLoader?.delegate = self

        // Load ad with request
        adLoader?.load(request())
    }
}

// MARK: - GADUnifiedNativeAdLoaderDelegate

extension SwiftyAdsNative: GADUnifiedNativeAdLoaderDelegate {

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        onReceive?(nativeAd)
    }

    func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {
        // The adLoader has finished loading ads, and a new request can be sent.
        isLoading = false
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        isLoading = false
        onError?(error)
    }
}
