// @ts-check
import { E } from '@endo/far';

export const startCounterContract = async (permittedPowers) => {
  const {
    consume: { startUpgradable, chainStorage },
    installation: {
      consume: { counter: counterInstallationP },
    },
    instance: {
      produce: { counter: produceInstance },
    },
  } = permittedPowers;

  const installation = await counterInstallationP;

  const boardAux = await E(chainStorage).makeChildNode('counterData');
  const node = await E(boardAux).makeChildNode('counter');
  await E(node).setValue(String(0));

  const { instance } = await E(startUpgradable)({
    installation,
    label: 'counter',
    privateArgs: harden({ node }),
  });

  produceInstance.reset();
  produceInstance.resolve(instance);
};

const counterManifest = {
  [startCounterContract.name]: {
    consume: {
      startUpgradable: true,
      chainStorage: true,
    },
    installation: { consume: { counter: true } },
    instance: { produce: { counter: true } },
  },
};
harden(counterManifest);

export const getManifestForCounter = ({ restoreRef }, { counterRef }) => {
  return harden({
    manifest: counterManifest,
    installations: {
      counter: restoreRef(counterRef),
    },
  });
};
