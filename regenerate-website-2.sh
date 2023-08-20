#!/bin/sh
# regenerate-website - download & regenerate the Metamath website contents

# Usage:
# REGENERATE_DOWNLOAD=n REGENERATE_COMPILE=n \
# REGENERATE_GENERATE=y COPY_TO_WEBPAGE=n ./regenerate-website

# Print the message $1 and exit with failure.
fail () {
  printf '%s\n' "$1" >&2
  exit 1
}

# set -eu
set -x

if [ "$(whoami)" = 'root' ]; then
    fail 'DO NOT run this as roo!! Execute /root/run-regenerate.sh instead!!'
fi

start_date="$(date)"

# This script by default downloads, generates, and pushes its results.
# Set environment variables to skip some steps:
: "${REGENERATE_DOWNLOAD:=y}"
: "${REGENERATE_COMPILE:=y}"
: "${REGENERATE_GENERATE:=y}"
: "${COPY_TO_WEBPAGE:=y}"

# Previously we generated all files to
# </opt/dts/mmmaster/metamathsite/>
# (e.g., </opt/dts/mmmaster/metamathsite/metamath/>)
# but now we'll just generate to METAMATHSITE which is $HOME/metamathsite
METAMATHSITE="$HOME/metamathsite"

# Configure git so it'll stop complaining about certain kinds of pulls
git config --global pull.rebase false

# Erase & re-download what we need.

case "${REGENERATE_DOWNLOAD}" in
y)
    # To ensure that we start from a clean slate, we'll first
    # REMOVE the "$METAMATHSITE" directory.
    rm -fr "${METAMATHSITE:?Must set METAMATHSITE}/"
    mkdir -p "$METAMATHSITE/"

    # Load the metamath-website-seed repo into $METAMATHSITE
    # to use as our starting point.
    (
    cd "$METAMATHSITE" || exit 1
    SEED='https://api.github.com/repos/metamath/metamath-website-seed/tarball'
    curl -L "$SEED" | tar xz --strip=1
    )

    # Download database information into "~/repos".
    # We once downloaded set.mm using git, but that creates a *huge* .git
    # directory we don't need. Downloading *just* the tarball from GitHub
    # is actually quite fast, so we'll just do it every time if we
    # are going to download it at all.
    rm -fr repos
    # cd repos; git clone https://github.com/metamath/set.mm.git
    mkdir -p repos/set.mm
    (
        cd repos/set.mm || exit 1
        curl -L https://api.github.com/repos/metamath/set.mm/tarball | \
            tar xz --strip=1
    )

    # Download metamath source code.
    './repos/set.mm/scripts/download-metamath'

    # Bring in latex styles.
    curl -L 'https://raw.githubusercontent.com/metamath/metamath-book/master/narrow.sty' > "$METAMATHSITE/latex/narrow.sty"
    curl -L 'https://raw.githubusercontent.com/metamath/metamath-book/master/normal.sty' > "$METAMATHSITE/latex/normal.sty"
;;
esac

# Regenerate website, now that we've downloaded all the external files.

case "${REGENERATE_COMPILE}" in
y)
    mkdir -p "$METAMATHSITE/metamath/"
    mkdir -p "$METAMATHSITE/mpegif/"

    # Rebuild metamath.exe, so we're certain to use the latest one.
    './repos/set.mm/scripts/build-metamath'
;;
esac

case "${REGENERATE_GENERATE}" in
y)
    mkdir -p "$METAMATHSITE/metamath/"
    mkdir -p "$METAMATHSITE/mpegif/"

    # Copy databases in.
    cp -p repos/set.mm/*.mm "$METAMATHSITE/metamath/"

    # TODO: START HERE
    # cd "$METAMATHSITE"

    # 
    # echo "Creating subdirectories..."
    # 
    # # Remove "backup" version of set.mm if any
    # rm -f metamathsite/set.mm~1
    # # Remove "working" version of set.mm if any
    # [ -f metamathsite/set.mm ] && rm -f metamathsite/set.mm
    # 
    # ##### Recreate the minimal site master for recovery and archiving #####
    # # The minimal site recovery files are placed in a temporary subdirectory
    # # called metamathsite, which persists until the end in case this script
    # # is aborted.  Before deleting the metamathsite subdirectory, it is
    # # archived into metamathsite.tar.gz which will allow the site to be
    # # rebuilt on another machine.
    # 
    # # Remove old tmp directory (if it exists) and create new one
    # rm -rf tmpmetamathsite
    # if [ -d tmpmetamathsite ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'tmpmetamathsite'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # #DEBUG
    # #echo debugmkdirtmpmetamathsite2
    # mkdir tmpmetamathsite
    # 
    # # Copy top directory files; create needed subdirectories
    # # First, copy the top directory files, skipping hidden (".") files.
    # find . ! -name '.' -prune ! -name '.*' -type f -exec cp -p {} tmpmetamathsite/
    # 
    # # We skip the tmpmetamathsite we're working on, of course; also, mpeuni
    # # and qleuni are fully automatically generated so we skip them too
    # #for i in `find . -type d -name "?*" | egrep -v "tmpmetamathsite|mpeuni|qleuni"`
    # # 16-Apr-2015 nm add nfeuni
    # # 12-Jul-2015 nm add holuni
    # # 21-Jul-2015 nm add ileuni
    # # for i in `find . -type d -name "?*" | egrep -v \
    # # 12-Jul-2015 match at least 2 characters so "." result will be skipped
    # for i in `find . -type d -name "??*" | egrep -v \
    #    "tmpmetamathsite|mpeuni|qleuni|nfeuni|holuni|ileuni"`
    # do
    #   mkdir tmpmetamathsite/$i
    # #????
    # #???? 7/12/15 What is going on here?  Why is 'find' prefixing './'?  From log:
    # #????
    # #????   + find . -type d -name ?*
    # #????   + egrep -v tmpmetamathsite|mpeuni|qleuni|nfeuni
    # #????   + mkdir tmpmetamathsite/.
    # #????   mkdir: cannot create directory `tmpmetamathsite/.': File exists
    # #????   + mkdir tmpmetamathsite/./mpegif
    # #????   + mkdir tmpmetamathsite/./metamath
    # #????
    # #???? I don't think this happened many years ago.  Did they change 'find'?
    # done
    # # Remove any log files from previous (or this) run
    # [ -f tmpmetamathsite/install.log ] && rm -f tmpmetamathsite/install.log
    # [ -f tmpmetamathsite/nohup.out ] && rm -f tmpmetamathsite/nohup.out
    # 
    # # Copy subdirectories but omit the two "Explorer"s for now
    # #for i in `find . -type d -name "?*" | egrep -v \
    # #    "tmpmetamathsite|mpegif|mpeuni|qlegif|qleuni"`
    # # 16-Apr-2015 nm add nfe
    # # 12-Jul-2015 nm add hol
    # # 21-Jul-2015 nm add ile
    # for i in `find . -type d -name "?*" | egrep -v \
    # "tmpmetamathsite|mpegif|mpeuni|qlegif|qleuni|nfegif|nfeuni|holgif|holuni|ilegif|ileuni"`
    # do
    #   cp -p $i/* tmpmetamathsite/$i/
    # done
    # 
    # # Copy only manually-created files from the "Explorer"s
    # 
    # # Metamath Proof Explorer
    # cd mpegif
    # # Copy all the non-html files
    # find . -type f ! -name "*.html" -exec cp -p {} ../tmpmetamathsite/mpegif/ \;
    # # Delete any non-custom symbols that exist in the symbols directory
    # for i in *.gif
    # do
    #   [ -f ../symbols/$i ] && rm -f ../tmpmetamathsite/mpegif/$i
    # done
    # # Delete files that will be copied from home directory
    # [ -f mm.gif ] && rm -f ../tmpmetamathsite/mpegif/mm.gif
    # [ -f favicon.ico ] && rm -f ../tmpmetamathsite/mpegif/favicon.ico
    # [ -f _nmemail.gif ] && rm -f ../tmpmetamathsite/mpegif/_nmemail.gif
    # # Our convention is that all manually-created html files begin with "mm"
    # cp -p mm*.html ../tmpmetamathsite/mpegif/
    # # But some of them are automatically generated, so we don't include them
    # # Omit the automatically-generated mm*.html files
    # [ -f mmtheorems.html ] && rm -f ../tmpmetamathsite/mpegif/mmtheorems*.html
    # [ -f mmdefinitions.html ] && rm -f ../tmpmetamathsite/mpegif/mmdefinitions.html
    # [ -f mmascii.html ] && rm -f ../tmpmetamathsite/mpegif/mmascii.html
    # # 16-Dec-2018: These are now generated from mm*.raw.html:
    # [ -f mmset.html ] && rm -f ../tmpmetamathsite/mpegif/mmset.html
    # [ -f mmcomplex.html ] && rm -f ../tmpmetamathsite/mpegif/mmcomplex.html
    # [ -f mmdeduction.html ] && rm -f ../tmpmetamathsite/mpegif/mmdeduction.html
    # [ -f mmnatded.html ] && rm -f ../tmpmetamathsite/mpegif/mmnatded.html
    # [ -f mmzfcnd.html ] && rm -f ../tmpmetamathsite/mpegif/mmzfcnd.html
    # cd ..
    # 
    # # Quantum Logic Explorer
    # cd qlegif
    # # Copy all the non-html files
    # find . -type f ! -name "*.html" -exec cp -p {} ../tmpmetamathsite/qlegif/ \;
    # # Delete any non-custom symbols that exist in the symbols directory
    # for i in *.gif
    # do
    #   [ -f ../symbols/$i ] && rm -f ../tmpmetamathsite/qlegif/$i
    # done
    # # Delete any non-custom symbols that exist in the mpegif directory
    # for i in *.gif
    # do
    #   [ -f ../mpegif/$i ] && rm -f ../tmpmetamathsite/qlegif/$i
    # done
    # # Delete font file if it already exists in mpegif directory
    # [ -f ../mpegif/xits-math.woff ] && \
    #    rm -f ../tmpmetamathsite/qlegif/xits-math.woff
    # # Delete files that will be copied from home directory
    # [ -f favicon.ico ] && rm -f ../tmpmetamathsite/qlegif/favicon.ico
    # [ -f _nmemail.gif ] && rm -f ../tmpmetamathsite/qlegif/_nmemail.gif
    # # Our convention is that all manually-created html files begin with "mm"
    # cp -p mm*.html ../tmpmetamathsite/qlegif/
    # # Omit the automatically-generated mm*.html files
    # [ -f mmtheorems.html ] && rm -f ../tmpmetamathsite/qlegif/mmtheorems*.html
    # [ -f mmdefinitions.html ] && rm -f ../tmpmetamathsite/qlegif/mmdefinitions.html
    # [ -f mmascii.html ] && rm -f ../tmpmetamathsite/qlegif/mmascii.html
    # cd ..
    # 
    # 
    # # 16-Apr-2015 nm Add nfe
    # # New Foundations Explorer
    # cd nfegif
    # # Copy all the non-html files
    # find . -type f ! -name "*.html" -exec cp -p {} ../tmpmetamathsite/nfegif/ \;
    # # Delete any non-custom symbols that exist in the symbols directory
    # for i in *.gif
    # do
    #   [ -f ../symbols/$i ] && rm -f ../tmpmetamathsite/nfegif/$i
    # done
    # # Delete any non-custom symbols that exist in the mpegif directory
    # for i in *.gif
    # do
    #   [ -f ../mpegif/$i ] && rm -f ../tmpmetamathsite/nfegif/$i
    # done
    # # Delete font file if it already exists in mpegif directory
    # [ -f ../mpegif/xits-math.woff ] && \
    #    rm -f ../tmpmetamathsite/nfegif/xits-math.woff
    # # Delete files that will be copied from home directory
    # [ -f favicon.ico ] && rm -f ../tmpmetamathsite/nfegif/favicon.ico
    # [ -f _nmemail.gif ] && rm -f ../tmpmetamathsite/nfegif/_nmemail.gif
    # # Our convention is that all manually-created html files begin with "mm"
    # cp -p mm*.html ../tmpmetamathsite/nfegif/
    # # Omit the automatically-generated mm*.html files
    # [ -f mmtheorems.html ] && rm -f ../tmpmetamathsite/nfegif/mmtheorems*.html
    # [ -f mmdefinitions.html ] && rm -f ../tmpmetamathsite/nfegif/mmdefinitions.html
    # [ -f mmascii.html ] && rm -f ../tmpmetamathsite/nfegif/mmascii.html
    # cd ..
    # 
    # 
    # # 12-Jul-2015 nm Add hol
    # # Higher-Order Logic Explorer
    # cd holgif
    # # Copy all the non-html files
    # find . -type f ! -name "*.html" -exec cp -p {} ../tmpmetamathsite/holgif/ \;
    # # Delete any non-custom symbols that exist in the symbols directory
    # for i in *.gif
    # do
    #   [ -f ../symbols/$i ] && rm -f ../tmpmetamathsite/holgif/$i
    # done
    # # Delete any non-custom symbols that exist in the mpegif directory
    # for i in *.gif
    # do
    #   [ -f ../mpegif/$i ] && rm -f ../tmpmetamathsite/holgif/$i
    # done
    # # Delete font file if it already exists in mpegif directory
    # [ -f ../mpegif/xits-math.woff ] && \
    #    rm -f ../tmpmetamathsite/holgif/xits-math.woff
    # # Delete files that will be copied from home directory
    # [ -f favicon.ico ] && rm -f ../tmpmetamathsite/holgif/favicon.ico
    # [ -f _nmemail.gif ] && rm -f ../tmpmetamathsite/holgif/_nmemail.gif
    # # Our convention is that all manually-created html files begin with "mm"
    # cp -p mm*.html ../tmpmetamathsite/holgif/
    # # Omit the automatically-generated mm*.html files
    # [ -f mmtheorems.html ] && rm -f ../tmpmetamathsite/holgif/mmtheorems*.html
    # [ -f mmdefinitions.html ] && rm -f ../tmpmetamathsite/holgif/mmdefinitions.html
    # [ -f mmascii.html ] && rm -f ../tmpmetamathsite/holgif/mmascii.html
    # cd ..
    # 
    # 
    # # 21-Jul-2015 nm Add ile
    # # Intuitionistic Logic Explorer
    # cd ilegif
    # # Copy all the non-html files
    # find . -type f ! -name "*.html" -exec cp -p {} ../tmpmetamathsite/ilegif/ \;
    # # Delete any non-custom symbols that exist in the symbols directory
    # for i in *.gif
    # do
    #   [ -f ../symbols/$i ] && rm -f ../tmpmetamathsite/ilegif/$i
    # done
    # # Delete any non-custom symbols that exist in the mpegif directory
    # for i in *.gif
    # do
    #   [ -f ../mpegif/$i ] && rm -f ../tmpmetamathsite/ilegif/$i
    # done
    # # Delete font file if it already exists in mpegif directory
    # [ -f ../mpegif/xits-math.woff ] && \
    #    rm -f ../tmpmetamathsite/ilegif/xits-math.woff
    # # Delete files that will be copied from home directory
    # [ -f favicon.ico ] && rm -f ../tmpmetamathsite/ilegif/favicon.ico
    # [ -f _nmemail.gif ] && rm -f ../tmpmetamathsite/ilegif/_nmemail.gif
    # # Our convention is that all manually-created html files begin with "mm"
    # cp -p mm*.html ../tmpmetamathsite/ilegif/
    # # Omit the automatically-generated mm*.html files
    # [ -f mmtheorems.html ] && rm -f ../tmpmetamathsite/ilegif/mmtheorems*.html
    # [ -f mmdefinitions.html ] && rm -f ../tmpmetamathsite/ilegif/mmdefinitions.html
    # [ -f mmascii.html ] && rm -f ../tmpmetamathsite/ilegif/mmascii.html
    # cd ..
    # 
    # 
    # # Metamath Solitaire
    # cd mmsolitaire
    # # Delete any non-custom symbols that exist in the symbols directory
    # for i in *.gif
    # do
    #   [ -f ../symbols/$i ] && rm -f ../tmpmetamathsite/mmsolitaire/$i
    # done
    # # Delete any symbols that exist in the mpegif directory
    # for i in *.gif
    # do
    #   [ -f ../mpegif/$i ] && rm -f ../tmpmetamathsite/mmsolitaire/$i
    # done
    # # Delete files that will be copied from home directory
    # [ -f mm.gif ] && rm -f ../tmpmetamathsite/mmsolitaire/mm.gif
    # [ -f favicon.ico ] && rm -f ../tmpmetamathsite/mmsolitaire/favicon.ico
    # [ -f _nmemail.gif ] && rm -f ../tmpmetamathsite/mmsolitaire/_nmemail.gif
    # cd ..
    # 
    # 
    # # GIF Images for Math Symbols
    # cd symbols
    # # Delete files that will be copied from home directory
    # [ -f mm.gif ] && rm -f ../tmpmetamathsite/symbols/mm.gif
    # [ -f favicon.ico ] && rm -f ../tmpmetamathsite/symbols/favicon.ico
    # [ -f _nmemail.gif ] && rm -f ../tmpmetamathsite/symbols/_nmemail.gif
    # #[ -f valid-html401.png ] && rm -f ../tmpmetamathsite/symbols/valid-html401.png
    # cd ..
    # 
    # # LaTeX directory
    # cd latex
    # # Remove auxilliary files created by LaTeX (all files but *.tex)
    # find . -type f ! -name "*.tex" -exec rm -f ../tmpmetamathsite/latex/{} \;
    # cd ..
    # 
    # # 6-Jun-2021
    # echo "install.sh time create downloads: `date`"
    # 
    # # Download directory
    # # Remove the automatically-generated compressed downloads; by convention these
    # # are ones whose prefix is a directory name
    # #for i in mpegif mpeuni qlegif qleuni mmsolitaire symbols metamathsite metamath
    # # 16-Apr-2015 nm Added nfe
    # # 12-Jul-2015 nm Added hol
    # # 21-Jul-2015 nm Added ile
    # for i in mpegif mpeuni qlegif qleuni nfegif nfeuni holgif holuni ilegif ileuni \
    #        mmsolitaire symbols metamathsite metamath
    # do
    #   [ -f downloads/${i}.tar.bz2 ] && rm -f tmpmetamathsite/downloads/${i}.tar.bz2
    #   [ -f downloads/${i}.tar.gz ] && rm -f tmpmetamathsite/downloads/${i}.tar.gz
    #   [ -f downloads/${i}.zip ] && rm -f tmpmetamathsite/downloads/${i}.zip
    # done
    # # Remove the automatically-created .pdf files
    # #
    # #   Note: megillaward2005he and megillaward2005eu are not included
    # #   because they contain false pdflatex errors that make checking the log
    # #   for errors confusing.  Therefore, their pdfs are permanently stored in
    # #   the downloads directory instead of being recompiled each time.
    # #
    # # 6-Feb-2018 leave metamath.pdf alone for now
    # #for i in metamath finiteaxiom megillaward2003 megillaward2004
    # for i in finiteaxiom megillaward2003 megillaward2004
    # do
    #   [ -f downloads/${i}.pdf ] && rm -f tmpmetamathsite/downloads/${i}.pdf
    # done
    # # Remove all but one compressed quantum-logic - leave the .bz2
    # [ -f downloads/quantum-logic.tar.gz ] && rm -f tmpmetamathsite/downloads/quantum-logic.tar.gz
    # [ -f downloads/quantum-logic.zip ] && rm -f tmpmetamathsite/downloads/quantum-logic.zip
    # 
    # # Remove any previous (platform-dependent) metamath compilation left
    # # over from an aborted run
    # [ -f metamath/metamath ] && rm -f tmpmetamathsite/metamath/metamath
    # # 4-Feb-2005 Remove README files - they will be recreated from rdme-xxx.txt
    # # 15-Sep-2016 This is dangerous - it deleted completeusersproof__README.TXT,
    # # so it had to be renamed something else TODO: explicitly enumerate
    # # the actual files to be deleted
    # rm -f */*README*
    # rm -f *README*
    # # Keep the top-level LICENSE file
    # rm -f */LICENSE.TXT
    # 
    # # We're now done creating the minimal site master backup; rename it
    # # First delete any old metamathsite (shouldn't exist but just in case)
    # rm -rf metamathsite
    # if [ -d metamathsite ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'metamathsite'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "On Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv tmpmetamathsite metamathsite
    # if [ -d tmpmetamathsite ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'tmpmetamathsite'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "On Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # ########### End of creating minimal site master ###############
    # 
    # 
    # 
    # ########### Compile Metamath #############
    # cd metamath
    # 
    # # Make sure the Windows version is executable under Cygwin
    # [ -f metamath.exe ] && chmod +x metamath.exe
    # 
    # echo "Compiling Metamath..."
    # if $CYGWIN ; then
    #   # Save the original Windows metamath.exe in case we're running on Cygwin,
    #   # because in Cygwin, gcc appends .exe to the compiled file name
    #   [ -f metamath.exe ] && mv metamath.exe metamath.exe-save
    # fi
    # gcc m*.c -o metamath -O3 -funroll-loops -finline-functions \
    #    -fomit-frame-pointer -Wall -pedantic  -fno-strict-overflow
    # cd ..
    # 
    # ######## Generate Metamath Proof Explorer ############
    # # Copy manually-created files.  The mpegif directory is assumed to contain
    # # the lastest "master" versions of them.  The mpeuni directory is discarded.
    # mkdir mpegif-new
    # # 9/3/14 nm This is so Mario can add files
    # chmod a+w mpegif-new
    # cp -p metamathsite/mpegif/* mpegif-new/
    # 
    # [ -f favicon.ico ] && cp -p favicon.ico mpegif-new/
    # [ -f _nmemail.gif ] && cp -p _nmemail.gif mpegif-new/
    # [ -f mm.gif ] && cp -p mm.gif mpegif-new/
    # # Copy the non-custom symbols from the symbols subdirectory, plus mm.gif
    # # 30-Nov-2013 Changed iota to riota
    # # Note:  parallel.gif is for Paul Chapman's mathbox
    # # Note:  top.gif is for Anthony Hart's mathbox
    # # Note:  cpi oplus wbox wdiamond are for FL's mathbox
    # # Note:  bbi simeq sub1 subb subh subp subr subt supn are for Jeff Madsen's mathbox
    # # Note:  subw subin models subg phi prod are for Mario Carneiro's mathbox 28-Feb-2014
    # # Note:  subo added for 3o,4o 25-Aug-2013 (3o,4o may become single gif someday)
    # # Note:  bbe for Scott Fenton's mathbox:  Unicode is way too big
    # # Note:  zeta for Mario Carneiro's mathbox.  Warning: conflict w/ _zeta as var
    # # Note:  int sub2 rmd for Mario Carneiro's mathbox 3/23/14
    # # Note:  bbp....veebar for Mario Carneiro's gif conversion 4/2/14
    # # Note:  cgamma bba subf cx  for Mario 7/27/14
    # # Note: Is r.gif necessary? (Check ^r htmldef resolution.) 11/29/15
    # # Note:  bigtriangleup added 4/26/20
    # # Note:  ltimes for Peter Mazsa's mathbox 2/17/22
    # for i in \
    #     0 1 2 3 4 5 6 7 8 9 amp approx ast backquote backtick bang \
    #     barwedge bbc bbn bbq \
    #     bbr bbz bigcap bigcup bigto caln calp calq calr cap cdot \
    #     circ clambda colon \
    #     comma csigma cup diagup eq equiv exists forall gamma im in riota \
    #     langle lbrace lbrack ldots leftrightarrow le lfloor lnot \
    #     longrightarrow lp lt mapsto minus ne notin \
    #     omega onetoone onetooneonto onto perp pi plus \
    #     preccurlyeq prec rangle \
    #     rbrace rbrack re restriction rightsquigarrow rmcc rmce rmci rmcv rme rmi \
    #     rp scrh scrp setminus \
    #     shortminus smallsmile solidus subseteq subsetneq supast surd times to \
    #     uparrow varnothing vee vert wedge varaleph lessdot mm \
    #     parallel \
    #     top \
    #     cpi oplus wbox wdiamond \
    #     bbi simeq sub1 subb sube subh subp subr subt supn \
    #     subw subin models subg phi prod \
    #     subo \
    #     bbe \
    #     zeta \
    #     int sub2 rmd \
    #     bbp blacktriangleright llangle octothorpe otimes period rmcp \
    #     rrangle sub0 sub3 sub4 suba subc subcp subcr subm subminus \
    #     subrmw subs subv sup3 t veebar \
    #     cgamma bba subf cx cc rmcd cl sup1 co sigma theta mu subcl \
    #     comega subk subn subu gt ge pm infty r quote finv tau \
    #     bigtriangleup \
    #     ltimes
    # do
    #   [ -f symbols/${i}.gif ] && cp -p symbols/${i}.gif mpegif-new/
    # done
    # 
    # # All manually-created files are the same for both gif and symbol-font versions
    # mkdir mpeuni-new
    # # 9/3/14 nm This is so Mario can add files
    # chmod a+w mpeuni-new
    # cp -p mpegif-new/* mpeuni-new/
    # 
    # # 6-Jun-2021
    # echo "install.sh time start mpegif: `date`"
    # 
    # cd mpegif-new
    # # 16-Dec-2018 nm Added markup mm*.raw.html - note that this must be
    # #     done first so that mmset.html, mmhil.html will exist to check
    # #     bibliography references during 'show statement' etc.
    # # show statement... = regenerate proof pages
    # # write bibliography... = refresh bibiographic cross-reference
    # # write recent_additions... = refresh recent additions
    # ../metamath/metamath  "read '../metamath/set.mm'" \
    #     "markup mmset.raw.html mmset.html /html /symbols /css /labels" \
    #     "markup mmcomplex.raw.html mmcomplex.html /html /symbols /css /labels" \
    #     "markup mmdeduction.raw.html mmdeduction.html /html /symbols /css /labels" \
    #     "markup mmnatded.raw.html mmnatded.html /html /symbols /css /labels" \
    #     "markup mmzfcnd.raw.html mmzfcnd.html /html /symbols /css /labels" \
    #     "markup mmfrege.raw.html mmfrege.html /html /symbols /css /labels" \
    #     "show statement */html/time"  \
    #     "write theorem_list /html /theorems_per_page 100 /show_lemmas" \
    #     "write bibliography mmbiblio.html"  \
    #     "write recent_additions mmrecent.html /html /limit 100" \
    #     "write recent_additions mmrecent.html /html /limit 1000" \
    #     "exit"
    # rm -f mmtheorems.html~1
    # rm -f mmbiblio.html~1
    # rm -f mmrecent.html~2
    # mv mmrecent.html mmrecent1000.html
    # mv mmrecent.html~1 mmrecent.html
    # cd ..
    # 
    # # There should not be an old one, but just in case
    # rm -rf mpegif-old
    # if [ -d mpegif-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'mpegif-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv mpegif mpegif-old
    # if [ -d mpegif ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'mpegif'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv mpegif-new mpegif
    # if [ -d mpegif-new ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'mpegif-new'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # rm -rf mpegif-old
    # if [ -d mpegif-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'mpegif-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "On Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # 
    # # 6-Jun-2021
    # echo "install.sh time start mpeuni: `date`"
    # 
    # cd mpeuni-new
    # # 16-Dec-2018 nm Added markup mm*.raw.html
    # # show statement... = regenerate proof pages (alt_html = Unicode version)
    # # write bibliography... = refresh bibiographic cross-reference
    # # write recent_additions... = refresh recent additions
    # ../metamath/metamath  "read '../metamath/set.mm'" \
    #     "markup mmset.raw.html mmset.html /alt_html /symbols /css /labels" \
    #     "markup mmcomplex.raw.html mmcomplex.html /alt_html /symbols /css /labels" \
    #     "markup mmdeduction.raw.html mmdeduction.html /alt_html /symbols /css /labels" \
    #     "markup mmnatded.raw.html mmnatded.html /alt_html /symbols /css /labels" \
    #     "markup mmzfcnd.raw.html mmzfcnd.html /alt_html /symbols /css /labels" \
    #     "markup mmfrege.raw.html mmfrege.html /alt_html /symbols /css /labels" \
    #     "show statement */alt_html/time"  \
    #     "write theorem_list /alt_html /theorems_per_page 100 /show_lemmas" \
    #     "write bibliography mmbiblio.html" \
    #     "write recent_additions mmrecent.html /alt_html / limit 100" \
    #     "write recent_additions mmrecent.html /alt_html / limit 1000" \
    #     "exit"
    # rm -f mmtheorems.html~1
    # rm -f mmbiblio.html~1
    # rm -f mmrecent.html~2
    # mv mmrecent.html mmrecent1000.html
    # mv mmrecent.html~1 mmrecent.html
    # cd ..
    # 
    # if  ! [ -d mpeuni ] ; then
    #   # We're doing an initial build, not a rebuild
    #   mkdir mpeuni
    # fi
    # # There should not be an old one, but just in case
    # rm -rf mpeuni-old
    # if [ -d mpeuni-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'mpeuni-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv mpeuni mpeuni-old
    # if [ -d mpeuni ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'mpeuni'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv mpeuni-new mpeuni
    # if [ -d mpeuni-new ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'mpeuni-new'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # rm -rf mpeuni-old
    # if [ -d mpeuni-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'mpeuni-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "On Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # 
    # 
    # ######## Generate Quantum Logic Explorer ############
    # # Copy manually-created files.  The qlegif directory is assumed to contain
    # # the lastest "master" versions of them.  The qleuni directory is discarded.
    # mkdir qlegif-new
    # cp -p metamathsite/qlegif/* qlegif-new/
    # 
    # [ -f favicon.ico ] && cp -p favicon.ico qlegif-new/
    # [ -f _nmemail.gif ] && cp -p _nmemail.gif qlegif-new/
    # 
    # # Copy the non-custom symbols needed from the symbols subdirectory
    # for i in \
    #     0 1 amp bigto cap cc comma cup eq equiv le lnot lp rp to \
    #     vee supperp langle rangle perp
    # do
    #   [ -f symbols/${i}.gif ] && cp -p symbols/${i}.gif qlegif-new/
    # done
    # 
    # # Copy the custom symbols needed from the mpegif subdirectory
    # for i in _scrch _veeh _vdash _wff bn65_20 spacer _bi
    # do
    #   [ -f mpegif/${i}.gif ] && cp -p mpegif/${i}.gif qlegif-new/
    # done
    # # Copy font file from mpegif directory
    # [ -f mpegif/xits-math.woff ] && \
    #    cp -p mpegif/xits-math.woff qlegif-new/
    # 
    # # All manually-created files are the same for both gif and symbol-font versions
    # mkdir qleuni-new
    # cp -p qlegif-new/* qleuni-new/
    # 
    # # 6-Jun-2021
    # echo "install.sh time start qlegif and others: `date`"
    # 
    # # Regenerate proof pages
    # cd qlegif-new
    # ../metamath/metamath  "read '../metamath/ql.mm'" \
    #     "show statement */html" \
    #     "write theorem_list /theorems_per_page 100 /show_lemmas" \
    #     "exit"
    # rm -f mmtheorems.html~1
    # cd ..
    # # There should not be an old one, but just in case
    # rm -rf qlegif-old
    # if [ -d qlegif-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'qlegif-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv qlegif qlegif-old
    # if [ -d qlegif ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'qlegif'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv qlegif-new qlegif
    # if [ -d qlegif-new ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'qlegif-new'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # rm -rf qlegif-old
    # if [ -d qlegif-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'qlegif-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "On Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # cd qleuni-new
    # ../metamath/metamath  "read '../metamath/ql.mm'" \
    #     "show statement */alt_html" \
    #     "write theorem_list /theorems_per_page 100 /show_lemmas" \
    #     "exit"
    # rm -f mmtheorems.html~1
    # cd ..
    # if  ! [ -d qleuni ] ; then
    #   # We're doing an initial build, not a rebuild
    #   mkdir qleuni
    # fi
    # # There should not be an old one, but just in case
    # rm -rf qleuni-old
    # if [ -d qleuni-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'qleuni-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv qleuni qleuni-old
    # if [ -d qleuni ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'qleuni'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv qleuni-new qleuni
    # if [ -d qleuni-new ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'qleuni-new'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # rm -rf qleuni-old
    # if [ -d qleuni-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'qleuni-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "On Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # 
    # 
    # # 16-Apr-2015 nm Added nfe
    # ######## Generate New Foundations Explorer ############
    # # Copy manually-created files.  The nfegif directory is assumed to contain
    # # the lastest "master" versions of them.  The nfeuni directory is discarded.
    # mkdir nfegif-new
    # cp -p metamathsite/nfegif/* nfegif-new/
    # 
    # [ -f favicon.ico ] && cp -p favicon.ico nfegif-new/
    # [ -f _nmemail.gif ] && cp -p _nmemail.gif nfegif-new/
    # 
    # # Copy the non-custom symbols needed from the symbols subdirectory
    # for i in \
    #     bigto amp \
    #     backquote backquote lp oplus varnothing otimes rp comma longrightarrow \
    #     lnot barwedge onetoone onetooneonto to onto solidus diagup wedge colon \
    #     leftrightarrow langle llangle lt le le lt eq ne rangle rrangle forall  \
    #     subsetneq subseteq exists perp top bigcup times times lbrack setminus vee \
    #     rbrack rmce rmci rmci rmcv backtick in notin cap riota circ circ cup   \
    #     lbrace vert mapsto bigcap restriction rbrace scrp scrp approx finv \
    #     veebar
    # do
    #   [ -f symbols/${i}.gif ] && cp -p symbols/${i}.gif nfegif-new/
    # done
    # 
    # # Copy the custom symbols needed from the mpegif subdirectory
    # # 18-Aug-2016 nm Added _.plus.gif ... _.vee.gif needed by nf.mm
    # # 6-Jun-2019 nm _set -> _setvar
    # for i in \
    #     _plc _plus _wedge _le _vee _1st _2nd _ca _cb _cc _cd _ce _e1 _em1 _cf    \
    #     _fix _fn _fun _cg _ch _ci _isom _cj _ck _cl _cm _cn _co _cp _cq _cr _rel \
    #     _cs _ct _cu _cupbar _cv _cw _cx _cy _cz _ulbrack _urbrack _hatm _hatpm   \
    #     _cnv _cnv _a _b _c _chi _class _d _dom _e _eta _f _g _h _i _if _j _k     \
    #     _kappa _l _lambda _m _mu _n _o _p _varphi _psi _q _r _ran _rho _s _setvar \
    #     _sigma _t _tau _theta _u _v _w _wff _x _y _z _zeta _vdash _capbar  \
    #     _.plus _.wedge _.le _.vee                                                 \
    #     _.oplus _.otimes _.ast _.plushat _.plusb _.comma _.minus _.solidus _.0    \
    #     _.bf0 _.1 _.lt _.times _.uparrow _.perp _.cdot _.bullet _.parallel _.sim  \
    #     _finvbar _dlbrack _drbrack
    # do
    #   [ -f mpegif/${i}.gif ] && cp -p mpegif/${i}.gif nfegif-new/
    # done
    # # Copy font file from mpegif directory
    # [ -f mpegif/xits-math.woff ] && \
    #    cp -p mpegif/xits-math.woff nfegif-new/
    # # 18-Oct-2015 nm The customized mmbiblio.html template now has a
    # # globally-unique name to prevent confusion during editing
    # [ -f nfegif-new/mmbiblio_NF.html ] && \
    #     cp -p nfegif-new/mmbiblio_NF.html nfegif-new/mmbiblio.html
    # 
    # # All manually-created files are the same for both gif and symbol-font versions
    # mkdir nfeuni-new
    # cp -p nfegif-new/* nfeuni-new/
    # 
    # # Regenerate proof pages
    # cd nfegif-new
    # ../metamath/metamath  "read '../metamath/nf.mm'" \
    #     "markup mmnf.raw.html mmnf.html /html /symbols /css /labels" \
    #     "show statement */html" \
    #     "write theorem_list /theorems_per_page 100 /show_lemmas" \
    #     "write bibliography mmbiblio.html" \
    #     "exit"
    # rm -f mmtheorems.html~1
    # cd ..
    # # There should not be an old one, but just in case
    # rm -rf nfegif-old
    # if [ -d nfegif-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'nfegif-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv nfegif nfegif-old
    # if [ -d nfegif ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'nfegif'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv nfegif-new nfegif
    # if [ -d nfegif-new ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'nfegif-new'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # rm -rf nfegif-old
    # if [ -d nfegif-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'nfegif-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "On Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # cd nfeuni-new
    # ../metamath/metamath  "read '../metamath/nf.mm'" \
    #     "markup mmnf.raw.html mmnf.html /alt_html /symbols /css /labels" \
    #     "show statement */alt_html"  \
    #     "write theorem_list /theorems_per_page 100 /show_lemmas" \
    #     "write bibliography mmbiblio.html" \
    #     "exit"
    # rm -f mmtheorems.html~1
    # cd ..
    # if  ! [ -d nfeuni ] ; then
    #   # We're doing an initial build, not a rebuild
    #   mkdir nfeuni
    # fi
    # # There should not be an old one, but just in case
    # rm -rf nfeuni-old
    # if [ -d nfeuni-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'nfeuni-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv nfeuni nfeuni-old
    # if [ -d nfeuni ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'nfeuni'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv nfeuni-new nfeuni
    # if [ -d nfeuni-new ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'nfeuni-new'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # rm -rf nfeuni-old
    # if [ -d nfeuni-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'nfeuni-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "On Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # 
    # 
    # 
    # # 12-Jul-2015 nm Added hol
    # ######## Generate Higher-Order Logic Explorer ############
    # # Copy manually-created files.  The holgif directory is assumed to contain
    # # the lastest "master" versions of them.  The holuni directory is discarded.
    # mkdir holgif-new
    # cp -p metamathsite/holgif/* holgif-new/
    # 
    # [ -f favicon.ico ] && cp -p favicon.ico holgif-new/
    # [ -f _nmemail.gif ] && cp -p _nmemail.gif holgif-new/
    # 
    # # Copy the non-custom symbols needed from the symbols subdirectory
    # for i in \
    #     bigto amp \
    #     bigto colon comma eq exists forall hexstar iota lambda lbrack lnot lp \
    #     models perp rbrack rp to top varepsilon vee wedge
    # do
    #   [ -f symbols/${i}.gif ] && cp -p symbols/${i}.gif holgif-new/
    # done
    # 
    # # Copy the custom symbols needed from the mpegif subdirectory
    # # 12-Jul-2015 Note: _alpha.gif _beta.gif _delta.gif _gamma.gif are for hol only
    # for i in \
    #                  _ca _cb _cc _cf _cr _cs _ct        _e1 _f _g        _p _q \
    #     _vdash _x _y _z
    # do
    #   [ -f mpegif/${i}.gif ] && cp -p mpegif/${i}.gif holgif-new/
    # done
    # # Copy font file from mpegif directory
    # [ -f mpegif/xits-math.woff ] && \
    #    cp -p mpegif/xits-math.woff holgif-new/
    # 
    # # 18-Oct-2015 nm The customized mmbiblio.html template now has a
    # # globally-unique name to prevent confusion during editing
    # [ -f holgif-new/mmbiblio_HOL.html ] && \
    #     cp -p holgif-new/mmbiblio_HOL.html holgif-new/mmbiblio.html
    # 
    # # All manually-created files are the same for both gif and Unicode versions
    # mkdir holuni-new
    # cp -p holgif-new/* holuni-new/
    # 
    # # Regenerate proof pages
    # cd holgif-new
    # ../metamath/metamath  "read '../metamath/hol.mm'" \
    #     "show statement */html" \
    #     "write theorem_list /theorems_per_page 100 /show_lemmas" \
    #     "write bibliography mmbiblio.html" \
    #     "exit"
    # rm -f mmtheorems.html~1
    # cd ..
    # # There should not be an old one, but just in case
    # rm -rf holgif-old
    # if [ -d holgif-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'holgif-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv holgif holgif-old
    # if [ -d holgif ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'holgif'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv holgif-new holgif
    # if [ -d holgif-new ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'holgif-new'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # rm -rf holgif-old
    # if [ -d holgif-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'holgif-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "On Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # cd holuni-new
    # ../metamath/metamath  "read '../metamath/hol.mm'" \
    #     "show statement */alt_html"  \
    #     "write theorem_list /theorems_per_page 100 /show_lemmas" \
    #     "write bibliography mmbiblio.html" \
    #     "exit"
    # rm -f mmtheorems.html~1
    # cd ..
    # if  ! [ -d holuni ] ; then
    #   # We're doing an initial build, not a rebuild
    #   mkdir holuni
    # fi
    # # There should not be an old one, but just in case
    # rm -rf holuni-old
    # if [ -d holuni-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'holuni-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv holuni holuni-old
    # if [ -d holuni ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'holuni'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv holuni-new holuni
    # if [ -d holuni-new ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'holuni-new'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # rm -rf holuni-old
    # if [ -d holuni-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'holuni-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "On Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # 
    # 
    # 
    # # 21-Jul-2015 nm Added ile
    # ######## Generate Intuitionistic Logic Explorer ############
    # # Copy manually-created files.  The ilegif directory is assumed to contain
    # # the lastest "master" versions of them.  The ileuni directory is discarded.
    # mkdir ilegif-new
    # cp -p metamathsite/ilegif/* ilegif-new/
    # 
    # [ -f favicon.ico ] && cp -p favicon.ico ilegif-new/
    # [ -f _nmemail.gif ] && cp -p _nmemail.gif ilegif-new/
    # 
    # # Copy the non-custom symbols needed from the symbols subdirectory
    # for i in \
    #     lp rp lnot barwedge to solidus wedge leftrightarrow  forall eq  \
    #      exists perp top lbrack vee rbrack  in   \
    #      lbrace vert rbrace veebar finv notin  \
    #      varnothing comma langle rangle subsetneq subseteq bigcup setminus \
    #      rmcv cap cup bigcap scrp mapsto omega rmce rmci
    # do
    #   [ -f symbols/${i}.gif ] && cp -p symbols/${i}.gif ilegif-new/
    # done
    # 
    # # Copy the custom symbols needed from the mpegif subdirectory
    # for i in \
    #     _ca _cb  \
    #     _e1 _em1 _chi _class _eta _f _g  \
    #     _kappa _lambda _mu _varphi _psi _rho _set _sigma _tau _theta _u _v _w  \
    #     _wff _x _y _z _zeta _vdash     \
    #     _.oplus _.otimes _.ast _.plus _.plushat _.plusb _.comma _.minus            \
    #     _.solidus _.wedge _.0 _.bf0 _.1 _.lt _.le _.times _.vee _.uparrow _.perp   \
    #     _.cdot _.bullet _.parallel _.sim ne _cc _cd _ce _cf _finvbar _cg           \
    #     _ch _ci _cj _ck _cl _cm _cn _co _cp _cq _cr _cs _ct _cu _cv _cw _cx _cy    \
    #     _cz  _a _b _c _d _e _h _i _j _k _l _m _n _o _p _q _r _s _sandbox \
    #     _dlbrack _ulbrack _drbrack _urbrack _t \
    #     _capbar _ctr _cupbar _lim _on _or _ord _po _suc
    # do
    #   [ -f mpegif/${i}.gif ] && cp -p mpegif/${i}.gif ilegif-new/
    # done
    # # Copy font file from mpegif directory
    # [ -f mpegif/xits-math.woff ] && \
    #    cp -p mpegif/xits-math.woff ilegif-new/
    # # 18-Oct-2015 nm The customized mmbiblio.html template now has a
    # # globally-unique name to prevent confusion during editing
    # [ -f ilegif-new/mmbiblio_IL.html ] && \
    #     cp -p ilegif-new/mmbiblio_IL.html ilegif-new/mmbiblio.html
    # 
    # # 15-Aug-2018 nm The customized mmrecent.html template now has a
    # # globally-unique name to prevent confusion during editing
    # [ -f ilegif-new/mmrecent_IL.html ] && \
    #     cp -p ilegif-new/mmrecent_IL.html ilegif-new/mmrecent.html
    # 
    # # All manually-created files are the same for both gif and symbol-font versions
    # mkdir ileuni-new
    # cp -p ilegif-new/* ileuni-new/
    # 
    # # Regenerate proof pages
    # cd ilegif-new
    # ../metamath/metamath  "read '../metamath/iset.mm'" \
    #     "markup mmil.raw.html mmil.html /html /symbols /css /labels" \
    #     "show statement */html" \
    #     "write theorem_list /theorems_per_page 100 /show_lemmas" \
    #     "write bibliography mmbiblio.html"  \
    #     "write recent_additions mmrecent.html / limit 100" \
    #     "write recent_additions mmrecent.html / limit 1000" \
    #     "exit"
    # rm -f mmtheorems.html~1
    # rm -f mmbiblio.html~1
    # rm -f mmrecent.html~2
    # mv mmrecent.html mmrecent1000.html
    # mv mmrecent.html~1 mmrecent.html
    # cd ..
    # # There should not be an old one, but just in case
    # rm -rf ilegif-old
    # if [ -d ilegif-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'ilegif-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv ilegif ilegif-old
    # if [ -d ilegif ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'ilegif'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv ilegif-new ilegif
    # if [ -d ilegif-new ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'ilegif-new'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # rm -rf ilegif-old
    # if [ -d ilegif-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'ilegif-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "On Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # cd ileuni-new
    # ../metamath/metamath  "read '../metamath/iset.mm'" \
    #     "markup mmil.raw.html mmil.html /alt_html /symbols /css /labels" \
    #     "show statement */alt_html" \
    #     "write theorem_list /theorems_per_page 100 /show_lemmas" \
    #     "write bibliography mmbiblio.html"  \
    #     "write recent_additions mmrecent.html / limit 100" \
    #     "write recent_additions mmrecent.html / limit 1000" \
    #     "exit"
    # rm -f mmtheorems.html~1
    # rm -f mmbiblio.html~1
    # rm -f mmrecent.html~2
    # mv mmrecent.html mmrecent1000.html
    # mv mmrecent.html~1 mmrecent.html
    # cd ..
    # if  ! [ -d ileuni ] ; then
    #   # We're doing an initial build, not a rebuild
    #   mkdir ileuni
    # fi
    # # There should not be an old one, but just in case
    # rm -rf ileuni-old
    # if [ -d ileuni-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'ileuni-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv ileuni ileuni-old
    # if [ -d ileuni ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'ileuni'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # mv ileuni-new ileuni
    # if [ -d ileuni-new ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not rename the subdirectory 'ileuni-new'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "If this is Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # rm -rf ileuni-old
    # if [ -d ileuni-old ] ; then
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'ileuni-old'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "On Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # 
    # 
    # # 6-Jun-2021
    # echo "install.sh time start gifs, latex: `date`"
    # 
    # ########### Get files needed for Metamath Solitaire ###########
    # [ -f mm.gif ] && cp -p mm.gif mmsolitaire/
    # [ -f favicon.ico ] && cp -p favicon.ico mmsolitaire/
    # [ -f _nmemail.gif ] && cp -p _nmemail.gif mmsolitaire/
    # 
    # # Copy the non-custom symbols from the symbols subdirectory
    # for i in \
    #     bigcap bigcup cap cup eq exists forall in lbrace leftrightarrow lnot \
    #     lp rbrace rp subseteq to varnothing vee vert wedge
    # do
    #   [ -f symbols/${i}.gif ] && cp -p symbols/${i}.gif mmsolitaire/
    # done
    # # Copy the custom symbols from the mpegif subdirectory
    # for i in _ca _cb _x _y _z _varphi _psi
    # do
    #   [ -f mpegif/${i}.gif ] && cp -p mpegif/${i}.gif mmsolitaire/
    # done
    # 
    # 
    # ########### Get files needed for GIF Images for Math Symbols ###########
    # [ -f mm.gif ] && cp -p mm.gif symbols/
    # [ -f favicon.ico ] && cp -p favicon.ico symbols/
    # [ -f _nmemail.gif ] && cp -p _nmemail.gif symbols/
    # # This was taken out 10-Aug-03 since the directory is pubic domain
    # # and we don't want to include copyrighted images
    # #[ -f valid-html401.png ] && cp -p valid-html401.png symbols/
    # 
    # 
    # ########### Generate PDF files from LaTeX sources ###########
    # # Since not all systems will have LaTeX, we will just warn if it is missing.
    # # But the user will have to get the PDF files from the Metamath site.
    # 
    # # Check that LaTeX software is present
    # LATEX_OK=true
    # LATEX_DEPS="touch sed grep makeindex bibtex pdflatex"
    # LATEX_WRN2="?Therefore PDF files 'metamath.pdf', 'finiteaxiom.pdf',"
    # LATEX_WRN3="?'megillaward2003.pdf', and 'megillaward2004.pdf' may not have"
    # ### (See note above about megillaward2005he.pdf and megillaward2005eu.pdf,
    # ### which are omitted here)
    # LATEX_WRN4="?been created.  You should download them from http://metamath.org"
    # LATEX_WRN5="?and put them in the 'downloads' subdirectory."
    # for item in $LATEX_DEPS
    #   do
    #   if [ -z "`which $item`" ]; then
    #     LATEX_OK=false
    #     LATEX_WRN1="?Warning: '$item' (needed for LaTeX) is not present on your system."
    #   fi
    # done
    # 
    # if $LATEX_OK ; then
    # 
    #   cd latex
    # 
    #   # Compile metamath.pdf - ignore warnings from initial runs
    # 
    #   # 6-Feb-2019 temporarily disable metamath.pdf generation
    # # rm -f realref.sty
    # # rm -f metamath.bib
    # # touch metamath.ind
    # # pdflatex metamath > /dev/null 2>&1
    # # pdflatex metamath > /dev/null 2>&1
    # # bibtex metamath
    # # makeindex metamath > /dev/null 2>&1
    # # pdflatex metamath > /dev/null 2>&1
    # # pdflatex metamath
    # 
    #   # Compile finiteaxiom.pdf
    #   pdflatex finiteaxiom > /dev/null 2>&1
    #   pdflatex finiteaxiom
    # 
    #   # Compile megillaward2003.pdf
    #   pdflatex megillaward2003 > /dev/null 2>&1
    #   pdflatex megillaward2003
    # 
    #   # Compile megillaward2004.pdf
    #   pdflatex megillaward2004 > /dev/null 2>&1
    #   pdflatex megillaward2004
    # 
    # ### See note above about these, which have pdflatex errors.
    # #   # Compile megillaward2005he.pdf
    # #   pdflatex megillaward2005he > /dev/null 2>&1
    # #   pdflatex megillaward2005he
    # #
    # #   # Compile megillaward2005eu.pdf
    # #   pdflatex megillaward2005eu > /dev/null 2>&1
    # #   pdflatex megillaward2005eu
    # 
    #   # Move the PDF files to the downloads directory
    #   if [ -f metamath.pdf ] ; then
    #     mv metamath.pdf ../downloads
    #   else
    #     LATEX_OK=false
    #     LATEX_WRN1="?Warning: There was a problem creating 'metamath.pdf'."
    #   fi
    #   if [ -f finiteaxiom.pdf ] ; then
    #     mv finiteaxiom.pdf ../downloads
    #   else
    #     LATEX_OK=false
    #     LATEX_WRN1="?Warning: There was a problem creating 'finiteaxiom.pdf'."
    #   fi
    #   if [ -f megillaward2003.pdf ] ; then
    #     mv megillaward2003.pdf ../downloads
    #   else
    #     LATEX_OK=false
    #     LATEX_WRN1="?Warning: There was a problem creating 'megillaward2003.pdf'."
    #   fi
    #   if [ -f megillaward2004.pdf ] ; then
    #     mv megillaward2004.pdf ../downloads
    #   else
    #     LATEX_OK=false
    #     LATEX_WRN1="?Warning: There was a problem creating 'megillaward2004.pdf'."
    #   fi
    # 
    # ### See note above about these, which have pdflatex errors.
    # # if [ -f megillaward2005he.pdf ] ; then
    # #   mv megillaward2005he.pdf ../downloads
    # # else
    # #   LATEX_OK=false
    # #   LATEX_WRN1="?Warning: There was a problem creating 'megillaward2005he.pdf'."
    # # fi
    # # if [ -f megillaward2005eu.pdf ] ; then
    # #   mv megillaward2005eu.pdf ../downloads
    # # else
    # #   LATEX_OK=false
    # #   LATEX_WRN1="?Warning: There was a problem creating 'megillaward2005eu.pdf'."
    # # fi
    # 
    #   cd ..
    # fi
    # 
    # 
    # # 6-Jun-2021
    # echo "install.sh time start final cleanup: `date`"
    # 
    # ########### Final cleanup ###########
    # # A file name with ~ is a previous version of a file created by Metamath
    # # (There should be none, but just in case...)
    # find . -name '*~[1-9]' -exec rm -f {} \;
    # 
    # # We don't keep the compiled code because it is platform-dependent
    # if $CYGWIN ; then
    #   # Cygwin
    #   [ -f metamath/metamath.exe ] && rm -f metamath/metamath.exe
    #   # Restore the original Windows exe
    #   # Note: the original was compiled with lcc:
    #   #     lc -O m*.c -o metamath.exe
    #   # because it has a small size and doesn't require the Cygwin dll
    #   [ -f metamath/metamath.exe-save ] && mv metamath/metamath.exe-save \
    #       metamath/metamath.exe
    # else
    #   # Unix
    #   # (8/1/03:  I decided to keep it for convenience.  The drawback is
    #   #     that it may not run on all systems without recompiling.
    #   #     I put a note about this in metamath/README.TXT. - nm)
    #   # [ -f metamath/metamath ] && rm -f metamath/metamath
    #   # Dummy statement - bash doesn't like empty else..fi
    #   echo ' ' > /dev/null
    # fi
    # 
    # # Create the README.TXT for the home directory
    # cp -p rdme-home.txt README.TXT
    # # Copy the README.TXT file to DOS-format __README.TXT
    # # (This sed command changes LF to CRLF)
    # sed -e "s/\$/`echo -e '\r'`/" README.TXT > __README.TXT
    # 
    # # Copy the LICENCE file to directories containing GPL'ed software
    # cp -p LICENSE.TXT metamath/LICENSE.TXT
    # cp -p LICENSE.TXT mmsolitaire/LICENSE.TXT
    # 
    # echo "Creating compressed downloads..."
    # # Create the download files linked on the home page
    # 
    # 
    # # 4-Feb-04: I changed all README.TXT files to rdme-xxx.txt because
    # # it was too confusing having so many files with the same name.
    # # The individual README.TXT files are created individually for each
    # # download.
    # # Create the README.TXT for the downloads directory
    # cp -p rdme-downloads.txt downloads/README.TXT
    # # Copy the README.TXT file to DOS-format __README.TXT
    # # (This sed command changes LF to CRLF)
    # sed -e "s/\$/`echo -e '\r'`/" downloads/README.TXT > downloads/__README.TXT
    # 
    # # Create the local README.TXT for the download
    # cp -p rdme-metamath.txt metamath/README.TXT
    # # Copy the README.TXT file to DOS-format __README.TXT
    # # (This sed command changes LF to CRLF)
    # sed -e "s/\$/`echo -e '\r'`/" metamath/README.TXT > metamath/__README.TXT
    # # Take out the Linux compiled image & also set.mm.bz2 (if there)
    # [ -f metamath/metamath ] && mv metamath/metamath metamath-unix-bin
    # [ -f metamath/set.mm.bz2 ] && mv metamath/set.mm.bz2 set.mm.bz2
    # tar -cjf downloads/metamath.tar.bz2 metamath
    # tar -cf - metamath | gzip -9 > downloads/metamath.tar.gz
    # [ -f downloads/metamath.zip ] && rm -f downloads/metamath.zip
    # zip -r9 downloads/metamath.zip metamath
    # # 30-Dec-2016 Create a download for just the source files and metamath.exe
    # # 1-Feb-2020 Create metamath-program.zip manually when it changes to make sha256 stable
    # # [ -f downloads/metamath-program.zip ] && rm -f downloads/metamath-program.zip
    # #zip -9 downloads/metamath-program.zip metamath/*.c metamath/*.h \
    # #    metamath/configure.ac metamath/Makefile.am \
    # #    metamath/metamath.1
    # # Now restore the original files
    # # Restore the Linux compiled image
    # [ -f metamath-unix-bin ] && mv metamath-unix-bin metamath/metamath
    # [ -f set.mm.bz2 ] && mv set.mm.bz2 metamath/set.mm.bz2
    # # 4-Feb-05 I decided it's better to leave these in the master site as well
    # #rm -f metamath/README.TXT
    # #rm -f metamath/__README.TXT
    # 
    # 
    # # Added 8-Oct-2008 per suggestion of FL
    # # Create a standalone set.mm.bz2 for the daily "preproduction set.mm"
    # # download from mmrecent.html
    # cp metamath/set.mm 1.tmp
    # bzip2 -f metamath/set.mm
    # mv 1.tmp metamath/set.mm
    # 
    # 
    # # Change out-of-directory links in the mpeuni download to
    # # absolute URLs so that it won't have broken links
    # # (The links to the "GIF version" will still be broken,
    # # but the user is told that on index.html.)
    # FILE_LIST="mmset.html mmhil.html mmmusic.html"
    # mkdir tmp
    # for i in $FILE_LIST ; do
    #   cp -p mpeuni/$i tmp/
    #   # The 2nd sed removes the web bug.
    #   sed -e 's/HREF=\"..\//HREF=\"http:\/\/us.metamath.org\//g' \
    #      < tmp/$i \
    #      | sed -e 's/http:\/\/us2.metamath.org:8888\/mpegif\/short/short/g' \
    #      > mpegif/$i
    # done
    # # Create the local README.TXT for the download
    # cp -p rdme-mpeuni.txt mpeuni/README.TXT
    # # Copy the README.TXT file to DOS-format __README.TXT
    # # (This sed command changes LF to CRLF)
    # sed -e "s/\$/`echo -e '\r'`/" mpeuni/README.TXT > mpeuni/__README.TXT
    # # Create the download files
    # tar -cjf downloads/mpeuni.tar.bz2 mpeuni
    # # We're running out of space, don't generate this
    # # tar -cf - mpeuni | gzip -9 > downloads/mpeuni.tar.gz
    # [ -f downloads/mpeuni.zip ] && rm -f downloads/mpeuni.zip
    # zip -r9 downloads/mpeuni.zip mpeuni
    # # Now restore the original files
    # mv tmp/* mpeuni/
    # rmdir tmp/
    # #rm -f mpeuni/__README.TXT
    # #rm -f mpeuni/README.TXT
    # 
    # 
    # # Change out-of-directory links in the qleuni download to
    # # absolute URLs so that it won't have broken links
    # mkdir tmp/
    # cp -p qleuni/mmql.html tmp/
    # sed -e 's/HREF=\"..\//HREF=\"http:\/\/us.metamath.org\//g' \
    #    < tmp/mmql.html > qleuni/mmql.html
    # # Create the local README.TXT for the download
    # cp -p rdme-qleuni.txt qleuni/README.TXT
    # # Copy the README.TXT file to DOS-format __README.TXT
    # # (This sed command changes LF to CRLF)
    # sed -e "s/\$/`echo -e '\r'`/" qleuni/README.TXT > qleuni/__README.TXT
    # # Create the download files
    # tar -cjf downloads/qleuni.tar.bz2 qleuni
    # tar -cf - qleuni | gzip -9 > downloads/qleuni.tar.gz
    # [ -f downloads/qleuni.zip ] && rm -f downloads/qleuni.zip
    # zip -r9 downloads/qleuni.zip qleuni
    # # Now restore the original mmql.html
    # mv tmp/* qleuni/
    # rmdir tmp/
    # #rm -f qleuni/__README.TXT
    # #rm -f qleuni/README.TXT
    # 
    # 
    # # 16-Apr-2015 nm Added nfe
    # # Change out-of-directory links in the nfeuni download to
    # # absolute URLs so that it won't have broken links
    # mkdir tmp/
    # cp -p nfeuni/mmnf.html tmp/
    # sed -e 's/HREF=\"..\//HREF=\"http:\/\/us.metamath.org\//g' \
    #    < tmp/mmnf.html > nfeuni/mmnf.html
    # # Create the local README.TXT for the download
    # cp -p rdme-nfeuni.txt nfeuni/README.TXT
    # # Copy the README.TXT file to DOS-format __README.TXT
    # # (This sed command changes LF to CRLF)
    # sed -e "s/\$/`echo -e '\r'`/" nfeuni/README.TXT > nfeuni/__README.TXT
    # # Create the download files
    # tar -cjf downloads/nfeuni.tar.bz2 nfeuni
    # tar -cf - nfeuni | gzip -9 > downloads/nfeuni.tar.gz
    # [ -f downloads/nfeuni.zip ] && rm -f downloads/nfeuni.zip
    # zip -r9 downloads/nfeuni.zip nfeuni
    # # Now restore the original mmnf.html
    # mv tmp/* nfeuni/
    # rmdir tmp/
    # #rm -f nfeuni/__README.TXT
    # #rm -f nfeuni/README.TXT
    # 
    # 
    # # 12-Jul-2015 nm Added hol
    # # Change out-of-directory links in the holuni download to
    # # absolute URLs so that it won't have broken links
    # mkdir tmp/
    # cp -p holuni/mmhol.html tmp/
    # sed -e 's/HREF=\"..\//HREF=\"http:\/\/us.metamath.org\//g' \
    #    < tmp/mmhol.html > holuni/mmhol.html
    # # Create the local README.TXT for the download
    # cp -p rdme-holuni.txt holuni/README.TXT
    # # Copy the README.TXT file to DOS-format __README.TXT
    # # (This sed command changes LF to CRLF)
    # sed -e "s/\$/`echo -e '\r'`/" holuni/README.TXT > holuni/__README.TXT
    # # Create the download files
    # tar -cjf downloads/holuni.tar.bz2 holuni
    # tar -cf - holuni | gzip -9 > downloads/holuni.tar.gz
    # [ -f downloads/holuni.zip ] && rm -f downloads/holuni.zip
    # zip -r9 downloads/holuni.zip holuni
    # # Now restore the original mmhol.html
    # mv tmp/* holuni/
    # rmdir tmp/
    # #rm -f holuni/__README.TXT
    # #rm -f holuni/README.TXT
    # 
    # 
    # # 21-Jul-2015 nm Added ile
    # # Change out-of-directory links in the ileuni download to
    # # absolute URLs so that it won't have broken links
    # mkdir tmp/
    # cp -p ileuni/mmil.html tmp/
    # sed -e 's/HREF=\"..\//HREF=\"http:\/\/us.metamath.org\//g' \
    #    < tmp/mmil.html > ileuni/mmil.html
    # # Create the local README.TXT for the download
    # cp -p rdme-ileuni.txt ileuni/README.TXT
    # # Copy the README.TXT file to DOS-format __README.TXT
    # # (This sed command changes LF to CRLF)
    # sed -e "s/\$/`echo -e '\r'`/" ileuni/README.TXT > ileuni/__README.TXT
    # # Create the download files
    # tar -cjf downloads/ileuni.tar.bz2 ileuni
    # tar -cf - ileuni | gzip -9 > downloads/ileuni.tar.gz
    # [ -f downloads/ileuni.zip ] && rm -f downloads/ileuni.zip
    # zip -r9 downloads/ileuni.zip ileuni
    # # Now restore the original mmil.html
    # mv tmp/* ileuni/
    # rmdir tmp/
    # #rm -f ileuni/__README.TXT
    # #rm -f ileuni/README.TXT
    # 
    # 
    # # The GIF versions are not presently downloadable
    # #tar -cf - mpegif | gzip -9 > downloads/mpegif.tar.gz
    # #tar -cf - qlegif | gzip -9 > downloads/qlegif.tar.gz
    # #tar -cf - nfegif | gzip -9 > downloads/nfegif.tar.gz
    # #tar -cf - holgif | gzip -9 > downloads/holgif.tar.gz
    # #tar -cf - ilegif | gzip -9 > downloads/ilegif.tar.gz
    # 
    # 
    # # Change out-of-directory links in the mmsolitaire download to
    # # absolute URLs so that it won't have broken links
    # mkdir tmp/
    # cp -p mmsolitaire/mms.html tmp/
    # sed -e 's/HREF=\"..\//HREF=\"http:\/\/us.metamath.org\//g' \
    #    < tmp/mms.html > mmsolitaire/mms.html
    # # Create the local README.TXT for the download
    # cp -p rdme-mmsolitaire.txt mmsolitaire/README.TXT
    # # Copy the README.TXT file to DOS-format __README.TXT
    # # (This sed command changes LF to CRLF)
    # sed -e "s/\$/`echo -e '\r'`/" mmsolitaire/README.TXT > mmsolitaire/__README.TXT
    # # Create the download files
    # tar -cjf downloads/mmsolitaire.tar.bz2 mmsolitaire
    # tar -cf - mmsolitaire | gzip -9 > downloads/mmsolitaire.tar.gz
    # [ -f downloads/mmsolitaire.zip ] && rm -f downloads/mmsolitaire.zip
    # zip -r9 downloads/mmsolitaire.zip mmsolitaire
    # # Now restore the original mmsolitaire directory
    # mv tmp/* mmsolitaire/
    # rmdir tmp/
    # #rm -f mmsolitaire/__README.TXT
    # #rm -f mmsolitaire/README.TXT
    # 
    # # Create the downloads
    # 
    # # 10-Aug-2011 nm Put the custom gifs in mpegif into the symbols
    # # download, for use by mmj2
    # mv symbols/ symbols-save/
    # mkdir symbols
    # cp -p symbols-save/* symbols/
    # cp -p mpegif/_*.gif symbols/
    # 
    # tar -cjf downloads/symbols.tar.bz2 symbols
    # tar -cf - symbols | gzip -9 > downloads/symbols.tar.gz
    # [ -f downloads/symbols.zip ] && rm -f downloads/symbols.zip
    # # (This old version causes argument list overflow on Cygwin:)
    # #  zip -r downloads/symbols.zip  `LC_COLLATE=C ls symbols/*`
    # # (This newer version seems to work on all systems:)
    # LC_COLLATE=C ls symbols | sed -e 's/^/symbols\//' | \
    #       xargs zip -r9 downloads/symbols.zip
    # # (Note that LC_COLLATE=C above forces a standard sorting order for 'ls',
    # #   regardless of the system setting that can be seen with the 'locale'
    # #   program.  [The 'locale' program doesn't seem to be available on Cygwin.])
    # #
    # # Remove the unofficial __README.TXT
    # #rm -f symbols/__README.TXT
    # 
    # 
    # # 10-Aug-2011 nm Restore original symbols directory
    # rm -rf symbols/
    # mv symbols-save/ symbols/
    # 
    # 
    # # Create the alternate quantum-logic downloads (only .bz2 is permanent)
    # tar -xjf downloads/quantum-logic.tar.bz2
    # tar -cf - quantum-logic | gzip -9 > downloads/quantum-logic.tar.gz
    # [ -f downloads/quantum-logic.zip ] && rm -f downloads/quantum-logic.zip
    # zip -r9 downloads/quantum-logic.zip quantum-logic
    # rm -rf quantum-logic/
    # 
    # ###### Temporary stuff that can be deleted eventually (but don't ########
    # ###### do any harm whether or not the indicated files are there) ########
    # ###### Also, the indicated files should be deleted eventually -  ########
    # ###### they're not part of Metamath.                             ########
    # # Apr. 28 2006 - font comparison for o'cat
    # #keep [ -f metamathsite/fontcompare.gif ] && rm -f metamathsite/fontcompare.gif
    # # May 10 2006 - safari font comparison
    # #keep [ -f metamathsite/fontcompare-safari.pdf ] && rm -f metamathsite/fontcompare-safari.pdf
    # # 23-Sep-2006 - sample scan of N. Megill's notes
    # #keep [ -f metamathsite/alephfp.png ] && rm -f metamathsite/alephfp.png
    # # 15-Nov-2008   /c/n/MAP/
    # # [ -f metamathsite/resume.pdf ] && rm -f metamathsite/resume.pdf
    # # [ -f metamathsite/megillproject.pdf ] && rm -f metamathsite/megillproject.pdf
    # # [ -f metamathsite/megillprojectslides.pdf ] && rm -f metamathsite/megillprojectslides.pdf
    # 
    # # Create final minimal site master file
    # # Copy the updated MD5 sum to the site build directory - just to be nitpicky
    # cp -p symbols/symbols.html metamathsite/symbols/
    # # Create the local README.TXT for the download
    # cp -p rdme-metamathsite.txt metamathsite/README.TXT
    # # Copy the README.TXT file to DOS-format __README.TXT
    # # (This sed command changes LF to CRLF)
    # sed -e "s/\$/`echo -e '\r'`/" metamathsite/README.TXT \
    #     > metamathsite/__README.TXT
    # # Remove any temporary working copy of set.mm
    # [ -f metamathsite/set.mm ] && rm -f metamathsite/set.mm
    # # Aug. 05 - Remove the temporary AWARD2005*.pdf's put there for the AWARD2005
    # # site link (take this out once Bill McCune changes his site link)
    # [ -f metamathsite/award2005he.pdf ] && rm -f metamathsite/award2005he.pdf
    # [ -f metamathsite/award2005eu.pdf ] && rm -f metamathsite/award2005eu.pdf
    # # Build the downloads
    # tar -cjf downloads/metamathsite.tar.bz2 metamathsite
    # # We're running out of space, don't generate this
    # # tar -cf - metamathsite | gzip -9 > downloads/metamathsite.tar.gz
    # [ -f downloads/metamathsite.zip ] && rm -f downloads/metamathsite.zip
    # zip -r9 downloads/metamathsite.zip metamathsite
    # # 30-Mar-05 nm Disabled the 'echo' below
    # # Put in instructions for after the build
    # # echo "To navigate this directory, open index.html in your browser." > \
    # #  __README.TXT
    # 
    # # Now delete the minimal site master directory
    # rm -rf metamathsite/
    # if [ -d metamathsite ] ; then
    #   # If the rm -rf failed, some files in 'metamathsite' may be gone but not
    #   # others.  However, everything else completed OK.  We must prevent
    #   # metamathsite from being used for recovery, so we create a dummy
    #   # tmpmetamathsite file for use by install.sh recovery the next time around.
    # #DEBUG
    # #echo debugmkdirtmpmetamathsite3
    #   mkdir tmpmetamathsite
    #   # See comment about Windows XP above.
    #   echo "?Fatal error: Could not delete the subdirectory 'metamathsite'."
    #   echo "Is someone else using that subdirectory?"
    #   echo "On Windows, please reboot before running install.sh again."
    #   exit 1
    # fi
    # 
    # ########### Create compressed site for metamath.planetmirror.com ##########
    # #tar -cf - * | gzip -9 > ../metamathmirror.tar.gz
    # 
    # echo ""
    # # Produce a warning if LaTeX is not installed
    # if $LATEX_OK ; then
    #   echo "The installation completed successfully.  The home page is index.html."
    # else
    #   echo "The installation completed (mostly) successfully, except the following:"
    #   echo ""
    #   echo $LATEX_WRN1
    #   echo $LATEX_WRN2
    #   echo $LATEX_WRN3
    #   echo $LATEX_WRN4
    #   echo $LATEX_WRN5
    # fi
    # 
    # # 6-Jun-2021
    # echo "install.sh time end: `date`"
    # 
    # TODO

    mkdir -p "$METAMATHSITE/mpegif/"
    # Copy .html / .raw.html files for mpe (set.mm)
    (
      cd repos/set.mm || exit 1
      cp -p \
        mmbiblio.html \
        mmcomplex.raw.html \
        mmdeduction.raw.html \
        mmfrege.raw.html \
        mmhil.html \
        mmmusic.html \
        mmnatded.raw.html \
        mmrecent.html \
        mmset.raw.html \
        mmtopstr.html \
        mmzfcnd.raw.html \
        mm-j-commands.html \
        "$METAMATHSITE/mpegif"
    )

    mkdir -p "$METAMATHSITE/ilegif/"
    # Copy .html / .raw.html files for ile (iset.mm)
    # Not handled:
    # /opt/dts/mmmaster/metamathsite/ilegif/mmbiblio_IL.html
    (
      cd repos/set.mm || exit 1
      cp -p \
        mmil.raw.html \
        mmrecent_IL.html \
        "$METAMATHSITE/ilegif/"
    )

    cp -p repos/set.mm/mm_100.html "$METAMATHSITE/"

;;
esac

# echo 'DEBUG: Showing the files generaated so far'
# find "$METAMATHSITE"

case "${COPY_TO_WEBPAGE}" in
y)
    if [ -d /var/www/us.metamath.org ]; then
        mkdir /var/www/us.metamath.org/html
        echo 'Copying generated pages to website'
        rsync -a --delete "$METAMATHSITE/" /var/www/us.metamath.org/html/
    fi
;;
esac

end_date="$(date)"
echo
echo "Start: ${start_date}"
echo "End:   ${end_date}"

exit 0
