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

## Gas price after reorder variables in struct
```
  Contract: Trickle
    create agreement
172212 gas (~$0.0842, 163 USD/ETH)
      ✓ creates agreement (112ms)
172212 gas (~$0.0842, 163 USD/ETH)
142212 gas (~$0.0695, 163 USD/ETH)
      ✓ creates multiple agreements (198ms)
      ✓ can't create without tokens approved
      ✓ can't create with invalid start
      ✓ can't create with invalid amount
      ✓ can't create with invalid token
      ✓ can't create with invalid recipient
      ✓ can't create with invalid duration
    cancel agreement
53233 gas (~$0.026, 163 USD/ETH)
      ✓ can be cancelled before agreement starts (116ms)
97737 gas (~$0.0478, 163 USD/ETH)
      ✓ can be cancelled in the middle of agreement (192ms)
81374 gas (~$0.0398, 163 USD/ETH)
      ✓ can be cancelled at the and of agreement (143ms)
81543 gas (~$0.0399, 163 USD/ETH)
      ✓ can be canceled from recipient (135ms)
      ✓ can't be canceled twice (138ms)
      ✓ can't be cancelled from 3rd party account (92ms)
      ✓ should fail if agreement does not exists (76ms)
    withdraw tokens
80795 gas (~$0.0395, 163 USD/ETH) - Withdraw tokens for the first time
35457 gas (~$0.0173, 163 USD/ETH) - Withdraw tokens for the second time
      ✓ withdraw tokens (290ms)
      ✓ should fail if agreement id doesn't exist (79ms)
      ✓ should fail if trying to get tokens after cancel (137ms)


  18 passing (4s)
```

### Gas price after encode 3 variables into one uint256
```
  Contract: Trickle
    create agreement
160520 gas (~$0.0785, 163 USD/ETH)
      ✓ creates agreement (105ms)
160520 gas (~$0.0785, 163 USD/ETH)
130520 gas (~$0.0638, 163 USD/ETH)
      ✓ creates multiple agreements (196ms)
      ✓ can't create without tokens approved
      ✓ can't create with invalid start
      ✓ can't create with invalid amount
      ✓ can't create with invalid token
      ✓ can't create with invalid recipient
      ✓ can't create with invalid duration
    cancel agreement
53875 gas (~$0.0263, 163 USD/ETH)
      ✓ can be cancelled before agreement starts (117ms)
97980 gas (~$0.0479, 163 USD/ETH)
      ✓ can be cancelled in the middle of agreement (187ms)
81904 gas (~$0.0401, 163 USD/ETH)
      ✓ can be cancelled at the and of agreement (149ms)
82073 gas (~$0.0401, 163 USD/ETH)
      ✓ can be canceled from recipient (100ms)
      ✓ can't be canceled twice (162ms)
      ✓ can't be cancelled from 3rd party account (87ms)
      ✓ should fail if agreement does not exists (76ms)
    withdraw tokens
80718 gas (~$0.0395, 163 USD/ETH) - Withdraw tokens for the first time
35385 gas (~$0.0173, 163 USD/ETH) - Withdraw tokens for the second time
      ✓ withdraw tokens (278ms)
      ✓ should fail if agreement id doesn't exist (80ms)
      ✓ should fail if trying to get tokens after cancel (127ms)


  18 passing (4s)
```

### Gas price after getting rid of memory variables where appliable. Set 1000 runs for solc optimizer.
```
  Contract: Trickle
    create agreement
157833 gas (~$0.0772, 163 USD/ETH)
      ✓ creates agreement (95ms)
157833 gas (~$0.0772, 163 USD/ETH)
127833 gas (~$0.0625, 163 USD/ETH)
      ✓ creates multiple agreements (179ms)
      ✓ can't create without tokens approved
      ✓ can't create with invalid start
      ✓ can't create with invalid amount
      ✓ can't create with invalid token
      ✓ can't create with invalid recipient
      ✓ can't create with invalid duration
    cancel agreement
49248 gas (~$0.0241, 163 USD/ETH)
      ✓ can be cancelled before agreement starts (114ms)
91374 gas (~$0.0447, 163 USD/ETH)
      ✓ can be cancelled in the middle of agreement (178ms)
75277 gas (~$0.0368, 163 USD/ETH)
      ✓ can be cancelled at the and of agreement (138ms)
75565 gas (~$0.037, 163 USD/ETH)
      ✓ can be canceled from recipient (92ms)
      ✓ can't be canceled twice (160ms)
      ✓ can't be cancelled from 3rd party account (80ms)
      ✓ should fail if agreement does not exists (74ms)
    withdraw tokens
78179 gas (~$0.0382, 163 USD/ETH) - Withdraw tokens for the first time
32843 gas (~$0.0161, 163 USD/ETH) - Withdraw tokens for the second time
      ✓ withdraw tokens (274ms)
      ✓ should fail if agreement id doesn't exist (76ms)
      ✓ should fail if trying to get tokens after cancel (123ms)


  18 passing (4s)
```