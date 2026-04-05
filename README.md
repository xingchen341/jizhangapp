# jizhangapp — 鸿蒙智能记账

基于 HarmonyOS（鸿蒙）的全功能智能记账应用，支持收支记录、自定义分类、预算管理、智能识别等功能。

---

## 功能特性

- **收支记录**：支持支出/收入双模式快速记账，可附加图片凭证
- **自定义分类**：内置 12 种支出分类 + 7 种收入分类，支持用户自行添加、删除自定义分类
- **OCR 智能识别**：拍摄/选取票据图片，自动提取金额和备注
- **智能记账**：自动识别微信、支付宝、银行等支付通知并记账
- **统计分析**：月度收支汇总、分类占比图表、近 6 个月趋势折线
- **预算管理**：按分类设置月度预算，超支自动提醒
- **数据管理**：导出 CSV、清空数据

---

## 环境要求

| 工具 / SDK | 版本要求 |
|---|---|
| [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/) | 4.0 及以上 |
| HarmonyOS SDK | API 10（HarmonyOS 4.0）及以上 |
| Node.js | 16.x 及以上（DevEco Studio 内置） |

---

## 获取代码

```bash
git clone https://github.com/xingchen341/jizhangapp.git
cd jizhangapp
```

---

## 构建与运行

### 方式一：使用 DevEco Studio（推荐）

1. 打开 DevEco Studio，选择 **File → Open**，选中项目根目录（含 `build-profile.json5` 的文件夹）。
2. 等待 Gradle / hvigor 依赖自动同步完成（首次可能需要几分钟）。
3. 连接 HarmonyOS 真机 **或** 启动模拟器（Phone / Tablet）。
4. 点击工具栏 ▶ **Run** 按钮，选择目标设备，即可编译并安装到设备。

### 方式二：命令行构建（hvigor）

```bash
# 安装 hvigor 构建工具（仅首次需要）
npm install -g @ohos/hvigor

# 在项目根目录执行全量构建（生成 .hap 包）
hvigorw assembleHap --mode module -p module=entry@default -p product=default

# 构建产物位于：
# entry/build/default/outputs/default/entry-default-signed.hap
```

### 安装到设备（命令行）

```bash
# 通过 hdc 安装（需要设备已开启开发者模式）
hdc install entry/build/default/outputs/default/entry-default-signed.hap
```

---

## 项目结构

```
jizhangapp/
├── AppScope/                    # 全局资源（图标、字符串）
├── entry/
│   └── src/main/
│       ├── ets/
│       │   ├── database/
│       │   │   └── DatabaseHelper.ets     # RDB 数据库封装（账单、预算、分类 CRUD）
│       │   ├── entryability/
│       │   │   └── EntryAbility.ets       # 应用入口，初始化数据库和智能服务
│       │   ├── model/
│       │   │   └── BillModel.ets          # 数据模型与内置分类常量
│       │   ├── pages/
│       │   │   ├── Index.ets              # 主页（含首页、统计、预算、设置四个 Tab）
│       │   │   ├── AddBillPage.ets        # 记账页（新增/编辑/OCR 模式）
│       │   │   ├── BudgetPage.ets         # 预算管理页
│       │   │   └── CategoryManagePage.ets # 自定义分类管理页
│       │   ├── service/
│       │   │   └── SmartPaymentService.ets # 支付通知智能识别服务
│       │   └── utils/
│       │       ├── Constants.ets          # 应用常量（颜色、路由、数据库表名）
│       │       └── DateUtils.ets          # 日期工具函数
│       └── resources/                     # 资源文件（颜色、字符串、页面路由配置）
├── build-profile.json5
├── hvigorfile.ts
└── oh-package.json5
```

---

## 权限说明

应用运行需要以下权限（已在 `module.json5` 中声明）：

| 权限 | 用途 |
|---|---|
| `READ_MEDIA` / `WRITE_MEDIA` | 选择图片凭证 |
| `CAMERA` | 拍摄票据进行 OCR |
| `NOTIFICATION_CONTROLLER` / `PUBLISH_NOTIFICATION` | 智能记账通知推送 |

---

## 自定义分类

进入应用 **"设置" Tab → 管理分类** 即可：

- **查看**内置支出/收入分类（不可删除）
- **添加**自定义分类：填写名称、选择图标 Emoji、选择颜色
- **删除**自定义分类

自定义分类添加后，在记账页的分类选择区域即可直接使用。

---

## 数据存储

- **账单 / 预算 / 分类**：使用鸿蒙 RDB（关系型数据库）持久化存储，数据库文件为 `jizhang.db`
- **应用设置**：使用鸿蒙 Preferences（KV 存储）保存智能记账开关、预算提醒等偏好设置
