import assert from 'node:assert'
import fs from 'node:fs'
import { CONSTANT, FUNCTION, LEXICON, STRUCT } from './types'
import { chooseType } from './dictionary'
// process a lexicon

export function transformStruct(struct: STRUCT,  existingStructs?: STRUCT[], basePath?: string){
    let line = `// ${struct.name}\n`
    line = line + `export interface ${struct.name} {\n`
    for(const property of struct.properties){
        const existingStruct = existingStructs?.find(s => s.name.trim() == property.type.trim())
        const typescriptEquivalent = existingStruct ? existingStruct : chooseType(property.type, existingStructs)
        line = line + `\t${property.name}: ${typescriptEquivalent}\n`   
    }
    line = line + '}\n\n'

    if(basePath){
    line += `
export const ${struct.name}_RESOURCE_TYPE = "${basePath}${struct.name}";

export const get${struct.name} = (locationAddress: string) => queryFn<${struct.name}>(locationAddress, ${struct.name}_RESOURCE_TYPE);
    `

    }
    return line
} 

export function transformFunction(fun: FUNCTION, basePath: string, existingStructs: STRUCT[]) {

    const FUNC_PATH = `${basePath}${fun.name}`
    let line = `// ${fun.name}\n`
    line = line + `import { Account, SimpleTransaction } from "@aptos-labs/ts-sdk"`
    line = line + `\nimport { buildTransaction, submitTransaction, composeAndSubmitTransaction } from "../utils"\n`

    const argStruct: STRUCT = {
        name: `${fun.name}_args`,
        properties: fun.parameters?.filter(({type})=> !type.includes('&signer'))
    }

    const structsToImport = fun.parameters.map(p=>existingStructs.find(struct => struct.name.trim() == p.type.trim())).filter(v => !!v)?.map(s => s.name)

    if(structsToImport.length > 0) {
        line += `import { ${structsToImport.join(', ')} } from "../STRUCTS"`
    }

    const argDefLine = transformStruct(argStruct, existingStructs)

    line = line + argDefLine

    line = line + `
export function build(sender: string, args: ${fun.name}_args) {
    return buildTransaction("${FUNC_PATH}", args, sender)
} 
    `

    line = line + `
export function submit(signer: Account, transaction: SimpleTransaction) {
    return submitTransaction(signer, transaction)
}
    `

    line = line + `
export function composeAndSubmit(signer: Account, args: ${fun.name}_args) {
    return composeAndSubmitTransaction(signer, "${FUNC_PATH}", args)
}
    `

    line += `
export const PATH = "${FUNC_PATH}";
    `

    return line

}

export function transformConstant(constant: CONSTANT) {
    let line = `// ${constant.name}\n`

    line = line + `export const ${constant.name} = ${constant.value?.replace(`b"`, `"`)} as const;`

    return line
}

function processLexicon(file: string){

    let new_file_contents = "// 🤖 this file was automatically generated, don't modify"
    const lexicon_str = fs.readFileSync(file, {encoding: 'utf-8'})


    assert(lexicon_str, "No Lexicon found")

    const lexicon = JSON.parse(lexicon_str) as LEXICON

    for (const constant of lexicon.constants) {
        let line = `export const ${constant.name} = ${constant.value?.replace('b', '')} as const;`
        new_file_contents = new_file_contents + line + "\n"
    }


    for (const struct of lexicon.structs) {
        const struct_def = transformStruct(struct)

        new_file_contents = new_file_contents + struct_def + "\n"
    }

    
}