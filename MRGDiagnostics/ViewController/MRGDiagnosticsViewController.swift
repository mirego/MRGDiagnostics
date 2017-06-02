// Copyright (c) 2017, Mirego
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// - Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
// - Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// - Neither the name of the Mirego nor the names of its contributors may
//   be used to endorse or promote products derived from this software without
//   specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

import UIKit

open class MRGDiagnosticsViewController: UIViewController {

    fileprivate let reachabilityUtils: MRGReachabilityUtils
    fileprivate var mainView: MRGDiagnosticsView!
    fileprivate var diagnosticsInfoList = [MRGDiagnosticsInfoViewData]()

    fileprivate let kDiagnosticsInfoCellIdentifier = "diagnosticsInfoCell"
    
    var systemName: String {
        get {
            return UIDevice.current.systemName
        }
    }

    var systemVersion: String {
        get {
            return UIDevice.current.systemVersion
        }
    }

    var deviceModel: String {
        get {
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8 , value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            return identifier
        }
    }

    var appVersion: String {
        get {
            let dictionary = Bundle.main.infoDictionary!
            let version = dictionary["CFBundleVersion"] as! String
            return "\(version)"
        }
    }

    var batteryLevel: String {
        get {
            UIDevice.current.isBatteryMonitoringEnabled = true;
            let batteryLevel = fabs(UIDevice.current.batteryLevel * Float(100))
            return String.init(format: "%.0f %%", batteryLevel)
        }
    }

    var totalDiskSpace: String {
        get {
            do {
                let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
                let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value
                return ByteCountFormatter.string(fromByteCount: space!, countStyle: .binary)
            } catch {
                return "?"
            }
        }
    }

    var freeDiskSpace: String {
        get {
            do {
                let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
                let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value
                return ByteCountFormatter.string(fromByteCount: freeSpace!, countStyle: .binary)
            } catch {
                return "?"
            }
        }
    }

    var memoryUsage: String {
        get {
            var info = mach_task_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info) / MemoryLayout<integer_t>.size)
            let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
                return infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { (machPtr: UnsafeMutablePointer<integer_t>) in
                    return task_info(
                            mach_task_self_,
                            task_flavor_t(MACH_TASK_BASIC_INFO),
                            machPtr,
                            &count
                    )
                }
            }
            guard kerr == KERN_SUCCESS else {
                return "?"
            }

            return ByteCountFormatter.string(fromByteCount: Int64(info.resident_size), countStyle: .memory)
        }
    }

    var connectivity: String {
        get {
            return MRGReachabilityUtils.isOnline() ?
                localizedString("diagnostics_connectivity_online") :
                localizedString("diagnostics_connectivity_offline")
        }
    }

    public init() {
        self.reachabilityUtils = MRGReachabilityUtils()
        super.init(nibName: nil, bundle: nil)
        title = localizedString("diagnostics_title")
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func loadView() {
        mainView = MRGDiagnosticsView()
        view = mainView
        mainView.tableView.delegate = self
        mainView.tableView.dataSource = self
        mainView.tableView.register(MRGDiagnosticsInfoTableViewCell.self, forCellReuseIdentifier: kDiagnosticsInfoCellIdentifier)
        
        if (self.presentingViewController != nil) {
            let closeButton = UIBarButtonItem(title: localizedString("diagnostics_close"), style: .plain, target: self, action: #selector(didTapCloseButton))
            closeButton.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 16), NSForegroundColorAttributeName: UIColor.black], for: .normal)
            navigationItem.leftBarButtonItem = closeButton
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupDiagnosticsInfo()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

extension MRGDiagnosticsViewController /* Events */ {
    func didTapCloseButton() {
        dismiss(animated: true)
    }
}

extension MRGDiagnosticsViewController /* Private Methods */ {
    func setupDiagnosticsInfo() {

        let osTypeInfo = MRGDiagnosticsInfoViewData(title: localizedString("diagnostics_os_name_title"), value: systemName)
        diagnosticsInfoList.append(osTypeInfo)

        let osVersionInfo = MRGDiagnosticsInfoViewData(title: localizedString("diagnostics_os_version_title"), value: systemVersion)
        diagnosticsInfoList.append(osVersionInfo)

        let deviceModelInfo = MRGDiagnosticsInfoViewData(title: localizedString("diagnostics_device_model_title"), value: deviceModel)
        diagnosticsInfoList.append(deviceModelInfo)

        let appVersionInfo = MRGDiagnosticsInfoViewData(title: localizedString("diagnostics_app_version_title"), value: appVersion)
        diagnosticsInfoList.append(appVersionInfo)

        let batteryLevelInfo = MRGDiagnosticsInfoViewData(title: localizedString("diagnostics_battery_level_title"), value: batteryLevel)
        diagnosticsInfoList.append(batteryLevelInfo)

        let totalDiskSpaceInfo = MRGDiagnosticsInfoViewData(title: localizedString("diagnostics_total_disk_title"), value: totalDiskSpace)
        diagnosticsInfoList.append(totalDiskSpaceInfo)

        let availableDiskSpaceInfo = MRGDiagnosticsInfoViewData(title: localizedString("diagnostics_available_disk_title"), value: freeDiskSpace)
        diagnosticsInfoList.append(availableDiskSpaceInfo)

        let memoryUsageInfo = MRGDiagnosticsInfoViewData(title: localizedString("diagnostics_memory_usage_title"), value: memoryUsage)
        diagnosticsInfoList.append(memoryUsageInfo)

        let connectivityInfo = MRGDiagnosticsInfoViewData(title: localizedString("diagnostics_connectivity_title"), value: connectivity)
        diagnosticsInfoList.append(connectivityInfo)
    }
    
    
    func localizedString(_ string: String) -> String {
        return NSLocalizedString(string, bundle: Bundle(for: self.classForCoder), comment: "")
    }
}

extension MRGDiagnosticsViewController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return diagnosticsInfoList.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = diagnosticsInfoList[indexPath.item]
        let cell = tableView.dequeueReusableCell(withIdentifier: kDiagnosticsInfoCellIdentifier, for: indexPath) as! MRGDiagnosticsInfoTableViewCell
        cell.configure(viewData: item)
        return cell
    }

    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
