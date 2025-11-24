import {
  StyleSheet,
  Button,
  Text,
  Alert,
  SafeAreaView,
  View,
  FlatList,
} from 'react-native';
import {
  Scanner,
  useIsScanning,
  requestLocalNetworkPermission,
  type ScanResult,
} from '@dawidzawada/bonjour-zeroconf';
import { useEffect, useState } from 'react';

export default function App() {
  const [results, setResults] = useState<ScanResult[]>([]);
  const isScanning = useIsScanning();

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
    const { remove } = Scanner.listenForScanResults((scan) => {
      setResults(scan);
    });
    return () => {
      remove();
    };
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.buttonsContainer}>
        <Button title={'Scan'} onPress={handleScan} />
        <Button title={'Log is Scanning'} onPress={handleCheck} />
        <Button title={'Stop'} onPress={handleStop} />
      </View>

      <View style={styles.status}>
        <Text style={styles.statusTxt}>
          {`Status: ${isScanning ? 'Scanning' : 'Not Scanning'}`}
        </Text>
      </View>
      <FlatList
        data={results}
        style={styles.list}
        ItemSeparatorComponent={() => <View style={styles.separator} />}
        renderItem={({ item }) => {
          return (
            <View key={item.name} style={styles.item}>
              <View style={styles.row}>
                <Text style={styles.label}>{`Name:`}</Text>
                <Text style={styles.value}>{item.name}</Text>
              </View>
              <View style={styles.row}>
                <Text style={styles.label}>{`IP:`}</Text>
                <Text style={styles.value}>{item.ipv4 ?? item.ipv6}</Text>
              </View>
              <View style={styles.row}>
                <Text style={styles.label}>{`Hostname:`}</Text>
                <Text style={styles.value}>{item.hostname}</Text>
              </View>
            </View>
          );
        }}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'flex-start',
    paddingTop: 100,
  },
  buttonsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    width: '100%',
    justifyContent: 'space-evenly',
  },
  statusTxt: { fontWeight: 'bold' },
  list: { width: '100%' },
  separator: {
    backgroundColor: '#878787',
    width: '100%',
    height: StyleSheet.hairlineWidth,
  },
  status: {
    backgroundColor: '#e7e9e9',
    width: '100%',
    padding: 10,
    marginVertical: 10,
    justifyContent: 'center',
    alignItems: 'center',
  },
  item: { backgroundColor: '#e7e9e9', width: '100%', padding: 20 },
  row: { flexDirection: 'row', gap: 20, width: '100%' },
  label: {
    fontWeight: 'bold',
    flexGrow: 1,
  },
  value: {
    fontFamily: 'monospace',
  },
});
