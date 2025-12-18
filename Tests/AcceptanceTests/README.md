
## Acceptance Tests

Acceptance Tests test the observable logic of the Mercator Chart system (previously Quark Builder).

## Running Single Tests

To run acceptance tests:

```sh
swift test --package-path Tests/AcceptanceTests
```

You can run a single suite of tests:

```sh
swift test --package-path Tests/AcceptanceTests --filter "AcceptanceTests.TransferTests/"
```

or even a single test:

```sh
swift test --package-path Tests/AcceptanceTests --filter "AcceptanceTests.TransferTests/testTransferUsdcToBobEthereum"
```