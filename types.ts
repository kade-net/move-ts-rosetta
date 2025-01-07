

export type CONSTANT = {
    name: string
    value: string
    type: string
}

export type Properties = {
    name: string
    type: string
}

export type STRUCT = {
    name: string
    properties: Array<Properties>
}

export type PARAMETER = {
    name: string 
    type: string
}

export type FUNCTION = {
    name: string,
    meta: string,
    parameters: Array<PARAMETER>
}


export type LEXICON = { 
    module: string,
    constants: Array<CONSTANT>
    structs: Array<STRUCT>
    functions: Array<FUNCTION>
}