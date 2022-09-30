#!/usr/bin/bash

# apt-get install zip unzip jq gnumeric html2text

file="$1"

if [ -z "$file" ]; then
	echo "Please provide input file; Usage $0 <input.zip>"
	exit
fi

dir=questions
rm -r "$dir"
unzip -qq -o "$file"

(
echo "Aufgaben-Nummer; Aufgabentext; Antwort Text 1; Antwort Text 2; Antwort Text 3; Antwort Text 4; Antwort Text 5; Richtige Antwort; Aufgaben-Punktzahl; Themen"

i=0
for f in $(ls $dir); do 
	type="$(eval "echo $(cat $dir/$f |jq .type)")"
	if [ $type != "MC" ]; then
		echo "unsupported type $type" >&2 #>&2 for all error msgs
		continue
	fi
	
	i=$(expr $i + 1) #durchnummerieren der Aufgaben; do hate the leerzeichen
	text="$(eval "echo $(cat $dir/$f |jq .text)" | html2text)"
	tags="$(eval "echo $(cat $dir/$f |jq .tags)")"
	tags="$(eval "echo $(echo $tags |jq '.[0]')")"
	answers="$(eval "echo $(cat $dir/$f |jq .answers)")"
	answercount=$(echo $answers |jq '. |length')
	
	if [ $answercount -ne 5 ]; then #not equal für Zahlenvergleich; man test
		echo "incorrect number of answers" >&2
		continue # wenn Fehler, dann Abbruch und springt wieder nach oben
	fi

	echo -n "$i; $text; "
	correctAnswer=""
	for j in $(seq 1 $answercount); do
		k=$(expr $j -  1)
		answerText=$(echo $answers |jq ".[$k].answerText")
		answerNumber=$(echo $answers |jq ".[$k].answerNumber")
		isCorrect=$(echo $answers |jq ".[$k].isCorrect")
		
		echo -n "$answerText;"
		
		if [ $isCorrect = "true" ]; then
			if [ "$correctAnswer" = "" ]; then
				correctAnswer="$answerNumber"
			else
				correctAnswer="$correctAnswer, $answerNumber"
			fi
		fi
	done
	echo "$correctAnswer; 1; $tags"
done
) > tmp.csv

ssconvert tmp.csv output.xlsx
cat tmp.csv
rm tmp.csv
echo "generated output.xlsx"
