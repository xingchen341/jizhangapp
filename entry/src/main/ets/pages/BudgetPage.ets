import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { Budget, Category, EXPENSE_CATEGORIES } from '../model/BillModel';
import { AppConstants } from '../utils/Constants';
import { DateUtils } from '../utils/DateUtils';

interface RouteParams {
  month?: string;
  budgetId?: number;
}

@Entry
@Component
struct BudgetPage {
  @State month: string = '';
  @State budgets: BudgetDisplayItem[] = [];
  @State showAddPanel: boolean = false;
  @State editingId: number = 0;
  @State selectedCategoryId: number = 1;
  @State budgetAmount: string = '';

  private db: DatabaseHelper = DatabaseHelper.getInstance();

  aboutToAppear() {
    const params = router.getParams() as RouteParams;
    this.month = (params && params.month) ? params.month : DateUtils.getCurrentMonth();
    this.loadBudgets();
  }

  async loadBudgets() {
    const raw = await this.db.getBudgetsByMonth(this.month);
    this.budgets = raw.map(b => ({
      id: b.id,
      categoryId: b.categoryId,
      categoryName: b.categoryName,
      categoryIcon: b.categoryIcon,
      amount: b.amount,
      spent: b.spent,
      month: b.month
    }));
  }

  getMonthChinese(): string {
    const parts = this.month.split('-');
    if (parts.length !== 2) return this.month;
    return `${parts[0]}年${parts[1]}月`;
  }

  getUnbudgetedCategories(): Category[] {
    const budgetedIds = new Set(this.budgets.map(b => b.categoryId));
    return EXPENSE_CATEGORIES.filter(c => !budgetedIds.has(c.id));
  }

  openAddPanel(catId: number = 0) {
    const cats = this.getUnbudgetedCategories();
    if (catId > 0) {
      this.selectedCategoryId = catId;
    } else if (cats.length > 0) {
      this.selectedCategoryId = cats[0].id;
    }
    this.budgetAmount = '';
    this.editingId = 0;
    this.showAddPanel = true;
  }

  openEditPanel(item: BudgetDisplayItem) {
    this.selectedCategoryId = item.categoryId;
    this.budgetAmount = item.amount.toString();
    this.editingId = item.id;
    this.showAddPanel = true;
  }

  async saveBudget() {
    const amount = parseFloat(this.budgetAmount);
    if (isNaN(amount) || amount <= 0) {
      promptAction.showToast({ message: '请输入有效预算金额' });
      return;
    }
    const cat = EXPENSE_CATEGORIES.find(c => c.id === this.selectedCategoryId);
    if (!cat) {
      promptAction.showToast({ message: '请选择分类' });
      return;
    }
    const budget: Budget = {
      id: this.editingId,
      categoryId: cat.id,
      categoryName: cat.name,
      categoryIcon: cat.icon,
      amount: amount,
      spent: 0,
      month: this.month
    };
    await this.db.saveBudget(budget);
    promptAction.showToast({ message: this.editingId > 0 ? '预算已更新' : '预算已添加' });
    this.showAddPanel = false;
    this.loadBudgets();
  }

  async deleteBudget(id: number) {
    await this.db.deleteBudget(id);
    promptAction.showToast({ message: '预算已删除' });
    this.loadBudgets();
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#FFFFFF')
          .padding(8)
          .onClick(() => router.back())
        Blank()
        Text('预算管理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Blank()
        Text('+ 新增')
          .fontSize(15)
          .fontColor('#FFFFFF')
          .onClick(() => this.openAddPanel())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .linearGradient({
        angle: 135,
        colors: [['#7B68EE', 0.0], ['#6C63FF', 1.0]]
      })

      // 月份显示
      Row() {
        Text(this.getMonthChinese() + ' 预算计划')
          .fontSize(15)
          .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(AppConstants.COLOR_CARD)

      // 预算总览
      if (this.budgets.length > 0) {
        this.BudgetOverview()
      }

      // 预算列表
      Scroll() {
        Column({ space: 10 }) {
          if (this.budgets.length === 0) {
            Column({ space: 16 }) {
              Text('💳')
                .fontSize(64)
              Text('还没有预算')
                .fontSize(17)
                .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
              Text('为各类支出设置预算上限\n合理规划每月财务')
                .fontSize(13)
                .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
                .textAlign(TextAlign.Center)
              Button('➕  立即设置预算')
                .height(46)
                .fontSize(15)
                .backgroundColor(AppConstants.COLOR_PRIMARY)
                .borderRadius(23)
                .padding({ left: 24, right: 24 })
                .shadow({ radius: 8, color: 'rgba(108,99,255,0.3)', offsetX: 0, offsetY: 4 })
                .onClick(() => this.openAddPanel())
            }
            .width('100%')
            .height(320)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(AppConstants.COLOR_CARD)
            .borderRadius(12)
          } else {
            ForEach(this.budgets, (item: BudgetDisplayItem) => {
              this.BudgetCard(item)
            })

            // 未设置预算的分类快速添加
            if (this.getUnbudgetedCategories().length > 0) {
              Column({ space: 10 }) {
                Text('快速添加预算')
                  .fontSize(14)
                  .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
                  .alignSelf(ItemAlign.Start)
                Row({ space: 8 }) {
                  ForEach(this.getUnbudgetedCategories().slice(0, 5), (cat: Category) => {
                    Column({ space: 4 }) {
                      Text(cat.icon)
                        .fontSize(20)
                        .width(40)
                        .height(40)
                        .borderRadius(20)
                        .backgroundColor(cat.color + '22')
                        .textAlign(TextAlign.Center)
                      Text(cat.name)
                        .fontSize(10)
                        .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
                    }
                    .onClick(() => this.openAddPanel(cat.id))
                  })
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor(AppConstants.COLOR_CARD)
              .borderRadius(12)
            }
          }
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 30 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor(AppConstants.COLOR_BACKGROUND)

      // 添加/编辑预算面板
      if (this.showAddPanel) {
        this.AddBudgetPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BACKGROUND)
  }

  @Builder
  BudgetOverview() {
    Row({ space: 0 }) {
      // 总预算
      Column({ space: 4 }) {
        Text('月度总预算')
          .fontSize(12)
          .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
        Text('¥' + this.budgets.reduce((s, b) => s + b.amount, 0).toFixed(2))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_PRIMARY)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      Divider().vertical(true).height(36).color(AppConstants.COLOR_DIVIDER)

      // 总已花费
      Column({ space: 4 }) {
        Text('已花费')
          .fontSize(12)
          .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
        Text('¥' + this.budgets.reduce((s, b) => s + b.spent, 0).toFixed(2))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_EXPENSE)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      Divider().vertical(true).height(36).color(AppConstants.COLOR_DIVIDER)

      // 剩余
      Column({ space: 4 }) {
        Text('剩余可用')
          .fontSize(12)
          .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
        const remain = this.budgets.reduce((s, b) => s + Math.max(0, b.amount - b.spent), 0);
        Text('¥' + remain.toFixed(2))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConstants.COLOR_INCOME)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(80)
    .backgroundColor(AppConstants.COLOR_CARD)
    .margin({ bottom: 0 })
  }

  @Builder
  BudgetCard(item: BudgetDisplayItem) {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Text(item.categoryIcon)
          .fontSize(26)
          .width(48)
          .height(48)
          .borderRadius(24)
          .backgroundColor(this.getCategoryColor(item.categoryId) + '22')
          .textAlign(TextAlign.Center)

        Column({ space: 3 }) {
          Row() {
            Text(item.categoryName)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
              .layoutWeight(1)
            Text(this.getProgressPercent(item) + '%')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getProgressColor(item))
          }
          Text(`已花 ¥${item.spent.toFixed(2)}  /  预算 ¥${item.amount.toFixed(2)}`)
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }

      Progress({
        value: Math.min(item.spent, item.amount),
        total: item.amount,
        type: ProgressType.Linear
      })
        .width('100%')
        .height(8)
        .color(this.getProgressColor(item))
        .backgroundColor(AppConstants.COLOR_DIVIDER)

      if (this.getProgressPercent(item) >= 90) {
        Row({ space: 6 }) {
          Text('⚠️').fontSize(13)
          Text(this.getProgressPercent(item) >= 100 ? '已超出预算！' : `即将超出，还剩 ¥${Math.max(0, item.amount - item.spent).toFixed(2)}`)
            .fontSize(12)
            .fontColor(this.getProgressPercent(item) >= 100 ? '#FF4444' : '#FF9800')
        }
      }

      Row({ space: 0 }) {
        Blank()
        Text('编辑')
          .fontSize(13)
          .fontColor(AppConstants.COLOR_PRIMARY)
          .padding({ left: 16, right: 8 })
          .onClick(() => this.openEditPanel(item))
        Text('删除')
          .fontSize(13)
          .fontColor('#FF4444')
          .padding({ left: 8, right: 0 })
          .onClick(() => {
            AlertDialog.show({
              title: '删除预算',
              message: `确认删除「${item.categoryName}」的预算吗？`,
              primaryButton: {
                value: '删除',
                fontColor: '#FF4444',
                action: () => this.deleteBudget(item.id)
              },
              secondaryButton: { value: '取消', action: () => {} }
            });
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppConstants.COLOR_CARD)
    .borderRadius(12)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetX: 0, offsetY: 2 })
  }

  @Builder
  AddBudgetPanel() {
    // 半透明蒙层
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0,0,0,0.5)')
      .position({ x: 0, y: 0 })
      .onClick(() => { this.showAddPanel = false; })

    // 底部面板
    Column({ space: 16 }) {
      // 拖拽条
      Column()
        .width(40)
        .height(4)
        .borderRadius(2)
        .backgroundColor(AppConstants.COLOR_DIVIDER)

      Text(this.editingId > 0 ? '编辑预算' : '新增预算')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppConstants.COLOR_TEXT_PRIMARY)

      // 分类选择
      if (this.editingId === 0) {
        Column({ space: 8 }) {
          Text('选择分类')
            .fontSize(13)
            .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
            .alignSelf(ItemAlign.Start)
          Grid() {
            ForEach(this.getUnbudgetedCategories(), (cat: Category) => {
              GridItem() {
                Column({ space: 4 }) {
                  Text(cat.icon)
                    .fontSize(22)
                    .width(44)
                    .height(44)
                    .borderRadius(22)
                    .backgroundColor(this.selectedCategoryId === cat.id ? cat.color : cat.color + '22')
                    .textAlign(TextAlign.Center)
                  Text(cat.name)
                    .fontSize(11)
                    .fontColor(this.selectedCategoryId === cat.id ? cat.color : AppConstants.COLOR_TEXT_SECONDARY)
                    .fontWeight(this.selectedCategoryId === cat.id ? FontWeight.Bold : FontWeight.Normal)
                }
                .onClick(() => { this.selectedCategoryId = cat.id; })
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
          .rowsGap(10)
          .columnsGap(6)
        }
      } else {
        // 编辑时显示当前分类
        const cat = EXPENSE_CATEGORIES.find(c => c.id === this.selectedCategoryId);
        if (cat) {
          Row({ space: 10 }) {
            Text(cat.icon).fontSize(28)
            Text(cat.name).fontSize(16).fontColor(AppConstants.COLOR_TEXT_PRIMARY)
          }
        }
      }

      // 金额输入
      Column({ space: 8 }) {
        Text('预算金额 (元)')
          .fontSize(13)
          .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
          .alignSelf(ItemAlign.Start)
        Row({ space: 8 }) {
          Text('¥')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_PRIMARY)
          TextInput({ placeholder: '输入月度预算金额', text: this.budgetAmount })
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppConstants.COLOR_PRIMARY)
            .backgroundColor('transparent')
            .type(InputType.Decimal)
            .layoutWeight(1)
            .onChange((v: string) => { this.budgetAmount = v; })
        }
        .width('100%')
        .padding({ bottom: 8 })
        .border({ width: { bottom: 1.5 }, color: AppConstants.COLOR_PRIMARY })

        // 快捷金额
        Row({ space: 8 }) {
          ForEach(['500', '1000', '2000', '3000', '5000'], (amt: string) => {
            Text(amt)
              .fontSize(13)
              .fontColor(this.budgetAmount === amt ? '#FFFFFF' : AppConstants.COLOR_PRIMARY)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .borderRadius(14)
              .backgroundColor(this.budgetAmount === amt ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_PRIMARY_LIGHT)
              .onClick(() => { this.budgetAmount = amt; })
          })
        }
      }

      // 按钮组
      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(46)
          .fontSize(15)
          .backgroundColor(AppConstants.COLOR_BACKGROUND)
          .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
          .borderRadius(23)
          .onClick(() => { this.showAddPanel = false; })
        Button('确认')
          .layoutWeight(1)
          .height(46)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(AppConstants.COLOR_PRIMARY)
          .borderRadius(23)
          .shadow({ radius: 8, color: 'rgba(108,99,255,0.3)', offsetX: 0, offsetY: 4 })
          .onClick(() => this.saveBudget())
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 34 })
    .backgroundColor(AppConstants.COLOR_CARD)
    .borderRadius({ topLeft: 20, topRight: 20 })
    .position({ x: 0, y: '100%' })
    .translate({ y: '-100%' })
  }

  getProgressPercent(item: BudgetDisplayItem): number {
    if (item.amount <= 0) return 0;
    return Math.round((item.spent / item.amount) * 100);
  }

  getProgressColor(item: BudgetDisplayItem): string {
    const p = this.getProgressPercent(item);
    if (p >= 100) return '#FF4444';
    if (p >= 80) return '#FF9800';
    return AppConstants.COLOR_PRIMARY;
  }

  getCategoryColor(catId: number): string {
    const cat = EXPENSE_CATEGORIES.find(c => c.id === catId);
    return cat ? cat.color : AppConstants.COLOR_PRIMARY;
  }
}

interface BudgetDisplayItem {
  id: number;
  categoryId: number;
  categoryName: string;
  categoryIcon: string;
  amount: number;
  spent: number;
  month: string;
}
