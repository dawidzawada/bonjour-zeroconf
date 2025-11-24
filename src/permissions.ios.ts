import { NitroModules } from 'react-native-nitro-modules';
import type { LocalNetworkPermission } from './specs/LocalNetworkPermission.nitro';
import { useEffect, useState } from 'react';

const LocalNetworkPermission =
  NitroModules.createHybridObject<LocalNetworkPermission>(
    'LocalNetworkPermission'
  );

export const requestLocalNetworkPermission = async () => {
  return await LocalNetworkPermission.requestPermission();
};

export const useLocalNetworkPermission = () => {
  const [permissionGranted, setPermissionGranted] = useState(false);

  useEffect(() => {
    const { remove } = LocalNetworkPermission.listenForPermission((granted) => {
      setPermissionGranted(granted);
    });
    return () => {
      remove();
    };
  }, []);

  return [permissionGranted, requestLocalNetworkPermission];
};
