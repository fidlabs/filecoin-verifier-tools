#!/usr/bin/env bash

__PWD=$PWD
__DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
__PARENT_DIR=$(dirname $__DIR)

LOTUS_BIN="lotus"
LOTUS_SEED="lotus-seed"
LOTUS_MINER="lotus-miner"

##### Functions

configure_lotus() {

  echo -e "\nDownloading the 2048 byte parameters:\n"
  $LOTUS_BIN fetch-params 2048

  echo -e "\nPre-seal some sectors:\n"
  $LOTUS_SEED pre-seal --sector-size 2KiB --num-sectors 2

  export ROOT=t101

  echo -e "\nCreate the genesis block and start up the first node:\n"
  $LOTUS_SEED genesis new localnet.json
  $LOTUS_SEED genesis add-miner localnet.json ~/.genesis-sectors/pre-seal-t01000.json
  jq '. + {VerifregRootKey: {Type: "multisig", Balance: "50000000000000000000000000", Meta: { Signers: ["t1vzw5hg23fn7ob4gfpzmzej7h76h6gjr3572elvi", "t1pnzozdkjnmtmnh6i3ufl7ianvwl2lq7tybazudy"], Threshold: 2 }}}' localnet.json > localnet2.json

  cp localnet2.json localnet.json
  tmux new-session -s lotus -n script -d bash balances.sh

  sleep 5
#  $LOTUS_BIN daemon --lotus-make-genesis=dev.gen --genesis-template=localnet.json --bootstrap=false &
  tmux new-window -t lotus:1 -n daemon -d $LOTUS_BIN daemon --lotus-make-genesis=dev.gen --genesis-template=localnet.json --bootstrap=false

  $LOTUS_BIN wait-api
  echo -e "\nImporting the genesis miner key:\n"
  $LOTUS_BIN wallet import ~/.genesis-sectors/pre-seal-t01000.key
  $LOTUS_BIN wallet import rootkey1

  sleep 3
  echo -e "\nSetting up the genesis miner:\n"
  $LOTUS_MINER init --genesis-miner --actor=t01000 --sector-size=2KiB \
    --pre-sealed-sectors=~/.genesis-sectors \
    --pre-sealed-metadata=~/.genesis-sectors/pre-seal-t01000.json --nosync

  sleep 3
  echo -e "\nStarting up the miner:\n"
  tmux new-window -t lotus:2 -n miner -d $LOTUS_MINER run --nosync
#  $LOTUS_MINER run --nosync
}

purge_local_dirs() {
  echo -e "\nRemoving local state\n"
  rm -rf ~/.lotus || true
  rm -rf ~/.lotusstorage || true
  rm -rf ~/.lotusminer || true
  rm -rf ~/.genesis-sectors || true
}

main() {

  echo -e "\nUsing Lotus Path: $LOTUS_PATH \n"

  echo -e "Purging"
  purge_local_dirs

  configure_lotus
}

#### Main

main
