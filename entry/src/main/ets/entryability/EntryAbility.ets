import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { SmartPaymentService } from '../service/SmartPaymentService';
import { AppConstants } from '../utils/Constants';
import { DateUtils } from '../utils/DateUtils';

const TAG = 'EntryAbility';
const DOMAIN = 0xFF00;

export default class EntryAbility extends UIAbility {
  onCreate(want: object, launchParam: object): void {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');
    AppStorage.SetOrCreate(AppConstants.STORAGE_CURRENT_MONTH, DateUtils.getCurrentMonth());
    AppStorage.SetOrCreate(AppConstants.STORAGE_TOTAL_EXPENSE, 0);
    AppStorage.SetOrCreate(AppConstants.STORAGE_TOTAL_INCOME, 0);
    AppStorage.SetOrCreate(AppConstants.STORAGE_BILLS_UPDATED, false);
    AppStorage.SetOrCreate(AppConstants.STORAGE_THEME_COLOR, AppConstants.COLOR_PRIMARY);

    // 初始化数据库
    const context = this.context as common.UIAbilityContext;
    AppStorage.SetOrCreate<common.UIAbilityContext>('uiAbilityContext', context);
    DatabaseHelper.getInstance().init(context).then(() => {
      hilog.info(DOMAIN, TAG, 'Database initialized');
      // 读取智能记账设置，若已开启则启动智能支付监听
      preferences.getPreferences(context, 'app_settings').then(prefs => {
        prefs.get(AppConstants.PREF_SMART_RECORD, false).then((enabled) => {
          if (enabled === true) {
            SmartPaymentService.getInstance().start().then(() => {
              hilog.info(DOMAIN, TAG, 'SmartPaymentService started');
            });
          }
        });
      });
    }).catch((err: Error) => {
      hilog.error(DOMAIN, TAG, 'Database init failed: %{public}s', err.message);
    });
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
    SmartPaymentService.getInstance().stop();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err) => {
      if (err && err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading content');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
    AppStorage.Set(AppConstants.STORAGE_CURRENT_MONTH, DateUtils.getCurrentMonth());
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}