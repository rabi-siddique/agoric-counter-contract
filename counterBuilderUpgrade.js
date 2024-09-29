import { makeHelpers } from '@agoric/deploy-script-support';
import { getManifestForCounter } from './counterUpgrade.js';

export const counterProposalBuilder = async ({ publishRef, install }) => {
  return harden({
    sourceSpec: './counterUpgrade.js',
    getManifestCall: [
      getManifestForCounter.name,
      {
        counterRef: publishRef(
          install('./counterContract.js', './bundles/bundle-counter.js')
        ),
      },
    ],
  });
};

export default async (homeP, endowments) => {
  const { writeCoreEval } = await makeHelpers(homeP, endowments);
  await writeCoreEval('bundles/start-counter', counterProposalBuilder);
};
