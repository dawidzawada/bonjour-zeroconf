import { Scanner } from '@dawidzawada/bonjour-zeroconf';
import { StyleSheet, View } from 'react-native';
import { ScannerPanel } from './components/ScannerPanel';

export const SingletonScanner = () => {
  return (
    <View style={styles.container}>
      <ScannerPanel
        scanner={Scanner}
        serviceType="_printer._tcp"
        color="#8e44ad"
        title="Singleton Scanner"
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    width: '100%',
  },
});
