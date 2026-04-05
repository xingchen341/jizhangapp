/**
 * 账单类型：支出或收入
 */
export type BillType = 'expense' | 'income';

/**
 * 账单数据模型
 */
export interface Bill {
  id: number;
  type: BillType;
  amount: number;
  categoryId: number;
  categoryName: string;
  categoryIcon: string;
  categoryColor: string;
  note: string;
  date: string;        // YYYY-MM-DD
  imagePath: string;
  createdAt: string;
}

/**
 * 预算数据模型
 */
export interface Budget {
  id: number;
  categoryId: number;
  categoryName: string;
  categoryIcon: string;
  amount: number;
  spent: number;
  month: string;       // YYYY-MM
}

/**
 * 分类数据模型
 */
export interface Category {
  id: number;
  name: string;
  icon: string;
  type: BillType;
  color: string;
  isCustom?: boolean;
}

/**
 * 月度统计数据
 */
export interface MonthSummary {
  month: string;
  totalExpense: number;
  totalIncome: number;
  balance: number;
}

/**
 * 分类统计
 */
export interface CategoryStat {
  categoryId: number;
  categoryName: string;
  categoryIcon: string;
  categoryColor: string;
  amount: number;
  percentage: number;
}

/**
 * 支出分类列表
 */
export const EXPENSE_CATEGORIES: Category[] = [
  { id: 1, name: '餐饮', icon: '🍔', type: 'expense', color: '#FF6B6B' },
  { id: 2, name: '交通', icon: '🚌', type: 'expense', color: '#4ECDC4' },
  { id: 3, name: '购物', icon: '🛍️', type: 'expense', color: '#45B7D1' },
  { id: 4, name: '娱乐', icon: '🎮', type: 'expense', color: '#A29BFE' },
  { id: 5, name: '住房', icon: '🏠', type: 'expense', color: '#FDCB6E' },
  { id: 6, name: '医疗', icon: '💊', type: 'expense', color: '#E17055' },
  { id: 7, name: '教育', icon: '📚', type: 'expense', color: '#6C5CE7' },
  { id: 8, name: '旅行', icon: '✈️', type: 'expense', color: '#00B894' },
  { id: 9, name: '通讯', icon: '📱', type: 'expense', color: '#74B9FF' },
  { id: 10, name: '宠物', icon: '🐾', type: 'expense', color: '#FD79A8' },
  { id: 11, name: '美容', icon: '💄', type: 'expense', color: '#E84393' },
  { id: 12, name: '其他', icon: '📦', type: 'expense', color: '#B2BEC3' },
];

/**
 * 收入分类列表
 */
export const INCOME_CATEGORIES: Category[] = [
  { id: 21, name: '工资', icon: '💰', type: 'income', color: '#00B894' },
  { id: 22, name: '奖金', icon: '🎁', type: 'income', color: '#00CEC9' },
  { id: 23, name: '理财', icon: '📈', type: 'income', color: '#55EFC4' },
  { id: 24, name: '兼职', icon: '💼', type: 'income', color: '#81ECEC' },
  { id: 25, name: '红包', icon: '🧧', type: 'income', color: '#FF7675' },
  { id: 26, name: '退款', icon: '↩️', type: 'income', color: '#74B9FF' },
  { id: 27, name: '其他', icon: '💵', type: 'income', color: '#A29BFE' },
];

/**
 * 获取所有分类
 */
export function getAllCategories(): Category[] {
  return [...EXPENSE_CATEGORIES, ...INCOME_CATEGORIES];
}

/**
 * 根据ID获取分类
 */
export function getCategoryById(id: number): Category | undefined {
  return getAllCategories().find(c => c.id === id);
}

/**
 * 创建默认账单对象
 */
export function createDefaultBill(): Bill {
  return {
    id: 0,
    type: 'expense',
    amount: 0,
    categoryId: 1,
    categoryName: '餐饮',
    categoryIcon: '🍔',
    categoryColor: '#FF6B6B',
    note: '',
    date: '',
    imagePath: '',
    createdAt: ''
  };
}
