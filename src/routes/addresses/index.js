import { h, Component } from 'preact';
import { route } from 'preact-router';
import style from './style';

export default class Addresses extends Component {
	state = {
	};

	componentDidMount() {
	}

	componentWillUnmount() {
	}

  getAddresses = () => {
    return this.props.addresses
      ? this.props.addresses.split(' ')
      : []
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

	render({ addresses }, { ethAddress }) {
		return (
			<div class={style.profile}>
				<h1>Addresses: {this.getAddresses().join(' ')}</h1>
        <form onSubmit={this.handleSubmit}>
          <label>Ethereum Address: <input name="ethAddress" value={ethAddress} onChange={this.handleChange} /></label>
          <input type="submit" value="Submit" />
        </form>
			</div>
		);
	}
}
