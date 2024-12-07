import React from 'react';
import Web3 from './web3';
import './App.css';
import ShareDrive from './contract';

class App extends React.Component {
  state = {
    driveOwner: '',
    listDir: '',
    viewCurrentDirName: '',
    readFile: '',
    viewFilePermission: '',
    userCount: 0,
    viewUserList: '',
    whoami: ''
  };
  async componentDidMount() {
    const driveOwner = await ShareDrive.methods.driveOwner().call();
    const listDir = await ShareDrive.methods.listDir().call();
    const viewCurrentDirName = await ShareDrive.methods.viewCurrentDirName().call();
    const readFile = await ShareDrive.methods.readFile().call({_filename: ""});
    const viewFilePermission = await ShareDrive.methods.viewFilePermission().call({_filename: "", _addr: 0});
    const userCount = await ShareDrive.methods.userCount().call();
    const viewUserList = await ShareDrive.methods.viewUserList().call();
    const whoami = await ShareDrive.methods.whoami().call();
    this.setState({ driveOwner, listDir, viewCurrentDirName, readFile, viewFilePermission, userCount, viewUserList, whoami});
  }
  render() {
    return (
      <div className="App">
        <header className="App-header">
          <p>
            The user count is:  {this.state.viewCurrentDirName} 
          </p>
        </header>
      </div>
    );
  }
}

export default App;