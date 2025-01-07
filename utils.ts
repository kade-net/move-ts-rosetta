import { Aptos, AptosConfig, Account, Network, AccountAddress, SimpleTransaction } from '@aptos-labs/ts-sdk'

const env = process.env.NEXT_PUBLIC_APTOS_NETWORK ?? process.env.APTOS_NETWORK ?? 'testnet'
const aptos = new Aptos(new AptosConfig({
    network: env == 'mainnet' ? 
    Network.MAINNET : env == 'testnet' ? 
    Network.TESTNET : env == 'devnet' ? 
    Network.DEVNET : env == 'local' ? 
    Network.LOCAL : env == 'custom' ? 
    Network.CUSTOM : Network.TESTNET
}))

export async function buildTransaction(funcName: string, args: Record<string, any>, sender: string){
    const transformedArgs = Object.entries(args).map(p=>p.at(1))

    const transaction = await aptos.transaction.build.simple({
        sender: sender,
        data: {
            function: funcName as any,
            functionArguments: transformedArgs,
        }
    })

    return transaction
}

export async function submitTransaction(signer: Account, transaction: SimpleTransaction) {
    const commitedTxn = await aptos.transaction.signAndSubmitTransaction({
        transaction,
        signer
    })

    return commitedTxn
}

export async function composeAndSubmitTransaction(signer: Account, funcName: string, args: Record<string, any>) {
    const transaction = await buildTransaction(funcName, args, signer.accountAddress.toString())
    const commitedTxn = await submitTransaction(signer, transaction)

    return commitedTxn
}

export async function queryFn<T extends {}>(locationAddress: string, path: string) {
    return aptos.getAccountResource<T>({
        accountAddress: locationAddress,
        resourceType: path as any
    })
}