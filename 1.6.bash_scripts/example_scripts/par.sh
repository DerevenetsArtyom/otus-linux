#!/usr/bin/env bash
# Script for vars and params

# Check parameters. Need at least one parameter
if [[ -n "$1" ]]
then
  echo "Everything is fine, continue!"
  echo ""
else
  echo "No parameters found. Exit..."
  exit
fi

echo '$@ = '$@
echo '$* = '$*
echo '$0 = '$0
echo '$1 = '$1
echo '$# = '$#
echo '$$ = '$$

echo '$? = '$?

# Comment next line to see how example works
ls /ebc
echo '$? = '$?