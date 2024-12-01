# CSCI2730-Project
***
## Functions to be implemented in FileSystem.sol (or maybe in another file)

fileMenu() --> interface to call below functions (using FileStorage.sol functions, refer to createFile())    
    - renameFile()   
    - writeFile()  
    - appendToFile()  
    - deleteFile()  
    - changeFilePermission()  
    - readFile()  
    - viewFilePermission()  

listDirectory() --> broken, can be used to show files and child directories in a directory when clicked

directoryMenu() --> interface to call below functions
    - createDirectory() -- done  
    - renameDirectory() -- done  
    - deleteDirectory()  
    - createFile -- done  

userMenu() --> interface to call below functions (maybe show in a side panel?) (still thinking)
    - addUser()
    - renameUser()
    - deleteUser()
