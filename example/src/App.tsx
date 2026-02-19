import { StyleSheet, Button, SafeAreaView } from 'react-native';
import { useState } from 'react';
import { SingletonScanner } from './SingletonScanner';
import { MultiScanner } from './MultiScanner';

export default function App() {
  const [view, setView] = useState<'singleton' | 'multi'>();

  return (
    <SafeAreaView style={styles.container}>
      {!view && (
        <>
          <Button
            title="Show Singleton Scanner"
            onPress={() => setView('singleton')}
          />
          <Button title="Show Multi Scanner" onPress={() => setView('multi')} />
        </>
      )}
      {view === 'singleton' && <SingletonScanner />}
      {view === 'multi' && <MultiScanner />}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    marginHorizontal: 4,
    paddingTop: 50,
    gap: 30,
  },
});
