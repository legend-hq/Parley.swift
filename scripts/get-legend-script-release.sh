#!/bin/bash

set -eo pipefail

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

LEGEND_SCRIPTS_VERSION=$1

if [ -z "$LEGEND_SCRIPTS_VERSION" ]; then
  echo "usage: scripts/get-legend-script-release.sh <VERSION>"
  exit 1
fi

source "$script_dir/__download_legend_scripts_release.sh" "$LEGEND_SCRIPTS_VERSION"

rm -rf "$script_dir/../Mercator.swift/Sources/Prelude/Contracts/"

for contract in "AaveScripts.sol/AaveActions.json" "AcrossScripts.sol/AcrossActions.json" "Actions.sol/Actions.json" "SwapScripts.sol/ApproveAndSwap.json" "DeFiScripts.sol/CometClaimRewards.json" "DeFiScripts.sol/CometRepayAndWithdrawMultipleAssets.json" "DeFiScripts.sol/CometSupplyActions.json" "DeFiScripts.sol/CometSupplyMultipleAssetsAndBorrow.json" "DeFiScripts.sol/CometWithdrawActions.json" "LoopLong.sol/LoopLong.json" "LoopShort.sol/LoopShort.json" "MerklScripts.sol/MerklRewardsActions.json" "MorphoScripts.sol/MorphoActions.json" "MorphoScripts.sol/MorphoRewardsActions.json" "MorphoScripts.sol/MorphoVaultActions.json" "Multicall.sol/Multicall.json" "QuarkBuilder.sol/QuarkBuilder.json" "QuotePay.sol/QuotePay.json" "DeFiScripts.sol/TransferActions.json" "UnloopLong.sol/UnloopLong.json" "UnloopShort.sol/UnloopShort.json" "WrapperScripts.sol/WrapperActions.json"; do
  "$script_dir/geno.sh" "./legend-script-releases/$LEGEND_SCRIPTS_VERSION/out/$contract" --outDir ../Mercator.swift/Sources/Prelude/Contracts/
done

swift format -i "$script_dir/../Mercator.swift/Sources/Prelude/Contracts/"
