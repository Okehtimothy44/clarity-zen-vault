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
  name: "Test adding and retrieving journal entries",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // First add a prompt
    let setupBlock = chain.mineBlock([
      Tx.contractCall('zen-vault', 'add-prompt', [
        types.ascii("What are you grateful for today?")
      ], deployer.address),
    ]);
    
    let promptId = setupBlock.receipts[0].result.expectOk().expectUint(1);
    
    // Now test journal entries
    let block = chain.mineBlock([
      // Add an entry
      Tx.contractCall('zen-vault', 'add-entry', [
        types.utf8("I am grateful for this beautiful day"),
        types.uint(promptId)
      ], wallet1.address),
    ]);
    
    let entryId = block.receipts[0].result.expectOk().expectUint(2);
    
    // Retrieve the entry
    let retrieveBlock = chain.mineBlock([
      Tx.contractCall('zen-vault', 'get-my-entry', [
        types.uint(entryId)
      ], wallet1.address),
    ]);
    
    // Verify entry contents
    let entry = retrieveBlock.receipts[0].result.expectOk();
    assertEquals(entry.content, "I am grateful for this beautiful day");
    assertEquals(entry.prompt-id, promptId);
  },
});

Clarinet.test({
  name: "Test entry privacy",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Add prompt and entry
    let setupBlock = chain.mineBlock([
      Tx.contractCall('zen-vault', 'add-prompt', [
        types.ascii("What are you grateful for today?")
      ], deployer.address),
      Tx.contractCall('zen-vault', 'add-entry', [
        types.utf8("My private thoughts"),
        types.uint(1)
      ], wallet1.address),
    ]);
    
    // Try to access someone else's entry
    let block = chain.mineBlock([
      Tx.contractCall('zen-vault', 'get-my-entry', [
        types.uint(2)
      ], wallet2.address),
    ]);
    
    block.receipts[0].result.expectErr(types.uint(102)); // err-entry-not-found
  },
});