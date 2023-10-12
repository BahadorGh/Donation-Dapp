# Design Patterns
## Access Control
We implemented a simple access control to restrict the ability of executig some functions authorized entities("_admin_" and "_campaign owner_")

* Note: It is possible to easily use __ACL from OZ contracts__, but i prefered to just implement an easy access control in the contract.

## Circuit-Breaker
We implemented a custom circuit-breaker into the contract. But it is also possible to easily use libraries(such as `Pausable` from `OpenZeppelin`) to restrict some functionalities when system is set to pause status in emergency by admin.

## Withdrawal pattern
In the `Crowdfunding.sol` we implemeneted a `withdrawFunds()` function which is applicable only by admin to make withdrawal action, only and only in case of _emergency_.
