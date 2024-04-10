#!/bin/bash
echo "Today is:"
cal
date

env_var="123456"
echo $env_var

echo "enter first string"
read st1

echo "enter 2nd string"
read st2

if [ $st1 == $st2];
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