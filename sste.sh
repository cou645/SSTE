#!/bin/bash
# simple text editor
# Copyright (C) 2024 stemsee

if [[ $(id -u) -ne 0 ]]; then
	[[ "$DISPLAY" ]] && exec gtksu "snapp" "$0" "$@" || exec su -c "$0 $*"
fi

export version=0.6
export TEXTDOMAIN=SSTE
export OUTPUT_CHARSET=UTF-8
export LAUNCHDIR="$(dirname "$(readlink -f "$0")")"
export iconpath="/usr/share/pixmaps"
export track=/tmp/SSTE-$$
export SCRIPT="$0"
export FILE="$1"
export limit='1'
mkdir -p "$track" 2>/dev/null

for i in sste/images sste/pdf sste/text
do
    [[ ! -d /root/"$i" ]] && mkdir -p /root/"$i" 2>/dev/null
done

[[ ! "$lng" ]] && lng=$(echo $LANG | cut -f1 -d'_') 
[[ -f $(type -p yad) ]] && cp $(type -p yad) -f "$track"/yad
[[ -f $(type -p yadu) ]] && cp $(type -p yadu) -f "$track"/yad
mkfifo "$track"/lpipe
exec 8<>"$track"/lpipe
mkfifo "$track"/tpipe
exec 9<>"$track"/tpipe

function updatefn {
echo -e '\f' >"$track"/lpipe
[ -d "$TXTDIR" ] && ls "$TXTDIR"/*.* | while read line
do
case "$line" in
*.txt|*.TXT|*.conf|*.lst|*.cfg|*.log|*.sh|.*.py|*.desktop|*.svg|*.set) #echo -e '\f' >"$track"/tpipe
if [[ ! -z "$(cat $line)" ]]; then
cat "$line" > "$track"/tpipe
echo -e '\t____________________________________________________\n\n' > "$track"/tpipe
fi
;;
esac
done
echo -e '\f' >"$track"/lpipe
[ -d "$IMGDIR" ] && ls "$IMGDIR"/*.* | while read line
do
case "$line" in
*.png|*.jpg|*.JPG|*.bmp|*.webp|*.svg) printf "%s\n%s\n" "$line" "$line" > "$track"/lpipe
;;
esac
done
};export -f updatefn

function depsfn {
for i in gm evince qpdfview yad xclip fmt xdotool flameshot xscreenshot
do
	[[ -z $(type -p "$i") ]] && echo -e "$i " >> "$track"/missing
done
};export -f depsfn
depsfn
function piconefn {
	exec 3<>"$track"/picpipe
	case "$1" in
	reload) echo -e '\f' >"$track"/picpipe
	piconefn "$limit"
	exit;;
	cleardl) rm -f /root/dlist
	piconefn reload
	exit;;
	esac
	if [ -f /root/dlist ]; then
	cat /root/dlist | grep -E -v -e '^$' | while read line1
	do
	read line2
	[ -z "$line1" ] && line1=$(cd /root/sste/images;"$track"/yad --file --add-preview --text="select left image")
	[ -z "$line2" ] && line2=$(cd /root/sste/images;"$track"/yad --file --add-preview --text="select right image")
	printf "%s\n%s\n%s\n" '' "$line1" "$line2" > "$track"/picpipe
	printf "%s\n%s\n%s\n" '' "$line1" "$line2" >> /root/sste/arrangement-$(date +%y%m%d%H%M).dl
	done
	elif [ "$1" -lt 4 ]; then
	for i in $(seq 1 1 "$1")
	do
	export imgone=$(cd /root/sste/images;"$track"/yad --file --add-preview --text="select left image")
	export imgtwo=$(cd /root/sste/images;"$track"/yad --file --add-preview --text="select right image")
	printf "%s\n%s\n%s\n" '' "$imgone" "$imgtwo" > "$track"/picpipe
	printf "%s\n%s\n%s\n" '' "$imgone" "$imgtwo" >> /root/sste/arrangement-$(date +%y%m%d%H%M).dl
	done
	else
	cat $("$track"/yad --file --text="select list of images" --add-preview) | grep -E -v -e '^$' | while read line1
	do
	read line2
	[ -z "$line2" ] && line1=$(cd /root/sste/images;"$track"/yad --file --add-preview --text="select left image")
	[ -z "$line1" ] && line2=$(cd /root/sste/images;"$track"/yad --file --add-preview --text="select right image")
	printf "%s\n%s\n%s\n" '' "$line1" "$line2" > "$track"/picpipe
	printf "%s\n%s\n%s\n" '' "$line1" "$line2" >> /root/sste/arrangement-$(date +%y%m%d%H%M).dl
	done
	fi
};export -f piconefn
function pictwofn {
	exec 4<>"$track"/tpicpipe
	case "$1" in
	reload) echo -e '\f' >"$track"/tpicpipe
	pictwofn
	exit;;
	cleardl) rm -f /root/dlist
	pictwofn reload
	exit;;
	esac
	if [ -f /root/dlist ]; then
	cat /root/dlist | grep -E -v -e '^$' | while read line1
	do
	read line2
	read line3 
	read line4
	printf "%s\n%s\n%s\n%s\n%s\n" '' "$line1" "$line2" "$line3" "$line4" >"$track"/tpicpipe
	printf "%s\n%s\n%s\n%s\n%s\n" '' "$line1" "$line2" "$line3" "$line4" >> /root/sste/arrangement-$(date +%y%m%d%H%M).dl
	done
	exit
	fi
	if [ "$1" == select ]; then
	cat $("$track"/yad --file --text="select list of images" --add-preview) | grep -E -v -e '^$' | while read line1
	do	
	read line2
	read line3 
	read line4
	printf "%s\n%s\n%s\n%s\n%s\n" '' "$line1" "$line2" "$line3" "$line4" >"$track"/tpicpipe
	printf "%s\n%s\n%s\n%s\n%s\n" '' "$line1" "$line2" "$line3" "$line4" >> /root/sste/arrangement-$(date +%y%m%d%H%M).dl
	done
	fi
};export -f pictwofn
function thumbnailsfn {
	FILE=$(echo "$1" | sed 's/file:\/\///g')
	if [ -f "$FILE" ]; then
		DIR=$(echo "$FILE" | awk -F'/' '{$NF="";print $0}' | sed 's| |\/|g')
		if [[ $(echo "$DIR" | rev | cut -f2 -d'/' | rev) == 'thumbs'||'thumbnails' ]]; then
		ls "$DIR"/* >> /root/dlist
		pictwofn reload
		exit
		fi
		[ -d "$DIR" ] && cd "$DIR"
		EXT=$(echo "$FILE" | rev | cut -f1 -d'.' | rev | sed 's/^/./')
	elif [ -d "$FILE" ]; then
		echo -e "Does not accept directories!!!\n        DnD one image file\n    from an image directory" | yad --text-info  --on-top --fore=red --back=black --fontname="sans bold 40" --no-buttons --no-decoration --skip-taskbar --timeout 4 --geometry=917x220+660+545 --no-border 
	exit
	fi
	mkdir -p thumbs
	case "$EXT" in
	*.webp|*.WEBP) cd "$DIR";pv -tpne "$DIR" | gm mogrify -thumbnail 475x -format png *"$EXT"
	mv -f *.png  thumbs
	;; 
	*.PNG|*.png) cd "$DIR";pv -tpne "$DIR" | gm mogrify -thumbnail 475x -format jpg *"$EXT"
	mv -f *.jpg  thumbs
	;;
	*.JPG|*.jpg) cd "$DIR";pv -tpne "$DIR" | gm mogrify -thumbnail 475x -format png *"$EXT"
	mv -f *.png  thumbs
	;;
	esac
	
	ls "$PWD"/thumbs/* >> /root/dlist
	pictwofn reload
}; export -f thumbnailsfn

function savefn {
	nlist=$(yad --text="Save as path and name" --entry)
	cat /root/dlist > "$nlist"
};export -f savefn
function byblockfn {
case "$1" in
moveup) xdotool key End Shift+Home ctrl+x Delete Up ctrl+v Return Up
exit;;
movedown) xdotool key End Shift+Home ctrl+x Delete Down ctrl+v Return Up
exit;;
esac
PAT="$(xclip -o)"
xdotool key ctrl+a
xdotool key ctrl+c
xclip -o > "$track"/MO
export L=$(xclip -o | grep -v -e '^$' -e '[^[:space:]]*$' | wc -l)
export N=$(xclip -o | wc -l)
case "$1" in
undo) cnt=0
while [[ "$cnt" -lt "$N" ]]; do
xdotool key ctrl+z
cnt=$((cnt + 1))
done
exit
;;
redo) cnt=0
while [[ "$cnt" -lt "$N" ]]; do
xdotool key ctrl+shift+z
cnt=$((cnt + 1))
done
exit
;;
dualimg) "$track"/yad --dnd --text="drop image files here" --on-top --width=200 --height=180 --command="bash -c \"sed 's/file:\/\///g'<<<$(echo "%s")>>/root/dlist \"" &

[ ! -p "$track"/picpipe ] && mkfifo "$track"/picpipe; exec 3<>"$track"/picpipe; limit=$($track/yad --entry --text="Number of Rows"); export limit="$limit";"$track"/yad --on-top --height=600 --width=900 --list --print-all --limit="$limit" --column=t:txt --column=pic1:img --column=pic2:img --listen --tail --hide-column=1 --editable --editable-cols="2,3" --no-headers --buttons-layout=center --dclick-action="bash -c \"dclickfn "%s" \"" --select-action="bash -c \"sclickfn "%s" \""  --button="Save List as":"bash -c \"savefn \""  --button="New dlist":"bash -c 'piconefn cleardl'" --button="Reload":"bash -c 'piconefn reload'" --button="Screenshot!/root/.config/snapp/icons/screeny.png!Capture area of screen and save to /root/sste/images":"bash -c \"screenshotfn \"" --button="Select Images":"bash -c \"piconefn $limit \"" <&3 &
piconefn "$limit"
echo -e '\n' >> /root/dlist
exit;;
thumbnails) "$track"/yad --dnd --text="drop one image file here from the image directory
All jpg or png or webp files will be thumbnailed."  --on-top --width=200 --height=180 --command="bash -c \"thumbnailsfn "%s" \"" &
#wait $!
[ ! -p "$track"/tpicpipe ] && mkfifo "$track"/tpicpipe; exec 4<>"$track"/tpicpipe;"$track"/yad --on-top --height=600 --width=900 --list --print-all --column=t:txt --column=pic1:img --column=pic2:img --column=pic3:img --column=pic4:img --listen --tail --hide-column=1 --editable --editable-cols="2,3,4,5" --no-headers --buttons-layout=center  --dclick-action="bash -c \"dclickfn "%s" \"" --select-action="bash -c \"sclickfn "%s" \"" --button="Save List as":"bash -c \"savefn \"" --button="New dlist":"bash -c 'pictwofn cleardl'" --button="Reload":"bash -c 'pictwofn reload'" --button="Screenshot!/root/.config/snapp/icons/screeny.png!Capture area of screen and save to /root/sste/images":"bash -c \"screenshotfn \"" --button="Select Images":"bash -c \"pictwofn select\"" <&4 & 
pictwofn
echo -e '\n' >> /root/dlist
exit;;
search) TERMS=$($track/yad  --item-separator='~' --fontname="Sans 24" --form --on-top --field="search for":txt "•" --field="replace with":txt "")
case "$?" in
252|1) exit;;
esac
FIND="$(echo $TERMS | cut -f1 -d'|')"
REPLACE="$(echo $TERMS | cut -f2 -d'|')"
echo "$PAT" | while read line; do sed -E -i "/$line/s~$FIND~$REPLACE~g" "$track"/MO; done
;;
gotoline) xdotool key down;;
center) columns="70"
    while IFS= read -r line; do
		line="$(echo $line | sed -e 's/\t//g')"
        NEW="$(printf "%*s\n" $(( (${#line} + columns) / 2)) "$line")"
        sed -i "s/$line/$NEW/" "$track"/MO
    done <<<"$PAT"
;;
right) columns="80"
    while IFS= read -r line; do
        line="$(echo $line | sed -e 's/\t//g')"
        NEW="$(printf "%*s\n" $columns "$line")"
        sed -i "s/$line/$NEW/" "$track"/MO
    done <<<"$PAT"
;;
grammar) [ -z "$PAT" ] && PAT="$(xclip -o)" && echo "$PAT" > "$track"/GRM_CHK
	java -jar /root/LanguageTool/languagetool-commandline.jar -l $(echo $LANG | cut -f1 -d'.' | tr '_' '-') "$track"/GRM_CHK | yad --fontname="" --fore="" --back="" --listen --text-info --file-op --editable --geometry=1308x1270+600+22 --title="$(hashtext 'Grammar Check')" --fontname="$(cat /root/sste/sstefont)" --fore="$(cat /root/sste/sstefront)" --back="$(cat /root/sste/ssteback)" &
	exit
;;
dictionary) curl -s dict://dict.org/d:"$PAT" | grep -E -v -e '150' -e '151' -e '220' -e '221' -e '250' | yad --listen --file-op --editable --text-info --geometry=788x765+600+22 --title="$(hashtext 'Dictionary Lookup')" --fontname="$(cat /root/sste/sstefont)" --fore="$(cat /root/sste/sstefront)" --back="$(cat /root/sste/ssteback)" &
exit
;;
ftabs) T='\t\t'
	NP=$(echo -e "$PAT" | fmt -s -w80 | sed "s|^|$T|g")
	echo -e "$NP" | xclip -b
	xdotool key ctrl+v
	exit
;;
dblines) echo -e "$PAT" | grep -v -e  '^$'  | while read line; do sed -i -e "/$line/s/$/\n/" "$track"/MO; done
;;
fold) NP=$(echo -e "$PAT" | fmt -s -w80)
	echo -e "$NP" | xclip -b
	xdotool key ctrl+v
	exit
;;
portrait) NP=$(fmt -s -w80 "$track"/MO)
cnt=1
echo -e "$NP" | tr '\r' '\n' | while read line; do [[ "$((cnt % 68))" -eq 0 ]] && sed -i "/$line/s~$line~$line\n\n\n\n~" "$track"/MO; cnt=$((cnt +1));done
;;
landscape) NP=$(fmt -s -w240 "$track"/MO)
	echo -e "$NP" | tr '\r' '\n' > "$track"/MO
;;
view_pango) #[ ! -p /tmp/sstep ] && mkfifo /tmp/sstep && exec 3<>/tmp/sstep
function markupfn {
TXT="$(xclip -o)"
#SETS=$(yad --title="Formatted Preview" --text="OPTIONS" --columns=3 --form --field=:fn "sans 26" --field=:fn "sans 14" --field=:fn "sans bold 14" --field=:fn "sans italic 14" --field=:fn "sans bold italic 14"  --field=:fn "sans 14" --field=:fn "sans bold 14" --field="<u>text</u>":clr "purple" --field=text:clr "orange" --field=text:clr "blue" --field=text:clr "green" --field=text:clr "yellow" --field="<s>text</s>":clr "red"  --field="<u><s>text</s></u>":clr "darkgrey" --field=back:clr "white" --field=back:clr "white" --field=back:clr "white" --field=back:clr "white" --field=back:clr "grey"  --field=back:clr "yellow" --field=back:clr "white" )
SETS=$(yad --title="Formatted Preview" --text="OPTIONS" --columns=3 --form --field=:fn "sans 26" --field=:fn "sans 14" --field=:fn "sans bold 14" --field=:fn "sans italic 14" --field=:fn "sans bold italic 14" --field=text:clr "black" --field=text:clr "black" --field=text:clr "black" --field=text:clr "black" --field=text:clr "black" --field=back:clr "white" --field=back:clr "white" --field=back:clr "white" --field=back:clr "yellow" --field=back:clr "white")

IFS='|' read -r tfont bodfont bodboldfont bodifont bodiboldfont tfcol bodfcol bodboldfcol bodifcol bodiboldfcol tbcol bodbcol bodboldbcol bodibcol bodiboldbcol<<<"${SETS}"

#IFS='|' read -r AA AB AC AD AE AF AG AH BA BB BC BD BE BF BG BH CA CB CC CD CE CF CG CH<<<"${SETS}"
#TTEXT="<span font=\"$AA\" fgcolor=\"$BA\" bgcolor=\"$CA\"><u>A A</u></span> <span font=\"$AB\" fgcolor=\"$BB\" bgcolor=\"$CB\">B B</span> <span font=\"$AC\" fgcolor=\"$BC\" bgcolor=\"$CC\">C C</span> <span font=\"$AD\" fgcolor=\"$BD\" bgcolor=\"$CD\">D D</span> <span font=\"$AE\" fgcolor=\"$BE\" bgcolor=\"$CE\"><u>E E</u></span> <span font=\"$AF\" fgcolor=\"$BF\" bgcolor=\"$CF\">F F</span> <span font=\"$AG\" fgcolor=\"$BG\" bgcolor=\"$CG\">G G</span> <span font=\"$AH\" fgcolor=\"$BH\" bgcolor=\"$CH\">H H</span>  "
TTEXT="  <span font=\"$tfont\" fgcolor=\"$tfcol\" bgcolor=\"$tbcol\"><u>A  A</u></span>  <span font=\"$tfont\" fgcolor=\"red\" bgcolor=\"$tbcol\"><u>A  A</u></span>  <span font=\"$tfont\" fgcolor=\"orange\" bgcolor=\"$tbcol\"><u>A  A</u></span> <span font=\"$tfont\" fgcolor=\"yellow\" bgcolor=\"$tbcol\"><u>A   A</u></span> <span font=\"$tfont\" fgcolor=\"lightgreen\" bgcolor=\"$tbcol\"><u>A  A</u></span> <span font=\"$tfont\" fgcolor=\"lightblue\" bgcolor=\"$tbcol\"><u>A  A</u></span> <span font=\"$tfont\" fgcolor=\"indigo\" bgcolor=\"$tbcol\"><u>A  A</u></span> 
<span font=\"$bodfont\" fgcolor=\"black\" bgcolor=\"$bodbcol\"><u>b  b</u></span> <span font=\"$bodfont\" fgcolor=\"black\" bgcolor=\"$bodbcol\">c  c</span> <span font=\"$bodfont\" fgcolor=\"$bodfcol\" bgcolor=\"$bodbcol\">b  b</span> <span font=\"$bodfont\" fgcolor=\"$bodfcol\" bgcolor=\"$bodbcol\"><s>c   c</s></span> <span font=\"$bodboldfont\" fgcolor=\"$bodboldfcol\" bgcolor=\"$bodbcol\">d  d</span> <span font=\"$bodboldfont\" fgcolor=\"$bodboldfcol\" bgcolor=\"$bodbcol\"><u>e  e</u></span> <span font=\"$bodboldfont\" fgcolor=\"$bodboldfcol\" bgcolor=\"$bodbcol\"><s>f   f</s></span> <span font=\"$bodifont\" fgcolor=\"$bodifcol\" bgcolor=\"$bodbcol\">g   g</span> <span font=\"$bodifont\" fgcolor=\"$bodifcol\" bgcolor=\"$bodibcol\"><u>i   i</u></span>  <span font=\"$bodifont\" fgcolor=\"$bodifcol\" bgcolor=\"$bodiboldbcol\"><s>j   j</s></span>
<span font=\"$bodfont\" fgcolor=\"yellow\" bgcolor=\"$bodbcol\"><u>b  b</u></span> <span font=\"$bodfont\" fgcolor=\"lightblue\" bgcolor=\"$bodbcol\"><s>c  c</s></span> <span font=\"$bodfont\" fgcolor=\"lightgreen\" bgcolor=\"$bodbcol\"><u>b  b</u></span> <span font=\"$bodfont\" fgcolor=\"lightblue\" bgcolor=\"$bodbcol\"><s>c   c</s></span> <span font=\"$bodboldfont\" fgcolor=\"blue\" bgcolor=\"$bodbcol\">d  d</span> <span font=\"$bodboldfont\" fgcolor=\"orange\" bgcolor=\"$bodbcol\"><u>e  e</u></span> <span font=\"$bodboldfont\" fgcolor=\"purple\" bgcolor=\"$bodbcol\"><s>f   f</s></span> <span font=\"$bodifont\" fgcolor=\"white\" bgcolor=\"lightblue\">g   g</span> <span font=\"$bodifont\" fgcolor=\"grey\" bgcolor=\"$bodibcol\"><u>i   i</u></span>  <span font=\"$bodifont\" fgcolor=\"white\" bgcolor=\"black\">j   j</span> <span font=\"$bodiboldfont\" fgcolor=\"$bodiboldfcol\" bgcolor=\"$bodbcol\">h   h</span> 
___________________________________________________________________________


"

A_TEXT=$(while read -r line; do printf "%s" "$line\n"; done <<< $(printf "%q" "$TTEXT" | sed -e "s/'$//" -e "s/^$'//"))
printf "%s\n" "$TTEXT" > /root/sste/markup-$(dat +%m%d%H%M%S).txt
printf "%s\n" "$A_TEXT" | yadu --title="Formatted Preview" --on-top --width=719 --height=412 --form --field=:txt --wrap --wrap-width=80 --enable-spell > /root/sste/text/mktext-$(date +%m%d%H%M%S).txt  --button="Screenshot!/root/.config/snapp/icons/screeny.png!Capture area of screen and save to /root/sste/images":"bash -c \"screenshotfn \"" &
wait $!
updatefn
}; export -f markupfn
markupfn
;;
execfn) xclip -o | sh
;;
tnumm) echo -e "$PAT" | grep -v -e '^$' | while read line; do NP=$(echo -e "$line" | sed -E "/^[0-999)]/s/^[0-9999)]*//g"); sed -i -e "s/$line/$NP/" "$track"/MO; done
;;
lnumm) sed -i -E -e "/^[0-9999)].*/s~^[0-9999)]+~~g" "$track"/MO
;;
bulletse) [ -z "$PAT" ] && exit; echo -e "$PAT" | grep -E -e '[a-zA-Z0-9].*' | while read line; do echo "$line" | sed -E 's/&/\&amp;/g; s/(/\(/g; s/)/\)/g; s/</\&lt;/g; s/>/\&gt;/g' | sed -E -i -e "/$line[)]*$/s/$line[)]*/$line •/" "$track"/MO; done
;;
tabsp)  echo -e "$PAT" | grep -v -e '^$'  | while read line; do sed -i -e "/$line/s/$line/\t$line/" "$track"/MO; done
;;
tabsm)  echo -e "$PAT" | grep -v -e '^$' | while read line; do sed -i -e "/$line/s/\t//" "$track"/MO; done
;;
bulletsp) [ -z "$PAT" ] && exit; echo -e "$PAT" |  grep -E -e '[a-zA-Z0-9].*' | while read line; do echo "$line" | sed -E 's/&/\&amp;/g; s/(/\(/g; s/)/\)/g; s/</\&lt;/g; s/>/\&gt;/g'  | sed -E -i -e "/[^\s\(]$line$/s/$line/• $line/" "$track"/MO; done
;;
tnum) NUM=1; echo -e "$PAT" | grep -v -e '^$' | while read line; do sed -E -i -e "/$line/s/$line/$NUM\) $line/" "$track"/MO; [ ! -z "$line" ] && NUM=$((NUM + 1)); done
;;
lnum) [ -f "$track"/a ] && rm -f "$track"/a
	[ -f "$track"/b ] && rm -f "$track"/b
	PN=$(xclip -o | wc -l)
	for i in $(seq 1 1 $PN); do echo -e "$i) " >> "$track"/a; done
	xclip -o > "$track"/b
	paste "$track"/a "$track"/b > "$track"/MO
	sed -i -e "s|\t| |" "$track"/MO
;;
rnum) [ -f "$track"/a ] && rm -f "$track"/a
	[ -f "$track"/b ] && rm -f "$track"/b
	#declare -a roman=( 0 I II III IV V VI VII VIII VIIII X XI XII XIII XIIII XV XVI XVII XVIII XVIIII XX XXI XXII XXIII XXIIII XXV XXVI XXVII XXVIII XXVIIII XXX XXXI XXXII XXXIII XXXIV XXXV XXXVI XXXVII XXXVIII XXXVIIII XXXX XXXXI XXXXII XXXXIII XXXXIV XXXXV XXXXVI XXXXVII XXXXVIII XXXXVIIII M )
	declare -a roman=( 0 i ii iii iv v vi vii viii viv x xi xii xiii xiv xv xvi xvii xviii xviv xx xxi xxii xxiii xxiv xxv xxvi xxvii xxviii xxviv xxx xxxi xxxii xxxiii xxxiv xxxv xxxvi xxxvii xxxviii xxxviv xxxx xxxxi xxxxii xxxxiii xxxxiv xxxxv xxxxvi xxxxvii xxxxviii xxxxviv m )
	export PN=$(echo -e "$PAT" | grep -v -e "^$" | wc -l)
	echo -e "$PAT" > "$track"/b
	cnt=1
	while read line
	do
	if [[ "$cnt" -lt "$PN" ]]; then 
		rn=$(echo "${roman[$cnt]}")
		[[ ! -z "$line" ]] && sed -i -e "/$line/s/$line/$rn. $line/"  "$track"/MO
		[[ ! -z "$line" ]] && cnt=$((cnt + 1))
        [[ "$cnt" -gt 50 ]] && cnt=1
	fi
	done<"$track"/b
;;
rmrnum) #declare -a roman=( 0 I II III IV V VI VII VIII VIIII X XI XII XIII XIIII XV XVI XVII XVIII XVIIII XX XXI XXII XXIII XXIIII XXV XXVI XXVII XXVIII XXVIIII XXX XXXI XXXII XXXIII XXXIV XXXV XXXVI XXXVII XXXVIII XXXVIIII XXXX XXXXI XXXXII XXXXIII XXXXIV XXXXV XXXXVI XXXXVII XXXXVIII XXXXVIIII M )
	declare -a roman=( 0 i ii iii iv v vi vii viii viv x xi xii xiii xiv xv xvi xvii xviii xviv xx xxi xxii xxiii xxiv xxv xxvi xxvii xxviii xxviv xxx xxxi xxxii xxxiii xxxiv xxxv xxxvi xxxvii xxxviii xxxviv xxxx xxxxi xxxxii xxxxiii xxxxiv xxxxv xxxxvi xxxxvii xxxxviii xxxxviv m )
	export PN=$(echo -e "$PAT" | grep -v -e "^$" | wc -l)
	echo -e "$PAT" > "$track"/b
	cnt=1
	while read line
	do
	if [[ "$cnt" -lt "$PN" ]]; then 
		rn=$(echo "${roman[$cnt]}")
		[[ ! -z "$line" ]] && sed -i -e "/$line/s/[^\s]^$rn.//"  "$track"/MO
		[[ ! -z "$line" ]] && cnt=$((cnt + 1))
        [[ "$cnt" -gt 50 ]] && cnt=1
	fi
	done<"$track"/b;;
days) [ -f "$track"/a ] && rm -f "$track"/a
	[ -f "$track"/b ] && rm -f "$track"/b
	declare -a DAYS=( 0 Mon Tue Wed Thu Fri Sat Sun )
	export PN=$(echo -e "$PAT" | grep -v -e "^$" | wc -l)
	echo -e "$PAT" > "$track"/b
	cnt=1
	while read line
	do
	if [[ "$cnt" -lt "$PN" ]]; then 
		rn=$(echo "${DAYS[$cnt]}")
		[[ ! -z "$line" ]] && sed -i -e "/$line/s/$line/$rn. $line/"  "$track"/MO
		[[ ! -z "$line" ]] && cnt=$((cnt + 1))
        [[ "$cnt" -gt 7 ]] && cnt=1
	fi
	done<"$track"/b
;;
months) [ -f "$track"/a ] && rm -f "$track"/a
	[ -f "$track"/b ] && rm -f "$track"/b
	declare -a MONTHS=( 0 Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )
	export PN=$(echo -e "$PAT" | grep -v -e "^$" | wc -l)
	echo -e "$PAT" > "$track"/b
	cnt=1
	while read line
	do
	if [[ "$cnt" -lt "$PN" ]]; then 
		rn=$(echo "${MONTHS[$cnt]}")
		[[ ! -z "$line" ]] && sed -i -e "/$line/s/$line/$rn. $line/"  "$track"/MO
		[[ ! -z "$line" ]] && cnt=$((cnt + 1))
        [[ "$cnt" -gt 12 ]] && cnt=1
	fi
	done<"$track"/b
;;
alpha) [ -f "$track"/a ] && rm -f "$track"/a
	[ -f "$track"/b ] && rm -f "$track"/b
	declare -a alpha=( 0 a b c d e f g h i j k l m n o p q r s t u v w x y z )
	export PN=$(echo -e "$PAT" | grep -v -e "^$" | wc -l)
	echo -e "$PAT" > "$track"/b
	cnt=1
	while read line
	do
	if [[ "$cnt" -lt "$PN" ]]; then 
		rn=$(echo "${alpha[$cnt]}")
		[[ ! -z "$line" ]] && sed -i -e "/$line/s/$line/$rn: $line/"  "$track"/MO
		[[ ! -z "$line" ]] && cnt=$((cnt + 1))
        [[ "$cnt" -gt 26 ]] && cnt=1
	fi
	done<"$track"/b
;;
unindent) NUM=1; echo -e "$PAT" | grep -E -v -e '^$' -e '^[[:space:]]' | while read line; do sed -E -i -e "/$line/s/$line/$NUM\) $line/" "$track"/MO; [ ! -z "$line" ] && NUM=$((NUM + 1)); done
;;
esac
MODIFIED=$(cat "$track"/MO)
echo -e '\f'> "$track"/tpipe
echo -e "$MODIFIED" >"$track"/tpipe
echo -e "$MODIFIED" | xclip
if [[ ! -z "$PAT" ]]; then
 export PATNUM="$(echo $PAT | wc -l)"
else
 export PATNUM="$N" 
fi
export PATU="$(xclip -o)"
};export -f byblockfn

function appendfn {
ADD="$($track/yad --file)"
cat "$ADD" > "$track"/tpipe
};export -f appendfn

function columnsfn {
PAT=$(xclip -o)
sleep 0.2
xdotool key ctrl+a
xdotool key ctrl+c
xclip -o > "$track"/a
FILEA="$track/a"
FILEB="$($track/yad --file)"
paste "$FILEA" "$FILEB" > "$track"/MOD
sed -i -e "s|\t| |" "$track"/MOD
MODIFIED=$(cat "$track"/MOD)
mkfifo "$track"/col
exec 4<>"$track"/col
while read -r lina && read -r linb <&4
do
echo "$lina" | sed "s/$lina/lineb/" >"$track"/MO
done<"$track"/a 4<"$track"/MOD
echo -e '\f'> "$track"/tpipe
echo -e "$MODIFIED" >"$track"/tpipe
};export -f columnsfn

function helpfn {
export TEXT="Click 'Format' button. Formatting preset (buttons) operate on selected text.  \nSelect text in editor. Then Click a formatting button.\n\nOn touchscreens use two finger tap to get right click menus.\n\nWhen opening a file, right-click on it and 'Copy Location', then open.\nPaste the location at the bottom of the new document."
 echo -e "$TEXT" | yad --text-info --no-buttons --undecorated --width=1140 --height=220 --skip-taskbar --fontname="sans 18" --back="green" --front="range" --text="SSTE Help" --timeout=12
};export -f helpfn

function adddirfn {
ADDIR="$($track/yad --file --directory --on-top)"
[ -d "$ADDIR" ] && ls "$ADDIR"/*.* | while read line
do
case "$line" in
*.png|*.jpg|*.JPG|*.bmp|*.webp|*.svg) printf "%s\n%s\n" "$line" "$line" > "$track"/lpipe
;;
esac
done
[ -d "$ADDIR" ] && ls "$ADDIR"/*.* | while read line
do
case "$line" in
*.txt|*.TXT|*.conf|*.lst|*.cfg|*.log|*.sh|.*.py|*.desktop|*.svg|*.set) printf "%s\n%s\n" "$line" "$line" > "$track"/lpipe
;;
esac
done
};export -f adddirfn



function prefsfn {
#xwininfo -stats | awk '{if (match($0, "geometry")) {print $NF}}'

X="$RANDOM"

PREFS=$(yad --item-separator="~" \
--text="These deps are missing: $(cat $track/missing 2>/dev/null)" \
--form --field=font:fn "$(cat /root/sste/sstefont)" \
--field=text:clr "$(cat /root/sste/sstefront)" \
--field=background:clr "$(cat /root/sste/ssteback)" \
--field="Save Set As":cbe "/root/sste/sste-default.set~$(ls /root/sste/sste-*.set | tr '\n' '~')" \
--field="Select A Set":CBE "~$(ls /root/sste/sste-*.set | tr '\n' '~')" \
--field="Image Scale Max Size":num "960" --field="Text Directory":dir "/root/sste/text/" \
--field="Image Directory":dir "/root/sste/images/" --field="help":fbtn "bash -c 'helpfn'" \
--field="Add Image Directory":CHK "FALSE" --field="Splitter Position":SCL "70" \
--field="GoTo Line":num "1" --field="Image on Right":chk "false" --field="Show Line Numbers":chk "false")

SCALE="$(echo $PREFS | cut -f11 -d'|')"

export SCALE=$(((1600 / 100) * $SCALE))

if [[ "$(echo $PREFS | cut -f10 -d'|')" = 'TRUE' ]]; then
	adddirfn &
fi 
if [[ ! -z "$(echo $PREFS | cut -f7 -d'|')" ]]; then
	export TXTDIR="$(echo $PREFS | cut -f7 -d'|')"
	updatefn
fi 
if [[ ! -z "$(echo $PREFS | cut -f8 -d'|')" ]]; then
	export IMGDIR="$(echo $PREFS | cut -f8 -d'|')"
	updatefn
fi 
if [[ ! -z "$(echo $PREFS | cut -f6 -d'|')" ]]; then
	export IMGSIZE="$(echo $PREFS | cut -f6 -d'|')"
	echo "$IMGSIZE" > "$track"/imgsz
fi 

if [[ ! -z  $(echo "$PREFS" | cut -f4 -d'|') ]]; then
	echo "$PREFS" > $(echo "$PREFS" | cut -f4 -d'|')
else
	echo "$PREFS" > /root/sste/sste-$(echo "$PREFS" | cut -f1,2,3 -d'|').set
fi
if [[ ! -z  $(echo $PREFS | cut -f13 -d'|') ]]; then
	export IOR="$(echo $PREFS | cut -f13 -d'|')"
fi
if [[ ! -z  $(echo $PREFS | cut -f5 -d'|') ]]; then
	PREFS="$(cat  $(echo $PREFS | cut -f5 -d'|'))"
fi

export gtline="$(echo $PREFS | cut -f12 -d'|')"
export lnumbers="$(echo $PREFS | cut -f14 -d'|')"
case "$lnumbers" in
TRUE) export lnm='--line-num';;
FALSE) export lnm='';;
esac
echo $(echo $PREFS | cut -f1 -d'|') >/root/sste/sstefont
echo $(echo $PREFS | cut -f2 -d'|') >/root/sste/sstefront
echo $(echo $PREFS | cut -f3 -d'|') >/root/sste/ssteback
echo $(echo $PREFS | cut -f11 -d'|') >/root/sste/sstesplit
};export -f prefsfn
prefsfn

function viewimgfn {
[[ ! -d /root/sste/{pdf,images} ]] && mkdir -p /root/sste/{pdf,images}
[[ ! -f /root/sste/pdf/"$(basename $1 | cut -f1 -d'.')".pdf ]] && img2pdf "$1" -o /root/sste/pdf/"$(basename $1 | cut -f1 -d'.')".pdf
evince /root/sste/pdf/"$(basename $1 | cut -f1 -d'.')".pdf
};export -f viewimgfn
function screenshotfn {
	DATE=$(date +%y%m%d%H%M%S)
[ -f "$track"/imgsz ] && IMGSIZE=$(cat $track/imgsz)
#if [ "$(type -p gm)" ]; then
	#gm import scale -geometry "$IMGSIZE"x /root/sste/images/sste-"$DATE".png
#fi
if [ "$(type -p xscreenshot)" ]; then
mkdir -p "$track"/sste
	xscreenshot -p "$track"/sste/sste
cd "$track"/sste/;for i in $(ls *); do gm convert -geometry "$IMGSIZE"x "$i" "$i"; mv -f "$i" /root/sste/images/; done

elif [ "$(type -p flameshot)" ]; then
	flameshot gui
fi
updatefn
};export -f screenshotfn

function importfn {
DIR=$(yad --file --directory)
[ -d "$DIR" ] && ls "$DIR"/*.* | while read line
do
shopt -s nocasematch 
case "$line" in
*.png|*.PNG|*.jpg|*.JPG|*.webp|*.bmp|*.svg) gm convert -scale "$IMGSIZE" "$line" /root/sste/images/$(basename "$line")
printf "%s\n%s\n" "/root/sste/images/$(basename $line)" "/root/sste/images/$(basename $line)" > "$track"/lpipe
;;
esac
done
};export -f importfn

function sclickfn {
	shopt -s nocasematch
case "$1" in
*.mp3|*.m4a|*.mp4|*.aiff|*.aac|*.wav|*.ogg|*.webm|*.flac|https*) killall mpv; mpv "$line";;
*.png|*.jpg|*.JPG|*.bmp|*.webp|*.svg) echo "$1" | tee -a "$track"/list-item >> /root/dlist
pictwofn
piconefn;;
*.txt|*.TXT|*.conf|*.lst|*.cfg|*.log|*.sh|.*.py|*.desktop|*.set) echo "$1" >>/root/sste/txt-history.log
#echo -e '\f' > "$track"/tpipe
TEXT="$(cat $1)"
printf "%s" "$TEXT" > "$track"/tpipe
;;
esac
};export -f sclickfn

function navipadfn {
comndone='bash -c "xdotool key ctrl+-"'
comndtwo='bash -c "xdotool key ctrl+z"'
comndthree='bash -c "xdotool key ctrl+x"'
comndfour='bash -c "xdotool key ctrl+a"'
comndfive='bash -c "xdotool key ctrl+f"'
comndsix='bash -c "xdotool key ctrl+s"'
comndseven='bash -c "xdotool key ctrl++"'
comndeight='bash -c "xdotool key ctrl+shift+z"'
comndnine='bash -c "xdotool key ctrl+v"'

[[ -f /root/sste/navi-pad.conf ]] && . /root/sste/navi-pad.conf

yad --title="Navi-Pad" --form --no-focus \
--field="➖!!Ctrl+- - Zoom Out":fbtn "$comndone" \
--field="⬅️!!Ctrl+z - Undo":fbtn "$comndtwo" \
--field="❎!!Ctrl+x - Cut":fbtn "$comndthree" \
--field="⬆️!!Ctrl+a - Select All":fbtn "$comndfour" \
--field="🔍️!!Ctrl+f - Search":fbtn "$comndfive" \
--field="⬇️!!Ctrl+s - Save":fbtn "$comndsix" \
--field="➕!!Ctrl++ - Zoom In":fbtn "$comndseven" \
--field="➡️!!Ctrl+y - Redo":fbtn "$comndeight" \
--field="🆗!!Ctrl+v - Paste":fbtn "$comndnine" \
--columns="3" --geometry=151x151-12-44 \
--no-buttons --skip-taskbar --on-top &
};export -f navipadfn
navipadfn &
export NAVIPID="$!"

function formatpadfn {
cmndzero='bash -c "byblockfn gotoline"'
cmndone='bash -c "byblockfn portrait"'
cmndtwo='bash -c "byblockfn landscape"'
cmndthree='bash -c "columnsfn"'
cmndfour='bash -c "byblockfn tnum"'
cmndfive='bash -c "byblockfn center"'
cmndsix='bash -c "byblockfn fold"'
cmndseven='bash -c "byblockfn tabsp"'
cmndeight='bash -c "byblockfn tabsm"'
cmndnine='bash -c "byblockfn grammar"'
cmndten='bash -c "byblockfn dictionary"'
cmndeleven='bash -c "byblockfn bulletsp"'
cmndtwelve='bash -c "byblockfn bulletse"'
cmndthirt='bash -c "byblockfn ftabs"'
cmndfourt='bash -c "byblockfn lnum"'
cmndfifth='bash -c "byblockfn tnumm"'
cmndsixth='bash -c "byblockfn lnumm"'
cmndsevte='bash -c "byblockfn search"'
cmndeighteen='bash -c "byblockfn right"'
cmndnineteen='bash -c "byblockfn undo"'
cmndtwenty='bash -c "byblockfn redo"'
cmndtwentyone='bash -c "byblockfn rnum"'
cmndtwentytwo='bash -c "byblockfn days"'
cmndtwentythree='bash -c "byblockfn months"'
cmndtwentyfour='bash -c "byblockfn alpha"'
cmndtwentyfive='bash -c "byblockfn dblines"'
cmndtwentysix='bash -c "byblockfn unindent"'
cmndtwentyseven='bash -c "byblockfn execfn"'
cmndtwentyeight='bash -c "byblockfn view_pango"'
cmndtwentynine='bash -c "byblockfn moveup"'
cmndthirty='bash -c "byblockfn movedown"'
cmndthirtyone='bash -c "byblockfn dualimg"'
cmndthirtytwo='bash -c "byblockfn thumbnails"'

[[ -f /root/sste/format-pad.conf ]] && . /root/sste/format-pad.conf

yad  --title="The Column" --form --no-focus --scroll \
--field="Portrait":fbtn  "$cmndone" \
--field="Landscape":fbtn "$cmndtwo" \
--field="Execute script":fbtn "$cmndtwentyseven" \
--field="Preview Markup":fbtn "$cmndtwentyeight" \
--field="Grammar":fbtn "$cmndnine" \
--field="Dictionary":fbtn "$cmndten" \
--field="Move line up":fbtn "$cmndtwentynine" \
--field="Move line down":fbtn "$cmndthirty" \
--field="+Tabs":fbtn "$cmndseven" \
--field="-Tabs":fbtn "$cmndeight" \
--field="+Line Numbers":fbtn "$cmndfourt" \
--field="-Line Numbers":fbtn "$cmndsixth" \
--field="+Text Numbers":fbtn "$cmndfour" \
--field="-Text Numbers":fbtn "$cmndfifth" \
--field="+Roman":fbtn "$cmndtwentyone" \
--field="Days":fbtn "$cmndtwentytwo" \
--field="Months":fbtn "$cmndtwentythree" \
--field="Alphabet":fbtn "$cmndtwentyfour" \
--field="Double Lines":fbtn "$cmndtwentyfive" \
--field="Number Unindented":fbtn "$cmndtwentysix" \
--field="+Bullets":fbtn "$cmndeleven" \
--field="Bullets+":fbtn "$cmndtwelve" \
--field="Center":fbtn "$cmndfive" \
--field="Fold 80":fbtn "$cmndsix" \
--field="Fold at Tabs":fbtn "$cmndthirt" \
--field="Columns":fbtn  "$cmndthree" \
--field="Search'n'Replace":fbtn  "$cmndsevte" \
--field="Right Justify":fbtn "$cmndeighteen" \
--field="Undo":fbtn "$cmndnineteen" \
--field="Redo":fbtn "$cmndtwenty" \
--field="Side by Side Images":fbtn "$cmndthirtyone" \
--field="4x Image columns":fbtn "$cmndthirtytwo" \
--columns="1" --geometry=185x774+6+114 \
--no-buttons --skip-taskbar --on-top &
};export -f formatpadfn

formatpadfn &
export FRMTPID="$!"

function deletefn {
	rm -f $(cat "$track"/list-item)
	updatefn
}; export -f deletefn

function EXITfn {
kill "$((1 + $NAVIPID))"
kill "$((1 + $FRMTPID))"
rm -rf "$track"
};export -f EXITfn
trap 'EXITfn' EXIT

[[ "$2" != [0-9] ]] && line=20 || line="$2"
export NAME="$1"
echo "          Welcome To SSTE!" > "$track"/tpipe
case "$IOR" in
TRUE) "$track"/yad --plug=$$ --tabnum=2 --search-column=1 --text="\t\t\t\t\tLIST OF IMAGES" --wrap-cols=1 --editable --wrap-width=80 --editable-cols=1 --tooltip-column=1 --tail --list --listen --column=Path:txt --column="Images":img --print-column=1 --select-action="bash -c \"sclickfn "%s" \"" --dclick-action="bash -c \"viewimgfn "%s" \"" <&8  &
"$track"/yad --plug=$$ --tabnum=1 --text="\t\t\t\t\t\t\tTEXT EDITING" --show-uri --listen --uri-colour=lightblue --text-info --editable --wrap --wrap-width=80 --uri-handler="defaultbrowser" "$lnm" --line-marks --show-hidden --enable-spell --brackets --right-margin=82 --complete=any --file-op --filename="/root/sste/text/start.txt" --add-preview --large-preview --line="$gtline" --text-align=fill --margins=4 --fontname="$(cat /root/sste/sstefont)" --fore="$(cat /root/sste/sstefront)" --back="$(cat /root/sste/ssteback)" --confirm-save="Save and Overwrite?" <&9 &
;;
FALSE) "$track"/yad --plug=$$ --tabnum=1  --search-column=1 --text="\t\t\t\t\tLIST OF IMAGES" --wrap-cols=1 --editable --wrap-width=80 --editable-cols=1 --tooltip-column=1 --tail --list --listen --column=Path:txt --column="Images":img --print-column=1 --select-action="bash -c \"sclickfn "%s" \"" --dclick-action="bash -c \"viewimgfn "%s" \"" <&8  &
"$track"/yad --plug=$$ --tabnum=2 --text="\t\t\t\t\t\t\tTEXT EDITING" --show-uri --listen --uri-colour=lightblue --text-info --editable --wrap --wrap-width=80 --uri-handler="defaultbrowser" "$lnm" --line-marks --show-hidden --enable-spell --brackets --right-margin=82 --complete=any --file-op --filename="/root/sste/text/start.txt" --add-preview --large-preview --line="$gtline" --text-align=fill --margins=4 --fontname="$(cat /root/sste/sstefont)" --fore="$(cat /root/sste/sstefront)" --back="$(cat /root/sste/ssteback)" --confirm-save="Save and Overwrite?" <&9 &
;;
esac
updatefn
"$track"/yad --maximised --paned --splitter="$SCALE" --no-escape --key=$$ --tab=formatting --tab=Editor --orient=hor --geometry=2113x1265-0+26 --title="Super Simple Text Editor - $$" --button="Delete Item!/usr/share/pixmaps/midi-icons/trashcan_empty48.png":"bash -c 'deletefn'" --button="Import!/usr/share/pixmaps/folder.png!Select Directory of Images to import":"bash -c 'importfn'" --button="Print!/usr/share/pixmaps/midi-icons/printer48.png!Print Text and Preview":"bash -c 'xclip -o > $track/sste.txt;$track/yad --print --type=text --add-preview --filename=$track/sste.txt'" --button="Screenshot!/root/.config/snapp/icons/screeny.png!Capture area of screen and save to /root/sste/images":"bash -c \"screenshotfn \"" --button="Prefs!/usr/share/pixmaps/midi-icons/system48.png!Set Preferences For next Instance":"bash -c \"prefsfn \"" --button="Format!!Text Formatting Pad":"bash -c 'formatpadfn'" --button="Texts!!Open text directory":"bash -c 'rox /root/sste/text/'" --buttons-layout=center &
ret="$?"
wait "$!"
case "$ret" in
252|1|0) rm -rf "$track";;
esac
exit 0
