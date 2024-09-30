// @ts-check
import { E } from '@endo/far';

export const startCounterContract = async (permittedPowers) => {
  const {
    consume: { zoe, chainStorage },
    installation: {
      consume: { counter: counterInstallationP },
    },
    instance: {
      produce: { counter: produceInstance, counterStartResult },
    },
  } = permittedPowers;

  const installation = await counterInstallationP;

  const boardAux = await E(chainStorage).makeChildNode('counterData');
  const node = await E(boardAux).makeChildNode('counter');
  await E(node).setValue(String(0));

  const startResult = await E(zoe).startInstance(
    installation,
    undefined,
    undefined,
    harden({ node })
  );

  counterStartResult.resolve(startResult);

  produceInstance.reset();
  produceInstance.resolve(startResult.instance);
};

const counterManifest = {
  [startCounterContract.name]: {
    consume: {
      zoe: true,
      chainStorage: true,
    },
    installation: { consume: { counter: true } },
    instance: { produce: { counter: true, counterStartResult: true } },
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
