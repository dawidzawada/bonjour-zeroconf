import { NitroModules } from 'react-native-nitro-modules';
import type { BonjourZeroconf } from './BonjourZeroconf.nitro';

const BonjourZeroconfHybridObject =
  NitroModules.createHybridObject<BonjourZeroconf>('BonjourZeroconf');

export function multiply(a: number, b: number): number {
  return BonjourZeroconfHybridObject.multiply(a, b);
}
