import { E } from '@endo/far';

export const upgradeCounterContract = async (
  { consume: { counter, chainStorage } },
  options
) => {
  const { counterRef } = options.options;

  const boardAux = await E(chainStorage).makeChildNode('counterData');
  const node = await E(boardAux).makeChildNode('counter');
  await E(node).setValue(String(0));

  const privateArgs = {
    node,
  };

  const { adminFacet } = await counter;

  await E(adminFacet).upgradeContract(counterRef.bundleID, privateArgs);

  console.log(`Successfully upgraded Counter`);
};

export const getManifestForCounter = (_powers, { counterRef }) => ({
  manifest: {
    [upgradeCounterContract.name]: {
      consume: {
        chainStorage: true,
        counter: true,
      },
    },
  },
  options: { counterRef },
});
