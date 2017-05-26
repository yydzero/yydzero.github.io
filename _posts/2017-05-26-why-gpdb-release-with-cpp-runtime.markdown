---
layout: post
title: "Why GPDB releases with C++ runtime"
author: Adam
date: 2017-05-26 16:00:00 +0800
comments: true
---

因为即使C++标准相同, ABI也不一定.

	#include <iostream>
	
	int main()
	{
	    std::string str = "Hello, world!\n";
	    std::cout << str;
	
	    return 0;
	}

这样一个简单的C++程序, 用g++ 6.2.0和C++98标准编译后的二进制文件放到CentOS 5上运行会提示:

	./a.out: /usr/lib64/libstdc++.so.6: version `GLIBCXX_3.4.21' not found (required by ./a.out)

又没有用什么很新的特性, 还指定了C++98标准, CentOS上的g++ 4.1.2当然也支持C++98, 为什么还会报错?

因为从GCC 5.1开始[1], `std::string`和`std::list`使用了新的C++11的ABI, **即使你显式指定使用老标准**.

解决方法不难, 手动将\_GLIBCXX\_USE\_CXX11\_ABI宏置0就可以了, 当然, 为了避免更多的麻烦(谁知道哪儿还有坑呢?), 你也可以自带运行时发布, 感谢GCC Runtime Library Exception[2], 即使私有软件也是可以的.

为什么GCC要这么做呢? 我是不大理解, 官方文档说因为这样就保证可以和C++11的代码链接了, **即使你显式指定使用老标准**, 惊不惊喜?

### ref:
1, [https://gcc.gnu.org/onlinedocs/libstdc++/manual/using\_dual\_abi.html](https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_dual_abi.html)  
2, [https://www.gnu.org/licenses/gcc-exception-3.1.en.html](https://www.gnu.org/licenses/gcc-exception-3.1.en.html)  
3, [http://adam8157.info/blog/2017/05/understanding-\_GLIBCXX\_USE\_CXX11\_ABI/](http://adam8157.info/blog/2017/05/understanding-_GLIBCXX_USE_CXX11_ABI/)
