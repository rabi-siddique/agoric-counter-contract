import { Far } from '@endo/far';

let counter = 0;
export const start = async (_zcf) => {
  console.log('Starting Counter Contract');

  const increment = () => {
    counter += 1;
  };

  const creatorFacet = Far('Creator Facet', {
    increment,
  });

  return harden({ creatorFacet });
};
harden(start);
