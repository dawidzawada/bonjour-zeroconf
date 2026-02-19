import {
  BonjourScanner,
  requestLocalNetworkPermission,
  type ScanResult,
} from '@dawidzawada/bonjour-zeroconf';
import { useEffect, useState } from 'react';
import { Alert, Button, FlatList, StyleSheet, Text, View } from 'react-native';

export interface ScannerPanelProps {
  scanner: BonjourScanner;
  serviceType: string;
  color: string;
  title: string;
}

export const ScannerPanel = ({
  scanner,
  serviceType,
  color,
  title,
}: ScannerPanelProps) => {
  const [results, setResults] = useState<ScanResult[]>([]);
  const [isScanning, setIsScanning] = useState(false);

  useEffect(() => {
    const { remove: removeResults } = scanner.listenForScanResults(setResults);
    const { remove: removeState } = scanner.listenForScanState(setIsScanning);
    return () => {
      removeResults();
      removeState();
    };
  }, [scanner]);

  const handleScan = async () => {
    const granted = await requestLocalNetworkPermission();
    if (granted) {
      scanner.scan(serviceType, 'local');
    }
  };

  return (
    <View style={[styles.panel, { borderColor: color }]}>
      <View style={[styles.panelHeader, { backgroundColor: color }]}>
        <Text style={styles.panelTitle}>{title}</Text>
        <Text style={styles.panelType}>{serviceType}</Text>
      </View>

      <View style={styles.buttonsRow}>
        <Button title="Scan" onPress={handleScan} disabled={isScanning} />
        <Button
          title="Stop"
          onPress={() => scanner.stop()}
          disabled={!isScanning}
        />
        <Button
          title="Check"
          onPress={() =>
            Alert.alert(title, `Is scanning: ${scanner.isScanning}`)
          }
        />
      </View>

      <View style={[styles.status, { backgroundColor: color + '33' }]}>
        <Text style={styles.statusTxt}>
          {isScanning ? '🔍 Scanning...' : '⏹ Stopped'}
        </Text>
        <Text style={styles.countTxt}>{results.length} found</Text>
      </View>

      <FlatList
        data={results}
        style={styles.list}
        keyExtractor={(item) => item.name}
        ItemSeparatorComponent={() => <View style={styles.separator} />}
        renderItem={({ item }) => (
          <View style={styles.item}>
            <Text style={styles.itemName}>{item.name}</Text>
            <Text style={styles.itemDetail}>
              {`IP: ${item.ipv4 ?? item.ipv6 ?? '-'}, Port: ${item.port ?? '-'}, Hostname: ${item.hostname ?? '-'}`}
            </Text>
          </View>
        )}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  panel: {
    flex: 1,
    width: '100%',
    borderWidth: 2,
    borderRadius: 8,
    overflow: 'hidden',
  },
  panelHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 8,
  },
  panelTitle: {
    color: 'white',
    fontWeight: 'bold',
  },
  panelType: {
    color: 'white',
    fontFamily: 'monospace',
    fontSize: 12,
  },
  buttonsRow: {
    flexDirection: 'row',
    justifyContent: 'space-evenly',
    paddingVertical: 6,
  },
  status: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  statusTxt: { fontWeight: 'bold', fontSize: 12 },
  countTxt: { fontSize: 12, color: '#555' },
  list: { flex: 1 },
  separator: {
    backgroundColor: '#ddd',
    height: StyleSheet.hairlineWidth,
  },
  item: { padding: 10 },
  itemName: { fontWeight: 'bold', fontSize: 13 },
  itemDetail: { fontFamily: 'monospace', fontSize: 12, color: '#555' },
});
