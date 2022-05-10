#!/bin/sh

parameters="`echo $@`"
variables="`echo $parameters \
    | sed -e 's/--/\^\^/g' \
    | sed -e 's/\(=[],[,A-Za-z0-9,"+~!@#$%&:/\ {}()-]*\)/\<\1\>/g' \
    | sed -e :a -e 's/<[^>]*>//g;/</N;//ba' \
    | sed -e 's/\^\^/ /g' \
    `"
values="`echo $parameters \
    | sed -e 's/\(--[a-z]*=\)/\<\1\>/g' \
    | sed -e :a -e 's/<[^>]*>//g;/</N;//ba' \
    `"

echo variables = $variables

for variable in $variables; do
    value="`echo $parameters \
        | sed -e 's/--/\^\^/g' \
        | sed -e "s/.*$variable=\([^^]*\).*/\1/g"
        `"
    echo $variable=$value
done
