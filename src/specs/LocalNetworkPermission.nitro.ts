import type { HybridObject } from 'react-native-nitro-modules';
import type { BonjourListener } from './BonjourListener';

export interface LocalNetworkPermission extends HybridObject<{ ios: 'swift' }> {
  requestPermission(): Promise<boolean>;
  listenForPermission(onChange: (granted: boolean) => void): BonjourListener;
}
