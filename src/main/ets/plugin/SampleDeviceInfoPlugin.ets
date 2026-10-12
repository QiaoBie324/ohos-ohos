/*
 * Copyright (c) 2026 Sample Device Info Plugin Authors
 *
 * Flutter OHOS MethodChannel plugin for sample_device_info.
 * Provides device platform version and integer addition via MethodChannel.
 */

import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import deviceInfo from '@ohos.deviceInfo';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * SampleDeviceInfoPlugin — Flutter OHOS MethodChannel 插件
 *
 * Channel 名: sample_device_info
 * 公开方法:
 *   - getPlatformVersion(): 返回 HarmonyOS 系统版本字符串（格式 "OpenHarmony-x.x.x.x"）
 *   - add(left, right): 返回两个整数的算术和（缺键/空值兜底 0）
 */
export default class SampleDeviceInfoPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  getUniqueClassName(): string {
    return 'SampleDeviceInfoPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    // 创建 MethodChannel 并注册 Handler
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'sample_device_info');
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    // 清理资源
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
    this.channel = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'getPlatformVersion':
        this.handleGetPlatformVersion(result);
        break;
      case 'add':
        this.handleAdd(call, result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  /**
   * 获取 HarmonyOS 系统版本号。
   *
   * 使用 @ohos.deviceInfo 的 osFullName，该字段已包含平台名前缀与版本号
   * （例如 "OpenHarmony-5.0.0.1"），因此直接返回即可，避免重复拼接 "HarmonyOS"/"OpenHarmony" 前缀。
   * 与 Android "Android {version}"、iOS "iOS {version}" 的用户可见语义保持一致。
   */
  private handleGetPlatformVersion(result: MethodResult): void {
    try {
      const version: string = deviceInfo.osFullName;
      result.success(version);
    } catch (error) {
      const err = error as BusinessError;
      result.error('GET_VERSION_ERROR', 'Failed to get platform version: ' + err.message, null);
    }
  }

  /**
   * 整数加法。
   *
   * 从参数中提取 left 和 right（Dart int → ETS number），相加后返回。
   * 缺键 / 空值兜底为 0，与 Android(Kotlin `?: 0`)、iOS(Swift `?? 0`) 的兜底语义对齐。
   *
   * 位宽说明：ArkTS number 为 IEEE754 双精度（安全整数上限 2^53），
   * 当前 add 用例为安全小整数，使用 number 承载即可；若扩展到大数场景，应切换为 bigint。
   */
  private handleAdd(call: MethodCall, result: MethodResult): void {
    try {
      const leftRaw: Object | null = call.argument('left');
      const rightRaw: Object | null = call.argument('right');
      const left: number = (leftRaw === null || leftRaw === undefined) ? 0 : (leftRaw as Object) as number;
      const right: number = (rightRaw === null || rightRaw === undefined) ? 0 : (rightRaw as Object) as number;
      const sum: number = left + right;
      result.success(sum);
    } catch (error) {
      const err = error as BusinessError;
      result.error('ADD_ERROR', 'Failed to add integers: ' + err.message, null);
    }
  }
}
