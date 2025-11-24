# @dawidzawada/bonjour-zeroconf

Zeroconf devices scanner using Bonjour (iOS) and NSD (Android) for React Native & Expo apps. Powered by Nitro Modules.

## Installation

```sh
npm install @dawidzawada/bonjour-zeroconf react-native-nitro-modules

> `react-native-nitro-modules` is required as this library relies on [Nitro Modules](https://nitro.margelo.com/).
```

## Usage

```js
import { Scanner } from '@dawidzawada/bonjour-zeroconf';

// ...

Scanner.scan('_bonjour._tcp', 'local');
```

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
