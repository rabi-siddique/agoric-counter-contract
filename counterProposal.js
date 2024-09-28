// @ts-check
import { E } from '@endo/far';

export const startCounterContract = async (permittedPowers) => {
  const {
    consume: { startUpgradable },
    installation: {
      consume: { counter: counterInstallationP },
    },
    instance: {
      produce: { counter: produceInstance },
    },
  } = permittedPowers;

  const installation = await counterInstallationP;

  const { instance } = await E(startUpgradable)({
    installation,
    label: 'counter',
  });

  produceInstance.reset();
  produceInstance.resolve(instance);
};

const counterManifest = {
  [startCounterContract.name]: {
    consume: {
      startUpgradable: true,
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
