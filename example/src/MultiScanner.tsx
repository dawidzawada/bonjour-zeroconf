import { BonjourScanner } from '@dawidzawada/bonjour-zeroconf';
import { StyleSheet, View } from 'react-native';
import { ScannerPanel } from './components/ScannerPanel';

const printerScanner = new BonjourScanner({ id: 'printer-scanner' });
const httpScanner = new BonjourScanner({ id: 'http-scanner' });

export const MultiScanner = () => {
  return (
    <View style={styles.container}>
      <ScannerPanel
        scanner={printerScanner}
        serviceType="_printer._tcp"
        color="#e74c3c"
        title="Printer"
      />
      <View style={styles.divider} />
      <ScannerPanel
        scanner={httpScanner}
        serviceType="_http._tcp"
        color="#2980b9"
        title="Pstryk"
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    width: '100%',
  },
  divider: { height: 8 },
});
