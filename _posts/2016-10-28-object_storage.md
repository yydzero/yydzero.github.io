### Object Storage
* Each object typically includes the data itself, a variable amount of metadata, and a globally unique identifier.
* Object storage explicitly separates file metadata from data to support additional capabilities: as opposed to fixed metadata in file systems (filename, creation date, type, etc.), object storage provides object-level metadata in order to:
	* Capture application-specific or user-specific information for better indexing purposes
	* Support data management policies (e.g. a policy to drive object movement from one storage tier to another)
	* Centralize management of storage across many individual nodes and clusters
* Additionally, in some object-based file system implementations, the file system clients only contact metadata servers once when the file is opened and then get content directly via object storage servers (vs. block-based file systems which would require constant metadata access)
* Object-based storage devices (OSD):
	* Instead of providing a block-oriented interface that reads and writes fixed sized blocks of data, data is organized into flexible-sized data containers, called objects
	* The command interface includes commands to create and delete objects, write bytes and read bytes to and from individual objects, and to set and get attributes on objects
* Object-based file systems:Some distributed file systems use an object-based architecture, where file metadata is stored in metadata servers and file data is stored in object storage servers. File system client software interacts with the distinct servers, and abstracts them to present a full file system to users and applications