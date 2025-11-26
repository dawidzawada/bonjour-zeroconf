# Bonjour Zeroconf 🇫🇷🥖

⚡ **High-performance Zeroconf/mDNS service discovery for React Native**

Discover devices and services on your local network using native Bonjour (iOS) and NSD (Android) APIs. Built with [Nitro Modules](https://nitro.margelo.com/) for maximum performance. Designed for both React Native and Expo. 🧑‍🚀

## ✨ Features

- 🏎️ **Racecar performance** – powered by Nitro Modules
- 🛡️ **Type-safe** – thanks to Nitro & Nitrogen
- 📡 **Cross-platform** – iOS (Bonjour) and Android (NSD)
- 📱 **Managing iOS permissions** - no need for extra libraries or custom code, just use `requestLocalNetworkPermission` or `useLocalNetworkPermission` before scanning!
- 🔄 **Real-time updates** – listen to scan results, state changes, and errors
- 🧩 **Expo compatible** - (config plugin coming soon)

## 📦 Installation

```sh
npm install @dawidzawada/bonjour-zeroconf react-native-nitro-modules
```

> **Note:** `react-native-nitro-modules` is required as a peer dependency.

## ⚙️ iOS Setup

On iOS we need to ask for permissions and configure services we want to scan.

### Expo:

Add this to your `app.json`, `app.config.json` or `app.config.js`:

```ts
{
  ios: {
    infoPlist: {
      NSLocalNetworkUsageDescription:
        'This app needs local network access to discover devices',
      NSBonjourServices: ['_bonjour._tcp', '_lnp._tcp.'],
    },
  },
}
// Add service types you want to scan to NSBonjourServices, first two service types are needed for permissions
```

Run prebuild command:

```sh
npx expo prebuild
```

### React Native:

Add this to your `Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs local network access to discover devices</string>
<key>NSBonjourServices</key>
<array>
    <!-- Needed for permissions -->
    <string>_bonjour._tcp</string>
    <string>_lnp._tcp</string>
    <!-- Add other service types you need here -->
</array>
```

## 🚀 Quick Start

```tsx
import {
  Scanner,
  useIsScanning,
  type ScanResult,
} from '@dawidzawada/bonjour-zeroconf';
import { useEffect, useState } from 'react';

function App() {
  const [devices, setDevices] = useState<ScanResult[]>([]);

  const handleScan = async () => {
    const granted = await requestLocalNetworkPermission();
    if (granted) {
      Scanner.scan('_bonjour._tcp', 'local');
    }
  };

  const handleStop = async () => {
    Scanner.stop();
  };

  const handleCheck = async () => {
    Alert.alert(`Is scanning? ${Scanner.isScanning}`);
  };

  useEffect(() => {
    // Listen for discovered devices
    const { remove } = Scanner.listenForScanResults((scan) => {
      setResults(scan);
    });

    return () => {
      remove();
    };
  }, []);

  return (
    <View>
      <Button title={'Scan'} onPress={handleScan} />
      <Button title={'Stop'} onPress={handleStop} />
      {devices.map((device) => (
        <Text key={device.name}>
          {device.name} - {device.ipv4}:{device.port}
        </Text>
      ))}
    </View>
  );
}
```

---

## 📖 API Reference

### **Scanner**

#### `scan(type: string, domain: string, options?: ScanOptions)`

Start scanning for services.

```ts
Scanner.scan('_http._tcp', 'local');
```

```ts
Scanner.scan('_printer._tcp', 'local', {
  addressResolveTimeout: 10000, // ms
});
```

**Common service types:**

- `_http._tcp` – HTTP servers
- `_ssh._tcp` – SSH servers
- `_airplay._tcp` – AirPlay devices
- `_printer._tcp` – Network printers

#### `stop()`

Stop scanning and clear cached results.

```ts
Scanner.stop();
```

#### `listenForScanResults(callback)`

Listen for discovered services.

```ts
const listener = Scanner.listenForScanResults((results: ScanResult[]) => {
  console.log('Found devices:', results);
});

// Clean up listener
listener.remove();
```

#### `listenForScanState(callback)`

Listen for scanning state changes.

```ts
const listener = Scanner.listenForScanState((isScanning: boolean) => {
  console.log('Scanning:', isScanning);
});

// Clean up listener
listener.remove();
```

#### `listenForScanFail(callback)`

Listen for scan failures.

```ts
const listener = Scanner.listenForScanFail((error: BonjourFail) => {
  console.log('Scan failed:', error);
});

// Clean up listener
listener.remove();
```

---

### **Hooks**

#### `useIsScanning()`

React hook that returns the current scanning state.

```tsx
const isScanning = useIsScanning();
```

#### `useLocalNetworkPermission()` (iOS only)

React hook for managing local network permission.

```tsx
const { status, request } = useLocalNetworkPermission();
```

---

### **Functions**

#### `requestLocalNetworkPermission()`

Displays prompt to request local network permission, always returns `true` on Android.

```tsx
const granted = await requestLocalNetworkPermission();
```

---

### **Types**

```ts
interface ScanResult {
  name: string;
  ipv4?: string;
  ipv6?: string;
  hostname?: string;
  port?: number;
}

interface ScanOptions {
  addressResolveTimeout?: number; // milliseconds, default: 10000
}

enum BonjourFail {
  DISCOVERY_FAILED = 'DISCOVERY_FAILED',
  RESOLVE_FAILED = 'RESOLVE_FAILED',
}
```

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## Credits

- [Nitro Modules](https://nitro.margelo.com/) - High-performance native module framework
- [mrousavy](https://github.com/mrousavy) - Creator of Nitro Modules
- [react-native-builder-bob](https://github.com/callstack/react-native-builder-bob) - Library template

Solution for handling permissions is based on [react-native-local-network-permission](https://github.com/neurio/react-native-local-network-permission)

## License

MIT

---

**Made with ❤️ for the React Native community**
