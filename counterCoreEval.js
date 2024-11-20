import { makeHelpers } from '@agoric/deploy-script-support';
import { getManifestForCounter } from './counterProposal.js';

export const defaultProposalBuilder = async ({ publishRef, install }, opts) => {
  return harden({
    sourceSpec: './counterProposal.js',
    getManifestCall: [
      getManifestForCounter.name,
      {
        economicCommitteeRef: publishRef(install('./counterContract.js')),
      },
    ],
  });
};

export default async (homeP, endowments) => {
  const { writeCoreEval } = await makeHelpers(homeP, endowments);

  await writeCoreEval(`counter-contract`, (utils) =>
    defaultProposalBuilder(utils, {})
  );
};
