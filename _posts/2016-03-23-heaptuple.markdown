==> heap_form_tuple would convert values and nulls arrays into a heap tuple,
	it would call heaptuple_form_to to compute the length, and call
	heap_fill_tuple to really fill in the data;
