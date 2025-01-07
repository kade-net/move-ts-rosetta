import { assert } from 'node:console';
import fs from 'node:fs'
import {CONSTANT, FUNCTION, LEXICON, PARAMETER, STRUCT} from './types';
const MODULE_DEF_REGEX = /module\s+([A-Za-z])+::([A-Za-z])+\s*{(\s|\S)+}/gm;
const MODULE_USE_STATEMENTS = /use (\S)+::(\S)+;/g;
const MACRO_MATCH = /#\[\w+\]/g;

const STRUCT_MATCHER = /struct\s(\w|\s|,)+{\n(\w|:|\s|,|<|>|_)+\n}/gm



/**
 * 
 * @param {string} str 
 */
function reverseString(str: string){
    let newStr = "";

    while (newStr.length < str.length){
        let index = str.length - newStr.length - 1;
        let c = str.at(index)

        newStr += c 
    }

    return newStr
}

/**
 * 
 * @param {string} str 
 */
export function extractConstants(str: string){
    const constants: Array<CONSTANT> = []
    for (const _line of str.split('\n')){
        let line = _line.trim()
        if(line.startsWith('const') && line.endsWith(';')) {
            const name = line.match(/\w+(?=:)/gm)!.at(0)!
            const value = line.match(/=\s*(b?"[^"]*"|\d+)/gm)!.at(0)!?.replace(";", "")?.replace("=", '').trim()
            const type = line.match(/(?!:)\S+\s*(?==)/gm)!.at(0)!

            constants.push({
                name,
                value,
                type
            })
        }
    }

    return constants

}

export function extractStructs(str: string) {
    const structs: Array<STRUCT> = []

    const allStructs = str.match(STRUCT_MATCHER) ?? []

    for (const struct of allStructs) {

        console.log(struct)

        const properties = struct.match(/\w+:\s(\w|:|_|<|>)+(\n|,)/gm) ?? []

        const name = struct.match(/(?![struct])\s\w+\s(?=[has])/gm)?.at(0)!

        const d: STRUCT = {
            name: name.trim(),
            properties: []
        }

        for (const property of properties) { 

            console.log("Property::", property)

            const name = property.match(/\w+(?=:)/gm)!.at(0)!
            const type = property.match(/(?!:)\S+\s*(?=(,|\n))/gm)!.at(0)!

            
            d.properties.push({
                name: name.trim(),
                type: type.trim()
            })
        }

        structs.push(d)
    }

    return structs
}

export function extractFunctions(str: string) {
    const functions: Array<FUNCTION> = []

    const matched_funs = str.match(/(?:(?:public\s+)?(?:view\s+)?(?:entry\s+)?fun\s+)(\w+)\s*\(([^)]*)\)\s*(?:(?:acquires\s+[\w, ]+)?)/gm) ?? []

    for (const fun of matched_funs){

        const name = fun.match(/\w+(?=\()/gm)?.at(0)

        const without_fun_name = fun?.replace(/(?:public\s)?(?:entry\s)?fun\s\w+(?=\()/gm, '')?.replace('(', '')?.replace(')','') ?? ''


        const parameters = without_fun_name?.split(',')
        ?.map(param=> param.trim())
        ?.filter(p=> p.length > 0)
        ?.map((p)=>{
            const p_name = p.match(/\w+(?=:\s)/gm)?.at(0) ?? ''
            const p_type = p.match(/(?!(?:\w+:\s))\s(\S)+/gm)?.at(0) ?? ''

            return {
                name: p_name?.trim(),
                type: p_type?.trim()
            } as PARAMETER
        })?.filter(p => !!p.name && !!p.type)
        

        functions.push({
            name: name?.trim() ?? 'unknown',
            meta: fun,
            parameters
        })

    }

    return functions
}


export function parseModule(moduleFile: string){

    const src = fs.readFileSync(moduleFile, {encoding: 'utf-8'})

    const module = src.match(MODULE_DEF_REGEX)!.at(0)

    assert(module, "No Module found")

    let declaration = module?.match(/(?:module)\s\S+(?=\s{)/gm)!.at(0) ?? ''

    declaration = (declaration?.match(/(?:::)\w+/gm)?.at(0) ?? '')?.replace('::','')?.trim()


    let without_declaraton = module!.match(/(?![module \w::\w\s])(\S|\s)+/gm)!.at(0)!.trim().replace("{", "")

    without_declaraton = reverseString(reverseString(without_declaraton).replace("}", "").trim()).replaceAll("  ","")

    let without_imports = without_declaraton.replaceAll(MODULE_USE_STATEMENTS, "").trim()

    let without_macros = without_imports.replaceAll(MACRO_MATCH, '').trim()

    // console.log(without_macros)

    const constants = extractConstants(without_macros)

    const structs = extractStructs(without_macros)

    const functions = extractFunctions(without_macros)

    const lexicon = {
        module: declaration,
        constants,
        structs,
        functions
    }

    return lexicon as LEXICON

}