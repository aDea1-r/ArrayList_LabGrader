@echo off
:: accepts first parameter as class file name, and second as class directory
cd %2
java %1 >>"%1.txt"

exit