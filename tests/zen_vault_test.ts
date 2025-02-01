import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test adding and retrieving prompts",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      // Owner adds a prompt
      Tx.contractCall('zen-vault', 'add-prompt', [
        types.ascii("What are you grateful for today?")
      ], deployer.address),
      
      // Non-owner tries to add a prompt
      Tx.contractCall('zen-vault', 'add-prompt', [
        types.ascii("Invalid prompt")
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    block.receipts[1].result.expectErr(types.uint(100)); // err-not-owner
  },
});

Clarinet.test({
  name: "Test shared entries functionality",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Add prompt and shared entry
    let setupBlock = chain.mineBlock([
      Tx.contractCall('zen-vault', 'add-prompt', [
        types.ascii("What are you grateful for today?")
      ], deployer.address),
      Tx.contractCall('zen-vault', 'add-entry', [
        types.utf8("Sharing my gratitude"),
        types.uint(1),
        types.bool(true) // shared entry
      ], wallet1.address),
    ]);
    
    // Another user retrieves shared entry
    let retrieveBlock = chain.mineBlock([
      Tx.contractCall('zen-vault', 'get-shared-entry', [
        types.uint(2)
      ], wallet2.address),
    ]);
    
    // Verify shared entry is accessible
    let entry = retrieveBlock.receipts[0].result.expectOk();
    assertEquals(entry.content, "Sharing my gratitude");
    assertEquals(entry.is-shared, true);
  },
});

Clarinet.test({
  name: "Test reflection functionality", 
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Add prompt and entry
    let setupBlock = chain.mineBlock([
      Tx.contractCall('zen-vault', 'add-prompt', [
        types.ascii("What are you grateful for today?")
      ], deployer.address),
      Tx.contractCall('zen-vault', 'add-entry', [
        types.utf8("Original entry"),
        types.uint(1),
        types.bool(false)
      ], wallet1.address),
    ]);
    
    // Add reflection
    let reflectionBlock = chain.mineBlock([
      Tx.contractCall('zen-vault', 'add-reflection', [
        types.uint(2),
        types.utf8("My later thoughts")
      ], wallet1.address),
    ]);
    
    reflectionBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Retrieve entry with reflection
    let retrieveBlock = chain.mineBlock([
      Tx.contractCall('zen-vault', 'get-my-entry', [
        types.uint(2)
      ], wallet1.address),
    ]);
    
    let entry = retrieveBlock.receipts[0].result.expectOk();
    assertEquals(entry.reflection, "My later thoughts");
  },
});
