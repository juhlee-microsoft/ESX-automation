# Inputs are 1c, 10c, and 25c
# it returns like below for each cent value.
# MakeChange(10) == 1 ( 1 x 10c )
# MakeChange(100) == 4 ( 4 x 25c )
# MakeChange(11) == 2 ( 1x10c + 1x1c )
# MakeChange(3) = 3
# add all quotient from each step for the return value.

function MakeChange() {
    output=""
    cents=$1
    echo "Got $cents"
    # if input is bigger than 25
    if [[ $cents -ge 25 ]]; then
        quo=$((cents / 25))
        rem=$((cents % 25))
        output=$quo
        if [[ $rem -ge 10 ]]; then
            quo=$((rem/10))
            rem=$((rem%10))
            output-$((output + $quo))
        fi
        output=$((output+$rem))
    elif [[ $cents -lt 25 && $cents -ge 10 ]]; then
        quo=$((cents / 10))
        rem=$((cents % 10))
        output=$((quo + $rem))
    else
    output=$cents
    fi
    echo $output
}

MakeChange $1
