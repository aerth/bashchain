## bash proof-of-work chain (blockchain)

`./miner.bash | ./hashchain.bash run`

## about

stores chain headers as txt file, hash is not stored:

fields are: 

  * parenthash
  * timestamp
  * nonce
  * contents

example chain.db:

```
f08d28edd4251370855e84d9cf7e522cea075eced0658086c33d9669ced0e6ea
1537410726
19490
none

00098c9ffa307df5db2ad2ff3983b67bac6e6fd5211b1b1775e310bfc907f977
1537410745
18332
none

000c959edf5102f0d2bc3ef5bf9e58613f1c873d36925bbc4f2fd38618546d3f
1537410751
23042
none

000498f3fc8ba5961b0101f18e7a024a738bdd156d54546e548289c76b532857
1537410757
27743
none

```
