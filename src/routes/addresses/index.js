import { h, Component } from 'preact';
import { route } from 'preact-router';
import style from './style';

export default class Addresses extends Component {
	state = {
	};

	componentDidMount() {
    const addresses = this.getAddresses()
    const priceFetch = fetch('https://api.coinmarketcap.com/v1/ticker/ethereum/').then(this.handlePriceResponse)
    const balanceFetches = addresses.map((address) => fetch(`https://api.blockcypher.com/v1/eth/main/addrs/${address}/balance`).then(this.handleAddressResponse(address)))
	}

	componentWillUnmount() {
	}

  getAddresses = () => {
    return this.props.addresses
      ? this.props.addresses.split(' ')
      : []
  };

  handleAddressResponse = (address) => (response) => {
    const self = this;
    response.json()
      .then((json) => self.setState({ [address]: json }));
  };

  handlePriceResponse = (response) => {
    const self = this;
    response.json()
      .then((json) => {
        if (json && json[0] && json[0].price_usd) {
          self.setState({ ethPrice: json[0].price_usd });
        }
      })
  };

  handleChange = (e) => {
    this.setState({
      [e.target.name]: e.target.value
    });
  };

  handleSubmit = (e) => {
    e.preventDefault();
    if (this.state.ethAddress) {
      const addresses = this.getAddresses().concat([this.state.ethAddress])
      route(`/addresses/${addresses.join(' ')}`);
    }
  };

  renderRow = (address) => {
    const result = this.state[address];
    const price = this.state.ethPrice;
    return result && price
      ? <tr><td>{address}</td><td>{result.final_balance / 1000000000000000000}</td><td>{price}</td><td>{result.final_balance * price / 1000000000000000000}</td></tr>
      : <tr><td colspan="3">Loading...</td></tr>
  };

	render(props, state) {
    const { ethAddress, ethPrice } = state
    const addresses = this.getAddresses()
    const totalBalance = addresses.length && addresses.reduce((m, address) => (m + (state[address] && state[address].final_balance || 0)), 0) / 1000000000000000000
    const totalUsd = totalBalance && ethPrice && totalBalance * ethPrice
    const table = !!addresses.length && <table>
      <thead><th>Address</th><th>Balance</th><th>Price</th><th>Total</th></thead>
      {addresses.map(this.renderRow)}
      <tfoot><th>Total</th><th>{totalBalance}</th><th>--</th><th>{totalUsd}</th></tfoot>
    </table>
		return (
			<div class={style.profile}>
				<h1>Addresses: {this.getAddresses().join(' ')}</h1>
        <form onSubmit={this.handleSubmit}>
          <label>Add Ethereum Address: <input name="ethAddress" value={ethAddress} onChange={this.handleChange} /></label>
          <input type="submit" value="Submit" />
        </form>
        {table}
			</div>
		);
	}
}
