// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import Result
import BigInt
import SwiftChart
import EasyTipView
import Crashlytics

enum KNTokenChartType: Int {
  case day = 0
  case week = 1
  case month = 2
  case year = 3
  case all = 4

  var resolution: String {
    switch self {
    case .day: return "15"
    case .week, .month: return "60"
    case .year, .all: return "D"
    }
  }

  func fromTime(for toTime: Int64) -> Int64 {
    switch self {
    case .day:
      return toTime - 24 * 60 * 60
    case .week:
      return toTime - 7 * 24 * 60 * 60
    case .month:
      return toTime - 30 * 24 * 60 * 60
    case .year:
      return toTime - 365 * 24 * 60 * 60
    case .all:
      return 1
    }
  }

  var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    switch self {
    case .day:
      formatter.dateFormat = "HH:mm"
    case .week, .month:
      formatter.dateFormat = "dd/MM HH:MM"
    case .year, .all:
      formatter.dateFormat = "dd/MM"
    }
    return formatter
  }

  func label(for time: Double) -> String {
    let date = Date(timeIntervalSince1970: time)
    return self.dateFormatter.string(from: date)
  }
}

enum KNTokenChartViewEvent {
  case back
  case buy(token: TokenObject)
  case sell(token: TokenObject)
  case send(token: TokenObject)
  case openEtherscan(token: TokenObject)
}

protocol KNTokenChartViewControllerDelegate: class {
  func tokenChartViewController(_ controller: KNTokenChartViewController, run event: KNTokenChartViewEvent)
}

class KNTokenChartViewModel {
  let token: TokenObject
  var type: KNTokenChartType = .day
  var data: [KNChartObject] = []
  var balance: Balance = Balance(value: BigInt())

  init(token: TokenObject) {
    self.token = token
    self.data = []
  }

  var navigationTitle: String { return "\(self.token.symbol)" }
  var isTokenSupported: Bool { return self.token.isSupported }

  var rateAttributedString: NSAttributedString {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: self.token) else {
      return NSMutableAttributedString()
    }
    let rateString: String = {
      let rate = BigInt(trackerRate.rateETHNow * Double(EthereumUnit.ether.rawValue))
      return rate.displayRate(decimals: 18)
    }()
    let change24hString: String = {
      let numberFormatter = NumberFormatter()
      numberFormatter.maximumFractionDigits = 2
      numberFormatter.minimumFractionDigits = 2
      numberFormatter.minimumIntegerDigits = 1
      let string = numberFormatter.string(from: NSNumber(value: trackerRate.changeETH24h)) ?? "0.00"
      return "\(string)%"
    }()
    let changeColor: UIColor = {
      if trackerRate.changeETH24h == 0.0 { return UIColor.Kyber.grayChateau }
      return trackerRate.changeETH24h > 0 ? UIColor.Kyber.shamrock : UIColor.Kyber.strawberry
    }()
    let rateAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(red: 46, green: 57, blue: 87),
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 22),
      NSAttributedStringKey.kern: 0.0,
    ]
    let changeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: changeColor,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 16),
      NSAttributedStringKey.kern: 0.0,
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "TOMO \(rateString) ", attributes: rateAttributes))
    attributedString.append(NSAttributedString(string: "\n\(change24hString)", attributes: changeAttributes))
    return attributedString
  }

  var balanceAttributedString: NSAttributedString {
    let balance: String = self.balance.value.string(
      decimals: self.token.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.token.decimals, 6)
    )
    let balanceAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(red: 46, green: 57, blue: 87),
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 18),
      NSAttributedStringKey.kern: 0.0,
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: balance, attributes: balanceAttributes))
    return attributedString
  }

  var totalValueString: String {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: self.token) else { return "" }
    let value: BigInt = {
      return trackerRate.rateETHBigInt * self.balance.value / BigInt(10).power(self.token.decimals)
    }()
    if value.isZero { return "0 TOMO" }
    let valueString: String = value.displayRate(decimals: 18)
    return self.token.isTOMO ? "\(valueString) TOMO" : "~\(valueString) TOMO"
  }

  var totalUSDAmount: BigInt? {
    if let usdRate = KNRateCoordinator.shared.usdRate(for: self.token) {
      return usdRate.rate * self.balance.value / BigInt(10).power(self.token.decimals)
    }
    return nil
  }

  var displayTotalUSDAmount: String? {
    guard let amount = self.totalUSDAmount else { return nil }
    if amount.isZero { return "$0 USD" }
    let value = amount.displayRate(decimals: 18)
    return "~ $\(value) USD"
  }

  func updateType(_ newType: KNTokenChartType) {
    self.type = newType
    self.data = []
  }

  func updateBalance(_ balance: Balance) {
    self.balance = balance
  }

  func updateData(_ newData: JSONDictionary, symbol: String, resolution: String) {
    let objects: [KNChartObject] = KNChartObject.objects(
      from: newData,
      symbol: symbol,
      resolution: resolution
    )
    if self.token.symbol == symbol && self.type.resolution == resolution {
      self.data.append(contentsOf: objects)
      self.data = self.data.sorted(by: { $0.time < $1.time })
      let fromTime = self.type.fromTime(for: Int64(floor(Date().timeIntervalSince1970)))
      for id in 0..<self.data.count where self.data[id].time >= fromTime {
        self.data = Array(self.data.suffix(from: id)) as [KNChartObject]
        return
      }
      // no data between from and to time to display
      self.data = []
    }
  }

  var displayDataSeries: ChartSeries {
    if let object = self.data.first {
      self.data = self.data.filter({ $0.time >= self.type.fromTime(for: object.time) })
    }
    guard let first = self.data.first else {
      return ChartSeries(data: [(x: 0, y: 0)])
    }
    let data = self.data.map {
      return (x: Double($0.time - first.time) / (15.0 * 60.0), y: $0.close)
    }
    let series = ChartSeries(data: data)
    series.color = UIColor.Kyber.blueGreen
    series.area = true
    return series
  }

  var xDoubleLabels: [Double] {
    guard let first = self.data.first else {
      return []
    }
    let data = self.data.map { return Double($0.time - first.time) / (15.0 * 60.0) }
    return data
  }

  var yDoubleLables: [Double] {
    if self.data.isEmpty { return [] }
    var minDouble: Double = self.data.first!.close
    var maxDouble: Double = self.data.first!.close
    self.data.forEach({
      minDouble = min(minDouble, $0.close)
      maxDouble = max(maxDouble, $0.close)
    })
    return [minDouble, maxDouble]
  }

  func fetchNewData(for token: TokenObject, type: KNTokenChartType, completion: @escaping ((Result<Bool, AnyError>) -> Void)) {
//    let to: Int64 = Int64(floor(Date().timeIntervalSince1970))
//    let from: Int64 = {
//      let fromTime: Int64 = type.fromTime(for: to)
//      if let time = self.data.first?.time {
//        return max(time + 60, fromTime)
//      }
//      return fromTime
//    }()
//    let provider = MoyaProvider<KNTrackerService>()
//    let service = KNTrackerService.getChartHistory(
//      symbol: token.symbol,
//      resolution: type.resolution,
//      from: from,
//      to: to,
//      rateType: "mid"
//    )
//    print("------ Chart history: Fetching for \(token.symbol) resolution \(type.resolution) ------")
//    DispatchQueue.global(qos: .background).async {
//      provider.request(service) { response in
//        DispatchQueue.main.async {
//          switch response {
//          case .success(let result):
//            do {
//              if let data = try result.mapJSON(failsOnEmptyData: false) as? JSONDictionary {
//                self.updateData(data, symbol: token.symbol, resolution: type.resolution)
//                print("------ Chart history: Successfully load data for \(token.symbol) resolution \(type.resolution) ------")
//                completion(.success(true))
//              } else {
//                print("------ Chart history: Failed parse data for \(token.symbol) resolution \(type.resolution) ------")
//                completion(.success(false))
//              }
//            } catch let error {
//              print("------ Chart history: Failed map JSON data for \(token.symbol) resolution \(type.resolution) error \(error.prettyError)------")
//              completion(.failure(AnyError(error)))
//            }
//          case .failure(let error):
//            print("------ Chart history: Successfully load data for \(token.symbol) resolution \(type.resolution) error \(error.prettyError) ------")
//            completion(.failure(AnyError(error)))
//          }
//        }
//      }
//    }
  }
}

//swiftlint:disable file_length
class KNTokenChartViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navigationLabel: UILabel!
  @IBOutlet weak var symbolLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!

  @IBOutlet weak var ethRateLabel: UILabel!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var totalValueLabel: UILabel!
  @IBOutlet weak var totalUSDValueLabel: UILabel!

  @IBOutlet weak var priceChart: Chart!
  @IBOutlet weak var noDataLabel: UILabel!
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var buyButton: UIButton!
  @IBOutlet weak var sellButton: UIButton!
  @IBOutlet weak var sendButton: UIButton!

  @IBOutlet weak var dataTypeButtonContainerView: UIView!
  @IBOutlet var dataTypeButtons: [UIButton]!

  @IBOutlet weak var bottomPaddingConstraintForButton: NSLayoutConstraint!
  weak var delegate: KNTokenChartViewControllerDelegate?
  fileprivate var viewModel: KNTokenChartViewModel

  fileprivate var timer: Timer?
  @IBOutlet weak var touchPriceLabel: UILabel!
  @IBOutlet weak var leftPaddingForTouchPriceLabelConstraint: NSLayoutConstraint!

  lazy var preferences: EasyTipView.Preferences = {
    var preferences = EasyTipView.Preferences()
    preferences.drawing.font = UIFont.Kyber.medium(with: 14)
    preferences.drawing.textAlignment = .left
    preferences.drawing.foregroundColor = UIColor.Kyber.mirage
    preferences.drawing.backgroundColor = UIColor.white
    preferences.animating.dismissDuration = 0
    return preferences
  }()

  fileprivate var dataTipView: EasyTipView!
  fileprivate var sourceTipView: UIView!
  fileprivate func tipView(with value: Double, at index: Int) -> EasyTipView {
    let formatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm dd MMM yyyy"
      return formatter
    }()
    let timeString = formatter.string(from: self.viewModel.data[index].date)
    let timeText = NSLocalizedString("time", value: "Time", comment: "")
    let priceText = NSLocalizedString("price", value: "Price", comment: "")
    let numberFormatter: NumberFormatter = {
      let formatter = NumberFormatter()
      formatter.maximumFractionDigits = self.viewModel.token.decimals
      formatter.minimumIntegerDigits = 1
      return formatter
    }()
    let rate = numberFormatter.string(from: NSNumber(value: value)) ?? "0"
    return EasyTipView(text: "\(timeText): \(timeString)\n\(priceText): ETH \(rate.displayRate())")
  }

  init(viewModel: KNTokenChartViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNTokenChartViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if self.viewModel.isTokenSupported {
      self.startTimer()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.stopTimer()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  //swiftlint:disable function_body_length
  fileprivate func setupUI() {
    self.touchPriceLabel.isHidden = true

    self.bottomPaddingConstraintForButton.constant = 16.0 + self.bottomPaddingSafeArea()
    let style = KNAppStyleType.current
    self.view.backgroundColor = style.chartBackgroundColor
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)

    self.iconImageView.setTokenImage(
      token: self.viewModel.token,
      size: self.iconImageView.frame.size
    )
    self.navigationLabel.text = self.viewModel.navigationTitle
    self.navigationLabel.addLetterSpacing()
    self.symbolLabel.text = self.viewModel.token.symbol
    self.symbolLabel.addLetterSpacing()
    self.nameLabel.text = self.viewModel.token.name
    self.nameLabel.addLetterSpacing()

    self.ethRateLabel.attributedText = self.viewModel.rateAttributedString
    self.ethRateLabel.textAlignment = .center
    self.ethRateLabel.numberOfLines = 0

    self.balanceLabel.attributedText = self.viewModel.balanceAttributedString
    self.totalValueLabel.text = self.viewModel.totalValueString
    self.totalValueLabel.addLetterSpacing()
    self.totalUSDValueLabel.text = self.viewModel.displayTotalUSDAmount
    self.totalUSDValueLabel.addLetterSpacing()

    self.touchPriceLabel.isHidden = true

    self.priceChart.delegate = self
    self.noDataLabel.isHidden = false

    self.priceChart.isHidden = true
    self.priceChart.labelColor = UIColor.Kyber.mirage
    self.priceChart.labelFont = UIFont.Kyber.medium(with: 12)

    self.sendButton.rounded(
      color: UIColor.Kyber.border,
      width: 1,
      radius: style.buttonRadius(for: self.sendButton.frame.height)
    )
    self.sendButton.backgroundColor = .clear//UIColor.Kyber.merigold
    self.sendButton.setTitle(
      NSLocalizedString("send", value: "Send", comment: ""),
      for: .normal
    )
    self.sendButton.setTitleColor(UIColor(red: 90, green: 94, blue: 103), for: .normal)
    self.buyButton.rounded(
      color: UIColor.Kyber.border,
      width: 1,
      radius: style.buttonRadius(for: self.buyButton.frame.height)
    )
    self.buyButton.backgroundColor = .clear//UIColor.Kyber.shamrock
    self.buyButton.setTitle(
      NSLocalizedString("buy", value: "Buy", comment: ""),
      for: .normal
    )
    self.buyButton.setTitleColor(UIColor(red: 90, green: 94, blue: 103), for: .normal)
    self.sellButton.rounded(
      color: UIColor.Kyber.border,
      width: 1,
      radius: style.buttonRadius(for: self.sellButton.frame.height)
    )
    self.sellButton.backgroundColor = .clear//UIColor.Kyber.blueGreen
    self.sellButton.setTitle(
      NSLocalizedString("sell", value: "Sell", comment: ""),
      for: .normal
    )
    self.sellButton.setTitleColor(UIColor(red: 90, green: 94, blue: 103), for: .normal)

    self.dataTypeButtons.forEach { button in
      let title: String = {
        switch button.tag {
        case 0: return "24H"
        case 1: return "7 \(NSLocalizedString("days", value: "Days", comment: ""))"
        case 2: return "\(NSLocalizedString("month", value: "Month", comment: ""))"
        case 3: return "\(NSLocalizedString("year", value: "Year", comment: ""))"
        case 4: return "\(NSLocalizedString("all", value: "All", comment: ""))"
        default: return ""
        }
      }()
      button.setTitle(title, for: .normal)
    }

    if self.viewModel.isTokenSupported {
      self.noDataLabel.text = "\(NSLocalizedString("updating.data", value: "Updating data", comment: "")) ..."
      self.updateDisplayDataType(.day)
    } else {
      self.dataTypeButtonContainerView.isHidden = true
      self.noDataLabel.text = NSLocalizedString("this.token.is.not.supported", value: "This token is not supported by TomoSwap", comment: "")
      self.buyButton.isHidden = true
      self.sellButton.setTitle(
        NSLocalizedString("send", value: "Send", comment: ""),
        for: .normal
      )
      self.sellButton.backgroundColor = .clear//UIColor.Kyber.merigold
      self.sendButton.isHidden = true
    }
    self.noDataLabel.addLetterSpacing()

    EasyTipView.globalPreferences = self.preferences

    // Add gestures to open token in etherscan
    self.iconImageView.isUserInteractionEnabled = true
    self.iconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openTokenOnEtherscanPressed(_:))))
    self.nameLabel.isUserInteractionEnabled = true
    self.nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openTokenOnEtherscanPressed(_:))))
    self.symbolLabel.isUserInteractionEnabled = true
    self.symbolLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openTokenOnEtherscanPressed(_:))))
  }

  fileprivate func updateDisplayDataType(_ type: KNTokenChartType) {
    self.viewModel.updateType(type)
    for button in self.dataTypeButtons {
      button.rounded(
        color: button.tag == type.rawValue ? UIColor.Kyber.shamrock : UIColor.clear,
        width: 2,
        radius: 4.0
      )
    }
    if self.dataTipView != nil { self.dataTipView.dismiss() }
    self.reloadViewDataDidUpdate()
    self.startTimer()
  }

  @objc func openTokenOnEtherscanPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "token_chart", customAttributes: ["type": "open_token_on_etherscan_\(self.viewModel.token.symbol)"])
    self.delegate?.tokenChartViewController(self, run: .openEtherscan(token: self.viewModel.token))
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.tokenChartViewController(self, run: .back)
  }

  @IBAction func actionButtonDidPress(_ sender: UIButton) {
    if !self.viewModel.isTokenSupported {
      KNCrashlyticsUtil.logCustomEvent(withName: "token_chart", customAttributes: ["type": "send_\(self.viewModel.token.symbol)"])
      self.delegate?.tokenChartViewController(self, run: .send(token: self.viewModel.token))
      return
    }
    if sender.tag == 0 {
      KNCrashlyticsUtil.logCustomEvent(withName: "token_chart", customAttributes: ["type": "buy_\(self.viewModel.token.symbol)"])
      self.delegate?.tokenChartViewController(self, run: .buy(token: self.viewModel.token))
    } else if sender.tag == 1 {
      KNCrashlyticsUtil.logCustomEvent(withName: "token_chart", customAttributes: ["type": "sell_\(self.viewModel.token.symbol)"])
      self.delegate?.tokenChartViewController(self, run: .sell(token: self.viewModel.token))
    } else {
      KNCrashlyticsUtil.logCustomEvent(withName: "token_chart", customAttributes: ["type": "send_\(self.viewModel.token.symbol)"])
      self.delegate?.tokenChartViewController(self, run: .send(token: self.viewModel.token))
    }
  }

  @IBAction func dataTypeDidChange(_ sender: UIButton) {
    let type = KNTokenChartType(rawValue: sender.tag) ?? .day
    KNCrashlyticsUtil.logCustomEvent(withName: "token_chart", customAttributes: ["type": "data_type_changed_\(type.rawValue)"])
    self.updateDisplayDataType(type)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
  }

  fileprivate func shouldUpdateData(for type: KNTokenChartType, token: TokenObject) {
    self.noDataLabel.text = NSLocalizedString("can.not.update.data", value: "Can not update data", comment: "")
//    self.noDataLabel.text = "\(NSLocalizedString("updating.data", value: "Updating data", comment: ""))..."
//    self.noDataLabel.addLetterSpacing()
//    self.viewModel.fetchNewData(
//      for: self.viewModel.token,
//      type: self.viewModel.type) { [weak self] result in
//        switch result {
//        case .success(let isSuccess):
//          if isSuccess {
//            self?.reloadViewDataDidUpdate()
//          } else {
//            self?.noDataLabel.text = NSLocalizedString("can.not.update.data", value: "Can not update data", comment: "")
//          }
//        case .failure:
//          self?.noDataLabel.text = NSLocalizedString("can.not.update.data", value: "Can not update data", comment: "")
//        }
//        self?.noDataLabel.addLetterSpacing()
//    }
  }

  fileprivate func startTimer() {
//    self.stopTimer()
//    // Immediately call fetch data
//    self.shouldUpdateData(for: self.viewModel.type, token: self.viewModel.token)
//    self.timer = Timer.scheduledTimer(
//      withTimeInterval: 60,
//      repeats: true,
//      block: { [weak self] _ in
//        guard let `self` = self else { return }
//        self.shouldUpdateData(for: self.viewModel.type, token: self.viewModel.token)
//      }
//    )
  }

  fileprivate func stopTimer() {
//    self.timer?.invalidate()
  }

  fileprivate func reloadViewDataDidUpdate() {
    self.ethRateLabel.attributedText = self.viewModel.rateAttributedString
    if self.viewModel.data.isEmpty {
      self.noDataLabel.text = NSLocalizedString("no.data.for.this.token", value: "There is no data for this token", comment: "")
      self.noDataLabel.isHidden = false
      self.noDataLabel.addLetterSpacing()
      self.priceChart.isHidden = true
      if self.dataTipView != nil { self.dataTipView.dismiss() }
    } else {
      self.noDataLabel.isHidden = true
      self.priceChart.isHidden = false
      self.priceChart.removeAllSeries()
      self.priceChart.series = [self.viewModel.displayDataSeries]
      self.priceChart.yLabels = self.viewModel.yDoubleLables
      let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = min(9, self.viewModel.token.decimals)
        formatter.minimumFractionDigits = 2
        formatter.minimumIntegerDigits = 1
        return formatter
      }()
      self.priceChart.yLabelsFormatter = { (_, value) in
        let rate = numberFormatter.string(from: NSNumber(value: value)) ?? ""
        return rate.displayRate()
      }
      self.priceChart.xLabels = []
      self.priceChart.setNeedsDisplay()
    }
  }

  func coordinatorUpdateRate() {
    self.ethRateLabel.attributedText = self.viewModel.rateAttributedString
    self.totalUSDValueLabel.text = self.viewModel.displayTotalUSDAmount
    self.totalUSDValueLabel.addLetterSpacing()
  }

  func coordinatorUpdateBalance(balance: [String: Balance]) {
    if let bal = balance[self.viewModel.token.contract] {
      self.viewModel.updateBalance(bal)
      self.balanceLabel.attributedText = self.viewModel.balanceAttributedString
      self.totalValueLabel.text = self.viewModel.totalValueString
      self.totalValueLabel.addLetterSpacing()
      self.totalUSDValueLabel.text = self.viewModel.displayTotalUSDAmount
      self.totalUSDValueLabel.addLetterSpacing()
    }
  }
}

extension KNTokenChartViewController: ChartDelegate {
  func didFinishTouchingChart(_ chart: Chart) {
  }

  func didEndTouchingChart(_ chart: Chart) {
  }

  func didTouchChart(_ chart: Chart, indexes: [Int?], x: Double, left: CGFloat) {
    for (seriesId, dataId) in indexes.enumerated() {
      if let id = dataId, let value = chart.valueForSeries(seriesId, atIndex: id) {
        let minMaxValues = self.viewModel.yDoubleLables
        let topPadding = chart.frame.height * CGFloat((minMaxValues[0] == minMaxValues[1] ? 0.0 : (minMaxValues[1] - value) / (minMaxValues[1] - minMaxValues[0])))
        if self.dataTipView != nil { self.dataTipView.dismiss() }
        if self.sourceTipView != nil {
          self.sourceTipView.frame = CGRect(x: left, y: chart.frame.minY + topPadding, width: 1, height: 1)
          self.sourceTipView.removeFromSuperview()
        } else {
          self.sourceTipView = UIView(frame: CGRect(x: left, y: chart.frame.minY + topPadding, width: 1, height: 1))
          self.sourceTipView.backgroundColor = UIColor.clear
        }
        self.view.addSubview(self.sourceTipView)
        self.dataTipView = self.tipView(with: value, at: id)
        self.dataTipView.show(animated: false, forView: self.sourceTipView, withinSuperview: self.view)
        self.view.layoutIfNeeded()
      }
    }
  }
}
