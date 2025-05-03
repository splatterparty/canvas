# Splatterparty Canvas

Canvas uses the [Gemforge](https://gemforge.xyz) framework to deploy a diamond proxy contract with multiple facets.

The Canvas diamond was deployed on the Lamina1 mainnet at 0x7A7485C4876BfA5C533a52Cfabeff758baC59dc0
by the Splatterparty deployer (0x8880b4De2d17d400f6dd25Ea2DFdb5B6d0c3A888) 

## Requirements

* [Node.js 20+](https://nodejs.org)
* [PNPM](https://pnpm.io/) _(NOTE: `yarn` and `npm` can also be used)_
* [Foundry](https://github.com/foundry-rs/foundry/blob/master/README.md)

## Installation

Change into the folder and run in order:

```
$ foundryup
$ forge install foundry-rs/forge-std
$ pnpm i
$ git submodule update --init --recursive
```

Create `.env` and set the following within:

```
LAMINA1_PRIVATE_KEY=<your deployers private key>
SALT=<32 byte salt for create3>
```

## Usage

Run a local dev node in a separate terminal with anvil

Run gemforge build

Run gemforge deploy

## License

MIT - see [LICENSE.md](LICENSE.md)
