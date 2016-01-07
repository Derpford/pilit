#!/bin/bash
#Pilit site-compiling script, written by Christian Scott (squiggle.city/~dawnbreeze)

#Set some vars.
temp=~/.pilit/temp.html
final=~/public_html/index.html
arch=~/public_html/archive.html
snippets=~/.pilit/html
notes=~/notes
n=5
difftemp=~/.pilit/diff

#The functions that get the files.
function getTopFiles {
    find ${notes} -type f -printf '%TY:%Tm:%Td %TH:%Tm %h/%f\n' | sort -r | sed '/\~$/d' | sed '/\.swp/d' | cut -d " " -f 3 | head -n ${n}
}

function getAllFiles {
    find ${notes} -type f -printf '%TY:%Tm:%Td %TH:%Tm %h/%f\n' | sed '/\~$/d' | sed '/\.swp/d' | cut -d " " -f 3
}

#Now, see if the user wants to set those vars differently.
while getopts f:a:s:n:N:Aih opt; do
    case $opt in
	f) #He wants a different final file.
	    final=$OPTARG
	    ;;
	a) #He wants a different archive file.
	    arch=$OPTARG
	    ;;
	s) #He wants a different snippets directory.
	    snippets=$OPTARG
	    ;;
	n) #More or less files!
	    n=$OPTARG
	    ;;
	N) #He wants a different notes directory.
	    notes=$OPTARG
	    ;;
	A) #He doesn't want an archive file.
	    noarch=true
	    ;;
	i) #Install time!
	    #TODO: Make an install thingy.
	    echo "Making head/tail files. You should edit these before running the script, they're at $snippets/head and $snippets/tail."
	    touch $snippets/head
	    echo '
<html>
  <head>
    <title>Made with Pilit</title>
    <link rel="stylesheet" media="screen and (min-device-width: 800px)" href="squigglepage.css" />
  </head>
  <body>' > $snippets/head
	    touch $snippets/tail
	    echo '
</body>
</html>' > $snippets/tail
	    touch $difftemp
	    exit 0
	    ;;
	h|*) #Help time!
	    echo "
Pilit: A simple bash-based page maker
Usage: pilit.sh [-i]|[-A][-n number][-fasN file]
Options:
    -i: Run the install script.
    -A: Don't make an archive file.
    -n: Choose how many files from notes get put on the frontpage.
    -f: Choose where the 'final' (homepage) file goes.
    -a: Choose where the archive file goes.
    -s: Choose a directory to look for snippets of HTML in.
    -N: Choose a directory to look for notes in.
Each time this script is run, it will check everything in ~/notes (or the specified directory),
take the top 5 (or n) files in that directory,
and stick them between a header (in .pilit/html/head) and a footer (in .pilit/html/tail).
Then it takes everything in ~/notes, and puts it into an archive file, between the header and footer.
The home page and archive page are placed in ~/public_html by default, but their locations can be specified separately.
"
    esac
done
#Do some error reporting.

if [ ! -f ${snippets}/head ]; then
   echo "No head file! Make one at ${snippets}/head!"
   exit 1
fi
   
if [ ! -f ${snippets}/tail ]; then
   echo "No tail file! Make one at ${snippets}/tail!"
   exit 1
fi

#Empty the temp file
cat /dev/null > $temp
#Add the header
cat ${snippets}/head >> $temp
#Add everything in notes
for i in `getTopFiles`; do
    f="$(readlink -f ${i})"
    if [[ "$i" =~ .*\~ ]]; then
	# Skip the backup file.
	test
    else
	echo "<p><div class='title' id='${i}'>>>${f}</div>" >> $temp
	echo "<div class='entry'>" >> $temp
	cat $i | sed -e 's/$/<br>/' >> $temp
	echo "</div>" >> $temp
    fi
done
#Add the tail
echo "<p>" >> $temp
cat ${snippets}/tail >> $temp
diff ${temp} ${final} > $difftemp
if [[ $? -eq 1 ]]; then
    mv $temp $final
fi

#Now to do the archive file.
if [ -z $noarch ]; then
    cat /dev/null > $temp
    #Add the header
    cat ${snippets}/head >> $temp
    #Add everything in notes
    for i in `getAllFiles`; do
	if [[ "$i" =~ .*\~ ]]; then
	    test
	else
	    f="$(readlink -f ${i})"
	    echo "<p><div class='title' id='${i}'>>>${f}</div>" >> $temp
	    echo "<div class='entry'>" >> $temp
	    cat ${i} | sed -e 's/$/<br>/' >> $temp
	    echo "<a href='archive.html#${i}'>Link to this post</a>" >> $temp
	    echo "</div>" >> $temp
	fi
    done
    #Add the tail
    cat ${snippets}/tail >> $temp
    diff ${temp} ${final} >> $difftemp
    if [[ $? -eq 1 ]]; then
        mv $temp $arch
    fi
fi
