# Security policies:
# safeMath
Used to prevent overflow and underflow
# Re-entrancyGuard
In `CrowdFunding.sol`, We have implemented a structure to prevent re-entrancy attack when trying to transfer out ETH from the contract.