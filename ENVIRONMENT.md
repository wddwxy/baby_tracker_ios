# 步骤 01 环境与验收记录

## GitHub Actions 构建环境（2026-10-21 新增）

- 仓库：`wddwxy/baby_tracker_ios`，workflow：`.github/workflows/ios.yml`。
- CI 配置：`macos-15`、Xcode 16.4、自动发现 iPhone 模拟器、无签名构建。
- 执行 `build-simulator.sh`、全部单元/UI 测试、构建产物检查；上传环境、日志、`.xcresult`、截图与模拟器 App。
- 以下历史记录反映建立工程时的本地检查；不等于 CI 通过。首次在线编译和测试以 Actions 运行记录为准。
- 01-02 真机安装仍待签名/真机；当前 CI 不生成签名 IPA 或执行真机验收。

本文件记录步骤 01（构建环境、测试服务与最小 App）的**实际执行环境**和**逐条测试结果**。
按计划要求，执行记录**不得预先填"通过"**；只有真正执行过并留下证据的条目才标为通过。

状态词只使用：未开始、进行中、待环境、待真机、待修复、已通过。
模拟器通过但未真机验证的步骤不能标为"已验收"。

## 一、构建环境

以下带 `TODO` 的项需要在目标 Mac 上填写；已确定的值直接列出。

### Mac / Xcode

| 项目 | 值 | 说明 |
| --- | --- | --- |
| macOS 版本 | TODO | 执行构建的机器 |
| Xcode 版本 | TODO（要求 ≥ 16） | `xcodebuild -version` |
| Xcode 构建号 | TODO | 同一命令输出 |
| iOS SDK 版本 | TODO | `xcodebuild -showsdks` |
| Swift 版本 | TODO | `swift --version` |

### 目标设备与签名

| 项目 | 值 | 说明 |
| --- | --- | --- |
| 部署目标 | iOS 17.0 | `Config/Base.xcconfig`，交互式 Live Activity 的最低要求 |
| 模拟器机型 | iPhone 16（默认） | 可用 `SIMULATOR_DEVICE` 覆盖 |
| 真机机型 | TODO | 测试 01-02 |
| 真机 iOS 版本 | TODO | 需 ≥ 17 |
| Apple 开发者团队 | TODO（`LITTLE_NEST_DEVELOPMENT_TEAM`） | 只写在 `Config/Signing.local.xcconfig`（git 忽略） |
| Bundle ID | `com.wddwxy.littlenest`（占位，真机前需改） | `LITTLE_NEST_BUNDLE_ID`，需与 entitlements 一致 |

### 测试 Home Assistant / App 基线

| 项目 | 值 | 说明 |
| --- | --- | --- |
| App 名称 | Little Nest Baby Tracker | `baby_tracker/config.yaml` |
| App slug | `baby_tracker` | 计划要求记录 |
| App 版本（基线） | `0.7.17` | 对应 `.github-publish` HEAD `74f9853`（2026-10-16） |
| Ingress 端口 | `8099` | `baby_tracker/config.yaml` 的 `ingress_port` |
| HA Core 版本 | TODO | 计划要求记录（在测试 HA 上执行 `ha core info` 或从界面读取） |
| Supervisor 版本 | TODO | 计划要求记录（`ha supervisor info`） |
| 普通测试照护者账号 | TODO | 不得使用管理员账号做自动化 |
| 分发方式 | TODO（开发安装 / TestFlight） | 按实际账号资格确定 |

### 隔离后端

| 项目 | 值 | 说明 |
| --- | --- | --- |
| 数据目录 | `<ios-repo>/.ios-test-data/<dataset>` | 由 `scripts/run-isolated-backend.py` 创建，已 git 忽略 |
| 当前支持数据集 | `f0` | F1 及以后随消费它们的步骤加入 |
| 启动方式 | `python scripts/run-isolated-backend.py --reset` | 见 `README.md` |

## 二、测试用例记录

| ID / 层级 | 前置与操作 | 预期结果 | 状态 | 证据 / 备注 |
| --- | --- | --- | --- | --- |
| 01-01 UI | 干净签出后按 `README.md` 构建模拟器版本 | 无个人绝对路径依赖，可启动 | 待环境 | `verify-build-artifacts.py` 已在 Windows 通过（无绝对路径/凭证）；实际 `xcodebuild` 与启动待 macOS 执行 |
| 01-02 D | 用 `Config/Signing.local.xcconfig` 指定团队签名安装真机 | 可启动，Bundle ID 与 entitlements 一致 | 待真机 | 需要 Mac + 开发者团队 + 真机 |
| 01-03 C | `python scripts/run-isolated-backend.py --reset` | 数据目录指向隔离目录，不含生产数据 | **已通过** | Windows 执行，退出码 0；`DATA_DIR=<workspace>/.ios-test-data/f0`；`/health` → 200 `{"status":"ok","alive":true,"ready":true}` |
| 01-04 U | 离线运行模型/领域测试 | 不访问 HA，不要求凭证 | 待环境 | 用例已写好（`Tests/Unit/`），需 macOS + Xcode 运行 `test-simulator.sh` |
| 01-05 UI | 启动固定 F1 的 Demo 模式 | 数据和时间可重复，不伪装已连接 HA | 待环境 | 用例已写好（`Tests/UI/DemoModeUITests.swift`），需模拟器执行 |
| 01-06 C | 检查构建产物、配置和日志 | 不包含 token、cookie、生产导出 | 部分通过 | 源码/配置检查已在 Windows 通过（`verify-build-artifacts.py` 退出码 0）；已构建产物的 `--app-bundle` 检查待 macOS 构建后补做 |

## 三、Windows 环境已完成的检查

以下检查不依赖 Xcode，已在当前 Windows 机器执行通过：

| 检查 | 命令 | 结果 |
| --- | --- | --- |
| 合成 fixtures 结构校验 | `python scripts/check-fixtures.py` | 通过（退出码 0） |
| 构建产物/配置无泄漏 | `python scripts/verify-build-artifacts.py` | 通过（退出码 0） |
| 隔离 F0 后端健康检查 | `python scripts/run-isolated-backend.py --reset` | 通过（退出码 0） |
| Xcode 工程结构校验 | 临时脚本解析 `project.pbxproj` | 通过（分组路径可解析、target 成员正确、无绝对路径） |

## 四、尚未验证 / 待办

- Swift 源码与 `project.pbxproj` **未真正编译**：当前机器没有 Swift/Xcode，只做了结构校验。
- 真机签名与安装（01-02）需要 Mac 与开发者团队。
- 01-01 / 01-04 / 01-05 的模拟器执行与截图/录像证据待补。
- 上表中所有 `TODO` 需在目标 Mac 与测试 HA 上补齐后，本文件才算完整。
