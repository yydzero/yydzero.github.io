==> ResetExprContext actually only resets memory context of expr context;
	PostgreSQL would reset memory context each time ResetExprContext is called,
	while GPDB has an optimization to only reset memory context when the holding
	memory is larger than 50000KB;

	MemoryContextReset would delete blocks from alloc set, and only leave one
	block(keeper block) remained, each block would be memseted to 0x7F in debug
	build;

	AllocSetAlloc would alloc a new block if current available space is not
	enough for the request, before allocating block, it would carve the
	available space of current block(end_ptr - free_ptr) into freelist of the
	memory context, and new allocated block would be inserted as the first block
	of the block list;

	From low address to high address, the contents of a block should be:
	block header(ALLOC_BLOCKHDRSZ large), chunk header(ALLOC_CHUNKHDRSZ, 56 in general),
	chunk data, chunk header, chunk data, etc. free_ptr of block points to the
	end of the last chunk data, end_ptr points to end of block; palloc would
	return one chunk, and the returned address is the chunk data, not address of
	chunk header;

	Normally, there is an allignment of size for the requested size, for
	example, if requested size is 56, then a chunk of 64 would be returned, and
	in debug build, the 57th byte of the chunk data would be set to 0x7E('~' in ascii),
	when deleting this block or reseting this block, there would be
	AllocSetCheck in debug build, which would check the memory health of the
	block, including the '~' here; if not as expected, error would be
	raised(e.g, detected write past chunk end);

==> find a content in memory, use `find <start_addr> <end_addr> pattern` in gdb
