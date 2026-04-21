# Octopus Manager

基于 Flutter 的 [Octopus](https://github.com/lingyuins/octopus) 管理客户端 —— LLM API 网关与代理管理器。

## 功能特性

- **仪表盘** — 查看今日/累计实时指标、请求与费用合并趋势图、渠道与 API Key 排行榜，并支持 15/30/60 秒自动刷新
- **渠道管理** — 添加、编辑、启用/禁用渠道，同步上游配置，拉取可用模型，并在保存前测试渠道连通性
- **分组管理** — 配置轮询、随机、故障转移、加权和自动模式分组；支持自动分组、分组健康测试，以及 AI 路由生成
- **模型管理** — 维护模型价格，查看已关联渠道，并手动同步上游模型价格信息
- **API Key 管理** — 创建、编辑、启用/禁用和删除 API Key，支持费用限制和过期时间
- **转发日志** — 分页浏览日志，支持下拉刷新和一键清空
- **设置与运维** — 修改账户信息、导入导出设置、调整重试/熔断/自动策略参数、同步渠道、更新模型价格以及触发核心更新
- **初始化引导** — 连接新的 Octopus 服务器时，引导创建初始管理员账户
- **国际化** — 支持中文和英文界面

## 环境要求

- Flutter 3.x SDK
- Dart SDK `^3.10.4`
- 运行中的 [Octopus](https://github.com/lingyuins/octopus) 服务端

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/lingyuins/Octopus-Manage.git
cd Octopus-Manage

# 安装依赖
flutter pub get

# 可选检查
flutter analyze
flutter test

# 运行应用
flutter run
```

## 使用说明

1. 输入 Octopus 服务器地址（例如 `http://192.168.1.1:8080`）
2. 如果服务器尚未创建管理员账户，将自动进入初始设置页面
3. 使用管理员凭据登录
4. 勾选“记住我”可使用长期会话，不勾选则使用短期登录
5. 登录后可通过底部标签页管理仪表盘、渠道、分组、模型、API Key、日志和系统设置

## 项目结构

核心运行说明：

- `AppProvider` 是唯一的 `ChangeNotifier`，负责认证状态、语言、初始化状态、等待时间单位、仪表盘自动刷新偏好和全局错误状态。
- `ApiService` 提供原始 HTTP 能力，包含 Bearer Token、15 秒超时、基础地址与令牌持久化，以及 `401` 自动登出。
- `OctopusApi` 是类型化 API 封装，覆盖认证、统计、渠道、分组、模型、API Key、日志、设置和更新接口。
- `main.dart` 先进入加载壳层；存在令牌时进入 `HomePage`，否则进入 `LoginPage`；是否需要初始化由登录流程检查并在需要时跳转到 `BootstrapPage`。

```
lib/
├── l10n/           # 国际化
├── models/         # 数据模型
├── pages/          # 页面
│   ├── bootstrap_page.dart   # 初始化引导
│   ├── login_page.dart       # 登录
│   ├── home_page.dart        # 主页框架
│   ├── dashboard_page.dart   # 仪表盘
│   ├── channel_page.dart     # 渠道管理
│   ├── group_page.dart       # 分组管理
│   ├── model_page.dart       # 模型管理
│   ├── api_key_page.dart     # API Key 管理
│   ├── log_page.dart         # 日志
│   └── setting_page.dart     # 设置
├── providers/      # 状态管理（Provider）
├── services/       # API 服务层
│   ├── api_service.dart
│   └── octopus_api.dart
├── theme/          # 设计令牌与响应式辅助
├── utils/          # 公共解析工具
├── widgets/        # 可复用组件
└── main.dart
```

## 测试说明

- `flutter test` 当前执行 [test/widget_test.dart](/F:/codecil/octopusmanage/test/widget_test.dart) 中的测试
- 现有测试主要覆盖核心模型的序列化与空值安全行为
- 仓库暂未包含 Widget 测试或集成测试

## 许可证

本项目与 Octopus 使用相同的许可证。
