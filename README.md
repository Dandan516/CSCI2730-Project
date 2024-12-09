# Project Description: 

The project is about implementing a web-based Dapps that served as file system 

## Smart contracts:

FileStorage.sol
ShareDrive.sol
UserSystem.sol

Code description:

## FileStorage.sol

struct File{
	string filename;
	string content;
	bool exist;
	address fileOwner;
}

modifier:
fileExists()           : check whether the filename exist or not
notExceedFileLimit()   : check whether the total number of file exceed the limit or not (50)

Functions:

createFile()           : create a file with file name, owner, content 
renameFile()           : rename file
appendToFile()         : Add new content to file
writeFile()            : Rewrite the file
deleteFile()           : Delete the file
changeFilePermission() : Change to mode of access ( read, read & append , read, append & write )
readFile()             : read a file
viewFilePermisson()    : return a mode ( read, read & append , read, append & write )
listFile()             : return a list of file with filename
getMode()              : return the mode number
getFileOwner           : return the owner address



## UserSystem.sol

struct User {
	address addr;
	uint id;
	string username;
	bool exists;
}

modifier:
onlyDriveOwner  : check whether the function caller is performed by owner
userExists      : check whether the address exist

Functions:

addUser()         : A whitelist function that grant permission by the address
renameSelf()      : rename a user 
removeUser()      : remove a user by address, can only be done by Owner
viewUserList()    : return a list of users access to the drive
whoami()          : return the username of the caller


## ShareDrive.sol

struct Directory{
	string dirName;
	uint id;          //root directory id = 1
	bool exists;
	uint parent;  
        uint[] children;
        FileStorage currentFiles;
}

modifier:
dirNameValid()             : check whether a directory is valid (unique name, limited length, alphanumeric characters)
onlyFileOwner()            : check whether the function caller is performed by owner
notExceedGlobalFileLimit() : check whether total number of file exceed the limit or not (1000)
notExceedDirLimit()        : check whether total number of directory exceed the limit or not (10)

Functions: 

createDir()             : create directory
renameDir()             : rename current
deleteDir()             : delete current directory and navigate back to parent directory
goUp()                  : Navigate to parent directory
goDown()                : Navigate to a dedicated child directory
createFile()            : Define in FileStorage
renameFile()            : Define in FileStorage
appendToFile()          : Define in FileStorage
writetoFile()           : Define in FileStorage
deleteFile()            : Define in FileStorage, only file owner can delete it
readFile()              : Define in FileStorage
listDir()               : return All child directory and file 
viewCurreentDirName()   : return the directory name
changeFilePermission()  : change the permission of access(mode) of file, only file owner can change it
viewFilePermssion       : return the permission of access of a user
changeDir()             : change to other directory
