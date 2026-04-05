import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { Category } from '../model/BillModel';
import { AppConstants } from '../utils/Constants';

const ICON_OPTIONS: string[] = [
  '🍔', '🍜', '🍕', '☕', '🍺', '🛒', '🥗', '🍰',
  '🚌', '🚗', '✈️', '🚢', '🚲', '⛽', '🚕', '🛵',
  '🛍️', '👗', '👟', '📱', '💻', '⌚', '🎁', '💍',
  '🎮', '🎬', '🎵', '🎨', '📚', '🏋️', '⚽', '🎯',
  '🏠', '💡', '🔧', '🌿', '🐾', '💊', '🏥', '🧴',
  '💰', '💵', '📈', '💼', '🧧', '📦', '🔖', '⭐'
];

const COLOR_OPTIONS: string[] = [
  '#FF6B6B', '#FF8E53', '#FDCB6E', '#F7DC6F',
  '#55EFC4', '#00B894', '#4ECDC4', '#00CEC9',
  '#74B9FF', '#45B7D1', '#6C5CE7', '#A29BFE',
  '#FD79A8', '#E84393', '#E17055', '#B2BEC3'
];

@Entry
@Component
struct CategoryManagePage {
  @State activeTab: string = 'expense';
  @State expenseCategories: Category[] = [];
  @State incomeCategories: Category[] = [];
  @State showAddPanel: boolean = false;
  @State newName: string = '';
  @State newIcon: string = '📦';
  @State newColor: string = '#6C63FF';

  private db: DatabaseHelper = DatabaseHelper.getInstance();

  aboutToAppear() {
    this.loadCategories();
  }

  async loadCategories(): Promise<void> {
    this.expenseCategories = await this.db.getCategoriesByType('expense');
    this.incomeCategories = await this.db.getCategoriesByType('income');
  }

  getCurrentCategories(): Category[] {
    return this.activeTab === 'expense' ? this.expenseCategories : this.incomeCategories;
  }

  async addCategory(): Promise<void> {
    const name = this.newName.trim();
    if (!name) {
      promptAction.showToast({ message: '请输入分类名称' });
      return;
    }
    const existing = this.getCurrentCategories().find(c => c.name === name);
    if (existing) {
      promptAction.showToast({ message: '该分类名称已存在' });
      return;
    }
    const category: Category = {
      id: 0,
      name: name,
      icon: this.newIcon,
      type: this.activeTab as 'expense' | 'income',
      color: this.newColor,
      isCustom: true
    };
    await this.db.insertCategory(category);
    promptAction.showToast({ message: '分类已添加' });
    this.showAddPanel = false;
    this.newName = '';
    this.newIcon = '📦';
    this.newColor = '#6C63FF';
    this.loadCategories();
  }

  deleteCategory(id: number, name: string): void {
    AlertDialog.show({
      title: '删除分类',
      message: `确认删除「${name}」分类吗？`,
      primaryButton: {
        value: '删除',
        fontColor: '#FF4444',
        action: async () => {
          await this.db.deleteCategory(id);
          promptAction.showToast({ message: '分类已删除' });
          this.loadCategories();
        }
      },
      secondaryButton: { value: '取消', action: () => {} }
    });
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#FFFFFF')
          .padding(8)
          .onClick(() => router.back())
        Blank()
        Text('分类管理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Blank()
        Text('完成')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .padding(8)
          .onClick(() => router.back())
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 16, bottom: 16 })
      .linearGradient({
        angle: 135,
        colors: [['#7B68EE', 0.0], ['#6C63FF', 1.0]]
      })

      // 收支类型切换
      Row() {
        Text('支出')
          .fontSize(15)
          .fontWeight(this.activeTab === 'expense' ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.activeTab === 'expense' ? '#FFFFFF' : 'rgba(255,255,255,0.6)')
          .padding({ left: 30, right: 30, top: 8, bottom: 8 })
          .borderRadius(20)
          .backgroundColor(this.activeTab === 'expense' ? 'rgba(255,255,255,0.25)' : 'transparent')
          .onClick(() => { this.activeTab = 'expense'; })
        Text('收入')
          .fontSize(15)
          .fontWeight(this.activeTab === 'income' ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.activeTab === 'income' ? '#FFFFFF' : 'rgba(255,255,255,0.6)')
          .padding({ left: 30, right: 30, top: 8, bottom: 8 })
          .borderRadius(20)
          .backgroundColor(this.activeTab === 'income' ? 'rgba(255,255,255,0.25)' : 'transparent')
          .onClick(() => { this.activeTab = 'income'; })
      }
      .padding({ top: 8, bottom: 16 })
      .linearGradient({
        angle: 135,
        colors: [['#7B68EE', 0.0], ['#6C63FF', 1.0]]
      })
      .width('100%')
      .justifyContent(FlexAlign.Center)

      // 分类列表
      Scroll() {
        Column({ space: 0 }) {
          ForEach(this.getCurrentCategories(), (cat: Category) => {
            Row({ space: 12 }) {
              Text(cat.icon)
                .fontSize(22)
                .width(44)
                .height(44)
                .borderRadius(22)
                .backgroundColor(cat.color + '22')
                .textAlign(TextAlign.Center)
              Text(cat.name)
                .fontSize(15)
                .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
                .layoutWeight(1)
              if (cat.isCustom) {
                Text('删除')
                  .fontSize(13)
                  .fontColor('#FF4444')
                  .padding({ left: 12, right: 4 })
                  .onClick(() => this.deleteCategory(cat.id, cat.name))
              } else {
                Text('🔒')
                  .fontSize(16)
                  .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .backgroundColor(AppConstants.COLOR_CARD)

            Divider()
              .color(AppConstants.COLOR_DIVIDER)
              .margin({ left: 72 })
          })

          // 添加分类按钮
          Row({ space: 8 }) {
            Text('+')
              .fontSize(20)
              .fontColor(AppConstants.COLOR_PRIMARY)
            Text('添加自定义分类')
              .fontSize(15)
              .fontColor(AppConstants.COLOR_PRIMARY)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          .backgroundColor(AppConstants.COLOR_CARD)
          .justifyContent(FlexAlign.Center)
          .margin({ top: 8 })
          .borderRadius(12)
          .onClick(() => {
            this.showAddPanel = true;
          })

          Text(`内置分类不可删除，自定义分类删除后对应账单数据不受影响。`)
            .fontSize(12)
            .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
            .padding(16)
            .textAlign(TextAlign.Center)
        }
        .padding({ bottom: 30 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor(AppConstants.COLOR_BACKGROUND)

      // 添加分类面板
      if (this.showAddPanel) {
        this.AddCategoryPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BACKGROUND)
  }

  @Builder
  AddCategoryPanel() {
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

      // 标题
      Text(`添加${this.activeTab === 'expense' ? '支出' : '收入'}分类`)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppConstants.COLOR_TEXT_PRIMARY)

      // 分类名称
      Column({ space: 6 }) {
        Text('分类名称')
          .fontSize(13)
          .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
          .alignSelf(ItemAlign.Start)
        TextInput({ placeholder: '请输入分类名称（最多6个字）', text: this.newName })
          .fontSize(15)
          .maxLength(6)
          .backgroundColor(AppConstants.COLOR_BACKGROUND)
          .borderRadius(8)
          .onChange((val: string) => { this.newName = val; })
      }

      // 选择图标
      Column({ space: 6 }) {
        Row() {
          Text('选择图标')
            .fontSize(13)
            .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
          Blank()
          Text(`已选：${this.newIcon}`)
            .fontSize(14)
        }
        .width('100%')

        Scroll() {
          Grid() {
            ForEach(ICON_OPTIONS, (icon: string) => {
              GridItem() {
                Text(icon)
                  .fontSize(24)
                  .width(44)
                  .height(44)
                  .borderRadius(22)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(this.newIcon === icon ? AppConstants.COLOR_PRIMARY_LIGHT : 'transparent')
                  .border(this.newIcon === icon ?
                    { width: 2, color: AppConstants.COLOR_PRIMARY, radius: 22 } :
                    { width: 0 })
                  .onClick(() => { this.newIcon = icon; })
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
          .rowsGap(6)
          .columnsGap(4)
        }
        .scrollBar(BarState.Off)
        .scrollable(ScrollDirection.Horizontal)
        .height(56)
      }

      // 选择颜色
      Column({ space: 6 }) {
        Text('选择颜色')
          .fontSize(13)
          .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
          .alignSelf(ItemAlign.Start)

        Row({ space: 8 }) {
          ForEach(COLOR_OPTIONS, (color: string) => {
            Column()
              .width(28)
              .height(28)
              .borderRadius(14)
              .backgroundColor(color)
              .border(this.newColor === color ?
                { width: 3, color: AppConstants.COLOR_TEXT_PRIMARY, radius: 14 } :
                { width: 0 })
              .onClick(() => { this.newColor = color; })
          })
        }
        .flexWrap(FlexWrap.Wrap)
        .width('100%')
      }

      // 预览
      Row({ space: 10 }) {
        Text(this.newIcon)
          .fontSize(22)
          .width(44)
          .height(44)
          .borderRadius(22)
          .backgroundColor(this.newColor + '22')
          .textAlign(TextAlign.Center)
        Text(this.newName || '分类名称')
          .fontSize(15)
          .fontColor(this.newName ? AppConstants.COLOR_TEXT_PRIMARY : AppConstants.COLOR_TEXT_SECONDARY)
      }
      .width('100%')
      .padding(12)
      .backgroundColor(AppConstants.COLOR_BACKGROUND)
      .borderRadius(8)

      // 操作按钮
      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
          .backgroundColor(AppConstants.COLOR_BACKGROUND)
          .borderRadius(22)
          .onClick(() => {
            this.showAddPanel = false;
            this.newName = '';
            this.newIcon = '📦';
            this.newColor = '#6C63FF';
          })
        Button('确认添加')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(AppConstants.COLOR_PRIMARY)
          .borderRadius(22)
          .onClick(() => this.addCategory())
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 30 })
    .backgroundColor(AppConstants.COLOR_CARD)
    .borderRadius({ topLeft: 20, topRight: 20 })
    .position({ x: 0, y: '100%' })
    .translate({ y: '-100%' })
  }
}
