#!/usr/bin/env node
import { program } from 'commander'
import { run } from './index'
import * as process from "node:process";

program.name('move-ts-rosetta').version('1.0.0').description('A tool for quickly transpiling a MOVE smart contract to it\'s respective ts definition')

program
    .command('run')
    .description('Transpile a MOVE package from the source folder to a ts lib in the dest folder')
    .option('-t, --target <TargetFolder>', 'Target Folder')
    .option('-s, --source <SourceFolder>', 'Source folder')
    .option('-a, --address <ContractAddress>', 'Contract address')
    .action((options)=>{
        run(
            options.target,
            options.source,
            options.address,
        )
    })

program.parse(process.argv)