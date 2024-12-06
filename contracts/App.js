import React, { useEffect, useState } from 'react';
import Web3 from 'web3';
import './App.css';

import ShareDrive from './artifacts/ShareDrive.json'; 

const App = () => {
    const [files, setFiles] = useState([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [web3, setWeb3] = useState(null);
    const [contract, setContract] = useState(null);
    const [currentDir, setCurrentDir] = useState('');

    const contractAddress = '0x5B38Da6a701c568545dCfcB03FcB875f56beddC4'; // Replace with your deployed contract address

    useEffect(() => {
        const init = async () => {
            // Connect to Ethereum provider
            const web3Instance = new Web3(window.ethereum);
            setWeb3(web3Instance);

            // Request account access if needed
            await window.ethereum.request({ method: "eth_requestAccounts" });

            // Create a contract instance
            const contractInstance = new web3Instance.eth.Contract(ShareDrive.abi, contractAddress);
            setContract(contractInstance);

            // Load files on component mount
            loadFiles();
        };

        init();
    }, []);

    const loadFiles = async () => {
        if (contract) {
            try {
                const filesList = await contract.methods.listDir().call();
                setFiles(filesList[1]); // Assuming the second element contains file names
                setCurrentDir(await contract.methods.viewCurrentDirName().call());
            } catch (error) {
                console.error("Error loading files:", error);
            }
        }
    };

    const handleFileChange = (event) => {
        const selectedFiles = Array.from(event.target.files);
        setFiles(prevFiles => [...prevFiles, ...selectedFiles]);
    };

    const handleUpload = async () => {
        if (contract && files.length > 0) {
            for (const file of files) {
                const reader = new FileReader();
                reader.onloadend = async () => {
                    const content = reader.result;
                    try {
                        // Call the createFile function on the smart contract
                        await contract.methods.createFile(file.name, content).send({ from: window.ethereum.selectedAddress });
                        console.log(`Uploaded: ${file.name}`);
                    } catch (error) {
                        console.error("Error uploading file:", error);
                    }
                };
                reader.readAsText(file); // Read file as text
            }
            // Reset files after upload if needed
            setFiles([]);
            loadFiles(); // Reload files after upload
        }
    };

    const filteredFiles = files.filter(file => 
        file.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="App">
            <div className="top-bar">
                <h1>Blockchain Storage</h1>
                <h2>Current Directory: {currentDir}</h2>
            </div>

            <div className="container"> 
                <div className="file-list-title"> Files Available</div>
                <div className="file-list-container">
                    <div>
                        <div id="listed-item"> Listed item</div>
                        <input 
                            type="text" 
                            placeholder="Search files" 
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)} 
                        />
                    </div>
                    <div className="file-list-container2">
                        <ul className="file-list">
                            {filteredFiles.map((file, index) => (
                                <li key={index}>{file}</li>
                            ))}
                        </ul>
                    </div>
                </div>    
            </div>

            <div className="container">
                <div id="Upload">
                    <h2 id="Upload-Files">Upload Files</h2>
                    <input 
                        type="file" 
                        id="fileInput" 
                        multiple 
                        onChange={handleFileChange} 
                    />
                </div>
            </div> 
        </div>
    );
}

export default App;
