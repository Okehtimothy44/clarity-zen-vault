Clarinet.test({
  name: "Test rate limiting and entry limits",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Test rate limiting
    let block1 = chain.mineBlock([
      Tx.contractCall('zen-vault', 'add-entry', [
        types.utf8("Test entry 1"),
        types.uint(1),
        types.bool(false)
      ], wallet1.address),
    ]);
    
    block1.receipts[0].result.expectOk();
    
    // Try to add another entry immediately
    let block2 = chain.mineBlock([
      Tx.contractCall('zen-vault', 'add-entry', [
        types.utf8("Test entry 2"),
        types.uint(1),
        types.bool(false)
      ], wallet1.address),
    ]);
    
    block2.receipts[0].result.expectErr(types.uint(106));
  },
});

[Previous tests remain unchanged...]
