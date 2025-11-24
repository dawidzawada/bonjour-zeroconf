import { NitroModules } from 'react-native-nitro-modules';
import type { BonjourZeroconf } from './specs/BonjourZeroconf.nitro';
import { useIsScanning } from './useIsScanning';
import { type ScanResult } from './specs/ScanResult';
import { type ScanOptions } from './specs/BonjourZeroconf.nitro';
import { BonjourFail } from './specs/BonjourFail';
import {
  requestLocalNetworkPermission,
  useLocalNetworkPermission,
} from './permissions';

export const Scanner =
  NitroModules.createHybridObject<BonjourZeroconf>('BonjourZeroconf');

export {
  useIsScanning,
  requestLocalNetworkPermission,
  useLocalNetworkPermission,
  BonjourFail,
  type ScanResult,
  type ScanOptions,
};
