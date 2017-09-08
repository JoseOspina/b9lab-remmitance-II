<template>
  <div class="w3-container">
    <h1>Remittances App</h1>
    <h3>Total App Balance {{ contractBalance }} eth</h3>
    <div class="w3-row from-row">
      <label class=""><b>From:</b></label>
      <select class="w3-input" v-model="from">
        <option v-for="account in accounts">
          {{ account }}
        </option>
      </select>
    </div>

    <div class="w3-row">
      <h5>address balance: {{ fromBalance.toFixed(2) }} eth</h5>
    </div>

    <div class="w3-row w3-margin-top">
      <button class="w3-col s6 w3-bottombar w3-button" :class="{'w3-border-blue': sendRemittance}"
        @click="sendRemittance = true">
        Send
      </button>
      <button class="w3-col s6 w3-bottombar w3-button" :class="{'w3-border-blue': !sendRemittance}"
        @click="switchToReceive()">
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
          <select class="w3-input" v-model="exchangerAddress">
            <option v-for="account in accounts">
              {{ account }}
            </option>
          </select>
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
        <label><b>Secrets Hash</b></label>
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

      <div v-if="paymentProcessed" class="">
        <div v-if="paymentSuccesfull" class="w3-panel w3-padding w3-green w3-round">
          Payment succesfully made!
        </div>
        <div v-if="!paymentSuccesfull" class="w3-panel w3-padding w3-red w3-round">
          Error while processing payment transaction
        </div>
      </div>
    </div>

    <hr>
    <h2>Remittances History</h2>
    <table class="w3-table w3-bordered w3-centered">

      <tr>
        <th>State</th>
        <th>Amount (eth)</th>
        <th class="hashCol">id</th>
        <th class="hashCol">Ex. Hash</th>
      </tr>

      <tr v-for="remittance in remittancesHistory">
        <td class="w3-tag w3-padding"
          :class="{'w3-green': isPaid(remittance.args.secretsHash), 'w3-red': !isPaid(remittance.args.secretsHash)}">
          <b>{{ isPaid(remittance.args.secretsHash) ? 'PAID' : 'PENDING' }}</b>
        </td>
        <td>{{ Number(web3.fromWei(remittance.args.amount, 'ether')) }}</td>
        <td class="hashCol">{{ remittance.args.secretsHash }}</td>
        <td class="hashCol">{{ remittance.args.exchangerAddressHash }}</td>
      </tr>

    </table>

  </div>
</template>

<script>
import { Remittance, web3 } from '@/web3-loader.js'

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
      contractBalance: '0',
      paymentProcessed: false,
      paymentSuccesfull: true,
      fromBalance: 0,
      remittancesHistory: [],
      paymentsHistory: []
    }
  },

  computed: {
    web3 () {
      return web3
    }
  },

  methods: {
    switchToReceive () {
      this.sendRemittance = false
      this.secret1 = ''
      this.secret2 = ''
      this.secretsHash = ''
      this.exchangerAddressHash = ''
    },
    updateContractBalance () {
      web3.eth.getBalance(this.instance.address, (err, balance) => {
        if (err) {
          console.log(err)
        } else {
          this.contractBalance = Number(web3.fromWei(balance, 'ether'))
        }
      })
    },
    updateFromBalance () {
      web3.eth.getBalance(this.from, (err, balance) => {
        if (err) {
          console.log(err)
        } else {
          this.fromBalance = Number(web3.fromWei(balance, 'ether'))
        }
      })
    },
    send () {
      var secret1 = this.randomString()
      var secret2 = this.randomString()

      console.log(secret1)
      console.log(secret2)

      var secretsHash = web3.sha3(secret1 + secret2)
      console.log(secretsHash)

      var exchangerHash = web3.sha3(this.exchangerAddress, {encoding: 'hex'})
      console.log(exchangerHash)

      this.instance.sendRemittance(secretsHash, exchangerHash, { from: this.from, value: web3.toWei(this.amount, 'ether') })
      .then((result) => {
        if (result) {
          this.remittanceSuccesfullySent = true
          this.secretsHash = secretsHash
          this.secret1 = secret1
          this.secret2 = secret2
          this.updateContractBalance()
          this.updateFromBalance()
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
          this.paymentProcessed = true
          this.paymentSuccesfull = true
          this.secret1 = ''
          this.secret2 = ''
          this.secretsHash = ''
          this.exchangerAddressHash = ''
          this.updateContractBalance()
          this.updateFromBalance()
          setTimeout(() => {
            this.paymentProcessed = false
            this.paymentSuccesfull = false
          }, 5000)
        } else {
          console.log('error sending remittance')
          this.paymentSuccesfull = false
        }
      }).catch((err) => {
        this.paymentProcessed = true
        this.paymentSuccesfull = false
        console.log(err)
      })
    },
    isPaid (secretsHash) {
      for (var ix in this.paymentsHistory) {
        if (this.paymentsHistory[ix].args.secretsHash === secretsHash) {
          return true
        }
      }

      return false
    },
    configureEvents () {
      this.instance.LogRemittanceSent({}, { fromBlock: 0 }).watch((err, event) => {
        if (err) {
          console.log(err)
        }
        this.remittancesHistory.push(event)
      })

      this.instance.LogRemittancePaid({}, { fromBlock: 0 }).watch((err, event) => {
        if (err) {
          console.log(err)
        }
        this.paymentsHistory.push(event)
      })
    }
  },

  watch: {
    from () {
      this.updateFromBalance()
    }
  },

  created () {
    Remittance.deployed().then((instance) => {
      this.instance = instance
      this.updateContractBalance()
      this.configureEvents()
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

.hashCol {
  max-width: 200px;
  overflow-x: auto;
}

</style>
