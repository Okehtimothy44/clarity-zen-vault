// [Previous test content remains, adding new tests for new features]

Clarinet.test({
  name: "Test entry deletion",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Add entry
    let setupBlock = chain.mineBlock([
      Tx.contractCall('zen-vault', 'add-entry', [
        types.utf8("Test entry"),
        types.uint(1),
        types.bool(false)
      ], wallet1.address),
    ]);
    
    // Delete entry
    let deleteBlock = chain.mineBlock([
      Tx.contractCall('zen-vault', 'delete-entry', [
        types.uint(1)
      ], wallet1.address),
    ]);
    
    deleteBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Try to retrieve deleted entry
    let retrieveBlock = chain.mineBlock([
      Tx.contractCall('zen-vault', 'get-my-entry', [
        types.uint(1)
      ], wallet1.address),
    ]);
    
    retrieveBlock.receipts[0].result.expectErr(types.uint(102));
  },
});
