<template>
  <div class="w3-container">
    <h1>Remittances App</h1>
    <h3>Total balance {{ contractBalance }} eth</h3>
    <div class="w3-row from-row">
      <label class=""><b>From:</b></label>
      <select class="w3-input" v-model="from">
        <option v-for="account in accounts">
          {{ account }}
        </option>
      </select>
    </div>

    <div class="w3-row w3-margin-top">
      <button class="w3-col s6 w3-bottombar w3-button" :class="{'w3-border-blue': sendRemittance}"
        @click="sendRemittance = true">
        Send
      </button>
      <button class="w3-col s6 w3-bottombar w3-button" :class="{'w3-border-blue': !sendRemittance}"
        @click="sendRemittance = false">
        Receive
      </button>
    </div>

    <div v-if="sendRemittance" class="send-container">
      <div class="w3-row w3-margin-top">
        <div class="w3-col m6 w3-padding">
          <label class=""><b>Amount to be Sent</b></label>
        </div>
        <div class="w3-col m6">
          <input v-model="amount" type="number" class="w3-input">
        </div>
      </div>

      <div class="w3-row w3-margin-top">
        <div class="w3-col m6 w3-padding">
          <label class=""><b>Exchanger Address</b></label>
        </div>
        <div class="w3-col m6">
          <input v-model="exchangerAddress" type="text" class="w3-input">
        </div>
      </div>

      <div class="w3-row w3-margin-top send-row">
        <button @click="send()" class="w3-button w3-blue w3-round">generate secrets and send</button>
      </div>

      <div class="w3-row-padding w3-margin-top">
        <div class="w3-col m6">
          <label><b>Secret #1</b></label>
          <input v-model="secret1" type="text" class="w3-input" disabled>
        </div>
        <div class="w3-col m6">
          <label><b>Secret #2</b></label>
          <input v-model="secret2" type="text" class="w3-input" disabled>
        </div>
      </div>

      <div class="w3-row-padding w3-margin-top">
        <label><b>Secrets Hash String</b></label>
        <input v-model="secretsHash" type="text" class="w3-input" disabled>
      </div>

    </div>
    <div v-else class="">

      <div class="w3-row-padding w3-margin-top">
        <div class="w3-col m6">
          <label><b>Secret #1</b></label>
          <input v-model="secret1" type="text" class="w3-input">
        </div>
        <div class="w3-col m6">
          <label><b>Secret #2</b></label>
          <input v-model="secret2" type="text" class="w3-input">
        </div>
      </div>

      <div class="w3-row w3-margin-top send-row">
        <button @click="pay()" class="w3-button w3-blue w3-round">request funds</button>
      </div>
    </div>
  </div>
</template>

<script>
import { Remittance, web3 } from '@/web3-loader.js'
import { keccak256 } from 'js-sha3'

export default {
  data () {
    return {
      sendRemittance: true,
      accounts: [],
      from: '',
      instance: null,
      amount: 0,
      exchangerAddress: '',
      secret1: '',
      secret2: '',
      secretsHash: '',
      remittanceSuccesfullySent: false,
      contractBalance: '0'
    }
  },

  methods: {
    updateContractBalance () {
      web3.eth.getBalance(this.instance.address, (err, balance) => {
        if (err) {
          console.log(err)
        } else {
          this.contractBalance = Number(web3.fromWei(balance, 'ether'))
        }
      })
    },
    send () {
      var secret1 = this.randomString()
      var secret2 = this.randomString()

      console.log(secret1)
      console.log(secret2)

      var secretsHash = '0x' + keccak256(secret1 + secret2)
      console.log(secretsHash)

      var exchangerHash = keccak256(this.exchangerAddress)

      this.instance.sendRemittance(secretsHash, exchangerHash, { from: this.from, value: web3.toWei(this.amount, 'ether') })
      .then((result) => {
        if (result) {
          this.remittanceSuccesfullySent = true
          this.secretsHash = secretsHash
          this.secret1 = secret1
          this.secret2 = secret2
          this.updateContractBalance()
        } else {
          console.log('error sending remittance')
        }
      })
    },
    randomString () {
      var text = ''
      var possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'

      for (var i = 0; i < 32; i++) {
        text += possible.charAt(Math.floor(Math.random() * possible.length))
      }

      return text
    },
    pay () {
      this.instance.pay(this.secret1, this.secret2, { from: this.from })
      .then((result) => {
        if (result) {
          this.updateContractBalance()
        } else {
          console.log('error sending remittance')
        }
      })
    }
  },

  created () {
    Remittance.deployed().then((instance) => {
      this.instance = instance
      this.updateContractBalance()
    })

    web3.eth.getAccountsPromise().then((accounts) => {
      this.accounts = accounts
      this.from = accounts[0]
    })
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

.from-row select {
  max-width: 500px;
  margin: 0 auto;
}

.send-row button {
  min-width: 300px;
}

</style>
