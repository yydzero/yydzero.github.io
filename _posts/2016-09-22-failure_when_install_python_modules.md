## failure when install python modules
* Meanings of PYTHONHOME and PYTHONPATH:
	* PYTHONHOME refers to the home dir of python, if python binary is in /usr/bin/python, then PYTHONHOME should be /usr; if python binary is in /data/home/gpadmin/python2.7/bin/python, then PYTHONHOME should be /data/home/gpadmin/python2.7, that is to say, PYTHONHOME should be the dir which is two levels upper than python binary;
	* PYTHONPATH is the 'PATH' variable to find modules when import, usally, modules installed by 'pip install' or 'python setpy.py build & python setpy.py install' is under $PYTHONHOME/lib/python2.7/site-packages;
	* when meeting ImportError: No Module Named xxx, we should check whether the module can be found in the $PYTHONPATH, and **the user has permission to the dirs there**;
	* usally, modules installed by 'pip install' would have a dir under site-packages, while modules installed by 'python setup.py install' would install a .egg file there, both are fine;
* If compiling python from source code, by default, it would not build shared library, we have to specify it during configure: ./configure --enable-shared