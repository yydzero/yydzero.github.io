### hash_search in GPDB
* there are two APIs for hash table manupulation:
	* hash_search
	* hash_search_with_hash_value
* For hash_search_with_hash_value, the hashvalue parameter must have been calculated with get_hash_value, which would call invoke the function pointer hash in struct HTAB
* hash_search would compute the bucket from the hashvalue, and then each bucket would be organized into several segments, segment_num and segment_ndx would be computed from bucket number
* For REMOVE action of hash_search, the returned element would be linked into the freelist of the whole hash table, note that there is no freelist for each bucket, there is only one freelist for whole hash table, hence for ENTER action of hash_search, it would be possible to allocate an element from the freelist which is just returned by previous REMOVE action, even though their hashvalues are not the same, nor do they belong to same one bucket.