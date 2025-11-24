export const requestLocalNetworkPermission = async () => {
  return true;
};

export const useLocalNetworkPermission = () => {
  return [true, requestLocalNetworkPermission];
};
