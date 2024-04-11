#!/bin/bash
name=('umi' 'ming' 'fede')
echo "${name[0]}"

echo "Today is:"
cal
date

env_var="123456"
echo $env_var

echo "enter first string"
read st1

echo "enter 2nd string"
read st2

if [ $st1 == $st2 ];
then 
     echo "strings match"
else 
     echo "strings dont match"
fi

car=('mercedes' 'Toyota' 'Tesla')

echo "${car[@]}"

names=("Tim" "Jim" "Ming")
age=(12 24 31 40)
 if  [ ${#names[@]} -eq ${#age[@]} ]; then
   
echo "length is the same"
else
 echo "not the same"
 fi
function  funcheck()
{
    verticalValue="I LOVE MAC"

}
 funcheck
 echo $verticalValue

 count=10
 if [$count -eq 10]
 then
      echo "the condition is true"
else 
       echo "the condition is false"
fi
and operation  && or -a
or operation -r or ||

: '  
number=2
while [ "$number -eq 10"]
do
  echo "$number"
  number=$(( number+1 ))
done '

name=('umi' 'ming' 'fede')
echo "${name[0]}"

echo "Enter directory name to check if directory exists"
read direct
if [ -d "direct" ] 
then 
     echo "$direct exists"
else 
     echo "$direct does not exist"
fi
