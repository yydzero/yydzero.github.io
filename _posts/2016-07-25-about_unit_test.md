## About Unit Test
* Generally speaking, behave test would cover the code logic, while unit test would focus on monitoring system fault such as memory and network at specific code point;
* Simple assertion in code can be declared by Assert, while complicated code logic which is intentionally writen should be guaranteed by unit test, to handle special corner case, which is hard to be manufactured from high level behave test;
* Unit test would also take care of function logic, since compared with behave test, it wins on fast feadback; it is said that unit test is part of the developers documentation, for the expected output of a function given specific inputs; unit test focus on what the function aimed for.
* When using cmockery testing framework, we MUST explictly do type casting when calling will_assign_value() to coerce to exactly same type as mocked function.