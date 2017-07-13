#!/bin/bash

# example: ./jetloader.sh -p --input-url= --splits= --approx-maxsize=

function setDefaults()  {
    if [ -z $INPUTURL ] ; then
        echo 'ERROR: input not set'
        usage
    fi

    if [ -z $SPLITS ] && [ "$MULTIPLEPART" -eq "on" ] ; then
        SPLITS=4
    fi

    if [ -z $OUTPUTFILE ] ; then
        OUTPUTFILE=`basename $INPUTURL`
    fi

    if [ -z $MAXSIZE ] ; then
        MAXSIZE=`curl --proxy $PROXY -I $INPUTURL | grep "^Content-Length:" | cut -d' ' -f2`
        MAXSIZE=${MAXSIZE//$'\r'}
    fi
}

MULTIPLEPART="off"

usage()	{
	echo 
	"usage: $0 -p --input-url=#url --output-filename=#filename --splits=#n --proxy=#proxy --approx-maxsize=#maxsize
	Required options:
       	-input-url	
    	Optional long options:
		--output-filename
		--proxy
		--splits
        --approx-maxsize
	No argument short option:
		-p
	" ; exit 1
	}

setParams() 
{
    OPTS=`getopt \
        -o p \
        -n $0 \
        --long input-url:,splits::,proxy::,output-filename::,approx-maxsize:: \
        -- "$@"`

    if [ $? != 0 ] ; then
        echo 'error'
        usage
        exit 1
    fi

    eval set -- "$OPTS"
    echo "$OPTS"
    while true ; do
        case "$1" in
        --input-url)
            case "$2" in
            "") 
                shift 2
                ;;
            *) 
                INPUTURL=$2 ; shift 2
                ;;
            esac
            ;;	
        --splits)
            case "$2" in
            "") 
                shift 2
                ;;
            *)
                SPLITS=$2 ; shift 2
                ;;
            esac
            ;;
        --proxy)
            case "$2" in
            "") 
                shift 2
                ;;
            *)
                PROXY=$2 ; shift 2
                ;;
            esac
            ;;
        --output-filename)
            case "$2" in
            "") 
                shift 2
                ;;
            *)
                OUTPUTFILE=$2 ; shift 2
                ;;
            esac
            ;;
        --approx-maxsize)
            case "$2" in
            "") 
                shift 2
                ;;
            *)
                MAXSIZE=$2 ; shift 2
                ;;
            esac
            ;;
        -p)
            MULTIPLEPART="on" ; shift
            ;;
        --)
            shift ; break
            ;;
        *)
            echo "Unknown option:$1"
            usage >&2
            exit 1
            ;;
        esac
    done
}

# invoked upon an EXIT/SIGINT/SIGHUP
function cleanup_on_exit()  {
    for f in $OUTPUTFILE.part*;
    do
        if [ -e $f ] ; then
            rm $f
        fi
    done
}

function cleanup()  {
    cleanup_on_exit
    if [ -e $OUTPUTFILE ] ; then
        rm $OUTPUTFILE
    fi
    exit 1
}

setParams "$@"
setDefaults

if [ ! -z "$MAXSIZE" ] && [ ! -z "$SPLITS" ] ; then

   echo "file is downloaded over multiple parts"

   trap "{ echo 'in exit' ; cleanup_on_exit; }" EXIT
   trap "{ echo 'in sigint' ; kill $(jobs -pr) && cleanup; }" SIGINT SIGTERM

   SPLIT_SIZE=$((MAXSIZE/ SPLITS))
   PIDLIST=""
   for (( c=0; c<=SPLITS-2; c++ ))
   do
       startbyte=$(( c * SPLIT_SIZE ))
       echo "startbyte $startbyte"
       endbyte=$(( startbyte + SPLIT_SIZE - 1 ))
       echo "endbyte $endbyte"
       if [ -z "$PROXY" ] ; then
           curl --range $startbyte-$endbyte -o $OUTPUTFILE.part$c $INPUTURL &
       else
           curl --proxy $PROXY --range $startbyte-$endbyte -o $OUTPUTFILE.part$c $INPUTURL &
       fi
       PIDLIST="$PIDLIST $!"
   done

   startbyte=$(( (SPLITS-1) * SPLIT_SIZE ))
   if [ -z "$PROXY" ] ; then
       curl --range $startbyte-$endbyte -o $OUTPUTFILE.part$c $INPUTURL &
   else
       curl --proxy $PROXY --range $startbyte-$endbyte -o $OUTPUTFILE.part$c $INPUTURL &
   fi
   PIDLIST="$PIDLIST $!"

   wait $PIDLIST

   cat $OUTPUTFILE.part* > $OUTPUTFILE

else
   echo "single part file download"
   echo "output in $OUTPUTFILE and input is $INPUTURL"
   curl -o $OUTPUTFILE $INPUTURL &
fi
