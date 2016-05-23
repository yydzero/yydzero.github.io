###How to mock a function in same tested file?
* using weak \__attrubue__, which means the function can be overriden; not perfect for just test usage;
* assembler feature to wrap the function call? NO
* use MACRO combined with function pointer

```
-- file.c
int bar(int x)
{
	int result = 0;
	
	for (int i = 0; i < 10; i++)
	{
		result += foo(i + x);
	}
	
	return result;
}

#ifdef TEST
int (*test_foo)(int x) = NULL;
int foo__(int x)
#else
int foo(int x)
#endif
{
	int result;
	
	/* Do something complex to calculate the result */
	
	return result;
}

#ifdef TEST
int foo(int x)
{
	if (test_foo) return test_foo(x);
	return foo__(x);
}
#endif

-- test.c
#define TEST
#include "file.c"

int __wrap_foo(int x)
{
	return 0;
}

int unittest(void)
{
	test_foo = __wrap_foo;
	ASSERT(bar(3) == 0);		
}
```
* there is a way to make the above method look better, by using assembly to subsitute the macros, and define the assembly to a macro, but it is platform-dependent;
* in the documentation of GNU linker(ld), it says: for undefined references, linker would try to resolve them to wrappers; here "undefined reference" means the function body is not defined in the same file, that means, even if there is a extern declaration for the function, it is still an undefined reference; for the "defined reference", assembler would resolve the calling relationship before linker goes to work;