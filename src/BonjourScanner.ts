import { NitroModules } from 'react-native-nitro-modules';
import type { BonjourZeroconf } from './specs/BonjourZeroconf.nitro';
import type { ScanOptions } from './specs/BonjourZeroconf.nitro';
import type { ScanResult } from './specs/ScanResult';
import type { BonjourListener } from './specs/BonjourListener';
import type { BonjourFail } from './specs/BonjourFail';

export interface BonjourScannerOptions {
  id?: string;
}

export class BonjourScanner {
  private _scanner: BonjourZeroconf;
  readonly id: string | undefined;

  constructor(options?: BonjourScannerOptions) {
    this._scanner =
      NitroModules.createHybridObject<BonjourZeroconf>('BonjourZeroconf');
    this.id = options?.id;
    if (this.id !== undefined) {
      this._scanner.id = this.id;
    }
  }

  get isScanning(): boolean {
    return this._scanner.isScanning;
  }

  scan(type: string, domain: string, options?: ScanOptions): void {
    this._scanner.scan(type, domain, options);
  }

  scanFor(
    time: number,
    type: string,
    domain: string,
    options?: ScanOptions
  ): Promise<ScanResult[]> {
    return this._scanner.scanFor(time, type, domain, options);
  }

  stop(): void {
    this._scanner.stop();
  }

  listenForScanResults(
    onResult: (results: ScanResult[]) => void
  ): BonjourListener {
    return this._scanner.listenForScanResults(onResult);
  }

  listenForScanState(onChange: (isScanning: boolean) => void): BonjourListener {
    return this._scanner.listenForScanState(onChange);
  }

  listenForScanFail(onFail: (fail: BonjourFail) => void): BonjourListener {
    return this._scanner.listenForScanFail(onFail);
  }
}
