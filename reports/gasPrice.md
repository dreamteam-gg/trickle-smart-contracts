## Gas price before optimization

```  
  Contract: Trickle
    create agreement
205951 gas (~$0.1007, 163 USD/ETH)
      ✓ creates agreement (109ms)
205951 gas (~$0.1007, 163 USD/ETH)
175951 gas (~$0.086, 163 USD/ETH)
      ✓ creates multiple agreements (197ms)
      ✓ can't create without tokens approved
      ✓ can't create with invalid start
      ✓ can't create with invalid amount
      ✓ can't create with invalid token
      ✓ can't create with invalid recipient
      ✓ can't create with invalid duration
    cancel agreement
55980 gas (~$0.0274, 163 USD/ETH)
      ✓ can be cancelled before agreement starts (116ms)
101633 gas (~$0.0497, 163 USD/ETH)
      ✓ can be cancelled in the middle of agreement (181ms)
85278 gas (~$0.0417, 163 USD/ETH)
      ✓ can be cancelled at the and of agreement (141ms)
85447 gas (~$0.0418, 163 USD/ETH)
      ✓ can be canceled from recipient (98ms)
      ✓ can't be canceled twice (171ms)
      ✓ can't be cancelled from 3rd party account (88ms)
      ✓ should fail if agreement does not exists (75ms)
    withdraw tokens
82262 gas (~$0.0402, 163 USD/ETH) - Withdraw tokens for the first time
36888 gas (~$0.018, 163 USD/ETH) - Withdraw tokens for the second time
      ✓ withdraw tokens (223ms)
      ✓ should fail if agreement id doesn't exist (78ms)
      ✓ should fail if trying to get tokens after cancel (129ms)


  18 passing (4s)
  ```

  ## Gas price after optimization
  TBD