/**
 * 应用常量
 */

export class AppConstants {
  // 颜色主题
  static readonly COLOR_PRIMARY: string = '#6C63FF';
  static readonly COLOR_PRIMARY_DARK: string = '#4A42D4';
  static readonly COLOR_PRIMARY_LIGHT: string = '#EEF0FF';
  static readonly COLOR_EXPENSE: string = '#FF6B6B';
  static readonly COLOR_INCOME: string = '#4CAF50';
  static readonly COLOR_BACKGROUND: string = '#F8F9FA';
  static readonly COLOR_CARD: string = '#FFFFFF';
  static readonly COLOR_TEXT_PRIMARY: string = '#212121';
  static readonly COLOR_TEXT_SECONDARY: string = '#757575';
  static readonly COLOR_DIVIDER: string = '#F0F0F0';

  // 数据库
  static readonly DB_NAME: string = 'jizhang.db';
  static readonly TABLE_BILLS: string = 'bills';
  static readonly TABLE_BUDGETS: string = 'budgets';
  static readonly TABLE_CATEGORIES: string = 'categories';

  // 路由页面
  static readonly PAGE_INDEX: string = 'pages/Index';
  static readonly PAGE_HOME: string = 'pages/HomePage';
  static readonly PAGE_ADD_BILL: string = 'pages/AddBillPage';
  static readonly PAGE_STATISTICS: string = 'pages/StatisticsPage';
  static readonly PAGE_BUDGET: string = 'pages/BudgetPage';
  static readonly PAGE_SETTINGS: string = 'pages/SettingsPage';
  static readonly PAGE_CATEGORY_MANAGE: string = 'pages/CategoryManagePage';

  // AppStorage Keys
  static readonly STORAGE_CURRENT_MONTH: string = 'currentMonth';
  static readonly STORAGE_TOTAL_EXPENSE: string = 'totalExpense';
  static readonly STORAGE_TOTAL_INCOME: string = 'totalIncome';
  static readonly STORAGE_BILLS_UPDATED: string = 'billsUpdated';
  static readonly STORAGE_THEME_COLOR: string = 'themeColor';

  // Preferences Keys
  static readonly PREF_CURRENCY: string = 'currency';
  static readonly PREF_SMART_RECORD: string = 'smartRecord';
  static readonly PREF_NOTIFICATION_ENABLED: string = 'notificationEnabled';
  static readonly PREF_BUDGET_ALERT: string = 'budgetAlert';

  // 货币符号
  static readonly CURRENCIES: string[] = ['¥', '$', '€', '£', '₩'];

  // 默认分类 ID（用于新建账单时的初始选中项）
  static readonly DEFAULT_EXPENSE_CATEGORY_ID: number = 1;
  static readonly DEFAULT_INCOME_CATEGORY_ID: number = 21;

  // 快捷分类 (主页快速添加用)
  static readonly QUICK_EXPENSE_IDS: number[] = [1, 2, 3, 4, 5, 6];
}
