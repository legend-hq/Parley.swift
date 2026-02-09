public extension Token {
    var blurb: String? {
        switch self {
            case .`1INCH`:
                """
                1inch is a decentralized exchange (DEX) aggregator, pooling liquidity from numerous DEXs to ensure users access the most competitive rates. This aggregation is crucial for traders seeking optimal prices without the hassle of manual comparisons across multiple platforms.
                """
            case .AAVE:
                """
                Aave (AAVE) is an Ethereum token that powers Aave, a decentralized non-custodial money market protocol where users can earn interest on their assets or borrow against them. Trade the token or access the Aave markets to interact with Aave. 
                """
            case .AERO:
                """
                Aerodrome Finance (AERO) is an automated market maker and liquidity hub on Base, similar to Uniswap, but focused on Base. Aerodrome Finance was launched as a fork of Velodrome Finance. 
                """
            case .ANON:
                """
                Super Anon (ANON) is a token deployed by the AI Agent Clanker (CLANKER), an automated AI that creates memecoins on Base when given a user prompt in the form of a cast on Farcaster. Anon was created by the user @superanon, a now shared account that allows anyone holding a certain amount of ANON to anonymously post a message to the protocol. 
                """
            case .ARB:
                """
                Arbitrum (ARB) is the utility token of Arbitrum, an Ethereum layer-2 network (similar to OP for Optimism). ARB functions as the governance token of the Arbitrum DAO, as holders may create and vote on governance proposals.
                """
            case .ATH:
                """
                Aethir is the only Enterprise-grade AI-focused GPU-as-a-service provider in the market. Its decentralized cloud computing infrastructure allows GPU providers (containers) to meet Enterprise clients who need powerful H100 chips for professional AI/ML tasks.
                """
            case .BNKR:
                """
                Bankr is an advanced AI agent focused on simplifying the process of buying and selling digital assets. Bankr was the first AI agent on Farcaster to help you quickly buy all your favorites coins directly in the feed. BankrCoin (BNKR) is the official coin of the agent and was deployed by Bankr itself directly in the Farcaster feed. Fees from swaps go to support BankrCoin (BNKR). Bankr is available on Farcaster and will soon be launching a private terminal, token recs, and limit orders on Base.
                """
            case .BRETT:
                """
                BRETT is a meme coin based on BRETT character, famously know in the boy's club comics as PEPE's Friend. The oldest launched Brett Token on the ETH Chain. Dogs have had their time and now it's time for Brett to take it from here.
                """
            case .CAKE:
                """
                CAKE is the governance token for PancakeSwap. The supply of CAKE is not hard-capped. Theoretically, CAKE’s supply is unlimited. The team is looking into conducting regular token burns to make deflation higher than emission.
                """
            case .cbBTC:
                """
                Coinbase Wrapped BTC (cbBTC) is a token that is backed 1:1 by Bitcoin (BTC) held by Coinbase. cbBTC is fully transferable, and Coinbase customers can unwrap cbBTC and redeem a corresponding amount of the underlying BTC simply by depositing the cbBTC into their Coinbase accounts. cbETH can be used in DeFi protocols such as Aave, Compound, and Morpho. 
                """
            case .cbETH:
                """
                Wrapped Staked ETH (cbETH) is a utility token that represents ETH staked through Coinbase. cbETH is a liquid staking token because it allows holders to get the benefits of staking wiithout lockups or unbonding periods. cbETH can be used in DeFi protocols such as Aave, Compound, and Morpho. 
                """
            case .CLANKER:
                """
                Clanker is an autonomous agent for deploying tokens on Base, with the native token Clanker (CLANKER) powering the system. Currently, users may request clanker to deploy an ERC-20 token on Base by tagging it @clanker on Farcaster.
                """
            case .COMP:
                """
                Compound (COMP) is an Ethereum token that enables community governance of the Compound protocol. The protocol is a series of decentralized interest rate markets that allow users to supply and borrow Ethereum tokens at variable interest rates. COMP token holders and their delegates can also debate, propose, and vote on changes to the protocol. Trade the token or access the Compound markets to interact with Compound. 
                """
            case .CRV:
                """
                Curve DAO Token (CRV) is an Ethereum token that powers Curve, a decentralized exchange (similar to Uniswap and 0x), but with a primary focus on stablecoins. Curve, launched in January 2020, has emerged as a notable entity in the decentralized finance (DeFi) sector. CRV is used for governance, awarded to users based on their liquidity commitment and duration of ownership.
                """
            case .DEGEN:
                """
                Degen (DEGEN) is a reward token for Farcaster users, born from meme culture. It uses a unique tipping system that empowers the community to reward quality content creators. It also powers the Degen chain, one of the pioneering L3s launched on Base.
                """
            case .DOT:
                """
                Polkadot is a platform that allows various blockchains to transfer messages, including value, in a trust-free fashion; sharing their unique features while pooling their security. DOT is the native token to support the network, built initially on the Cosmos blockchain.
                """
            case .EIGEN:
                """
                EigenLayer is a protocol that leverages the Ethereum blockchain to introduce a novel concept known as restaking. This innovative approach to cryptoeconomic security allows Ethereum stakers to reuse their staked ETH or Liquid Staking Tokens (LST) across various decentralized services within the EigenLayer ecosystem
                """
            case .ENA:
                """
                Ethena (ENA) is a synthetic dollar protocol built on Ethereum that provides a crypto-native solution for money not reliant on traditional banking system infrastructure, alongside a globally accessible dollar denominated rewards instrument - the 'Internet Bond'.
                """
            case .EUL:
                """
                Euler is an onchain lending platform, which makes lending and borrowing simpler, more efficient in DeFi.
                """
            case .EURC:
                """
                Euro Coin (EURC) is a stablecoin by Circle: a cryptocurrency that is fully backed by the Euro through cash and cash-equivalent asset reserves. As a stablecoin, the value of one EURC is kept roughly equal to the price of the Euro because it can be redeemed for a euro through the company that issues it. 
                """
            case .ezETH:
                """
                Renzo Staked ETH (ezETH) is an ERC-20 liquid restaking token for the Renzo Protocol. It represents a user's restaked position in the EigenLayer ecosystem, where users can deposit native ETH or Liquid Staking Tokens (LSTs) to receive ezETH, a token that accumulates staking rewards with auto-compounding mechanics. Users may achieve higher rewards compared to other restaking protocols through Renzo's auto-compounding feature.
                """
            case .GMX:
                """
                GMX (GMX) is a decentralized spot and perpetual exchange on Arbitrum, powered by the GMX token. Trading is supported by a unique multi-asset pool that earns liquidity providers fees from market making, swap fees, leverage trading, and asset rebalancing. 
                """
            case .HIGHER:
                """
                Higher is an ERC-20 memecoin deployed on Base, that launched from a specific channel on Farcaster (with support from a relatively strong and active community). The token mainly serves to encourage creativity in the form of meme generation and community participation, with a stronger focus on aesthetics than most communities. 
                """
            case .ICP:
                """
                The Internet Computer blockchain incorporates a radical rethink of blockchain design, powered by innovations in cryptography. It provides the first “World Computer” blockchain that can be used to build almost any Web 2.0 online system or service, and web3 services, including web3 social media services, without any need for centralized traditional IT such as cloud computing services.
                """
            case .JUP:
                """
                Jupiter is a decentralized exchange (DEX) aggregator that allows users to swap tokens at optimal prices with low slippage and transaction fees in the Solana ecosystem. It also provides users the optimal routes for direct swaps between multiple exchanges and liquidity pools.
                """
            case .KAITO:
                """
                Kaito is building an attention dashboard, visualizing what brands and protocols are most discussed on X (otherwise known as “yaps” by the Kaito community). $KAITO is the native token and the fundamental building block of the network.
                """
            case .LINK:
                """
                Chainlink (LINK) is an ERC-677 token (extending standard ERC-20 functionality) on the Ethereum blockchain. LINK serves as the native token for the Chainlink Decentralized Oracle Network (DON), which connects blockchain-based smart contracts with real-world data, events, and off-chain computation provided by Oracles. The token is primarily used to pay for the services provided by Chainlink oracles, and node operators are compensated in LINK for delivering accurate data. 
                """
            case .LUM:
                """
                The first AI Agent to AI agent created token on Base, Luminous (LUM). LUM was created by an AI Agent named aethernet, which became popularized on Farcaster. 
                """
            case .MOG:
                """
                Mog Coin (MOG) is a meme coin from the Mog community on Base. The cultural underpinning of Mog is an idea and mentality that anyone can adopt, and can be applied to any situation in life. It is simply about being the best version of yourself in anything that you do – being confident in yourself, your community, and your own success.
                """
            case .MORPHO:
                """
                Morpho (MORPHO) is an Ethereum token that powers Morpho, a decentralized non-custodial money market protocol where users can earn interest on their assets or borrow against them. Trade the token or access the Morpho markets to interact with Morpho. 
                """
            case .OP:
                """
                Optimism token (OP) is an ERC-20 token primarily used as the governance token for the Optimism L2 blockchain. Optimism started the "Superchain" mission and partners with many L2s to achieve easy interoporability for Superchain chains. OP is used to vote on proposed upgrades to the blockchain and network parameters, and to create an ongoing system of incentives for projects and users in the Optimism ecosystem. 
                """
            case .PENDLE:
                """
                Pendle (PENDLE) is a protocol that enables the tokenization and trading of future yield, with the PENDLE token powering the system. With the creation of a novel AMM that supports assets with time decay, Pendle gives users more control over future yield by providing optionality and opportunities for its utilization.
                """
            case .POL, .WPOL:
                """
                Polygon (POL) is the native token used on the Polygon L2 blockchain (now proof of stake) to pay for gas fees, stake, participate in governance, and secure block validation. POL was launched as the official successor to MATIC on September 4, 2024, with the first upgrade proposal presented in PIP-17. The POL upgrade aims to unify token utility across the Polygon ecosystem.
                """
            case .PRIME:
                """
                Prime (PRIME) is the utility and governance token for the Echelon gaming ecosystem and issued by the Echelon Prime Foundation. PRIME powers token-gated products, services, and experiences through PRIME sinks.
                """
            case .rETH:
                """
                Rocket Pool ETH (rETH) is the Rocket Pool protocol's liquid staking token. The rETH token represents an amount of ETH that is being staked and earning rewards within Ethereum Proof-of-Stake. Rocket Pool's liquid staking token allows holders to benefit from the returns of the Ethereum Proof-of-Stake.
                """
            case .rsETH:
                """
                Kelp DAO Restaked ETH (rsETH) is a liquid staking token on Ethereum. By holding rsETH, users can maximize their staking rewards while allowing the asset to be used in DeFi protocols such as Compound. 
                """
            case .SNX:
                """
                Synthetix is a decentralized perpetual futures protocol built on Ethereum. Synthetix uses a hybrid design — offchain order matching on a high-performance CLOB with onchain settlement — to deliver low latency, deep liquidity, and MEV-resistant execution while keeping custody and finality on Ethereum.
                """
            case .SYRUP:
                """
                The SYRUP token is central to Maple (onchain asset manager), aligning stakeholders, governing the platform, and incentivizing participation. It allows users to influence Maple's future and benefit from its growth by capturing value and promoting ecosystem-wide success.
                """
            case .TOSHI:
                """
                Toshi (TOSHI) is a memecoin on Base. Toshi brands itself as the “Face of Base”, taking its name from the name of Coinbase CEO Brian Armstrong’s cat Toshi, which was named after Satoshi Nakamoto, the creator of the Bitcoin whitepaper. 
                """
            case .TOWNS:
                """
                Towns is a decentralized group chat protocol that aims to help online communities build better "hometowns" on the internet. TOWNS is a governance token that also supports delegation to node operators and is also used to power communication on the platform. 
                """
            case .USDC:
                """
                USDC (USD Coin) is a stablecoin by Circle: a cryptocurrency that is fully backed by the US dollar through cash and cash-equivalent asset reserves. As a stablecoin, the value of one USDC is kept roughly equal to the price of the US dollar because it can be redeemed for a dollar through the company that issues it. 
                """
            case .USDe:
                """
                Ethena is a synthetic dollar protocol built on Ethereum. USDe is a yield bearing synthetic dollar created from the system, capturing yield created by Ethena. 
                """
            case .USDT:
                """
                Tether USD (USDT) is a popular stablecoin that is pegged to the US Dollar and issued by Tether. USDT and USDC are very similar, with the core difference of USDC being from Circle (based in the USA) and USDT being from Tether (Non-USA).  
                """
            case .uSOL:
                """
                Solana (Universal) (uSOL) is a wrapped version of Solana issued on the Universal Protocol. uSOL is backed by native Solana at a 1:1 ratio via a network of merchants and custodians, ensuring that its value remains pegged to Solana’s price at all times. uSOL allows users to gain exposure to Solana while operating within the Universal Protocol ecosystem, facilitating interoperability and enhanced liquidity across multiple blockchain networks.
                """
            case .uXRP:
                """
                Ripple (Universal) (uXRP) is a wrapped version of Ripple issued on the Universal Protocol. uXRP is backed by native Ripple at a 1:1 ratio via a network of merchants and custodians, ensuring that its value remains pegged to Ripple’s price at all times. uXRP enables users to engage with the Universal Protocol ecosystem while maintaining exposure to Ripple, providing enhanced liquidity and interoperability across multiple blockchain networks.
                """
            case .VIRTUAL:
                """
                Virtuals Protocol is building a co-ownership layer for AI agents in gaming and entertainment on Base. These agents can operate across a wide range of applications and games, significantly expanding their revenue surface area. The protocol enables these AI agents to be tokenized and co-owned via blockchain.
                """
            case .VVV:
                """
                VVV is a utility token on Base for Venice.ai, a private and permissionless generative AI app. By staking VVV tokens, agents, bots, and 3rd party apps can access private and uncensored inference at no cost while earning staking income. 
                """
            case .WBTC:
                """
                Wrapped Bitcoin (WBTC) is a tokenized version of Bitcoin (BTC) that operates on the Ethereum (ETH) blockchain. It adheres to the ERC-20 standard, which is the basic compatibility standard of the Ethereum blockchain. Users can trade into WBTC, but WBTC is mint/burned through the WBTC DAO. cbBTC is a Coinbase-backed alternative to WBTC. 
                """
            case .weETH:
                """
                Ether.fi Staked ETH (weETH) is a decentralized liquid staking token on Ethereum from Ether.fi. Holders earn staking rewards while maintaining full liquidity and control over their assets. weETH integrates seamlessly with the Ethereum ecosystem, offering users a flexible and secure way to contribute to network validation and participate in DeFi.
                """
            case .WELL:
                """
                Moonwell (WELL) is an Ethereum token that powers Moonwell, a decentralized non-custodial money market protocol where users can earn interest on their assets or borrow against them. Similar to others (Aave, Compound. Morpho), except Moonwell has made their focus on Base, similar to Aerodrome. Trade the token or access the Moonwell markets to interact with Moonwell. 
                """
            case .WLD:
                """
                Worldcoin aims to build the world’s largest public identity and financial network, giving ownership to everyone. At its core is World ID, a privacy-preserving identity system that lets users prove they’re human online—without revealing personal information—using zero-knowledge proofs. Platforms that integrate with World ID can protect against bots, ensure fair token distributions, and enable new governance models like quadratic voting or even AI-funded UBI.

                To get a World ID, users must download a compatible wallet and visit an Orb—a device that verifies humanness and uniqueness using multispectral imaging. Orbs are run by local businesses, and by default, images are deleted after verification. Verified users can claim recurring WLD token grants (subject to availability). The WLD token is a utility token used for governance within the Worldcoin protocol.
                """
            case .ETH, .WETH:
                """
                Ethereum (ETH) is a decentralized, open-source blockchain that aims to become a global platform for decentralized applications and strives to enable users worldwide to write and run software resistant to censorship, downtime, and fraud. Ether (ETH) is the native currency of the Ethereum blockchain and the second largest cryptocurrency by market cap. ETH is mainly used to pay for transactions directly onchain (gas), is rewarded to stakers and validators of the blockchain, and is the most used asset in DeFi. 
                """
            case .stETH, .wstETH:
                """
                Lido Staked ETH (stETH) is a liquid staking token on Ethereum. Holding stETH is used to participate in Ethereum's proof-of-stake consensus to earn staking rewards. stETH represents the combined value of the initial ETH deposit plus accumulated staking rewards.
                """
            case .ZORA:
                """
                Zora is a decentralized social network on Base where every post is a token itself. The ZORA token is not a governance token or utility token, but is used as the native asset on the Zora network and serves functions such as paying minting fees, rewards for creators, and tipping.
                """
            case .ZRO:
                """
                LayerZero (ZRO) is the native utility token of the LayerZero protocol, which focuses on powering bridging assets between blockchains. ZRO is an ERC-20 token on Ethereum, and is used to pay for messaging services and decentralized applications which require communication between blockchains. 
                """
            case .XAUt:
                """
                XAUt token represents ownership of one troy fine ounce of physical gold on a specific gold bar. XAUt, which is available as an ERC-20 token on the Ethereum blockchain and as a TRC20 token on the TRON blockchain. Tether Gold (XAUt) is the only product among the competition that offers zero custody fees and has direct control over the physical gold storage, safely held in a Switzerland vault, adopting best in class security and anti-threat measures. Today, Tether Gold (XAUt) is the best way to hold Gold.
                """
            // Explicitly return nil for tokens with no Blurb so that new tokens which are added aren't forgotten
            case .BLUR,
                .BSHIB,
                .CRASH,
                .DAI,
                .FRAX,
                .GHO,
                .HYPE,
                .LDO,
                .MKR,
                .osETH,
                .PEPE,
                .RPL,
                .SHIB,
                .SNX,
                .SYRUP,
                .UNI,
                .USDH,
                .WHYPE,
                .UNKNOWN:
                nil
        }
    }
}
