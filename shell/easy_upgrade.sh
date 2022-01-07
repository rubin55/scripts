#!/bin/sh
MODULE_LIST=`python -c "for dist in __import__('pkg_resources').working_set: print dist.project_name.replace('Python', '')"`
case "$1" in
	upgrade)
	for i in "$MODULE_LIST"; do
		easy_install -U $i
	done;
	;;
	list)
	echo $MODULE_LIST
	;;
	*)
	echo $"Usage: $0 {upgrade|list}"
esac
