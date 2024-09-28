import React, { useEffect } from 'react';
import './App.css';
import {
  makeAgoricChainStorageWatcher,
  AgoricChainStoragePathKind as Kind,
} from '@agoric/rpc';
import { create } from 'zustand';
import {
  makeAgoricWalletConnection,
  suggestChain,
} from '@agoric/web-components';

type Wallet = Awaited<ReturnType<typeof makeAgoricWalletConnection>>;

const ENDPOINTS = {
  RPC: 'http://localhost:26657',
  API: 'http://localhost:1317',
};

const watcher = makeAgoricChainStorageWatcher(ENDPOINTS.API, 'agoriclocal');

interface AppState {
  wallet?: Wallet;
  contractInstance?: unknown;
}

const useAppStore = create<AppState>(() => ({}));

const setup = async () => {
  watcher.watchLatest<Array<[string, unknown]>>(
    [Kind.Data, 'published.agoricNames.instance'],
    (instances) => {
      console.log('got instances', instances);
      useAppStore.setState({
        contractInstance: instances.find(([name]) => name === 'counter')?.[1],
      });
    }
  );
};

const connectWallet = async () => {
  await suggestChain('https://local.agoric.net/network-config');
  const wallet = await makeAgoricWalletConnection(watcher, ENDPOINTS.RPC);
  useAppStore.setState({ wallet });
};

const makeOffer = () => {
  const { wallet, contractInstance } = useAppStore.getState();
  if (!contractInstance) throw Error('No contract instance');

  wallet?.makeOffer(
    {
      source: 'contract',
      instance: contractInstance,
      publicInvitationMaker: 'makeInvitation',
    },
    {},
    {
      userAddress: wallet.address,
    },
    (update: { status: string; data?: unknown }) => {
      if (update.status === 'error') {
        alert(`Offer error: ${update.data}`);
      } else if (update.status === 'accepted') {
        alert('Offer accepted');
      } else if (update.status === 'refunded') {
        alert('Offer rejected');
      }
    }
  );
};

function App() {
  useEffect(() => {
    setup();
  }, []);

  const { wallet } = useAppStore(({ wallet }) => ({
    wallet,
  }));

  const tryConnectWallet = () => {
    connectWallet().catch((err) => {
      switch (err.message) {
        case 'KEPLR_CONNECTION_ERROR_NO_SMART_WALLET':
          alert('No smart wallet at that address');
          break;
        default:
          alert(err.message);
      }
    });
  };

  return (
    <>
      <div className='card'>
        <button onClick={makeOffer}>Increment Counter</button>
        {!wallet && <button onClick={tryConnectWallet}>Connect Wallet</button>}
      </div>
    </>
  );
}

export default App;
