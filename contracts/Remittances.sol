pragma solidity ^0.4.4;

contract Remittances {

	struct Remittance {
		uint amount;
		address exchangerAddress;
		bool paid;
	}

	/* use the hash of the secrets as key of the remittance! */
	mapping (bytes32 => Remittance) public remittances;

	event LogRemittanceSent(uint amount, bytes32 secretsHash, address exchangerAddress);
	event LogRemittancePaid(uint amount, bytes32 secretsHash, address exchanger);

	function Remmitances()	{
	}

	function sendRemittance(
		bytes32 secretsHash,
		address exchangerAddress)
		payable
		returns (bool success)
	{

		/* dont be cheap */
		if(msg.value == 0) throw;

		/* check that secrets have not been used before.
			empty struct cannot be detected, so use one property to check
			this key (and pair of secrets) have not been used before */
		if (remittances[secretsHash].exchangerAddress != 0) throw;

		/* store the remittance data using the secrets hash as key */
		remittances[secretsHash] = Remittance(msg.value, exchangerAddress, false);

		LogRemittanceSent(
		    remittances[secretsHash].amount,
		    secretsHash,
		    remittances[secretsHash].exchangerAddress);

		return true;
	}

	function pay(
		string secret1,
		string secret2)
		returns (bool success)
	{

		/* get remittance data */
		bytes32 secretsHash = keccak256(secret1, secret2);
		Remittance memory remittance = remittances[secretsHash];
		if (remittance.exchangerAddress == 0) throw;

		/* check is not paid */
		if (remittance.paid) throw;

		/* check exchanger is calling */
		if (remittance.exchangerAddress != msg.sender) throw;

 		remittance.paid = true;
		if(!msg.sender.send(remittance.amount)) {
		  remittance.paid = false;
			return false;
		}

		LogRemittancePaid(
		    remittance.amount,
		    secretsHash,
		    msg.sender);

		return true;
	}

}
