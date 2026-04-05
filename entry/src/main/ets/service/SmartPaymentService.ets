import commonEventManager from '@ohos.commonEventManager';
import notificationSubscribe from '@ohos.notificationSubscribe';
import notification from '@ohos.notification';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { Bill, EXPENSE_CATEGORIES } from '../model/BillModel';
import { DateUtils } from '../utils/DateUtils';
import { AppConstants } from '../utils/Constants';

const TAG = 'SmartPaymentService';

/**
 * 已识别的支付信息
 */
interface ParsedPayment {
  amount: number;
  merchant: string;
  categoryId: number;
  source: string;
}

/**
 * 智能支付识别服务
 *
 * 监听来自微信、支付宝、银行等支付 App 的通知，
 * 自动解析支付金额和商户信息，并完成自动记账。
 *
 * 使用方式：在 EntryAbility.onCreate() 中调用 SmartPaymentService.getInstance().start(context)
 */
export class SmartPaymentService {
  private static instance: SmartPaymentService;
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;
  private notificationSubscriber: notificationSubscribe.NotificationSubscriber | null = null;
  private enabled: boolean = false;
  private db: DatabaseHelper = DatabaseHelper.getInstance();

  private constructor() {}

  static getInstance(): SmartPaymentService {
    if (!SmartPaymentService.instance) {
      SmartPaymentService.instance = new SmartPaymentService();
    }
    return SmartPaymentService.instance;
  }

  /**
   * 启动智能支付监听
   */
  async start(): Promise<void> {
    if (this.enabled) return;
    this.enabled = true;
    await this.subscribeNotifications();
    console.info(TAG, 'SmartPaymentService started');
  }

  /**
   * 停止智能支付监听
   */
  stop(): void {
    this.enabled = false;
    if (this.notificationSubscriber) {
      notificationSubscribe.unsubscribe(this.notificationSubscriber).catch((err: Error) => {
        console.warn(TAG, 'Failed to unsubscribe notifications:', err.message);
      });
      this.notificationSubscriber = null;
    }
    console.info(TAG, 'SmartPaymentService stopped');
  }

  /**
   * 订阅通知消息，监听支付通知
   */
  private async subscribeNotifications(): Promise<void> {
    try {
      this.notificationSubscriber = {
        onConsume: (data: notificationSubscribe.SubscribeCallbackData) => {
          if (!this.enabled) return;
          this.handleNotification(data);
        },
        onCancel: (data: notificationSubscribe.SubscribeCallbackData) => {},
        onUpdate: (data: notification.NotificationSortingMap) => {},
        onConnect: () => {
          console.info(TAG, 'Notification subscription connected');
        },
        onDisconnect: () => {
          console.info(TAG, 'Notification subscription disconnected');
        },
        onDestroy: () => {}
      };

      await notificationSubscribe.subscribe(this.notificationSubscriber, {});
      console.info(TAG, 'Subscribed to notifications');
    } catch (err) {
      console.error(TAG, 'Failed to subscribe notifications:', JSON.stringify(err));
    }
  }

  /**
   * 处理收到的通知消息
   */
  private handleNotification(data: notificationSubscribe.SubscribeCallbackData): void {
    try {
      const request = data.request;
      if (!request) return;

      const bundleName = request.creatorBundleName || '';
      const title = request.content?.normal?.title || '';
      const text = request.content?.normal?.text || '';
      const fullText = `${title} ${text}`;

      // 仅处理支付相关 App 的通知
      if (!this.isPaymentApp(bundleName)) return;

      const parsed = this.parsePaymentNotification(fullText, bundleName);
      if (parsed && parsed.amount > 0) {
        this.autoRecord(parsed);
      }
    } catch (err) {
      console.error(TAG, 'Error handling notification:', JSON.stringify(err));
    }
  }

  /**
   * 判断是否来自支付类 App（HarmonyOS 应用包名）
   */
  private isPaymentApp(bundleName: string): boolean {
    const paymentApps = [
      'com.tencent.mm',              // 微信（HarmonyOS版）
      'com.alipay.mobile.client',    // 支付宝（HarmonyOS版）
      'com.unionpay.tsmservice',     // 云闪付
      'com.icbc.client',             // 工商银行
      'com.ccb.ccbmobilebank',       // 建设银行
      'com.cmbchina.ccd.pluto',      // 招商银行
      'com.bankcomm.mobilebanking',  // 交通银行
      'com.abc.mobile',              // 农业银行
    ];
    return paymentApps.some(app => bundleName.includes(app));
  }

  /**
   * 解析支付通知文字，提取金额和商户
   */
  private parsePaymentNotification(text: string, bundleName: string): ParsedPayment | null {
    // 匹配金额：支持多种支付通知格式
    const amountPatterns = [
      /支付[了成功]\s*[¥￥]?\s*(\d+\.?\d*)\s*元/,
      /消费\s*[¥￥]?\s*(\d+\.?\d*)\s*元/,
      /付款\s*[¥￥]?\s*(\d+\.?\d*)\s*元/,
      /[¥￥]\s*(\d+\.?\d*)/,
      /(\d+\.?\d*)\s*元/,
    ];

    let amount = 0;
    for (const pattern of amountPatterns) {
      const match = text.match(pattern);
      if (match && match[1]) {
        amount = parseFloat(match[1]);
        if (amount > 0 && amount < 100000) {
          break;
        }
        amount = 0;
      }
    }

    if (amount <= 0) return null;

    // 提取商户名
    let merchant = '';
    const merchantPatterns = [
      /向\s*(.+?)\s*(付款|支付|转账)/,
      /在\s*(.+?)\s*(消费|支付)/,
      /商户[：:]\s*(.+?)[\s,，]/,
    ];
    for (const pattern of merchantPatterns) {
      const match = text.match(pattern);
      if (match && match[1]) {
        merchant = match[1].trim().substring(0, 15);
        break;
      }
    }

    // 根据商户名智能匹配分类
    const categoryId = this.matchCategoryFromText(text + ' ' + merchant);

    // 标识来源 App
    let source = '智能记账';
    if (bundleName.includes('tencent.mm')) source = '微信支付';
    else if (bundleName.includes('AlipayGphone')) source = '支付宝';
    else source = '银行卡';

    return { amount, merchant, categoryId, source };
  }

  /**
   * 根据文字匹配支出分类
   */
  private matchCategoryFromText(text: string): number {
    const keywords: Record<number, string[]> = {
      1:  ['餐', '饮', '饭', '菜', '食堂', '超市', '便利店', '外卖', '咖啡', '奶茶', '美食', '烧烤', '火锅', '麦当劳', '肯德基', '星巴克'],
      2:  ['打车', '地铁', '公交', '出租', '高铁', '火车', '机票', '滴滴', '加油', '停车', '交通'],
      3:  ['购物', '商场', '淘宝', '京东', '天猫', '拼多多', '服装', '鞋', '包', '超市', '沃尔玛', '家乐福'],
      4:  ['电影', '游戏', '娱乐', 'KTV', '演唱会', '票', '视频', '音乐', 'bilibili'],
      5:  ['房租', '水费', '电费', '物业', '房贷', '燃气', '暖气'],
      6:  ['医院', '药店', '诊所', '医疗', '药品', '健康'],
      7:  ['学费', '培训', '书', '课程', '教育', '学习'],
      8:  ['酒店', '民宿', '景区', '旅游', '旅行', '携程', '美团酒店'],
      9:  ['话费', '流量', '宽带', '通讯', '电话'],
    };
    for (const [catId, words] of Object.entries(keywords)) {
      if (words.some(w => text.includes(w))) {
        return parseInt(catId);
      }
    }
    return 12; // 其他
  }

  /**
   * 将解析到的支付信息自动写入数据库
   */
  private async autoRecord(parsed: ParsedPayment): Promise<void> {
    try {
      const cat = EXPENSE_CATEGORIES.find(c => c.id === parsed.categoryId) || EXPENSE_CATEGORIES[EXPENSE_CATEGORIES.length - 1];
      const bill: Bill = {
        id: 0,
        type: 'expense',
        amount: parsed.amount,
        categoryId: cat.id,
        categoryName: cat.name,
        categoryIcon: cat.icon,
        categoryColor: cat.color,
        note: parsed.merchant || `${parsed.source}自动记账`,
        date: DateUtils.getTodayString(),
        imagePath: '',
        createdAt: ''
      };
      await this.db.insertBill(bill);
      AppStorage.Set(AppConstants.STORAGE_BILLS_UPDATED, !(AppStorage.Get(AppConstants.STORAGE_BILLS_UPDATED) as boolean));

      // 发送本地通知告知用户
      this.sendLocalNotification(parsed, cat.name);
      console.info(TAG, `Auto recorded: ${cat.name} ¥${parsed.amount}`);
    } catch (err) {
      console.error(TAG, 'Failed to auto record bill:', JSON.stringify(err));
    }
  }

  /**
   * 发送本地通知提醒用户已自动记账
   */
  private sendLocalNotification(parsed: ParsedPayment, categoryName: string): void {
    const notificationRequest: notification.NotificationRequest = {
      id: Math.floor(Math.random() * 10000),
      content: {
        contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '智能记账已完成',
          text: `已自动记录：${categoryName} ¥${parsed.amount.toFixed(2)}`,
          additionalText: parsed.merchant || ''
        }
      }
    };
    notification.publish(notificationRequest).catch((err: Error) => {
      console.warn(TAG, 'Failed to publish notification:', err.message);
    });
  }
}
