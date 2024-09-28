import { makeHelpers } from '@agoric/deploy-script-support';
import { getManifestForCounter } from './counterProposal.js';

export const counterProposalBuilder = async ({ publishRef, install }) => {
  return harden({
    sourceSpec: './counterProposal.js',
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
  const { writeCoreProposal } = await makeHelpers(homeP, endowments);
  await writeCoreProposal('core-bundles/start-counter', counterProposalBuilder);
};
