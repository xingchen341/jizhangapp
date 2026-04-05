import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import picker from '@ohos.file.picker';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { Bill, Category, EXPENSE_CATEGORIES, INCOME_CATEGORIES, getCategoryById } from '../model/BillModel';
import { AppConstants } from '../utils/Constants';
import { DateUtils } from '../utils/DateUtils';

interface RouteParams {
  type?: string;
  billId?: number;
  edit?: boolean;
  ocr?: boolean;
  // 智能场景快捷参数
  autoAmount?: number;
  autoCategory?: string;
  autoNote?: string;
}

@Entry
@Component
struct AddBillPage {
  @State billType: 'expense' | 'income' = 'expense';
  @State amount: string = '';
  @State selectedCategoryId: number = 1;
  @State note: string = '';
  @State selectedDate: string = '';
  @State imagePath: string = '';
  @State isOcrLoading: boolean = false;
  @State editBillId: number = 0;
  @State isEditMode: boolean = false;
  @State showDatePicker: boolean = false;
  @State selectedYear: number = new Date().getFullYear();
  @State selectedMonth: number = new Date().getMonth() + 1;
  @State selectedDay: number = new Date().getDate();

  private db: DatabaseHelper = DatabaseHelper.getInstance();

  aboutToAppear() {
    this.selectedDate = DateUtils.getTodayString();
    const params = router.getParams() as RouteParams;
    if (params) {
      if (params.type === 'income') {
        this.billType = 'income';
        this.selectedCategoryId = 21;
      }
      if (params.edit && params.billId) {
        this.isEditMode = true;
        this.editBillId = params.billId;
        this.loadBillForEdit(params.billId);
      }
      // 智能场景自动填充
      if (params.autoAmount) {
        this.amount = params.autoAmount.toString();
      }
      if (params.autoNote) {
        this.note = params.autoNote;
      }
      // OCR 模式
      if (params.ocr) {
        this.launchOcr();
      }
    }
  }

  async loadBillForEdit(id: number) {
    const bill = await this.db.getBillById(id);
    if (bill) {
      this.billType = bill.type;
      this.amount = bill.amount.toString();
      this.selectedCategoryId = bill.categoryId;
      this.note = bill.note;
      this.selectedDate = bill.date;
      this.imagePath = bill.imagePath;
    }
  }

  getCurrentCategories(): Category[] {
    return this.billType === 'expense' ? EXPENSE_CATEGORIES : INCOME_CATEGORIES;
  }

  getSelectedCategory(): Category | undefined {
    return getCategoryById(this.selectedCategoryId);
  }

  async saveBill() {
    const amountNum = parseFloat(this.amount);
    if (isNaN(amountNum) || amountNum <= 0) {
      promptAction.showToast({ message: '请输入有效金额' });
      return;
    }
    const cat = this.getSelectedCategory();
    if (!cat) {
      promptAction.showToast({ message: '请选择分类' });
      return;
    }
    const bill: Bill = {
      id: this.editBillId,
      type: this.billType,
      amount: amountNum,
      categoryId: cat.id,
      categoryName: cat.name,
      categoryIcon: cat.icon,
      categoryColor: cat.color,
      note: this.note,
      date: this.selectedDate,
      imagePath: this.imagePath,
      createdAt: ''
    };
    try {
      if (this.isEditMode) {
        await this.db.updateBill(bill);
        promptAction.showToast({ message: '已更新' });
      } else {
        await this.db.insertBill(bill);
        promptAction.showToast({ message: '记账成功 ✓' });
      }
      AppStorage.Set(AppConstants.STORAGE_BILLS_UPDATED, !(AppStorage.Get(AppConstants.STORAGE_BILLS_UPDATED) as boolean));
      router.back();
    } catch (err) {
      promptAction.showToast({ message: '保存失败，请重试' });
    }
  }

  /**
   * 启动图片OCR识别
   * 使用文件选择器选取图片，然后调用文字识别能力解析账单信息
   */
  async launchOcr() {
    try {
      // 打开相册选择图片
      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });
      if (result.photoUris && result.photoUris.length > 0) {
        const uri = result.photoUris[0];
        this.imagePath = uri;
        this.isOcrLoading = true;
        // 调用文字识别（鸿蒙视觉能力）
        await this.recognizeTextFromImage(uri);
        this.isOcrLoading = false;
      }
    } catch (err) {
      this.isOcrLoading = false;
      promptAction.showToast({ message: '图片选择失败' });
    }
  }

  /**
   * 图片文字识别 - 解析账单金额和商户信息
   * 通过鸿蒙 Vision Kit 的 TextRecognizer 实现 OCR
   */
  async recognizeTextFromImage(imageUri: string): Promise<void> {
    try {
      // 动态导入视觉识别能力
      const visionModule = await import('@ohos.ai.vision');
      // 创建文字识别器
      const recognizer = visionModule.textRecognizer.create();
      const imageSource = await import('@ohos.multimedia.image');
      const is = imageSource.createImageSource(imageUri);
      const pixelMap = await is.createPixelMap();

      const textResult = await recognizer.recognize(pixelMap);
      if (textResult && textResult.value) {
        this.parseOcrResult(textResult.value);
        promptAction.showToast({ message: 'OCR识别成功' });
      }
      pixelMap.release();
    } catch (err) {
      // OCR能力不可用时，提示用户手动输入
      promptAction.showToast({ message: '图片已附加，请手动填写金额' });
    }
  }

  /**
   * 解析OCR文字，提取金额和备注
   */
  parseOcrResult(text: string) {
    // 匹配金额：支持 ¥123.45 / 合计:123.45 / 总计 123.45 等格式
    const amountPatterns = [
      /[¥￥]\s*(\d+\.?\d*)/,
      /合计[：:]\s*(\d+\.?\d*)/,
      /总计[：:]\s*(\d+\.?\d*)/,
      /实付[：:]\s*(\d+\.?\d*)/,
      /金额[：:]\s*(\d+\.?\d*)/,
      /应付[：:]\s*(\d+\.?\d*)/,
    ];
    for (const pattern of amountPatterns) {
      const match = text.match(pattern);
      if (match && match[1]) {
        this.amount = match[1];
        break;
      }
    }

    // 提取商户名（第一行非空文字作为备注）
    const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 0);
    if (lines.length > 0 && !this.note) {
      const firstLine = lines[0].substring(0, 20);
      this.note = firstLine;
    }

    // 识别分类关键词
    this.autoMatchCategory(text);
  }

  /**
   * 根据OCR文本自动匹配分类
   */
  autoMatchCategory(text: string) {
    const keywords: Record<number, string[]> = {
      1: ['餐', '饮', '饭', '菜', '食堂', '超市', '便利店', '外卖', '咖啡', '奶茶', '烧烤', '火锅'],
      2: ['打车', '地铁', '公交', '出租', '高铁', '火车', '机票', '滴滴', '加油'],
      3: ['购物', '商场', '淘宝', '京东', '天猫', '拼多多', '服装', '鞋', '包'],
      4: ['电影', '游戏', '娱乐', 'KTV', '演唱会', '票'],
      5: ['房租', '水费', '电费', '物业', '房贷'],
      6: ['医院', '药店', '诊所', '医疗', '药品'],
      7: ['学费', '培训', '书', '课程', '教育'],
      8: ['酒店', '民宿', '景区', '旅游'],
      9: ['话费', '流量', '宽带', '通讯'],
    };
    for (const [catId, words] of Object.entries(keywords)) {
      if (words.some(w => text.includes(w))) {
        this.selectedCategoryId = parseInt(catId);
        return;
      }
    }
  }

  /**
   * 快捷金额按钮
   */
  @Builder
  QuickAmountButtons() {
    Row({ space: 8 }) {
      ForEach(['10', '20', '50', '100', '200'], (amt: string) => {
        Text(amt)
          .fontSize(13)
          .fontColor(this.amount === amt ? '#FFFFFF' : AppConstants.COLOR_PRIMARY)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(this.amount === amt ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_PRIMARY_LIGHT)
          .onClick(() => {
            this.amount = amt;
          })
      })
    }
    .margin({ top: 8 })
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
        Text(this.isEditMode ? '编辑账单' : '记一笔')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Blank()
        Text(this.isEditMode ? '保存' : '完成')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .padding(8)
          .onClick(() => this.saveBill())
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 16, bottom: 16 })
      .linearGradient({
        angle: 135,
        colors: [['#7B68EE', 0.0], ['#6C63FF', 1.0]]
      })

      // 收支切换
      Row() {
        Text('支出')
          .fontSize(15)
          .fontWeight(this.billType === 'expense' ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.billType === 'expense' ? '#FFFFFF' : 'rgba(255,255,255,0.6)')
          .padding({ left: 30, right: 30, top: 8, bottom: 8 })
          .borderRadius(20)
          .backgroundColor(this.billType === 'expense' ? 'rgba(255,255,255,0.25)' : 'transparent')
          .onClick(() => {
            this.billType = 'expense';
            this.selectedCategoryId = 1;
          })
        Text('收入')
          .fontSize(15)
          .fontWeight(this.billType === 'income' ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.billType === 'income' ? '#FFFFFF' : 'rgba(255,255,255,0.6)')
          .padding({ left: 30, right: 30, top: 8, bottom: 8 })
          .borderRadius(20)
          .backgroundColor(this.billType === 'income' ? 'rgba(255,255,255,0.25)' : 'transparent')
          .onClick(() => {
            this.billType = 'income';
            this.selectedCategoryId = 21;
          })
      }
      .padding({ top: 8, bottom: 16 })
      .linearGradient({
        angle: 135,
        colors: [['#7B68EE', 0.0], ['#6C63FF', 1.0]]
      })
      .width('100%')
      .justifyContent(FlexAlign.Center)

      Scroll() {
        Column({ space: 0 }) {
          // 金额输入卡片
          Column({ space: 8 }) {
            // OCR 加载指示
            if (this.isOcrLoading) {
              Row({ space: 8 }) {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color(AppConstants.COLOR_PRIMARY)
                Text('正在识别账单...')
                  .fontSize(13)
                  .fontColor(AppConstants.COLOR_PRIMARY)
              }
              .margin({ bottom: 8 })
            }

            Text('金额 (元)')
              .fontSize(13)
              .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
              .alignSelf(ItemAlign.Start)

            Row({ space: 8 }) {
              Text('¥')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.billType === 'expense' ? AppConstants.COLOR_EXPENSE : AppConstants.COLOR_INCOME)
              TextInput({ placeholder: '0.00', text: this.amount })
                .fontSize(32)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.billType === 'expense' ? AppConstants.COLOR_EXPENSE : AppConstants.COLOR_INCOME)
                .layoutWeight(1)
                .backgroundColor('transparent')
                .type(InputType.Decimal)
                .caretColor(AppConstants.COLOR_PRIMARY)
                .onChange((val: string) => {
                  this.amount = val;
                })
            }
            .width('100%')

            this.QuickAmountButtons()
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD)

          Divider().height(8).color(AppConstants.COLOR_BACKGROUND)

          // 分类选择
          Column({ space: 10 }) {
            Text('选择分类')
              .fontSize(13)
              .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
              .alignSelf(ItemAlign.Start)

            Grid() {
              ForEach(this.getCurrentCategories(), (cat: Category) => {
                GridItem() {
                  Column({ space: 4 }) {
                    Text(cat.icon)
                      .fontSize(24)
                      .width(48)
                      .height(48)
                      .borderRadius(24)
                      .backgroundColor(this.selectedCategoryId === cat.id ? cat.color : cat.color + '22')
                      .textAlign(TextAlign.Center)
                    Text(cat.name)
                      .fontSize(11)
                      .fontColor(this.selectedCategoryId === cat.id ? cat.color : AppConstants.COLOR_TEXT_SECONDARY)
                      .fontWeight(this.selectedCategoryId === cat.id ? FontWeight.Bold : FontWeight.Normal)
                  }
                  .onClick(() => {
                    this.selectedCategoryId = cat.id;
                  })
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
            .rowsGap(12)
            .columnsGap(8)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD)

          Divider().height(8).color(AppConstants.COLOR_BACKGROUND)

          // 备注和日期
          Column({ space: 0 }) {
            // 备注
            Row({ space: 12 }) {
              Text('📝')
                .fontSize(18)
              TextInput({ placeholder: '添加备注（选填）', text: this.note })
                .fontSize(15)
                .backgroundColor('transparent')
                .layoutWeight(1)
                .maxLength(50)
                .onChange((val: string) => {
                  this.note = val;
                })
            }
            .width('100%')
            .padding({ top: 14, bottom: 14 })

            Divider().color(AppConstants.COLOR_DIVIDER)

            // 日期
            Row({ space: 12 }) {
              Text('📅')
                .fontSize(18)
              Text(DateUtils.getFriendlyDate(this.selectedDate))
                .fontSize(15)
                .fontColor(AppConstants.COLOR_TEXT_PRIMARY)
                .layoutWeight(1)
              Text('修改')
                .fontSize(13)
                .fontColor(AppConstants.COLOR_PRIMARY)
                .onClick(() => {
                  this.showDatePicker = true;
                })
            }
            .width('100%')
            .padding({ top: 14, bottom: 14 })

            Divider().color(AppConstants.COLOR_DIVIDER)

            // 图片附件
            Row({ space: 12 }) {
              Text('📷')
                .fontSize(18)
              Text(this.imagePath ? '已附加图片凭证' : '添加图片凭证（可OCR识别）')
                .fontSize(15)
                .fontColor(this.imagePath ? AppConstants.COLOR_PRIMARY : AppConstants.COLOR_TEXT_SECONDARY)
                .layoutWeight(1)
              if (this.imagePath) {
                Text('✓')
                  .fontSize(16)
                  .fontColor(AppConstants.COLOR_INCOME)
              }
            }
            .width('100%')
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.launchOcr();
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .backgroundColor(AppConstants.COLOR_CARD)

          Divider().height(8).color(AppConstants.COLOR_BACKGROUND)

          // 快捷指令提示
          Row({ space: 8 }) {
            Text('💡')
              .fontSize(14)
            Text('支持语音快捷指令：「记账 餐饮 30元」')
              .fontSize(12)
              .fontColor(AppConstants.COLOR_TEXT_SECONDARY)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppConstants.COLOR_CARD)

          // 保存按钮
          Button(this.isEditMode ? '保存修改' : '确认记账')
            .width('90%')
            .height(50)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(this.billType === 'expense' ? AppConstants.COLOR_EXPENSE : AppConstants.COLOR_INCOME)
            .borderRadius(25)
            .margin({ top: 20, bottom: 30 })
            .shadow({
              radius: 12,
              color: this.billType === 'expense' ? 'rgba(255,107,107,0.3)' : 'rgba(76,175,80,0.3)',
              offsetX: 0,
              offsetY: 6
            })
            .onClick(() => this.saveBill())
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // 日期选择弹窗
      if (this.showDatePicker) {
        DatePickerDialog({
          start: new Date('2000-01-01'),
          end: new Date(),
          selected: new Date(this.selectedDate),
          onAccept: (value: DatePickerResult) => {
            const y = value.year ?? new Date().getFullYear();
            const m = ((value.month ?? new Date().getMonth()) + 1).toString().padStart(2, '0');
            const d = (value.day ?? new Date().getDate()).toString().padStart(2, '0');
            this.selectedDate = `${y}-${m}-${d}`;
            this.showDatePicker = false;
          },
          onCancel: () => {
            this.showDatePicker = false;
          }
        });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppConstants.COLOR_BACKGROUND)
  }
}
