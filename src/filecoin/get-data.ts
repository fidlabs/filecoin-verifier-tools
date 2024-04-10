import { NodejsProvider as Provider } from '@filecoin-shipyard/lotus-client-provider-nodejs'
import { mainnet } from '@filecoin-shipyard/lotus-client-schema'

export function make(endpointUrl) {
  const provider = new Provider(endpointUrl)

  let client

  return {
    load: async function (a) {
      if (client === undefined) {
        const LotusRPC = (await import('@filecoin-shipyard/lotus-client-rpc')).LotusRPC
        client = new LotusRPC(provider, { schema: mainnet.fullNode })
      }

      const res = await client.chainGetNode(a)
      return res.Obj
    },

    getData: async function (path) {
      const head = await client.chainHead()
      const state = head.Blocks[0].ParentStateRoot['/']
      return (await client.chainGetNode(`${state}/${path}`)).Obj
    },
  }
}
