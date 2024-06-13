#!/bin/sh
# build-website.sh - build the Metamath website contents

# set -eu
set -x

# prepare GIF census
ls symbols > symbols.tmp

# copy files
cp ../repos/set.mm/mm_100.html .
cp ../repos/set.mm/mmbiblio.raw.html \
   ../repos/set.mm/mmcomplex.raw.html \
   ../repos/set.mm/mmdeduction.raw.html \
   ../repos/set.mm/mmfrege.raw.html \
   ../repos/set.mm/mmhil.html \
   ../repos/set.mm/mmnatded.raw.html \
   ../repos/set.mm/mmrecent.raw.html \
   ../repos/set.mm/mmset.raw.html \
   ../repos/set.mm/mmzfcnd.raw.html \
   ../repos/set.mm/mm-j-commands.html mpegif
cp ../repos/set.mm/mmrecent_IL.raw.html ilegif/mmrecent.raw.html
cp ../repos/set.mm/mmil.raw.html ilegif
cp ../repos/set.mm/mmnf.raw.html nfegif

# compile HTML pages for databases
build_db () {
  db=$1
  mm=../repos/set.mm/$2.mm

  # The mpeuni build complains if we don't have these gifs, even though
  # it won't actually be using them. So make some empty files and remember
  # to delete them later.
  add_fake_gif () {
    if ! [ -f ${db}uni/$1 ]; then
      touch ${db}uni/$1
      echo $1 >> fake_gifs.tmp
    fi
  }

  # the font used for unicode math
  if [ $db != mpe ]; then
    ln -rs mpegif/xits-math.woff ${db}gif/xits-math.woff
  fi

  # initial clone of ${db}gif to ${db}uni
  mkdir -p ${db}uni
  cd ${db}gif
    for i in `ls`; do ln -rs $i ../${db}uni/$i; done
    # metamath.exe chokes on symbolic links
    for i in *.html; do rm ../${db}uni/$i; cp $i ../${db}uni; done
  cd ..

  # look for any images referenced in the html files and import them from symbols/
  for file in ${db}gif/*.html; do
    sed -n "s/^.*<IMG SRC=['\"]\([^'\"]*\)['\"].*$/\\1/p" < $file >> 1.tmp
  done
  sort -u < 1.tmp > 2.tmp
  set +x # this loop is too noisy for the log
  for i in `echo mm.gif | comm -23 2.tmp - | comm -12 - symbols.tmp`; do
    ln -rs symbols/$i ${db}gif/$i
    ln -rs symbols/$i ${db}uni/$i
  done
  set -x

  # look for any images referenced in the .mm file and import them from symbols/
  sed -n "s/^.*<IMG SRC=['\"]\([^'\"]*\)['\"].*$/\\1/p" < $mm | sort -u > 2.tmp
  echo mm.gif >> 1.tmp
  set +x # this loop is too noisy for the log
  for i in `sort -u < 1.tmp | comm -23 2.tmp - | comm -12 - symbols.tmp`; do
    ln -rs symbols/$i ${db}gif/$i
    add_fake_gif $i
  done
  set -x
  rm 1.tmp 2.tmp

  for k in gif uni; do
    # basic files
    ln -rs favicon.ico $db$k/favicon.ico
    ln -rs _nmemail.gif $db$k/_nmemail.gif
    [ $db = mpe ] && ln -rs mm.gif $db$k/mm.gif

    # /html means GIF, /alt_html means Unicode
    if [ $k = gif ]; then alt=html; else alt=alt_html; fi

    cd $db$k
      # prepare a script for metamath to produce the web pages
      echo set scroll continuous > 1.tmp
      for i in *.raw.html; do
        base=`basename $i .raw.html`
        if [ $base = mmbiblio ]; then
          cp $base.raw.html $base.html
          echo write bibliography $base.html >> 1.tmp
        elif [ $base = mmrecent ]; then
          cp $base.raw.html $base.html
          echo write recent_additions $base.html /$alt /limit 1000 >> 1.tmp
          echo write recent_additions $base.html /$alt /limit 100 >> 1.tmp
        else
          echo markup $base.raw.html $base.html /$alt /symbols /css /labels >> 1.tmp
        fi
      done
      echo write theorem_list /$alt /theorems_per_page 100 /show_lemmas >> 1.tmp
      echo "show statement * /$alt /time" >> 1.tmp

      # run metamath (this is the longest step)
      ../metamath/metamath ../$mm < 1.tmp

      [ -f mmrecent.html~1 ] && mv mmrecent.html~1 mmrecent1000.html
      rm -f 1.tmp mmbiblio.html~1 mmrecent.html~2 *.raw.html
    cd ..
  done

  for i in `< fake_gifs.tmp`; do
    rm ${db}uni/$i
  done
  rm fake_gifs.tmp
}

build_db mpe set
build_db qle ql
build_db nfe nf
build_db hol hol
build_db ile iset

# prepare additional files for mmsolitaire and symbols dirs
for dir in mmsolitaire symbols; do
  ln -rs favicon.ico $dir/favicon.ico
  ln -rs _nmemail.gif $dir/_nmemail.gif
  ln -rs mm.gif $dir/mm.gif
done

# resolve gifs in mmsolitaire
sed -n "s/^.*<IMG SRC=['\"]\([^'\"]*\)['\"].*$/\\1/p" < mmsolitaire/mms.html | sort -u > 1.tmp
for i in `echo mm.gif | comm -23 1.tmp - | comm -12 - symbols.tmp`; do
  ln -rs symbols/$i mmsolitaire/$i
done
rm 1.tmp symbols.tmp

# compile PDFs
cp ../repos/metamath-book/narrow.sty ../repos/metamath-book/normal.sty latex
cd latex
  for file in finiteaxiom megillaward2003 megillaward2004; do
    pdflatex $file
    pdflatex $file  # rerun to get references right
    mv $file.pdf ../downloads
  done
  rm *.aux *.sty # keep *.log
cd ..

[ -f rdme-home.txt ] && mv rdme-home.txt README.TXT
[ -f rdme-downloads.txt ] && mv rdme-downloads.txt downloads/README.TXT
[ -f rdme-metamath.txt ] && mv rdme-metamath.txt metamath/README.TXT
cp ../repos/set.mm/*.mm metamath

# Take out the Linux compiled image
mv metamath/metamath metamath-unix-bin

# zip the metamath folder
tar -cjf downloads/metamath.tar.bz2 metamath
tar -cf - metamath | gzip -9 > downloads/metamath.tar.gz
rm -f downloads/metamath.zip
zip -r9 downloads/metamath.zip metamath

# Restore the Linux compiled image
mv metamath-unix-bin metamath/metamath

# Create a standalone set.mm.bz2 for the daily "preproduction set.mm"
# download from mmrecent.html
bzip2 -kf metamath/set.mm

# Create downloads for the individual folders
mkdir tmp
cd tmp
  for dir in mpeuni qleuni nfeuni holuni ileuni mmsolitaire symbols; do
    [ -f ../rdme-$dir.txt ] && mv ../rdme-$dir.txt ../$dir/README.TXT

    # Change out-of-directory links in the download to
    # absolute URLs so that it won't have broken links
    cp -r ../$dir $dir
    cd $dir
      set +x # this loop is too noisy for the log
      for i in *.html; do
        sed -e 's/HREF=\"..\//HREF=\"http:\/\/us.metamath.org\//g' < ../../$dir/$i > $i
      done
      set -x
    cd ..

    tar -cjf ../downloads/$dir.tar.bz2 $dir
    # We're running out of space, don't generate this
    # tar -cf - $dir | gzip -9 > downloads/$dir.tar.gz
    rm -f ../downloads/$dir.zip
    zip -r9 ../downloads/$dir.zip $dir
    rm -r $dir
  done
cd ..
rm -r tmp

# Create the alternate quantum-logic downloads (only .bz2 is permanent)
tar -xjf downloads/quantum-logic.tar.bz2
tar -cf - quantum-logic | gzip -9 > downloads/quantum-logic.tar.gz
[ -f downloads/quantum-logic.zip ] && rm -f downloads/quantum-logic.zip
zip -r9 downloads/quantum-logic.zip quantum-logic
rm -r quantum-logic

# We no longer create the metamathsite.zip download, since this is now hosted on github
