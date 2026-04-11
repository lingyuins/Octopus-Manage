# Octopus Manager

基于 Flutter 的 [Octopus](https://github.com/lingyuins/octopus) 管理客户端 —— LLM API 网关与代理管理器。

## 功能特性

- **仪表盘** — 实时统计（请求数、费用、Token 数、成功率）及每日趋势合并图表
- **排行榜** — 渠道与 API Key 排行榜，支持费用、请求数、Token 数、Key 用量四种排序
- **渠道管理** — 添加、编辑、启用/禁用和同步上游 LLM 提供商渠道
- **分组管理** — 配置路由分组，支持轮询、随机、故障转移和加权模式
- **API Key 管理** — 创建、编辑和删除 API Key，支持费用限制和过期时间
- **转发日志** — 浏览和清除请求日志
- **系统设置** — 配置 CORS、代理、熔断器等服务端参数
- **初始化引导** — 连接新的 Octopus 服务器时，引导创建初始管理员账户
- **国际化** — 支持中文和英文界面

## 环境要求

- Flutter 3.x SDK
- 运行中的 [Octopus](https://github.com/lingyuins/octopus) 服务端

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/lingyuins/Octopus-Manage.git
cd Octopus-Manage

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

## 使用说明

1. 输入 Octopus 服务器地址（例如 `http://192.168.1.1:8080`）
2. 如果服务器尚未创建管理员账户，将自动进入初始设置页面
3. 使用管理员凭据登录
4. 勾选"记住我"可保持 30 天登录状态，不勾选则 15 分钟后过期

## 项目结构

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
│   ├── api_key_page.dart     # API Key 管理
│   ├── log_page.dart         # 日志
│   └── setting_page.dart     # 设置
├── providers/      # 状态管理（Provider）
├── services/       # API 服务层
│   ├── api_service.dart
│   └── octopus_api.dart
├── widgets/        # 可复用组件
└── main.dart
```

## 许可证

本项目与 Octopus 使用相同的许可证。
