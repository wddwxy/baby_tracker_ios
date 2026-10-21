# Little Nest iOS 原型

[![iOS build and tests](https://github.com/wddwxy/baby_tracker_ios/actions/workflows/ios.yml/badge.svg)](https://github.com/wddwxy/baby_tracker_ios/actions/workflows/ios.yml)

独立仓库：<https://github.com/wddwxy/baby_tracker_ios>。

## Windows 开发 + GitHub 在线构建

代码可继续在 Windows 编辑，无需购买 Mac 才能进行每次编译。GitHub Actions 使用 `macos-15` + Xcode 16.4 编译并运行模拟器单元/UI 测试；首次运行结果以 Actions 页面为准。

- `main` 分支 push、Pull Request 和 Actions 的 **Run workflow** 均可触发。
- [打开构建页面](https://github.com/wddwxy/baby_tracker_ios/actions/workflows/ios.yml)，选择一次运行，在 **Artifacts** 下载日志、`.xcresult`、演示截图和模拟器 `.app` 压缩包（保留 7 天）。
- CI 自动选择镜像中可用的 iPhone 模拟器，记录 Xcode/SDK/Swift 与设备列表，避免绑定本机模拟器名称。
- 当前 workflow 不使用任何 HA 账号、真实记录、Apple 证书或 GitHub 自定义 Secrets。
- **模拟器 `.app` 不能装到真实 iPhone，也不能在 Windows 上直接运行。** 真机 IPA/TestFlight 需要另行配置 Apple 开发者签名、provisioning 和分发流程；本 workflow 不生成可安装 IPA，不上传 App Store。
- GitHub runner 可代替本地 Mac 做编译/模拟器测试，不能代替 iPhone 真机上的锁屏、权限和网络验收。

在当前工作区中，本目录本身是独立 Git 仓库，父项目忽略 `/ios/`；不是 submodule，也不会改动 HA 后端仓库 remote。在 PowerShell 中：

```powershell
git -C D:/codex/baby_tracker/ios status
git -C D:/codex/baby_tracker/ios add Sources Tests Config scripts README.md ENVIRONMENT.md .github
git -C D:/codex/baby_tracker/ios commit -m "Describe the iOS change"
git -C D:/codex/baby_tracker/ios push
```

在其他机器单独克隆也可以：

```bash
git clone https://github.com/wddwxy/baby_tracker_ios.git
cd baby_tracker_ios
python scripts/check-fixtures.py
python scripts/verify-build-artifacts.py
# macOS only; GitHub Actions executes this remotely for Windows developers:
bash scripts/build-simulator.sh
```

后续将发布说明、协议文档与 iOS 测试资料一起维护在本仓库。HA 后端仍在 [baby_tracker](https://github.com/wddwxy/baby_tracker) 独立维护，不上传本地项目根目录的文件或历史。

这是 Little Nest 原生 iOS 计划**步骤 01（构建环境、测试服务与最小 App）** 的产物：
一个可构建、可安装的 SwiftUI 空壳 App，加上一个隔离的测试后端和一份可复现的环境说明。

步骤 01 只建立"外壳"：界面骨架、演示数据注入、隔离后端和构建/测试脚本。
真正的 Home Assistant 登录、API 契约、同步与计时在后续步骤加入，因此**当前版本不会连接任何真实服务**。

> 当前机器（Windows）没有 Xcode，只能运行 `scripts/*.py` 与源码编辑；
> Swift 编译、模拟器运行和真机签名必须在 macOS + Xcode 上完成。

## 环境要求

| 项目 | 要求 |
| --- | --- |
| 操作系统 | macOS（iOS 编译只在 Mac/CI 上进行） |
| Xcode | 16 或更高（`xcodebuild` 需要支持 `objectVersion 56` 与 iOS 17 SDK） |
| 部署目标 | iOS 17.0（交互式 Live Activity 的最低要求，见 `Config/Base.xcconfig`） |
| Swift | 5.0 语言模式，`SWIFT_STRICT_CONCURRENCY = minimal` |
| 模拟器 | 默认 `iPhone 16`，可用 `SIMULATOR_DEVICE` 覆盖 |
| 真机（可选） | 一台 iOS 17+ iPhone 与一个 Apple 开发者团队 |

实际使用的 Xcode/设备/签名信息请填到 [`ENVIRONMENT.md`](ENVIRONMENT.md)。

## 目录结构

```
./
  Config/
    Base.xcconfig                     机器无关的构建设置（无绝对路径、无凭证）
    Signing.local.xcconfig.example    真机签名的本地覆盖模板（复制后使用）
  LittleNest.xcodeproj/               App / 单元测试 / UI 测试 三个 target
  Sources/
    App/                              AppRootView、启动、模式与启动参数解析
    Core/Connection/                  连接状态机骨架（步骤 03 实现真实流程）
    Domain/                           演示数据、时间源、分组与格式化
    Features/                         首页、记录、趋势占位、设置、连接、诊断
    Shared/                           可访问性标识、演示横幅、AppInfo
    Resources/Assets.xcassets         AccentColor + 空的 AppIcon 占位
  Tests/
    Unit/                             Swift 单元测试（离线，不访问 HA）
    UI/                               XCTest UI 自动化（固定 F1 演示数据）
    Fixtures/                         F0.json / F1.json 合成数据快照
  scripts/                            构建、测试、隔离后端与校验脚本
```

三个 target：

- `LittleNest`：App。
- `LittleNestTests`：单元测试（`TEST_HOST` / `BUNDLE_LOADER` 指向 App）。
- `LittleNestUITests`：UI 测试（`TEST_TARGET_NAME = LittleNest`）。

`Sources/Shared/AccessibilityID.swift` 同时编进 App target 和 UI 测试 target，
因为 UI 测试无法 `@testable import` App。

## 构建模拟器版本（对应测试 01-01）

```bash
scripts/build-simulator.sh
# 指定机型：
SIMULATOR_DEVICE="iPhone 16 Pro" scripts/build-simulator.sh
```

脚本使用 `-scheme LittleNest -destination 'platform=iOS Simulator,...'` 并带 `CODE_SIGNING_ALLOWED=NO`，
因此**不需要**任何签名团队或个人路径即可构建。

## 在模拟器中运行

```bash
xcrun simctl boot "iPhone 16" 2>/dev/null || true
xcrun simctl install booted \
  build/DerivedData/Build/Products/Debug-iphonesimulator/LittleNest.app
xcrun simctl launch booted com.wddwxy.littlenest
```

也可以直接在 Xcode 里打开 `LittleNest.xcodeproj`，选择 `LittleNest` scheme 运行。

## 演示模式与启动参数

默认是**真实数据模式**（`live`）：不会伪造任何记录，连接页会如实报告"本版本尚未实现连接"。

演示数据必须显式请求。参数既可以写成命令行启动参数，也可以写成环境变量
（见 `Sources/App/LaunchOptions.swift`）：

| 命令行参数 | 环境变量 | 作用 |
| --- | --- | --- |
| `-LittleNestMode demo` | `LITTLENEST_MODE=demo` | 进入演示模式（默认数据集 F1） |
| `-LittleNestMode live` | `LITTLENEST_MODE=live` | 真实数据模式 |
| `-LittleNestDemoDataset F0` | `LITTLENEST_DEMO_DATASET=f0` | 指定数据集（F0/F1）；单独给出也会进入演示模式 |
| `-LittleNestFixedNow 2026-10-16T01:00:00Z` | `LITTLENEST_FIXED_NOW=...` | 固定"当前时间"（ISO 8601） |
| `-LittleNestDiagnostics YES` | `LITTLENEST_DIAGNOSTICS=1` | 在设置中显示开发诊断入口 |

演示模式的要点（对应测试 01-05）：

- 顶部固定显示"演示数据"横幅，并写明数据集和**固定时间**（例如 `F1 固定记录 · 固定时间 2026-10-16 09:00（Asia/Shanghai）`）。
- 时间被钉死为数据集固定的采集时刻（`DemoFixtures.captureInstant`），所以每次启动渲染完全一致。
- 演示模式**不做任何网络请求**，也**永远不会显示为已连接**。

在 Xcode 的 Scheme → Run → Arguments 里加 `-LittleNestMode demo` 即可手动进入演示模式。

## 真机签名（对应测试 01-02）

模拟器构建不需要签名；真机安装需要一个 Apple 开发者团队。

1. 复制模板：

   ```bash
   cp Config/Signing.local.xcconfig.example Config/Signing.local.xcconfig
   ```

2. 填入你自己的团队与 Bundle ID：

   ```
   LITTLE_NEST_DEVELOPMENT_TEAM = ABCDE12345
   LITTLE_NEST_BUNDLE_ID = com.example.littlenest
   ```

`Config/Signing.local.xcconfig` 已被 git 忽略，**不要提交**。
`Config/Base.xcconfig` 通过 `#include? "Signing.local.xcconfig"` 读取它，缺失时回退到空团队和默认 Bundle ID，
所以干净签出仍能在模拟器上构建（测试 01-01）。

## 隔离测试后端（对应测试 01-03）

```bash
python scripts/run-isolated-backend.py --reset
python scripts/run-isolated-backend.py --keep-running --port 8099   # 手动浏览
```

脚本会：

1. 本仓库不包含 Python 后端。位于原工作区的 `ios` 目录时可自动发现父目录的 `.github-publish/baby_tracker`；独立克隆时请用 `--candidate` 指定另行克隆的后端目录；
2. 把 `BABY_TRACKER_DATA` 指向 `<ios-repo>/.ios-test-data/f0`（隔离目录，绝不用生产数据目录）；
3. 在回环地址上启动服务，读取 `/health` 并断言 `200` 且 `status=ok`、`alive`、`ready`；
4. 断言实际 `DATA_DIR` 就是隔离目录，且在仓库内。

> `.ios-test-data/` 位于本 iOS 仓库内，已在 `.gitignore` 中忽略。后端测试另外需要安装该后端声明的 Python 依赖，不是模拟器构建的前置条件。
> 当前只支持 `f0`；F1 及后续数据集随消费它们的步骤加入（见 `Tests/Fixtures/README.md`）。

## 测试

```bash
scripts/test-simulator.sh                                   # 全部
scripts/test-simulator.sh -only-testing:LittleNestTests      # 单元测试（01-04）
scripts/test-simulator.sh -only-testing:LittleNestUITests/DemoModeUITests
```

- 单元测试（`LittleNestTests`）**离线运行**：不访问 Home Assistant、不需要凭证、不需要网络（测试 01-04）。
- UI 测试（`LittleNestUITests`）用固定的 F1 演示数据启动，断言横幅与重复性（测试 01-05）。

## 不依赖 Xcode 的检查脚本

以下脚本可在 Windows/Linux 上运行，用于在编辑源码时提前发现问题：

```bash
python scripts/check-fixtures.py            # 校验 F0.json / F1.json 的结构与不变量
python scripts/verify-build-artifacts.py    # 检查 01-06：无数据文件、无个人绝对路径、无凭证
python scripts/verify-build-artifacts.py --app-bundle <path-to-.app>   # 额外检查已构建产物
```

## 已知限制

- **没有 App 图标**：`AppIcon.appiconset` 只有占位 `Contents.json`，构建会有 AppIcon 资源警告，属预期。
- **未实现连接**：`ConnectionController.connect()` 在校验地址后返回 `notAvailableInThisBuild`，不会假装成功。
- **UI 测试键盘**：在少数模拟器上文本输入可能受软键盘影响而偶发失败；必要时改用硬件键盘设置或重跑。
- **本机无法编译**：当前 Windows 环境没有 Swift/Xcode，Swift 代码与 `project.pbxproj` 只做过结构校验，未真正编译。
- **默认 Bundle ID**：`com.wddwxy.littlenest` 只是占位，真机安装前请改成你自己的。

## 步骤 01 的范围（不包含）

- 没有 `＋` 新建按钮（步骤 07 才引入记录类型选择器，计划禁止"看得见却没用"的按钮）。
- 没有趋势图表（只有占位页），没有 Live Activity target（步骤 11）。
- 没有真实 API 契约、DTO、同步或计时逻辑（步骤 02 起）。

状态与验收记录见 [`ENVIRONMENT.md`](ENVIRONMENT.md)。
