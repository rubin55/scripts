#!/bin/sh

# parseParameters() - Handles parsing of given parameters starting with "--".
# Optionally supports a $mandatory and a $optional list, which allows validity
# and scope checking. The $mandatory variable stores parameters that MUST be 
# passed. The $optional variable stores parameters which MAY be passed. Not
# specifying $mandatory or $optional means any parameter that starts with "--"
# will be evaluated. You can pass just the parameter name, like --test, or
# you can specify --test=foobar. The first variant sets a variable $test to 1.
# The second variant sets $test to "foobar". Example:
# mandatory="foo bar" ; optional="baz" ; parseParameters $@  
parseParameters(){
    if [ "$debug" = true ]; then echo calling parseParameters with: $@ >> $logfile; fi

    parameters="`echo $@ \
        | sed -e 's/--/\^\^/g' \
        | sed -n 's/[^^]*//p' \
        | sed -e 's/\^\^/--/g' \
        `"
    variables="`echo $parameters \
        | sed -e 's/--/\^\^/g' \
        | sed -e 's/\(=[],[,A-Za-z0-9,."+~!@#$%&:/\ {}()_-]*\)/\<\1\>/g' \
        | sed -e :a -e 's/<[^>]*>//g;/</N;//ba' \
        | sed -e 's/\^\^/ /g' \
        | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
        `"
    values="`echo $parameters \
        | sed -e 's/\(--[a-z]*=\)/\<\1\>/g' \
        | sed -e :a -e 's/<[^>]*>//g;/</N;//ba' \
        | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
        `"
    
    if [ "$mandatory" ]; then
        for item in $mandatory; do
            if [ ! "`echo "$variables" | grep "$item"`" ]; then
                required="$required --$item"
            fi
        done
    fi

    if [ "$mandatory" -a "$optional" ]; then
        for variable in $variables; do
            value="`echo $parameters \
                | sed -e 's/--/\^\^/g' \
                | sed -e "s/.*$variable=\([^^]*\).*/\1/g" \
                | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
                `"
            if [ -z "$value" ]; then value=1; fi
            if [ "`echo "$optional" | grep "$variable"`" ]; then
                export "$variable=$value"
            elif [ "`echo "$mandatory" | grep "$variable"`" ]; then
                export "$variable=$value"
            else
                illegal="$illegal --$variable "
            fi
        done
    elif [ "$mandatory" ]; then
        for variable in $variables; do
            value="`echo $parameters \
                | sed -e 's/--/\^\^/g' \
                | sed -e "s/.*$variable=\([^^]*\).*/\1/g" \
                | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
                `"
            if [ -z "$value" ]; then value=1; fi
            if [ "`echo "$mandatory" | grep "$variable"`" ]; then
                export $variable=$value
            else
                illegal="$illegal --$variable "
            fi

        done
    elif [ "$optional" ]; then
        for variable in $variables; do
            value="`echo $parameters \
                | sed -e 's/--/\^\^/g' \
                | sed -e "s/.*$variable=\([^^]*\).*/\1/g" \
                | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
                `"
            if [ "`echo "$optional" | grep "$variable"`" ]; then
                export $variable=$value
            else
                illegal="$illegal --$variable "
            fi
        done
    else 
        for variable in $variables; do
            value="`echo $parameters \
                | sed -e 's/--/\^\^/g' \
                | sed -e "s/.*$variable=\([^^]*\).*/\1/g" \
                | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
                `"
            if [ -z "$value" ]; then value=1; fi
            export $variable=$value
        done
    fi

    illegal="`echo $illegal | sed '/^$/d'`"
    if [ ! -z "$illegal" ]; then
        echo "illegal parameters passed: $illegal"
    fi

    required="`echo $required | sed '/^$/d'`"
    if [ ! -z "$required" ]; then
        echo "required parameters missing: $required"
    fi

    if [ "$illegal" -o "$required" ]; then
        exit 1
    fi
}

mandatory="foo bar"
optional="baz"
parseParameters $@
echo foo: $foo
echo bar: $bar
echo baz: $baz

