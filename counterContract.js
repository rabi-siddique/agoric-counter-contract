import { Far } from '@endo/far';
import { EmptyProposalShape } from '@agoric/zoe/src/typeGuards';

let counter = 0;

export const start = async (zcf) => {
  console.log('Starting Counter Contract');
  console.log('Counter:', counter);

  const incrementCounter = () => {
    counter += 1;
    console.log('Counter:', counter);
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
  });

  return harden({ publicFacet });
};
harden(start);
