/**
 * 日期工具类
 */
export class DateUtils {
  /**
   * 获取当前日期字符串 YYYY-MM-DD
   */
  static getTodayString(): string {
    const now = new Date();
    return DateUtils.formatDate(now);
  }

  /**
   * 获取当前月份字符串 YYYY-MM
   */
  static getCurrentMonth(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    return `${year}-${month}`;
  }

  /**
   * 格式化日期为 YYYY-MM-DD
   */
  static formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * 格式化日期为 YYYY年MM月DD日
   */
  static formatDateChinese(dateStr: string): string {
    if (!dateStr || dateStr.length < 10) {
      return dateStr;
    }
    const parts = dateStr.split('-');
    if (parts.length !== 3) {
      return dateStr;
    }
    return `${parts[0]}年${parts[1]}月${parts[2]}日`;
  }

  /**
   * 格式化月份为 YYYY年MM月
   */
  static formatMonthChinese(monthStr: string): string {
    if (!monthStr || monthStr.length < 7) {
      return monthStr;
    }
    const parts = monthStr.split('-');
    if (parts.length !== 2) {
      return monthStr;
    }
    return `${parts[0]}年${parts[1]}月`;
  }

  /**
   * 获取上个月字符串 YYYY-MM
   */
  static getPreviousMonth(monthStr: string): string {
    const parts = monthStr.split('-');
    if (parts.length !== 2) {
      return monthStr;
    }
    let year = parseInt(parts[0]);
    let month = parseInt(parts[1]) - 1;
    if (month === 0) {
      month = 12;
      year -= 1;
    }
    return `${year}-${month.toString().padStart(2, '0')}`;
  }

  /**
   * 获取下个月字符串 YYYY-MM
   */
  static getNextMonth(monthStr: string): string {
    const parts = monthStr.split('-');
    if (parts.length !== 2) {
      return monthStr;
    }
    let year = parseInt(parts[0]);
    let month = parseInt(parts[1]) + 1;
    if (month === 13) {
      month = 1;
      year += 1;
    }
    return `${year}-${month.toString().padStart(2, '0')}`;
  }

  /**
   * 判断日期是否是今天
   */
  static isToday(dateStr: string): boolean {
    return dateStr === DateUtils.getTodayString();
  }

  /**
   * 判断日期是否是昨天
   */
  static isYesterday(dateStr: string): boolean {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return dateStr === DateUtils.formatDate(yesterday);
  }

  /**
   * 获取日期的友好显示名称
   */
  static getFriendlyDate(dateStr: string): string {
    if (DateUtils.isToday(dateStr)) {
      return '今天';
    }
    if (DateUtils.isYesterday(dateStr)) {
      return '昨天';
    }
    return DateUtils.formatDateChinese(dateStr);
  }

  /**
   * 格式化金额显示
   */
  static formatAmount(amount: number): string {
    return amount.toFixed(2);
  }

  /**
   * 获取当前时间戳字符串
   */
  static getNowTimestamp(): string {
    return new Date().toISOString();
  }

  /**
   * 从日期字符串获取月份
   */
  static getMonthFromDate(dateStr: string): string {
    if (!dateStr || dateStr.length < 7) {
      return '';
    }
    return dateStr.substring(0, 7);
  }

  /**
   * 获取最近6个月列表
   */
  static getLastSixMonths(): string[] {
    const months: string[] = [];
    const now = new Date();
    for (let i = 0; i < 6; i++) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const year = d.getFullYear();
      const month = (d.getMonth() + 1).toString().padStart(2, '0');
      months.push(`${year}-${month}`);
    }
    return months;
  }
}
