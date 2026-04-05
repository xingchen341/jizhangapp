import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { Bill, Budget, CategoryStat, MonthSummary } from '../model/BillModel';
import { AppConstants } from '../utils/Constants';
import { DateUtils } from '../utils/DateUtils';

const TAG = 'DatabaseHelper';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: AppConstants.DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
};

const CREATE_BILLS_TABLE = `
  CREATE TABLE IF NOT EXISTS ${AppConstants.TABLE_BILLS} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    amount REAL NOT NULL,
    category_id INTEGER NOT NULL,
    category_name TEXT NOT NULL,
    category_icon TEXT NOT NULL,
    category_color TEXT NOT NULL,
    note TEXT DEFAULT '',
    date TEXT NOT NULL,
    image_path TEXT DEFAULT '',
    created_at TEXT NOT NULL
  )
`;

const CREATE_BUDGETS_TABLE = `
  CREATE TABLE IF NOT EXISTS ${AppConstants.TABLE_BUDGETS} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER NOT NULL,
    category_name TEXT NOT NULL,
    category_icon TEXT NOT NULL,
    amount REAL NOT NULL,
    month TEXT NOT NULL,
    UNIQUE(category_id, month)
  )
`;

export class DatabaseHelper {
  private static instance: DatabaseHelper;
  private rdbStore: relationalStore.RdbStore | null = null;

  private constructor() {}

  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper();
    }
    return DatabaseHelper.instance;
  }

  /**
   * 初始化数据库
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.rdbStore) {
      return;
    }
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await this.rdbStore.executeSql(CREATE_BILLS_TABLE);
      await this.rdbStore.executeSql(CREATE_BUDGETS_TABLE);
      console.info(TAG, 'Database initialized successfully');
    } catch (err) {
      console.error(TAG, 'Failed to initialize database:', JSON.stringify(err));
      throw err;
    }
  }

  private getStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('Database not initialized. Call init() first.');
    }
    return this.rdbStore;
  }

  // ============================
  // 账单 CRUD
  // ============================

  /**
   * 插入账单
   */
  async insertBill(bill: Bill): Promise<number> {
    const store = this.getStore();
    const values: relationalStore.ValuesBucket = {
      'type': bill.type,
      'amount': bill.amount,
      'category_id': bill.categoryId,
      'category_name': bill.categoryName,
      'category_icon': bill.categoryIcon,
      'category_color': bill.categoryColor,
      'note': bill.note,
      'date': bill.date,
      'image_path': bill.imagePath || '',
      'created_at': DateUtils.getNowTimestamp()
    };
    const rowId = await store.insert(AppConstants.TABLE_BILLS, values);
    return rowId;
  }

  /**
   * 更新账单
   */
  async updateBill(bill: Bill): Promise<void> {
    const store = this.getStore();
    const values: relationalStore.ValuesBucket = {
      'type': bill.type,
      'amount': bill.amount,
      'category_id': bill.categoryId,
      'category_name': bill.categoryName,
      'category_icon': bill.categoryIcon,
      'category_color': bill.categoryColor,
      'note': bill.note,
      'date': bill.date,
      'image_path': bill.imagePath || ''
    };
    const predicates = new relationalStore.RdbPredicates(AppConstants.TABLE_BILLS);
    predicates.equalTo('id', bill.id);
    await store.update(values, predicates);
  }

  /**
   * 删除账单
   */
  async deleteBill(id: number): Promise<void> {
    const store = this.getStore();
    const predicates = new relationalStore.RdbPredicates(AppConstants.TABLE_BILLS);
    predicates.equalTo('id', id);
    await store.delete(predicates);
  }

  /**
   * 查询指定月份的账单
   */
  async getBillsByMonth(month: string): Promise<Bill[]> {
    const store = this.getStore();
    const predicates = new relationalStore.RdbPredicates(AppConstants.TABLE_BILLS);
    predicates.like('date', `${month}%`);
    predicates.orderByDesc('date');
    predicates.orderByDesc('created_at');
    const cursor = await store.query(predicates);
    return this.parseBillCursor(cursor);
  }

  /**
   * 查询最近N条账单
   */
  async getRecentBills(limit: number): Promise<Bill[]> {
    const store = this.getStore();
    const predicates = new relationalStore.RdbPredicates(AppConstants.TABLE_BILLS);
    predicates.orderByDesc('date');
    predicates.orderByDesc('created_at');
    predicates.limitAs(limit);
    const cursor = await store.query(predicates);
    return this.parseBillCursor(cursor);
  }

  /**
   * 根据ID查询账单
   */
  async getBillById(id: number): Promise<Bill | null> {
    const store = this.getStore();
    const predicates = new relationalStore.RdbPredicates(AppConstants.TABLE_BILLS);
    predicates.equalTo('id', id);
    const cursor = await store.query(predicates);
    const bills = this.parseBillCursor(cursor);
    return bills.length > 0 ? bills[0] : null;
  }

  /**
   * 获取月度汇总统计
   */
  async getMonthSummary(month: string): Promise<MonthSummary> {
    const bills = await this.getBillsByMonth(month);
    let totalExpense = 0;
    let totalIncome = 0;
    bills.forEach(bill => {
      if (bill.type === 'expense') {
        totalExpense += bill.amount;
      } else {
        totalIncome += bill.amount;
      }
    });
    return {
      month,
      totalExpense,
      totalIncome,
      balance: totalIncome - totalExpense
    };
  }

  /**
   * 获取分类统计（支出）
   */
  async getCategoryStats(month: string): Promise<CategoryStat[]> {
    const bills = await this.getBillsByMonth(month);
    const expenseBills = bills.filter(b => b.type === 'expense');
    const totalExpense = expenseBills.reduce((sum, b) => sum + b.amount, 0);

    const statsMap = new Map<number, CategoryStat>();
    expenseBills.forEach(bill => {
      const existing = statsMap.get(bill.categoryId);
      if (existing) {
        existing.amount += bill.amount;
      } else {
        statsMap.set(bill.categoryId, {
          categoryId: bill.categoryId,
          categoryName: bill.categoryName,
          categoryIcon: bill.categoryIcon,
          categoryColor: bill.categoryColor,
          amount: bill.amount,
          percentage: 0
        });
      }
    });

    const stats = Array.from(statsMap.values());
    stats.forEach(stat => {
      stat.percentage = totalExpense > 0 ? (stat.amount / totalExpense) * 100 : 0;
    });
    stats.sort((a, b) => b.amount - a.amount);
    return stats;
  }

  /**
   * 获取最近6个月汇总（用于趋势图）
   */
  async getMonthlyTrend(): Promise<MonthSummary[]> {
    const months = DateUtils.getLastSixMonths();
    const results: MonthSummary[] = [];
    for (const month of months) {
      const summary = await this.getMonthSummary(month);
      results.push(summary);
    }
    results.reverse();
    return results;
  }

  /**
   * 解析游标为账单数组
   */
  private parseBillCursor(cursor: relationalStore.ResultSet): Bill[] {
    const bills: Bill[] = [];
    if (cursor.rowCount === 0) {
      cursor.close();
      return bills;
    }
    cursor.goToFirstRow();
    do {
      const bill: Bill = {
        id: cursor.getLong(cursor.getColumnIndex('id')),
        type: cursor.getString(cursor.getColumnIndex('type')) as 'expense' | 'income',
        amount: cursor.getDouble(cursor.getColumnIndex('amount')),
        categoryId: cursor.getLong(cursor.getColumnIndex('category_id')),
        categoryName: cursor.getString(cursor.getColumnIndex('category_name')),
        categoryIcon: cursor.getString(cursor.getColumnIndex('category_icon')),
        categoryColor: cursor.getString(cursor.getColumnIndex('category_color')),
        note: cursor.getString(cursor.getColumnIndex('note')),
        date: cursor.getString(cursor.getColumnIndex('date')),
        imagePath: cursor.getString(cursor.getColumnIndex('image_path')),
        createdAt: cursor.getString(cursor.getColumnIndex('created_at'))
      };
      bills.push(bill);
    } while (cursor.goToNextRow());
    cursor.close();
    return bills;
  }

  // ============================
  // 预算 CRUD
  // ============================

  /**
   * 保存或更新预算（UPSERT）
   */
  async saveBudget(budget: Budget): Promise<void> {
    const store = this.getStore();
    const values: relationalStore.ValuesBucket = {
      'category_id': budget.categoryId,
      'category_name': budget.categoryName,
      'category_icon': budget.categoryIcon,
      'amount': budget.amount,
      'month': budget.month
    };
    if (budget.id > 0) {
      const predicates = new relationalStore.RdbPredicates(AppConstants.TABLE_BUDGETS);
      predicates.equalTo('id', budget.id);
      await store.update(values, predicates);
    } else {
      // 检查是否存在
      const existing = await this.getBudget(budget.categoryId, budget.month);
      if (existing) {
        const predicates = new relationalStore.RdbPredicates(AppConstants.TABLE_BUDGETS);
        predicates.equalTo('id', existing.id);
        await store.update(values, predicates);
      } else {
        await store.insert(AppConstants.TABLE_BUDGETS, values);
      }
    }
  }

  /**
   * 删除预算
   */
  async deleteBudget(id: number): Promise<void> {
    const store = this.getStore();
    const predicates = new relationalStore.RdbPredicates(AppConstants.TABLE_BUDGETS);
    predicates.equalTo('id', id);
    await store.delete(predicates);
  }

  /**
   * 获取指定月份所有预算
   */
  async getBudgetsByMonth(month: string): Promise<Budget[]> {
    const store = this.getStore();
    const predicates = new relationalStore.RdbPredicates(AppConstants.TABLE_BUDGETS);
    predicates.equalTo('month', month);
    const cursor = await store.query(predicates);

    const budgets: Budget[] = [];
    if (cursor.rowCount === 0) {
      cursor.close();
      return budgets;
    }

    // 获取该月份支出数据
    const bills = await this.getBillsByMonth(month);
    const spentMap = new Map<number, number>();
    bills.filter(b => b.type === 'expense').forEach(b => {
      const prev = spentMap.get(b.categoryId) || 0;
      spentMap.set(b.categoryId, prev + b.amount);
    });

    cursor.goToFirstRow();
    do {
      const catId = cursor.getLong(cursor.getColumnIndex('category_id'));
      budgets.push({
        id: cursor.getLong(cursor.getColumnIndex('id')),
        categoryId: catId,
        categoryName: cursor.getString(cursor.getColumnIndex('category_name')),
        categoryIcon: cursor.getString(cursor.getColumnIndex('category_icon')),
        amount: cursor.getDouble(cursor.getColumnIndex('amount')),
        spent: spentMap.get(catId) || 0,
        month: cursor.getString(cursor.getColumnIndex('month'))
      });
    } while (cursor.goToNextRow());
    cursor.close();
    return budgets;
  }

  /**
   * 获取单个预算
   */
  async getBudget(categoryId: number, month: string): Promise<Budget | null> {
    const store = this.getStore();
    const predicates = new relationalStore.RdbPredicates(AppConstants.TABLE_BUDGETS);
    predicates.equalTo('category_id', categoryId);
    predicates.equalTo('month', month);
    const cursor = await store.query(predicates);
    if (cursor.rowCount === 0) {
      cursor.close();
      return null;
    }
    cursor.goToFirstRow();
    const catId = cursor.getLong(cursor.getColumnIndex('category_id'));
    const budget: Budget = {
      id: cursor.getLong(cursor.getColumnIndex('id')),
      categoryId: catId,
      categoryName: cursor.getString(cursor.getColumnIndex('category_name')),
      categoryIcon: cursor.getString(cursor.getColumnIndex('category_icon')),
      amount: cursor.getDouble(cursor.getColumnIndex('amount')),
      spent: 0,
      month: cursor.getString(cursor.getColumnIndex('month'))
    };
    cursor.close();
    return budget;
  }
}
