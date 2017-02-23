## free output
* `total`: Your total (physical) RAM (excluding a small bit that the kernel permanently reserves for itself at startup); that's why it shows ca. 11.7 GiB , and not 12 GiB, which you probably have.
* `used`: memory in use by the OS.
* `free`: memory not in use.
* `total` = `used` + `free`

* `shared` / `buffers` / `cached`: This shows memory usage for specific purposes, these values are included in the value for used.
* The second line gives first line values adjusted. It gives the original value for used minus the sum `buffers` + `cached` and the original value for free plus the sum `buffers` + `cached`, hence its title. These new values are often more meaningful than those of first line.

* The last line (`swap`:) gives information about swap space usage (i.e. memory contents that have been temporarily moved to disk).

* `caches` will be freed automatically if memory gets scarce.
* `used` - `buffers` - `cached` is the physical memory really used by applications; In the event an application needs more memory, it can be taken either from free memory or from `cached/buffered`
* `buffers` is also referred to as `buffer cache`, while `cache` is referred to as `page cache`
* difference between `buffer` and `cache`:
> The `page cache` caches pages of files to optimize file I/O. The `buffer cache` caches disk blocks to optimize block I/O. Prior to Linux kernel version 2.4, the two caches were distinct: Files were in the page cache, disk blocks were in the buffer cache. Given that most files are represented by a filesystem on a disk, data was represented twice, once in each of the caches. This is simple to implement, but with an obvious inelegance and inefficiency. Starting with Linux kernel version 2.4, the contents of the two caches were unified. The virtual memory subsystem now drives I/O and it does so out of the page cache. If cached data has both a file and a block representation — as most data does — the buffer cache will simply point into the page cache; thus only one instance of the data is cached in memory. The page cache is what you picture when you think of a disk cache: It caches file data from a disk to make subsequent I/O faster. The buffer cache remains, however, as the kernel still needs to perform block I/O in terms of blocks, not pages. As most blocks represent file data, most of the buffer cache is represented by the page cache. But a small amount of block data isn't file backed — metadata and raw block I/O for example — and thus is solely represented by the buffer cache.

* difference between block size and page size
> page size concerns memory; block size concerns storage space on a filesystem. Page size is, I believe, architecture-dependent, 4k being the size for IA-32 (x86) machines. For IA-64 architecture, I'm pretty sure you can set the page size at compile time, with 8k or 16k considered optimal. Again, I'm not positive, but I think Linux supports 4,8,16, and 64k pages. Block size is a function of the filesystem in use. Many, if not all filesystems allow you to choose the block size when you format, although for some filesystems the block size is tied to/dependent upon the page size. Minimun block size is usually 512 bytes, the allowed values being determined by the filesystem in question. The PAGE size and the BLOCK size may or may not be the same size.
* so generally speaking, for kernel later than 2.4, `cached` is usally larger than `buffers` of `free` output
* `getconf PAGESIZE` can give us the page size of the OS(4K generally); normally, page size is fixed according to the architecture, while for some architectures, you can choose the page size while compiling kernel; block size is dependent on the file system, you can choose the block size while formating the file system; block size is usally a multiplier of page size, for performance reasons.