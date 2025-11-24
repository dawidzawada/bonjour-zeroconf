import type { HybridObject } from 'react-native-nitro-modules';
import type { BonjourFail } from './BonjourFail';
import type { BonjourListener } from './BonjourListener';
import type { ScanResult } from './ScanResult';

export interface ScanOptions {
  addressResolveTimeout?: number;
}

export interface BonjourZeroconf
  extends HybridObject<{ ios: 'swift'; android: 'kotlin' }> {
  readonly isScanning: boolean;
  scan(type: string, domain: string, options?: ScanOptions): void;
  stop(): void;
  listenForScanResults(
    onResult: (results: ScanResult[]) => void
  ): BonjourListener;
  listenForScanState(onChange: (isScanning: boolean) => void): BonjourListener;
  listenForScanFail(onFail: (fail: BonjourFail) => void): BonjourListener;
}
