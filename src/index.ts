import { useIsScanning } from './useIsScanning';
import { type ScanResult } from './specs/ScanResult';
import { type ScanOptions } from './specs/BonjourZeroconf.nitro';
import { BonjourFail } from './specs/BonjourFail';
import {
  requestLocalNetworkPermission,
  useLocalNetworkPermission,
} from './permissions';
import { BonjourScanner, type BonjourScannerOptions } from './BonjourScanner';

export const Scanner = new BonjourScanner();

export {
  BonjourScanner,
  useIsScanning,
  requestLocalNetworkPermission,
  useLocalNetworkPermission,
  BonjourFail,
  type BonjourScannerOptions,
  type ScanResult,
  type ScanOptions,
};
