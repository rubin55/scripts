#!/bin/sh

BASE="/net/Archive/Music/Library"
IFS=$'\x09'$'\x0A'$'\x0D'

ARTIST="AC Acoustics"
ALBUM="O"
TITLE="Clone Of Al Capone"
TRACKNUMBER="4/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="AC Acoustics"
ALBUM="O"
TITLE="16 4 2010"
TRACKNUMBER="5/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="AC Acoustics"
ALBUM="O"
TITLE="Interlude"
TRACKNUMBER="7/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="AC Acoustics"
ALBUM="O"
TITLE="Hold"
TRACKNUMBER="2/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="AC Acoustics"
ALBUM="O"
TITLE="Poem"
TRACKNUMBER="12/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="AC Acoustics"
ALBUM="O"
TITLE="A Bell (Of Love Rings Out For You)"
TRACKNUMBER="3/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="AC Acoustics"
ALBUM="O"
TITLE="Bright Anchor (Anchor Me)"
TRACKNUMBER="6/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="AC Acoustics"
ALBUM="O"
TITLE="Suck On Science"
TRACKNUMBER="9/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="AC Acoustics"
ALBUM="O"
TITLE="Intro"
TRACKNUMBER="1/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="AC Acoustics"
ALBUM="O"
TITLE="Victoria"
TRACKNUMBER="11/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="AC Acoustics"
ALBUM="O"
TITLE="Conspicuously Leaving (Without Saying Goodbye)"
TRACKNUMBER="10/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="AC Acoustics"
ALBUM="O"
TITLE="When We Were Very Young"
TRACKNUMBER="8/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="Cocinero, Cocinero"
TRACKNUMBER="7/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="Acacia De Madrid"
TRACKNUMBER="13/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="Adíos A España"
TRACKNUMBER="10/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="Ante Esa Cruz"
TRACKNUMBER="5/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="Estudiantina De Madrid"
TRACKNUMBER="2/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="Copla Y Fortuna"
TRACKNUMBER="12/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="El Macetero"
TRACKNUMBER="11/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="La Hija De Juan Simón"
TRACKNUMBER="3/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="Mi Rosa Morena"
TRACKNUMBER="9/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="Soy Minero"
TRACKNUMBER="1/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="Soy Un Pobre Presidiario"
TRACKNUMBER="4/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="Te Vas A Perder, Rosario"
TRACKNUMBER="14/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="Una Paloma Blanca"
TRACKNUMBER="6/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Antonio Molina"
ALBUM="Éxitos Originales"
TITLE="Yo Quiero Ser Mataor"
TRACKNUMBER="8/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Backstreet Boys"
ALBUM="Backstreet's Back"
TITLE="All I Have To Give"
TRACKNUMBER="3/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Backstreet Boys"
ALBUM="Backstreet's Back"
TITLE="10,000 Promises"
TRACKNUMBER="5/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Backstreet Boys"
ALBUM="Backstreet's Back"
TITLE="Everybody (Backstreet's Back)"
TRACKNUMBER="1/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Backstreet Boys"
ALBUM="Backstreet's Back"
TITLE="As Long As You Love Me"
TRACKNUMBER="2/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Backstreet Boys"
ALBUM="Backstreet's Back"
TITLE="That's What She Said"
TRACKNUMBER="9/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Backstreet Boys"
ALBUM="Backstreet's Back"
TITLE="Like A Child"
TRACKNUMBER="6/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Backstreet Boys"
ALBUM="Backstreet's Back"
TITLE="Hey, Mr DJ (Keep Playin' This Song)"
TRACKNUMBER="7/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Backstreet Boys"
ALBUM="Backstreet's Back"
TITLE="If I Don't Have You"
TRACKNUMBER="11/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Backstreet Boys"
ALBUM="Backstreet's Back"
TITLE="If You Want It To Be Good Girl (Get Yourself A Bad Boy)"
TRACKNUMBER="10/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Backstreet Boys"
ALBUM="Backstreet's Back"
TITLE="Set Adrift On Memory Bliss"
TRACKNUMBER="8/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Backstreet Boys"
ALBUM="Backstreet's Back"
TITLE="That's The Way I Like It"
TRACKNUMBER="4/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Bebo & Cigala"
ALBUM="Lágrimas Negras"
TITLE="Eu Sei Que Vou Te Amar"
TRACKNUMBER="9/9"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Bebo & Cigala"
ALBUM="Lágrimas Negras"
TITLE="Corazón Loco"
TRACKNUMBER="5/9"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Bebo & Cigala"
ALBUM="Lágrimas Negras"
TITLE="La Bien Pagá"
TRACKNUMBER="8/9"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Bebo & Cigala"
ALBUM="Lágrimas Negras"
TITLE="Inolvidable"
TRACKNUMBER="1/9"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Bebo & Cigala"
ALBUM="Lágrimas Negras"
TITLE="Nieblas Del Riachuelo"
TRACKNUMBER="4/9"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Bebo & Cigala"
ALBUM="Lágrimas Negras"
TITLE="Lágrimas Negras"
TRACKNUMBER="3/9"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Bebo & Cigala"
ALBUM="Lágrimas Negras"
TITLE="Se Me Olvidó Que Te Olvidé"
TRACKNUMBER="6/9"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Bebo & Cigala"
ALBUM="Lágrimas Negras"
TITLE="Veinte Años"
TRACKNUMBER="2/9"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Bebo & Cigala"
ALBUM="Lágrimas Negras"
TITLE="Vete De Mi"
TRACKNUMBER="7/9"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="God Bless The Child (Live)"
TRACKNUMBER="4/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="Don´t Explain (Live)"
TRACKNUMBER="6/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="Don´t Explain"
TRACKNUMBER="13/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="Easy To Remember"
TRACKNUMBER="11/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="Fine And Mellow (Live)"
TRACKNUMBER="8/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="Fooling Myself"
TRACKNUMBER="10/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="Moaning Law"
TRACKNUMBER="12/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="I Don´t Stand A Ghost Of A Chance With You"
TRACKNUMBER="1/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="I Loves You Porgy"
TRACKNUMBER="7/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="What A Little Moonlight Can Do"
TRACKNUMBER="9/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="Nice Work If You Can Get It"
TRACKNUMBER="3/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="Please Don´t Talk About Me When I´m Gone (Version 1)"
TRACKNUMBER="2/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="Please Don´t Talk About Me When I´m Gone (Version 2)"
TRACKNUMBER="5/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Billie Holiday"
ALBUM="Billie Holiday"
TITLE="When Your Lover Has Gone"
TRACKNUMBER="14/14"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Blur"
ALBUM="Parklife"
TITLE="Girvorbiscomment -R -c state.txt -w & Boys (Pet Shop Boys 12inch Remix)"
TRACKNUMBER="17/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Duran Duran"
ALBUM="Rio"
TITLE="The Chauffeur"
TRACKNUMBER="9/9"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="El Cabrero"
ALBUM="Por La Huella Del Fandango"
TITLE="Así Se Siembra El Fandango"
TRACKNUMBER="1/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="El Cabrero"
ALBUM="Por La Huella Del Fandango"
TITLE="A Los Perros Embusteros"
TRACKNUMBER="7/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="El Cabrero"
ALBUM="Por La Huella Del Fandango"
TITLE="Piden Tierra Y Se La Niegan"
TRACKNUMBER="9/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="El Cabrero"
ALBUM="Por La Huella Del Fandango"
TITLE="El Agua No Siente \"Na\""
TRACKNUMBER="2/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="El Cabrero"
ALBUM="Por La Huella Del Fandango"
TITLE="En La Noria De La \"Via\""
TRACKNUMBER="5/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="El Cabrero"
ALBUM="Por La Huella Del Fandango"
TITLE="En Una Fuente Que Corra"
TRACKNUMBER="4/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="El Cabrero"
ALBUM="Por La Huella Del Fandango"
TITLE="No Hay Pacienca"
TRACKNUMBER="3/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="El Cabrero"
ALBUM="Por La Huella Del Fandango"
TITLE="Se Lo Lleva La Corriente"
TRACKNUMBER="6/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="El Cabrero"
ALBUM="Por La Huella Del Fandango"
TITLE="Por Eso Yo Soy Así"
TRACKNUMBER="12/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="El Cabrero"
ALBUM="Por La Huella Del Fandango"
TITLE="Rebelde"
TRACKNUMBER="8/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="El Cabrero"
ALBUM="Por La Huella Del Fandango"
TITLE="Se Muere Huyendo De El"
TRACKNUMBER="10/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="El Cabrero"
ALBUM="Por La Huella Del Fandango"
TITLE="Y La Libertad Se Quiere"
TRACKNUMBER="11/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Francisco Céspedes"
ALBUM="Vida Loca"
TITLE="Como Si El Destino"
TRACKNUMBER="2/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Francisco Céspedes"
ALBUM="Vida Loca"
TITLE="Morena"
TRACKNUMBER="9/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Francisco Céspedes"
ALBUM="Vida Loca"
TITLE="Pensar En Tí"
TRACKNUMBER="5/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Francisco Céspedes"
ALBUM="Vida Loca"
TITLE="Qué Hago Contigo"
TRACKNUMBER="8/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Francisco Céspedes"
ALBUM="Vida Loca"
TITLE="Remolino"
TRACKNUMBER="4/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Francisco Céspedes"
ALBUM="Vida Loca"
TITLE="Se Me Antoja"
TRACKNUMBER="7/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Francisco Céspedes"
ALBUM="Vida Loca"
TITLE="Señora"
TRACKNUMBER="11/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Francisco Céspedes"
ALBUM="Vida Loca"
TITLE="Todo Es Un Misterio"
TRACKNUMBER="1/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Francisco Céspedes"
ALBUM="Vida Loca"
TITLE="Tú Por Qué"
TRACKNUMBER="6/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Francisco Céspedes"
ALBUM="Vida Loca"
TITLE="Vida Loca"
TRACKNUMBER="3/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Francisco Céspedes"
ALBUM="Vida Loca"
TITLE="Vida Mía"
TRACKNUMBER="10/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Joan Manuel Serrat"
ALBUM="Dedicado A Antonio Machado, Poeta"
TITLE="Del Pasado Efímero"
TRACKNUMBER="7/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Joan Manuel Serrat"
ALBUM="Dedicado A Antonio Machado, Poeta"
TITLE="A Un Olmo Seco"
TRACKNUMBER="9/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Joan Manuel Serrat"
ALBUM="Dedicado A Antonio Machado, Poeta"
TITLE="Cantares"
TRACKNUMBER="1/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Joan Manuel Serrat"
ALBUM="Dedicado A Antonio Machado, Poeta"
TITLE="Guitarra Del Mesón"
TRACKNUMBER="3/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Joan Manuel Serrat"
ALBUM="Dedicado A Antonio Machado, Poeta"
TITLE="En Coulliure"
TRACKNUMBER="11/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Joan Manuel Serrat"
ALBUM="Dedicado A Antonio Machado, Poeta"
TITLE="Españolito"
TRACKNUMBER="8/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Joan Manuel Serrat"
ALBUM="Dedicado A Antonio Machado, Poeta"
TITLE="He Andado Muchos Caminos"
TRACKNUMBER="10/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Joan Manuel Serrat"
ALBUM="Dedicado A Antonio Machado, Poeta"
TITLE="La Saeta"
TRACKNUMBER="6/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Joan Manuel Serrat"
ALBUM="Dedicado A Antonio Machado, Poeta"
TITLE="Las Moscas"
TRACKNUMBER="4/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Joan Manuel Serrat"
ALBUM="Dedicado A Antonio Machado, Poeta"
TITLE="Llanto Y Coplas"
TRACKNUMBER="5/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Joan Manuel Serrat"
ALBUM="Dedicado A Antonio Machado, Poeta"
TITLE="Parábola"
TRACKNUMBER="12/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Joan Manuel Serrat"
ALBUM="Dedicado A Antonio Machado, Poeta"
TITLE="Retrato"
TRACKNUMBER="2/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="B.B.K."
TRACKNUMBER="18/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="1"
TRACKNUMBER="1/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="10"
TRACKNUMBER="10/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="11"
TRACKNUMBER="11/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="12"
TRACKNUMBER="12/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="2"
TRACKNUMBER="2/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="3"
TRACKNUMBER="3/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="4"
TRACKNUMBER="4/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="5"
TRACKNUMBER="5/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="6"
TRACKNUMBER="6/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="7"
TRACKNUMBER="7/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="8"
TRACKNUMBER="8/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="9"
TRACKNUMBER="9/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="Dead Bodies Everywhere"
TRACKNUMBER="16/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="All In The Family"
TRACKNUMBER="20/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="Cameltosis"
TRACKNUMBER="24/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="Children Of The Korn"
TRACKNUMBER="17/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="Freak On A Leash"
TRACKNUMBER="14/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="Got The Life"
TRACKNUMBER="15/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="It's On"
TRACKNUMBER="13/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="Justin"
TRACKNUMBER="22/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="My Gift To You"
TRACKNUMBER="25/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="Pretty"
TRACKNUMBER="19/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="Reclaim My Place"
TRACKNUMBER="21/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Korn"
ALBUM="Follow The Leader"
TITLE="Seed"
TRACKNUMBER="23/25"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="Little Bank Anthem"
TRACKNUMBER="5/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="Attack Russia"
TRACKNUMBER="12/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="Be Happy"
TRACKNUMBER="11/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="Dream About Afghanistan Or Oakland"
TRACKNUMBER="9/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="Class Action Suit Against Earth"
TRACKNUMBER="1/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="Great Open Grey"
TRACKNUMBER="15/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="Numb"
TRACKNUMBER="8/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="Dream I Had On 25th Birthday"
TRACKNUMBER="14/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="Idol Victim"
TRACKNUMBER="2/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="Form Plus Prime Matter Equavorbiscomment -R -c state.txt -w Substance"
TRACKNUMBER="10/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="How To Be Rich And Powerful"
TRACKNUMBER="3/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="Ode To Clean Air"
TRACKNUMBER="4/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="If You Don't Like My Music"
TRACKNUMBER="16/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="Poor Is Cool"
TRACKNUMBER="13/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="We Thanks"
TRACKNUMBER="6/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Man's Best Friend"
ALBUM="The New Human Is Illegal"
TITLE="The Devil's A Travelling Man"
TRACKNUMBER="7/16"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manic Street Preachers"
ALBUM="Generation Terrorists"
TITLE="Methadone Pretty"
TRACKNUMBER="17/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manic Street Preachers"
ALBUM="La Tristesse Durera (Scream To A Sigh)"
TITLE="La Tristesse Durera (Scream To A  Sigh) (7inch Version)"
TRACKNUMBER="1/2"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="El Genio De Manolo Caracol"
TITLE="La Cárcel Del Cante - Ay, Que Pena Más Grande"
TRACKNUMBER="3/8"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="El Genio De Manolo Caracol"
TITLE="A La Deriva - Lástima De Besos Míos"
TRACKNUMBER="5/8"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="El Genio De Manolo Caracol"
TITLE="Entre Las Dos Y Las Tres"
TRACKNUMBER="6/8"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="El Genio De Manolo Caracol"
TITLE="Muerto De Amor - Que Grande Es Mi Pensamiento"
TRACKNUMBER="7/8"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="El Genio De Manolo Caracol"
TITLE="Por Los Rincones A Llorar"
TRACKNUMBER="1/8"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="El Genio De Manolo Caracol"
TITLE="Quería Construir - Dos Candelabros De Oro"
TRACKNUMBER="2/8"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="El Genio De Manolo Caracol"
TITLE="Romance De Juan Teba"
TRACKNUMBER="8/8"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="El Genio De Manolo Caracol"
TITLE="Sale El Sol De Días - Es Colora"
TRACKNUMBER="4/8"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="Manolo Caracol"
TITLE="De La Torre De La Vela"
TRACKNUMBER="3/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="Manolo Caracol"
TITLE="Carcelero, Carcelero"
TRACKNUMBER="8/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="Manolo Caracol"
TITLE="Cuando Yo Te Conocí"
TRACKNUMBER="7/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="Manolo Caracol"
TITLE="Evocación De La Malagueña"
TRACKNUMBER="1/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="Manolo Caracol"
TITLE="De Querer A No Querer"
TRACKNUMBER="5/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="Manolo Caracol"
TITLE="Morita, Mora"
TRACKNUMBER="2/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="Manolo Caracol"
TITLE="Mi Barca"
TRACKNUMBER="9/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="Manolo Caracol"
TITLE="Romance De Juan De Osuna"
TRACKNUMBER="6/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="Manolo Caracol"
TITLE="Mira Que Desgracia"
TRACKNUMBER="11/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="Manolo Caracol"
TITLE="Tientos De La Rosa"
TRACKNUMBER="4/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Manolo Caracol"
ALBUM="Manolo Caracol"
TITLE="Rosa Benenosa"
TRACKNUMBER="10/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="Darling, Je Vous Aime Beaucoup"
TRACKNUMBER="15/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="(Get Your Kicks On) Route 66"
TRACKNUMBER="8/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="Body And Soul"
TRACKNUMBER="16/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="Sweet Georgia Brown"
TRACKNUMBER="14/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="Embraceable You"
TRACKNUMBER="2/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="Got A Penny"
TRACKNUMBER="4/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="I'm Lost"
TRACKNUMBER="12/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="Gee Baby, Ain't I Good To You"
TRACKNUMBER="7/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="Let's Pretend"
TRACKNUMBER="11/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="Mona Lisa"
TRACKNUMBER="13/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="Nature Boy"
TRACKNUMBER="1/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="Paper Moon"
TRACKNUMBER="18/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="The Frim Fram Sauce"
TRACKNUMBER="6/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="Sweet Lorraine"
TRACKNUMBER="10/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="Yes Sir, That's My Baby"
TRACKNUMBER="9/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="The Sand And The Sea"
TRACKNUMBER="5/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="Unforgettable"
TRACKNUMBER="17/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Nat King Cole"
ALBUM="Unforgettable"
TITLE="You're The Cream In My Coffee"
TRACKNUMBER="3/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Oasis"
ALBUM="(What's The Story) Morning Glory?"
TITLE="Champagne Supernova"
TRACKNUMBER="12/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Oasis"
ALBUM="(What's The Story) Morning Glory?"
TITLE="Cast No Shadow"
TRACKNUMBER="8/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Oasis"
ALBUM="(What's The Story) Morning Glory?"
TITLE="Don't Look Back In Anger"
TRACKNUMBER="4/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Oasis"
ALBUM="(What's The Story) Morning Glory?"
TITLE="Hello"
TRACKNUMBER="1/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Oasis"
ALBUM="(What's The Story) Morning Glory?"
TITLE="Hey Now!"
TRACKNUMBER="5/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Oasis"
ALBUM="(What's The Story) Morning Glory?"
TITLE="Morning Glory"
TRACKNUMBER="10/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Oasis"
ALBUM="(What's The Story) Morning Glory?"
TITLE="Roll With It"
TRACKNUMBER="2/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Oasis"
ALBUM="(What's The Story) Morning Glory?"
TITLE="She's Electric"
TRACKNUMBER="9/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Oasis"
ALBUM="(What's The Story) Morning Glory?"
TITLE="Some Might Say"
TRACKNUMBER="7/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Oasis"
ALBUM="(What's The Story) Morning Glory?"
TITLE="Swamp Song #1"
TRACKNUMBER="6/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Oasis"
ALBUM="(What's The Story) Morning Glory?"
TITLE="Swamp Song #2"
TRACKNUMBER="11/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Oasis"
ALBUM="(What's The Story) Morning Glory?"
TITLE="Wonderwall"
TRACKNUMBER="3/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="Parallel Universe"
TRACKNUMBER="2/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="Around The World"
TRACKNUMBER="1/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="Californication"
TRACKNUMBER="6/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="Easily"
TRACKNUMBER="7/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="Emit Remmus"
TRACKNUMBER="9/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="Get On Top"
TRACKNUMBER="5/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="I Like Dirt"
TRACKNUMBER="10/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="Otherside"
TRACKNUMBER="4/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="Right On Time"
TRACKNUMBER="14/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="Porcelain"
TRACKNUMBER="8/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="Purple Stain"
TRACKNUMBER="13/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="This Velvet Glove"
TRACKNUMBER="11/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="Road Trippin'"
TRACKNUMBER="15/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="Savior"
TRACKNUMBER="12/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Red Hot Chili Peppers"
ALBUM="Californication"
TITLE="Scar Tissue"
TRACKNUMBER="3/15"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Al Final De Este Viaje"
TITLE="La Familia, La Propiedad Privada Y El Amor"
TRACKNUMBER="2/10"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Al Final De Este Viaje"
TITLE="Al Final De Este Viaje En La Vida"
TRACKNUMBER="10/10"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Al Final De Este Viaje"
TITLE="Aunque No Esté De Moda"
TRACKNUMBER="8/10"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Al Final De Este Viaje"
TITLE="Canción Del Elegido"
TRACKNUMBER="1/10"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Al Final De Este Viaje"
TITLE="Debo Partirme En Dos"
TRACKNUMBER="6/10"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Al Final De Este Viaje"
TITLE="La Era Esta Pariendo Un Corazón"
TRACKNUMBER="4/10"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Al Final De Este Viaje"
TITLE="Ojalá"
TRACKNUMBER="3/10"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Al Final De Este Viaje"
TITLE="Oleo De Una Mujer Con Sombrero"
TRACKNUMBER="7/10"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Al Final De Este Viaje"
TITLE="Qué Se Puede Hacer Con El Amor"
TRACKNUMBER="9/10"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Al Final De Este Viaje"
TITLE="Resumen De Noticias"
TRACKNUMBER="5/10"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Expedición"
TITLE="Ese Hombre"
TRACKNUMBER="8/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Expedición"
TITLE="Amanecer"
TRACKNUMBER="5/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Expedición"
TITLE="El Baile"
TRACKNUMBER="2/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Expedición"
TITLE="Expedición"
TRACKNUMBER="3/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Expedición"
TITLE="Anoche Fue La Orquesta"
TRACKNUMBER="9/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Expedición"
TITLE="Fronteras"
TRACKNUMBER="4/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Expedición"
TITLE="La Mancha"
TRACKNUMBER="10/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Expedición"
TITLE="Quedate"
TRACKNUMBER="11/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Expedición"
TITLE="Hace No Se Que Tiempo Ya"
TRACKNUMBER="7/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Expedición"
TITLE="Sortilegio"
TRACKNUMBER="6/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Expedición"
TITLE="Toti"
TRACKNUMBER="1/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Silvio Rodríguez"
ALBUM="Expedición"
TITLE="Tiempo De Ser Fantasma"
TRACKNUMBER="12/12"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Technotronic"
ALBUM="This Beat Is Technotronic"
TITLE="This Beat Is Technotronic (Single Version)"
TRACKNUMBER="2/5"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Technotronic"
ALBUM="This Beat Is Technotronic"
TITLE="This Beat Is Technotronic (Alaska Dub)"
TRACKNUMBER="3/5"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Technotronic"
ALBUM="This Beat Is Technotronic"
TITLE="This Beat Is Technotronic (Beats & Bass)"
TRACKNUMBER="5/5"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Technotronic"
ALBUM="This Beat Is Technotronic"
TITLE="This Beat Is Technotronic (Rap To Beats)"
TRACKNUMBER="4/5"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Technotronic"
ALBUM="This Beat Is Technotronic"
TITLE="This Beat Is Technotronic (My Favourite Club Mix)"
TRACKNUMBER="1/5"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Terremoto"
ALBUM="Terremoto En Sevilla"
TITLE="En La Calle Nueva"
TRACKNUMBER="7/7"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Terremoto"
ALBUM="Terremoto En Sevilla"
TITLE="El Limonar"
TRACKNUMBER="5/7"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Terremoto"
ALBUM="Terremoto En Sevilla"
TITLE="La Cartuja"
TRACKNUMBER="4/7"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Terremoto"
ALBUM="Terremoto En Sevilla"
TITLE="Erales"
TRACKNUMBER="3/7"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Terremoto"
ALBUM="Terremoto En Sevilla"
TITLE="Frijones"
TRACKNUMBER="1/7"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Terremoto"
ALBUM="Terremoto En Sevilla"
TITLE="Sentencias"
TRACKNUMBER="6/7"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Terremoto"
ALBUM="Terremoto En Sevilla"
TITLE="Onix"
TRACKNUMBER="2/7"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="Family Business"
TRACKNUMBER="7/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="Cowboys"
TRACKNUMBER="11/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="How Many Mics"
TRACKNUMBER="2/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="Fu-Gee-La"
TRACKNUMBER="6/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="Fu-Gee-La (Refugee Camp Global Mix)"
TRACKNUMBER="17/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="Fu-Gee-La (Refugee Camp Remix)"
TRACKNUMBER="14/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="Fu-Gee-La (Sly  Robbie Mix)"
TRACKNUMBER="15/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="Killing Me Softly"
TRACKNUMBER="8/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="Manifest - Outro"
TRACKNUMBER="13/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="Mista Mista"
TRACKNUMBER="16/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="No Woman, No Cry"
TRACKNUMBER="12/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="Ready Or Not"
TRACKNUMBER="3/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="Red Intro"
TRACKNUMBER="1/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="The Beast"
TRACKNUMBER="5/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="The Mask"
TRACKNUMBER="10/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="The Score"
TRACKNUMBER="9/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Fugees"
ALBUM="The Score"
TITLE="Zealots"
TRACKNUMBER="4/17"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="Don't Take Your Love From Me"
TRACKNUMBER="17/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="A Ghost Of A Chance"
TRACKNUMBER="3/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="Blue Skies"
TRACKNUMBER="12/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="Georgia On My Mind"
TRACKNUMBER="9/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="G'bye Now"
TRACKNUMBER="15/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="I'm In Love With Someone"
TRACKNUMBER="14/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="He's Funny That Way"
TRACKNUMBER="10/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="I'm Confessin'"
TRACKNUMBER="18/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="Somebody Loves Me"
TRACKNUMBER="5/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="It Had To Be You"
TRACKNUMBER="8/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="Lazy River"
TRACKNUMBER="13/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="Let's Try Again"
TRACKNUMBER="7/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="Rockin' Chair"
TRACKNUMBER="4/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="Sing You Sinners"
TRACKNUMBER="6/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="Windy City Blues"
TRACKNUMBER="16/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="Summertime"
TRACKNUMBER="1/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="They Can't Take That Away From Me"
TRACKNUMBER="2/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="The Nat King Cole Trio"
ALBUM="Georgia On My Mind"
TITLE="What Is This Thing Called Love?"
TRACKNUMBER="11/18"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="UB40"
ALBUM="Promises And Lies"
TITLE="Can't Help Falling In Love"
TRACKNUMBER="7/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="UB40"
ALBUM="Promises And Lies"
TITLE="Bring Me Your Cup"
TRACKNUMBER="4/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="UB40"
ALBUM="Promises And Lies"
TITLE="C'est La Vie"
TRACKNUMBER="1/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="UB40"
ALBUM="Promises And Lies"
TITLE="Higher Ground"
TRACKNUMBER="5/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="UB40"
ALBUM="Promises And Lies"
TITLE="Desert Sand"
TRACKNUMBER="2/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="UB40"
ALBUM="Promises And Lies"
TITLE="It's A Long Long Way"
TRACKNUMBER="10/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="UB40"
ALBUM="Promises And Lies"
TITLE="Now And Then"
TRACKNUMBER="8/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="UB40"
ALBUM="Promises And Lies"
TITLE="Promises And Lies"
TRACKNUMBER="3/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="UB40"
ALBUM="Promises And Lies"
TITLE="Reggae Music"
TRACKNUMBER="6/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="UB40"
ALBUM="Promises And Lies"
TITLE="Sorry"
TRACKNUMBER="11/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="UB40"
ALBUM="Promises And Lies"
TITLE="Things Ain't Like They Used To Be"
TRACKNUMBER="9/11"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Voicst"
ALBUM="11-11"
TITLE="How To Put It?"
TRACKNUMBER="12/13"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Voicst"
ALBUM="11-11"
TITLE="Dazzled Kids"
TRACKNUMBER="3/13"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Voicst"
ALBUM="11-11"
TITLE="And You Taste Like Something's Wrong"
TRACKNUMBER="11/13"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Voicst"
ALBUM="11-11"
TITLE="Detail 2003"
TRACKNUMBER="5/13"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Voicst"
ALBUM="11-11"
TITLE="Sgt. Gonzo"
TRACKNUMBER="9/13"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Voicst"
ALBUM="11-11"
TITLE="Porn"
TRACKNUMBER="10/13"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Voicst"
ALBUM="11-11"
TITLE="Enjoy The Kickback..."
TRACKNUMBER="13/13"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Voicst"
ALBUM="11-11"
TITLE="We Are On A Chemical Push"
TRACKNUMBER="2/13"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Voicst"
ALBUM="11-11"
TITLE="Shut Up And Dance"
TRACKNUMBER="8/13"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Voicst"
ALBUM="11-11"
TITLE="Someone Wake Me"
TRACKNUMBER="7/13"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Voicst"
ALBUM="11-11"
TITLE="Upside"
TRACKNUMBER="6/13"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Voicst"
ALBUM="11-11"
TITLE="Whatever You Want From Life"
TRACKNUMBER="1/13"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Voicst"
ALBUM="11-11"
TITLE="You Look Like Coffee"
TRACKNUMBER="4/13"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt

ARTIST="Zoppo"
ALBUM="Belgian Style Pop"
TITLE="2-01 Flooded"
TRACKNUMBER="19/19"
FILE="$BASE/$ARTIST/$ALBUM/$TITLE.ogg"
echo "ARTIST=$ARTIST"            > state.txt
echo "ALBUM=$ALBUM"             >> state.txt
echo "TITLE=$TITLE"             >> state.txt
echo "TRACKNUMBER=$TRACKNUMBER" >> state.txt

echo Working on $FILE
vorbiscomment -R -c state.txt -w $FILE
rm state.txt
