#!/bin/bash
trap 'find . -maxdepth 1 -name "*TEMPFILE*" -exec rm -f {} \;' INT HUP TERM

#called when there is an error with a MESSAGE.
#send message to stdout.
#Exits with value 1 (unsuccessful)
error(){
    echo "ERROR: $*" >&2
    exit 1
}

#removes all tempfiles. called throughout program
remove(){
    find . -maxdepth 1 -name "*TEMPFILE*" -exec rm -f {} \; #searches in current directory for files containing TEMPFILE, removes them
    return 0
}

#an internal version of dims. dimsinternal is either called by the user or my program internally,
#and handled the output differently based on calling function
dims_internal(){
    ROWS=$(wc -l < "$1") #count the rows === number of lines, separated by new lines
    read -r line <$1
    COLS=$(echo $line|wc -w)
    if [ "$2" = "true" ] #user called
    then
        echo "$ROWS" "$COLS" #echo rows and cols out
    else #I was calling it
        local dimsarray=()
        dimsarray+=("$ROWS") #add dimensions to an array
        dimsarray+=("$COLS")
        echo ${dimsarray[@]} #echo back to calling function
    fi
}

dims(){
    #error handling
    if [[ $# -eq 1 && ! -f $1 ]] # no file with that name
    then
        #printf "ENTERED 4"
        error "Sorry, the file doesn't exist"
    fi

    if [ -f "$1" ] #file or stdin
    then
        if [ -f "$2" ] #too many arguments and 2 is a file
        then
            error "Sorry, cannot accept more than one argument"
    elif [ -f "$1" ] #file exists
        then
            file=$1
    elif [ "$1" = "" ] #first arg is empty, enter inputs
        then
            file=$(mktemp "./$$.XXXXTEMPFILE")
            while read -r line
            do
                echo $line
            done > $file
        fi
elif [ -s "$1" ]
    then
        error "file does not exist"
    else #through pipe
        file=$(mktemp "./$$.XXXXTEMPFILE") #temp file with process id
        cat > $file
    fi
    if [[ ! $file && ! -f $1 ]] # no file with that name
    then
        error "Sorry, the file doesn't exist"
elif [[ ! -r $file && $file ]] #file is not readable
    then
        remove
        error "Sorry, file is not readable"
elif [ -e "$file" ] #file exists
    then
        #printf "ENTERED SUCCESS"
        output=$(dims_internal $file "true")
        echo $output
        #2>&1
        remove
        exit 0
    fi
}

#takes a file and returns an array, only called internally
getarray(){
    local arr=()
    local mychar=0
    local file=$1 #the file
    for char in $(cut -d ' ' -f1 $file) #take each char on the space as delimeter
    do
        arr+=("$char") #add char to the array
    done < $file
    echo ${arr[@]} #echos back to calling function
}

#calculates the mean of an array. takes input from stdin or piped
mean(){
    #error handling - checking for file appropriatness
    if [[ $# -eq 1 && ! -f $1 ]] # no file with that name
    then
        error "Sorry, the file doesn't exist"
    fi

    if [ -f "$1" ] #file or stdin
    then
        if [ -f "$2" ] #too many arguments and 2 is a file
        then
            error "Sorry, cannot accept more than one argument"
    elif [ -f "$1" ] #file exists
        then
            file=$1
    elif [ "$1" = "" ] #first arg is empty, enter inputs
        then
            file=$(mktemp "./$$.XXXXTEMPFILE") #create tempfile, read to it
            while read -r line
            do
                echo $line
            done > $file
        fi
elif [ -s "$1" ]  #file not found
    then
        error "file does not exist"
    else #through pipe
        file=$(mktemp "./$$.XXXXTEMPFILE") #temp file with process id
        cat > $file
    fi

    if [[ ! $file && ! -f $1 ]] # no file with that name
    then
        error "Sorry, the file doesn't exist"
elif [[ ! -r $file && $file ]] #file is not readable
    then
        remove
        error "Sorry, file is not readable"
elif [ -e "$file" ] #file exists
    then

        local dimensionsarray=( $(dims_internal $file "false") ) #get dimensions
        local newarray=( $(transpose_internal $file "false") ) #get the array
        local r=${dimensionsarray[0]} #rows
        local c=${dimensionsarray[1]} #cols

        ####MEAN OPS
        total=0
        mean=0
        meanarray=()
        arrvalue=0

        #operating on a transposed array
        idx=0
        for(( k=0; k < $c; k++ )) #for each column
        do
            total=0
            mean=0
            for(( i=0; i < $r; i++ )) #for each row in that column
            do
                arrvalue=${newarray[$idx]}
                total=$((total+arrvalue)) #add each item in that col to total
                idx=$(($idx+1))
            done
            mean="$((( $total + ($r / 2) * (($total > 0) * 2 - 1)) / $r ))"
            meanarray+=("$mean") #add mean to
        done

        #print the mean array
        idx=0
        for num in ${meanarray[@]}
        do
            printf -- "$num"
            idx=$(($idx+1))
            if [ $idx = ${#meanarray[@]} ] #reached the end
            then
                printf "\n"
            else
                printf "\t"
            fi
        done
        remove
        exit 0
fi
}

transpose_internal(){
    #make tempfiles
    colfile=$(mktemp "./$$.XXXXTEMPFILEC")
    trmatrix=$(mktemp "./$$.XXXXTEMPFILETR")
    cols=0
    read line < "$1" #read line
    cols=$(echo $line|wc -w)
    for (( i=1; i < $(($cols+1)); i++))
    do
        cut -f "$i" "$1" > "$colfile"
        line=$(cat "$colfile" | tr -s '\n' '\t')
        line=${line%?}
        echo "$line" >> "$trmatrix" #append each line to file
    done
    cat "$trmatrix" #print matrix
    remove
    exit 0
}

#calculates transpose of matrix and prints
transpose(){
    #error handling file
    if [[ $# -eq 1 && ! -f $1 ]] # no file with that name
    then
        error "Sorry, the file doesn't exist"
    fi

    if [ -f "$1" ] #file or stdin
    then
        if [ -f "$2" ] #too many arguments and 2 is a file
        then
            error "Sorry, cannot accept more than one argument"
    elif [ -f "$1" ] #file exists
        then
            file=$1
    elif [ "$1" = "" ] #first arg is empty, enter inputs
        then
            file=$(mktemp "./$$.XXXXTEMPFILE")
            while read -r line
            do
                echo $line
            done > $file
        fi
elif [ -s "$1" ]
    then
        error "file does not exist"
    else #through pipe
        file=$(mktemp "./$$.XXXXTEMPFILE") #temp file with process id
        cat > $file
    fi

    if [[ ! $file && ! -f $1 ]] # no file with that name
    then
        error "Sorry, the file doesn't exist"
elif [[ ! -r $file && $file ]]
#elif [[ ! -r $file || ! -r $1 ]] #file is not readable
    then
        remove
        error "Sorry, file is not readable"
elif [ -e "$file" ] #file exists
    then
        transpose_internal $file "true" #call internal transpose
        remove
        exit 0
    fi
}

add(){
    #error handling
    if [[ ! $2 ]] #if second argument is empty, it's incorrect
    then
        remove
        error "Missing argument 2"
elif [[ $3 ]] #more than 2
    then
        remove
        error "Too many arguments"
elif [[ ! -e $1 ]] || [[ ! -e $2 ]] #either one or both of the files don't exist
    then
        remove
        error "Sorry, file(s) do not exist"
elif [[ ! -r $1 ]] || [[ ! -r $2 ]] #files are not readable
    then
        remove
        error "Sorry, file(s) is not readable"
    fi

    #array 1 ops
    local dimensionsarray=( $(dims_internal $1 "false") ) #get dimensions
    local arr2=( $(getarray $1) ) #get the array
    local rows=${dimensionsarray[0]}
    local columns=${dimensionsarray[1]}
    idx=0

    #shift args for next input
    shift 1

    #array 2 ops
    local dimensionsarray2=( $(dims_internal $1 "false") ) #get dimensions
    local arr5=( $(getarray $1) ) #get the array
    local r2=${dimensionsarray2[0]}
    local c2=${dimensionsarray2[1]}

    #check to see if rows and columns are equal
    if [[ $rows -ne $r2 ]] || [[ $columns -ne $c2 ]] #dimensions don't match
    then
        error "Dimensions of the arrays don't match"
    fi

    ###ADDITION OPS
    addarray=()
    value=0
    r=$rows
    c=$columns
    combo=0
    value2=0

    for(( k=0; k < ${#arr2[@]}; k=$k+$r)) #add each item
    do
        combo=0
        for(( i=$k; i < $r+$k; i++)) #for each row in that column
        do
            value=${arr2[$i]}
            value2=${arr5[$i]} #add them
            #value=$(($value+$value2))
            total=$((value+value2))
            addarray[${#addarray[@]}]=$total
            #addarray+=" "
        done
    done

    #printing
    inc=0
    for r in $(seq 1 $rows)
    do
        for c in $(seq 1 $columns)
        do
            printf -- "${addarray[$inc]}"
            inc=$(($inc+1))
            if [ $c = $columns ] #reached the end
            then
                printf "\n"
            else
                printf "\t"
            fi
        done
    done
    remove
    exit 0
}

multiply(){
    #error handling file
    if [ ! $2 ] #if second argument is empty, it's incorrect
    then
        remove
        error "Missing argument 2"
elif [ $3 ] #more than 2
    then
        remove
        error "Too many arguments"
elif [[ ! -e $1 ]] || [[ ! -e $2 ]] #either one or both of the files don't exist
    then
        remove
        error "Sorry, file does not exist"
elif [[ ! -r $1 ]] || [[ ! -r $2 ]] #files are not readable
    then
        remove
        error "Sorry, file(s) is not readable"
    fi

    #array 1 ops
    local dimensionsarray=( $(dims_internal $1 "false") ) #get dimensions
    local arr1=( $(getarray $1) ) #get the array
    local r=${dimensionsarray[0]}
    local c=${dimensionsarray[1]}
    #redirect to second file
    shift 1

    #second array, need to transpose
    local dimensionsarray2=( $(dims_internal $1 "false") ) #get dimensions
    local arr2=( $(transpose_internal $1 "false") ) #get the array
    local r2=${dimensionsarray2[0]}
    local c2=${dimensionsarray2[1]}

    #check for matching dimensions, array 1 cols and array 2 rows must match .exit otherwise
    if [ $c -ne $r2 ]
    then
        remove
        error "Dimensions of the arrays don't match"
    fi


    #multiply ops
    value1=0
    value2=0
    total=0
    multiplied=0
    finalarray=()
    counter=0
    idx2=0
    idx=0
    #for every row in array 1
    for(( x=0; x < $r; x++ ))
    do
        #echo "INDEX 1 BEG " $idx
        #idx=0
        ###successfully multiples first row by every column in second, but then starts from beginning on array 1 again when it should start at 6---says IDX 6 but numbers start from 0th element
        ###also, array 2 starts at col 2 when it needs to start over from beginning col
        for(( k=0; k < $c2; k++ )) #for every row in array 1 JUST DO FIRST ROW SUCCESSFULLY PRINTS FIRST ROW
        do
            total=0 #reset total
            for(( i=0; i < $c; i++ )) #for every col element in row 1 of first array
            do
                for(( j=0; j < $r2; j++, i++ )) #for every row element in every col in array 2
                do
                    if [ $j = 0 ]
                    then
                        idx2=$(($counter*$c)) #index for array 2, RESET IT
                        idx=$(($x*$c))
                        value1=${arr1[$idx]}
                        value2=${arr2[$idx2]}
                        multiplied=$(($value1*$value2))
                        total=$(($total+$multiplied))
                    else
                        idx2=$(($idx2+1)) #increment it
                        idx=$(($idx+1))
                        value1=${arr1[$idx]}
                        value2=${arr2[$idx2]}
                        multiplied=$(($value1*$value2))
                        total=$(($total+$multiplied))
                    fi
                done
                finalarray+=("$total")
            done
            counter=$(($counter+1))
        done
        counter=0
    done

    #print
    cl=0
    for(( a=0; a < $r; a++ ))
    do
        for(( b=0; b < $c2; b++ ))
        do
            printf -- "${finalarray[$cl]}"
            if ((  b != c2-1 )) #haven;t reached end so print a tab
            then
                printf "\t"
            fi
            cl=$(($cl+1))
        done
        printf "\n"
    done
    remove
    exit 0
}

$@
