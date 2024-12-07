import React from 'react';
import Web3 from './web3';
import './App.css';
import ShareDrive from './contract';

class App extends React.Component {
  state = {
    whoami: ''
  };
  async componentDidMount() {
    const whoami = await ShareDrive.methods.whoami().call();
    this.setState({ whoami });
  }
  render() {
    return (
      <div className="App">
        <header className="App-header">
          <p>
            The owner address is:  {this.state.whoami}
          </p>
        </header>
      </div>
    );
  }
}

export default App;