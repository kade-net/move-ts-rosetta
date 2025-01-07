import {STRUCT} from "./types";

export const dictionary = {
    "string::String": "string",
    "u64": "number",
    "u8": "number",
    "address":"string",
    "&signer": "Account",
    "vector": "Array",
    "bool": "boolean"

} as Record<string, string>

export const processVectorType = (incoming: string, existingStructs?: Array<STRUCT>): string => {
    let actualType = incoming.replace("vector<", "").replace(">", '') 
    const tType = chooseType(actualType, existingStructs)

    return `Array<${tType}>`
}

export const chooseType = (incoming: string, existingStructs?: Array<STRUCT>): string => {
    if(incoming.includes("vector")){
        return processVectorType(incoming, existingStructs)
    }
    const existing = existingStructs?.find(s => s.name === incoming.trim())
    const tType = existing ? existing.name : dictionary[incoming] ?? "unknown"

    return tType
}