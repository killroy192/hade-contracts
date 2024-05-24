# Sol-starter

Template to bootstrap solidity project

## Features

- [Foundry]((https://book.getfoundry.sh/)) for unit testing
- [Hardhat](https://hardhat.org/docs) for JS integration tests & deployment
- [hardhat-sol-bundler](https://github.com/dgma/hardhat-sol-bundler) for declarative deployments and upgrades
- linters, code formatter, pre-commit and pre-push hooks
- Makefile & Docker dev container for convenient and safe development
- Custom github action and quality gate workflow for flexible CI strategy implementation

## Requirements

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you've done it right if you can run `git --version`
- [Foundry / Foundryup](https://github.com/gakonst/foundry)
  - This will install `forge`, `cast`, and `anvil`
  - You can test you've installed them right by running `forge --version` and get an output like: `forge 0.2.0 (f016135 2022-07-04T00:15:02.930499Z)`
  - To get the latest of each, just run `foundryup`
- [Node.js](https://nodejs.org/en)
- Optional. [Docker](https://www.docker.com/)
  - You'll need to run docker if you want to use dev container and safely play with smartcontracts & scripts

_note:_ For windows os you'll need to install `make`. For instance via choco: `sh choco install make`

## Installation

```sh
make
```

## Configuration

- All commands/aliases are declared in the Makefile.
- use forge as solidity formatter in your IDE settings
  - For VS it's recommended to use [Juan Blanco Plugin](https://github.com/juanfranblanco/vscode-solidity) and have the next sittings.json

```json
{
  "solidity.formatter": "forge",
  "solidity.packageDefaultDependenciesContractsDirectory": "src",
  "solidity.packageDefaultDependenciesDirectory": ["node_modules", "lib"],
  "solidity.remappings": [
    "@std=lib/forge-std/src/",
    "forge-std/=lib/forge-std/src/",
    "@openzeppelin/=node_modules/@openzeppelin/",
    "src=src/"
  ],
  "solidity.defaultCompiler": "localNodeModule",
  "[solidity]": {
    "editor.defaultFormatter": "JuanBlanco.solidity"
  }
}
```

## Contributing

Contributions are always welcome! Open a PR or an issue!

## Resources

- [Foundry Documentation](https://book.getfoundry.sh/)
- [Hardhat Documentation](https://hardhat.org/docs)
- [hardhat-sol-bundler Documentation](https://github.com/dgma/hardhat-sol-bundler)
- [Makefile simple guide](https://opensource.com/article/18/8/what-how-makefile)
