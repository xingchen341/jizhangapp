import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppConstants } from '../utils/Constants';
import { DateUtils } from '../utils/DateUtils';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  private tabController: TabsController = new TabsController();

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabController }) {
      TabContent() {
        HomePageContent()
      }
      .tabBar(this.TabBarItem(0, '🏠', '首页'))

      TabContent() {
        StatisticsPageContent()
      }
      .tabBar(this.TabBarItem(1, '📊', '统计'))

      TabContent() {
        BudgetPageContent()
      }
      .tabBar(this.TabBarItem(2, '💳', '预算'))

      TabContent() {
        SettingsPageContent()
      }
      .tabBar(this.TabBarItem(3, '⚙️', '我的'))
    }
    .scrollable(false)
    .animationDuration(200)
    .barHeight(60)
    .barBackgroundColor(AppConstants.COLOR_CARD)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }

  @Builder
  TabBarItem(index: number, icon: string, label: string) {
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(22)
        .fontColor(this.currentIndex === index ? AppConstants.COLOR_PRIMARY : '#AAAAAA')
      Text(label)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? AppConstants.COLOR_PRIMARY : '#AAAAAA')
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .width('100%')
    .height(60)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppConstants.COLOR_CARD)
  }
}

// ==================== 首页内容 ====================
@Component
struct HomePageContent {
  @StorageLink(AppConstants.STORAGE_BILLS_UPDATED) billsUpdated: boolean = false;
  @State currentMonth: string = '';
  @State totalExpense: number = 0;
  @State totalIncome: number = 0;
  @State recentBills: BillItem[] = [];

  aboutToAppear() {
    this.currentMonth = AppStorage.Get(AppConstants.STORAGE_CURRENT_MONTH) as string || '';
    this.loadData();
  }

  @Watch('billsUpdated')
  onBillsUpdated() {
    this.loadData();
  }

  loadData() {
    import('../database/DatabaseHelper').then(module => {
      const db = module.DatabaseHelper.getInstance();
      db.getMonthSummary(this.currentMonth).then(summary => {
        this.totalExpense = summary.totalExpense;
        this.totalIncome = summary.totalIncome;
      });
      db.getRecentBills(20).then(bills => {
        this.recentBills = bills as BillItem[];
      });
    });
  }

  build() {
    Column() {
      // 顶部渐变卡片
      Stack() {
        Column()
          .width('100%')
          .height(200)
          .linearGradient({
            angle: 135,
            colors: [['#7B68EE', 0.0], ['#6C63FF', 0.5], ['#5A52D5', 1.0]]
          })
          .borderRadius({ bottomLeft: 30, bottomRight: 30 })

        Column({ space: 8 }) {
          Row() {
            Text('智能记账')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Blank()
            Text('🔔')
              .fontSize(20)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 10 })

          Text(this.getCurrentMonthChinese())
            .fontSize(14)
            .fontColor('rgba(255,255,255,0.8)')

          Row({ space: 40 }) {
            Column({ space: 4 }) {
              Text('本月支出')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.8)')
              Text(`¥${this.totalExpense.toFixed(2)}`)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
            }
            Column({ space: 4 }) {
              Text('本月收入')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.8)')
              Text(`¥${this.totalIncome.toFixed(2)}`)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
            }
          }
          .margin({ top: 8 })
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')

      // 快速记账按钮
      Row({ space: 12 }) {
        Button('+ 记一笔')
          .width(140)
          .height(44)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(AppConstants.COLOR_PRIMARY)
          .borderRadius(22)
          .shadow({ radius: 8, color: 'rgba(108,99,255,0.3)', offsetX: 0, offsetY: 4 })
          .onClick(() => {
            router.pushUrl({ url: AppConstants.PAGE_ADD_BILL, params: { type: 'expense' } });
          })

        Button('📷 扫票据')
          .width(140)
          .height(44)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#FFFFFF')
          .fontColor(AppConstants.COLOR_PRIMARY)
          .borderRadius(22)
          .border({ width: 1.5, color: AppConstants.COLOR_PRIMARY })
          .onClick(() => {
            router.pushUrl({ url: AppConstants.PAGE_ADD_BILL, params: { type: 'expense', ocr: true } });
          })
      }
      .margin({ top: 20, bottom: 12 })

      // 最近账单
      Column() {
        Row() {
          Text('最近记录')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
          Blank()
          Text('查看全部 ›')
            .fontSize(13)
            .fontColor(AppConstants.COLOR_PRIMARY)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 10 })

        if (this.recentBills.length === 0) {
          Column({ space: 8 }) {
            Text('🧾')
              .fontSize(48)
            Text('暂无记录，快去记一笔吧！')
              .fontSize(14)
              .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
          }
          .width('100%')
          .height(180)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.recentBills, (bill: BillItem) => {
              ListItem() {
                BillListItem({ bill: bill, onDelete: () => { this.loadData(); } })
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .divider({ strokeWidth: 0.5, color: AppConstants.COLOR_DIVIDER, startMargin: 60 })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(AppConstants.COLOR_CARD)
      .borderRadius({ topLeft: 16, topRight: 16 })
      .padding({ top: 16 })
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: -2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BACKGROUND)
  }

  getCurrentMonthChinese(): string {
    if (!this.currentMonth) return '';
    const parts = this.currentMonth.split('-');
    if (parts.length !== 2) return this.currentMonth;
    return `${parts[0]}年${parts[1]}月`;
  }
}

// 账单列表项接口（用于类型注解）
interface BillItem {
  id: number;
  type: string;
  amount: number;
  categoryName: string;
  categoryIcon: string;
  categoryColor: string;
  note: string;
  date: string;
  imagePath: string;
  createdAt: string;
}

@Component
struct BillListItem {
  @Prop bill: BillItem;
  onDelete: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      // 分类图标
      Column() {
        Text(this.bill.categoryIcon)
          .fontSize(22)
      }
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor(this.bill.categoryColor + '22')
      .justifyContent(FlexAlign.Center)

      // 分类名和备注
      Column({ space: 4 }) {
        Text(this.bill.categoryName)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
        if (this.bill.note) {
          Text(this.bill.note)
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        } else {
          Text(this.bill.date)
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 金额
      Column({ space: 2 }) {
        Text((this.bill.type === 'expense' ? '-' : '+') + '¥' + this.bill.amount.toFixed(2))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.bill.type === 'expense' ? AppConstants.COLOR_EXPENSE : AppConstants.COLOR_INCOME)
        if (this.bill.imagePath) {
          Text('📎')
            .fontSize(10)
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          AlertDialog.show({
            title: '删除账单',
            message: `确认删除这条 ${this.bill.type === 'expense' ? '支出' : '收入'} 记录吗？`,
            primaryButton: {
              value: '删除',
              fontColor: '#FF4444',
              action: () => {
                import('../database/DatabaseHelper').then(module => {
                  module.DatabaseHelper.getInstance().deleteBill(this.bill.id).then(() => {
                    this.onDelete();
                  });
                });
              }
            },
            secondaryButton: {
              value: '取消',
              action: () => {}
            }
          });
        })
    )
    .onClick(() => {
      router.pushUrl({ url: AppConstants.PAGE_ADD_BILL, params: { billId: this.bill.id, edit: true } });
    })
  }
}

// ==================== 统计页内容 ====================
@Component
struct StatisticsPageContent {
  @State month: string = '';
  @State totalExpense: number = 0;
  @State totalIncome: number = 0;
  @State categoryStats: CategoryStatItem[] = [];
  @State trendData: MonthTrend[] = [];

  aboutToAppear() {
    this.month = AppStorage.Get(AppConstants.STORAGE_CURRENT_MONTH) as string || '';
    this.loadData();
  }

  loadData() {
    import('../database/DatabaseHelper').then(module => {
      const db = module.DatabaseHelper.getInstance();
      db.getMonthSummary(this.month).then(summary => {
        this.totalExpense = summary.totalExpense;
        this.totalIncome = summary.totalIncome;
      });
      db.getCategoryStats(this.month).then(stats => {
        this.categoryStats = stats as CategoryStatItem[];
      });
      db.getMonthlyTrend().then(trend => {
        this.trendData = trend as MonthTrend[];
      });
    });
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        // 标题栏
        Row() {
          Text('←')
            .fontSize(20)
            .fontColor(AppConstants.COLOR_PRIMARY)
            .onClick(() => {
              const prev = this.getPreviousMonth();
              this.month = prev;
              this.loadData();
            })
          Blank()
          Text(this.getMonthChinese())
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
          Blank()
          Text('→')
            .fontSize(20)
            .fontColor(AppConstants.COLOR_PRIMARY)
            .onClick(() => {
              const next = this.getNextMonth();
              this.month = next;
              this.loadData();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 16 })
        .backgroundColor(AppConstants.COLOR_CARD)

        // 收支汇总
        Row({ space: 0 }) {
          Column({ space: 6 }) {
            Text('支出')
              .fontSize(13)
              .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
            Text(`¥${this.totalExpense.toFixed(2)}`)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_EXPENSE)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)

          Divider().vertical(true).height(40).color(AppConstants.COLOR_DIVIDER)

          Column({ space: 6 }) {
            Text('收入')
              .fontSize(13)
              .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
            Text(`¥${this.totalIncome.toFixed(2)}`)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_INCOME)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)

          Divider().vertical(true).height(40).color(AppConstants.COLOR_DIVIDER)

          Column({ space: 6 }) {
            Text('结余')
              .fontSize(13)
              .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
            Text(`¥${(this.totalIncome - this.totalExpense).toFixed(2)}`)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppConstants.COLOR_PRIMARY)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height(90)
        .backgroundColor(AppConstants.COLOR_CARD)
        .margin({ top: 10 })

        // 分类占比
        Column() {
          Text('支出分类')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 12 })

          if (this.categoryStats.length === 0) {
            Text('暂无支出数据')
              .fontSize(14)
              .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
              .height(80)
              .textAlign(TextAlign.Center)
              .width('100%')
          } else {
            ForEach(this.categoryStats, (stat: CategoryStatItem, index: number) => {
              CategoryStatBar({ stat: stat, rank: index + 1 })
            })
          }
        }
        .width('100%')
        .padding(16)
        .margin({ top: 10 })
        .backgroundColor(AppConstants.COLOR_CARD)
        .borderRadius(12)

        // 趋势图（最近6个月）
        Column() {
          Text('近6个月趋势')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 16 })

          Row({ space: 6 }) {
            ForEach(this.trendData, (trend: MonthTrend) => {
              Column({ space: 4 }) {
                Text(`¥${Math.round(trend.totalExpense)}`)
                  .fontSize(9)
                  .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
                Column()
                  .width(28)
                  .height(this.getBarHeight(trend.totalExpense))
                  .backgroundColor(AppConstants.COLOR_EXPENSE)
                  .borderRadius({ topLeft: 4, topRight: 4 })
                Text(trend.month.substring(5))
                  .fontSize(10)
                  .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
              }
              .alignItems(HorizontalAlign.Center)
              .layoutWeight(1)
              .justifyContent(FlexAlign.End)
            })
          }
          .width('100%')
          .height(130)
          .alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .padding(16)
        .margin({ top: 10, bottom: 20 })
        .backgroundColor(AppConstants.COLOR_CARD)
        .borderRadius(12)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BACKGROUND)
    .scrollBar(BarState.Off)
  }

  getBarHeight(amount: number): number {
    const max = this.trendData.reduce((m, t) => Math.max(m, t.totalExpense), 1);
    return Math.max(4, (amount / max) * 100);
  }

  getMonthChinese(): string {
    if (!this.month) return '';
    const parts = this.month.split('-');
    if (parts.length !== 2) return this.month;
    return `${parts[0]}年${parts[1]}月`;
  }

  getPreviousMonth(): string {
    if (!this.month) return '';
    const parts = this.month.split('-');
    let year = parseInt(parts[0]);
    let month = parseInt(parts[1]) - 1;
    if (month === 0) { month = 12; year -= 1; }
    return `${year}-${month.toString().padStart(2, '0')}`;
  }

  getNextMonth(): string {
    if (!this.month) return '';
    const parts = this.month.split('-');
    let year = parseInt(parts[0]);
    let month = parseInt(parts[1]) + 1;
    if (month === 13) { month = 1; year += 1; }
    return `${year}-${month.toString().padStart(2, '0')}`;
  }
}

interface CategoryStatItem {
  categoryId: number;
  categoryName: string;
  categoryIcon: string;
  categoryColor: string;
  amount: number;
  percentage: number;
}

interface MonthTrend {
  month: string;
  totalExpense: number;
  totalIncome: number;
  balance: number;
}

@Component
struct CategoryStatBar {
  @Prop stat: CategoryStatItem;
  @Prop rank: number;

  build() {
    Column({ space: 6 }) {
      Row() {
        Text(this.stat.categoryIcon)
          .fontSize(18)
          .width(30)
        Text(this.stat.categoryName)
          .fontSize(14)
          .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
          .layoutWeight(1)
        Text(`${this.stat.percentage.toFixed(1)}%`)
          .fontSize(12)
          .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
          .width(40)
        Text(`¥${this.stat.amount.toFixed(2)}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
          .width(80)
          .textAlign(TextAlign.End)
      }
      .width('100%')

      Progress({ value: this.stat.percentage, total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(6)
        .color(this.stat.categoryColor)
        .backgroundColor(AppConstants.COLOR_DIVIDER)
    }
    .width('100%')
    .margin({ bottom: 12 })
  }
}

// ==================== 预算页内容 ====================
@Component
struct BudgetPageContent {
  @State month: string = '';
  @State budgets: BudgetItem[] = [];
  @State showAddDialog: boolean = false;
  @State editingBudget: BudgetItem | null = null;

  aboutToAppear() {
    this.month = AppStorage.Get(AppConstants.STORAGE_CURRENT_MONTH) as string || '';
    this.loadBudgets();
  }

  loadBudgets() {
    import('../database/DatabaseHelper').then(module => {
      module.DatabaseHelper.getInstance().getBudgetsByMonth(this.month).then(budgets => {
        this.budgets = budgets as BudgetItem[];
      });
    });
  }

  build() {
    Column() {
      // 标题
      Row() {
        Text('预算管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
        Blank()
        Button('+ 添加')
          .height(34)
          .fontSize(13)
          .backgroundColor(AppConstants.COLOR_PRIMARY)
          .borderRadius(17)
          .onClick(() => {
            router.pushUrl({ url: AppConstants.PAGE_BUDGET, params: { month: this.month } });
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 8 })
      .backgroundColor(AppConstants.COLOR_CARD)

      Scroll() {
        Column({ space: 10 }) {
          if (this.budgets.length === 0) {
            Column({ space: 12 }) {
              Text('💳')
                .fontSize(56)
              Text('还没有预算计划')
                .fontSize(16)
                .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
              Text('设置预算，合理掌控每月花销')
                .fontSize(13)
                .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
              Button('设置预算')
                .height(40)
                .backgroundColor(AppConstants.COLOR_PRIMARY)
                .borderRadius(20)
                .onClick(() => {
                  router.pushUrl({ url: AppConstants.PAGE_BUDGET, params: { month: this.month } });
                })
            }
            .width('100%')
            .height(300)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(AppConstants.COLOR_CARD)
            .borderRadius(12)
            .margin({ top: 10 })
          } else {
            ForEach(this.budgets, (budget: BudgetItem) => {
              BudgetCard({ budget: budget })
            })
          }
        }
        .padding({ left: 16, right: 16, top: 10, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor(AppConstants.COLOR_BACKGROUND)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BACKGROUND)
  }
}

interface BudgetItem {
  id: number;
  categoryId: number;
  categoryName: string;
  categoryIcon: string;
  amount: number;
  spent: number;
  month: string;
}

@Component
struct BudgetCard {
  @Prop budget: BudgetItem;

  getProgress(): number {
    if (this.budget.amount <= 0) return 0;
    return Math.min((this.budget.spent / this.budget.amount) * 100, 100);
  }

  getProgressColor(): string {
    const p = this.getProgress();
    if (p >= 90) return '#FF4444';
    if (p >= 70) return '#FF9800';
    return AppConstants.COLOR_PRIMARY;
  }

  build() {
    Column({ space: 10 }) {
      Row() {
        Text(this.budget.categoryIcon)
          .fontSize(24)
        Column({ space: 2 }) {
          Text(this.budget.categoryName)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
          Text(`已花 ¥${this.budget.spent.toFixed(2)} / 预算 ¥${this.budget.amount.toFixed(2)}`)
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
        }
        .margin({ left: 10 })
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 2 }) {
          Text(`${this.getProgress().toFixed(0)}%`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getProgressColor())
          Text(`剩 ¥${Math.max(0, this.budget.amount - this.budget.spent).toFixed(2)}`)
            .fontSize(11)
            .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      Progress({ value: this.getProgress(), total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(8)
        .color(this.getProgressColor())
        .backgroundColor(AppConstants.COLOR_DIVIDER)
        .borderRadius(4)

      if (this.getProgress() >= 90) {
        Row({ space: 4 }) {
          Text('⚠️')
            .fontSize(12)
          Text(this.getProgress() >= 100 ? '已超出预算！' : '即将超出预算，请注意控制支出')
            .fontSize(12)
            .fontColor('#FF6B6B')
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppConstants.COLOR_CARD)
    .borderRadius(12)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetX: 0, offsetY: 2 })
  }
}

// ==================== 设置页内容 ====================
@Component
struct SettingsPageContent {
  @State smartRecordEnabled: boolean = false;
  @State budgetAlertEnabled: boolean = true;
  @State currency: string = '¥';

  aboutToAppear() {
    import('@ohos.data.preferences').then(module => {
      const context = AppStorage.Get<object>('uiAbilityContext');
      if (!context) return;
      module.default.getPreferences(context, 'app_settings').then((prefs: object) => {
        const p = prefs as { get: (key: string, def: boolean) => Promise<boolean> };
        p.get(AppConstants.PREF_SMART_RECORD, false).then((v: boolean) => { this.smartRecordEnabled = v; });
        p.get(AppConstants.PREF_BUDGET_ALERT, true).then((v: boolean) => { this.budgetAlertEnabled = v; });
      });
    });
  }

  savePreference(key: string, value: boolean) {
    import('@ohos.data.preferences').then(module => {
      const context = AppStorage.Get<object>('uiAbilityContext');
      if (!context) return;
      module.default.getPreferences(context, 'app_settings').then((prefs: object) => {
        const p = prefs as { put: (key: string, val: boolean) => Promise<void>; flush: () => Promise<void> };
        p.put(key, value).then(() => p.flush());
      });
    });
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        // 用户头像区域
        Column({ space: 8 }) {
          Text('👤')
            .fontSize(56)
            .width(80)
            .height(80)
            .borderRadius(40)
            .backgroundColor(AppConstants.COLOR_PRIMARY_LIGHT)
            .textAlign(TextAlign.Center)
          Text('我的账本')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
          Text('管理您的财务数据')
            .fontSize(13)
            .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ top: 30, bottom: 20 })
        .backgroundColor(AppConstants.COLOR_CARD)
        .justifyContent(FlexAlign.Center)

        // 功能区
        Column({ space: 10 }) {
          // 智能场景
          Column() {
            Text('智能功能')
              .fontSize(13)
              .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 8 })

            SettingItem({
              icon: '🤖',
              title: '智能记账',
              subtitle: '支付后自动识别并记账',
              hasSwitch: true,
              switchValue: this.smartRecordEnabled,
              onChange: (val: boolean) => {
                this.smartRecordEnabled = val;
                this.savePreference(AppConstants.PREF_SMART_RECORD, val);
                import('../service/SmartPaymentService').then(m => {
                  if (val) {
                    m.SmartPaymentService.getInstance().start();
                    promptAction.showToast({ message: '智能记账已开启，将自动识别支付通知' });
                  } else {
                    m.SmartPaymentService.getInstance().stop();
                    promptAction.showToast({ message: '智能记账已关闭' });
                  }
                });
              }
            })

            SettingItem({
              icon: '🔔',
              title: '预算超支提醒',
              subtitle: '超出预算80%时提醒',
              hasSwitch: true,
              switchValue: this.budgetAlertEnabled,
              onChange: (val: boolean) => {
                this.budgetAlertEnabled = val;
                this.savePreference(AppConstants.PREF_BUDGET_ALERT, val);
              }
            })
          }
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD)
          .borderRadius(12)

          // 数据管理
          Column() {
            Text('数据管理')
              .fontSize(13)
              .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 8 })

            SettingItem({
              icon: '📤',
              title: '导出数据',
              subtitle: '导出为 CSV 文件',
              hasSwitch: false,
              switchValue: false,
              onChange: () => {
                promptAction.showToast({ message: '导出功能开发中...' });
              }
            })

            SettingItem({
              icon: '🗑️',
              title: '清空数据',
              subtitle: '删除所有账单记录',
              hasSwitch: false,
              switchValue: false,
              onChange: () => {
                AlertDialog.show({
                  title: '确认清空',
                  message: '此操作不可撤销，确认要删除所有数据吗？',
                  primaryButton: {
                    value: '确认清空',
                    fontColor: '#FF4444',
                    action: () => {
                      promptAction.showToast({ message: '数据已清空' });
                    }
                  },
                  secondaryButton: { value: '取消', action: () => {} }
                });
              }
            })
          }
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD)
          .borderRadius(12)

          // 关于
          Column() {
            Text('关于')
              .fontSize(13)
              .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 8 })

            SettingItem({
              icon: 'ℹ️',
              title: '版本信息',
              subtitle: 'v1.0.0  鸿蒙智能记账',
              hasSwitch: false,
              switchValue: false,
              onChange: () => {}
            })
          }
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD)
          .borderRadius(12)
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 30 })
        .backgroundColor(AppConstants.COLOR_BACKGROUND)
      }
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppConstants.COLOR_BACKGROUND)
  }
}

interface SettingItemProps {
  icon: string;
  title: string;
  subtitle: string;
  hasSwitch: boolean;
  switchValue: boolean;
  onChange: (val: boolean) => void;
}

@Component
struct SettingItem {
  @Prop icon: string = '';
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop hasSwitch: boolean = false;
  @Prop switchValue: boolean = false;
  onChange: (val: boolean) => void = () => {};

  build() {
    Row({ space: 12 }) {
      Text(this.icon)
        .fontSize(20)
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor(AppConstants.COLOR_PRIMARY_LIGHT)
        .textAlign(TextAlign.Center)

      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(15)
          .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
        Text(this.subtitle)
          .fontSize(12)
          .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.hasSwitch) {
        Toggle({ type: ToggleType.Switch, isOn: this.switchValue })
          .selectedColor(AppConstants.COLOR_PRIMARY)
          .onChange((isOn: boolean) => {
            this.onChange(isOn);
          })
      } else {
        Text('›')
          .fontSize(18)
          .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
      }
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .onClick(() => {
      if (!this.hasSwitch) {
        this.onChange(false);
      }
    })
  }
}
