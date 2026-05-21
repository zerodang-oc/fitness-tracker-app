# 健身饮食追踪 App - 开发指南

## 项目概述
跨平台 Flutter 应用（iOS/Android），追踪运动消耗和饮食摄入，计算热量缺口，提供建议。

## 技术栈
- Flutter 3.27+
- drift (SQLite ORM)
- HUAWEI Health Kit SDK
- 火山引擎豆包视觉识别 API
- fl_chart
- riverpod (状态管理)
- go_router (路由)

## 项目结构
```
lib/
├── main.dart              # 入口
├── app.dart               # App 根组件
├── core/                  # 核心基础设施
│   ├── database/          # 数据库定义 (drift)
│   ├── api/               # API 客户端
│   ├── theme/             # 主题
│   └── utils/             # 工具函数
├── models/                # 数据模型
├── providers/             # Riverpod providers
├── features/
│   ├── home/              # 首页 - 今日概览
│   ├── diet/              # 饮食模块 - 拍照识别 + 录入
│   ├── exercise/          # 运动模块 - 华为数据同步
│   ├── weight/            # 体重模块
│   ├── analysis/          # 分析与报告
│   └── settings/          # 设置
└── widgets/               # 共享 UI 组件
```

## 开发顺序
1. 数据库模型 + 基础设施
2. 基础 UI 框架（底部导航、页面 skeleton）
3. 饮食拍照识别模块
4. 运动数据模块（模拟 → 真实 API）
5. 热量计算引擎
6. 分析报告和建议
7. UI 美化

## 关键 API
- 食物识别: 火山引擎豆包 Vision API (待接入)
- 运动数据: HUAWEI Health Kit (待接入)
- 食物营养成分: 国内食物成分表 (内置数据库)
