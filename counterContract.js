import { Far, E } from '@endo/far';
import { EmptyProposalShape } from '@agoric/zoe/src/typeGuards';

let counter = 0;

export const start = async (zcf, privateArgs) => {
  const { node } = privateArgs;

  console.log('Starting Counter Contract');
  console.log('Counter:', counter);

  const incrementCounter = async () => {
    counter += 1;
    await E(node).setValue(String(counter));
    console.log('Counter Value:', counter);
  };

  const makeInvitation = () =>
    zcf.makeInvitation(
      (seat) => {
        seat.exit();
        incrementCounter();
      },
      'increment counter',
      undefined,
      EmptyProposalShape
    );

  const publicFacet = Far('Public Facet', {
    makeInvitation,
    getCounter: () => counter,
  });

  return harden({ publicFacet });
};
harden(start);
