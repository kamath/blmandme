#!/usr/local/bin/bash

# Check if tesseract is installed
if ! brew ls --versions tesseract > /dev/null; then
  brew ls --versions tesseract
fi

# Check if GNU grep (ggrep) is installed
if ! brew ls --versions grep > /dev/null; then
  brew ls --versions grep
fi

if [ ! -d ./tmp ]; then
  mkdir ./tmp
fi

for image in ./*.jpg; do
  echo "OCR processing for $image..."
  tesseract $image "./tmp/$image" >& /dev/null
done


for file in ./tmp/*; do
  # Example: "SIGN YWNDTO" in "Text SIGN YWNDTO to 50409"
  body=""
  # Example: "YWNDTO" in "SIGN YWNDTO"
  identifier=""
  # Example: AN OPEN LETTER to STATE GOVERNORS & LEGISLATURES STARTED by ...
  title=""
  # The body of the message (between the name and the title, so if the title isn't blank,
  # capture until you reach a line with one word, the name, or CONSTITUTENT)
  impact=""
  # Redirect opens the file in truncation mode, removing contents before reading, hence the
  # short circuiting (see https://superuser.com/a/597257)
  awk 'NF' $file > ./$file.$$ && mv $file.$$ $file
  while read line; do
    # Case 1: Body/identifier are empty, first line
    if [[ "$body" == "" && "$line" =~ ^Text ]]; then
      body="`echo "$line" | ggrep -Pio '(?<=Text\ )(.+?)(?=\ to)'`"
      identifier="`echo "$line" | ggrep -Pio '(?<=SIGN\ )(.+?)(?=\ to)'`"
    # Case 2: Body/identifier are not empty, but title is still empty and we havent
    # reached the line "AN OPEN LETTER..."
    elif [[ "$body" != "" && "$title" == "" && ! "$line" =~ "AN OPEN LETTER" ]]; then
      continue
    # Case 3: We have reached the line "AN OPEN LETTER..."
    # so we initialize the title
    elif [[ "$title" == "" && "$line" =~ "AN OPEN LETTER" ]]; then
      read nextline
      title="$nextline"
    # Case 4: Line is CONSTITUENT
    elif [[ "$line" =~ "CONSTITUENT" ]]; then
      # Erase last few characters from string (everything after last period)
      impact="`echo "$impact" | ggrep -Pio '.*\.'`"
      break
      # Continually append until we reach the line "CONSTITUTENT...", then break (case 4)
    else
      impact="$impact $line"
    fi
  done < $file
  # Take out any quotes or backticks that might cause Jekyll to throw up
  impact="`echo "$impact" | sed 's/"//g'`"
  impact="`echo "$impact" | sed 's/\`//g'`"
  impact="`echo "$impact" | sed 's/’//g'`"
  title="`echo "$title" | sed 's/"//g'`"
  title="`echo "$title" | sed 's/\`//g'`"
  title="`echo "$title" | sed 's/’//g'`"
  target_file="`echo "$identifier" | awk '{print tolower($0)}'`"
  target_file="${target_file}_to_50409.md"
  echo -e "---\ntype: \"sms\"\nnumber: \"50409\"\nbody: \"$body\"\ntitle: \"Text $identifier to 50409 to sign $title\"\nrepresentation: \"ResistBot\"\nimpact: \"$impact\"\n---"\
    > ../../_links/sms/$target_file
done

if [ -d ./tmp ]; then
  echo "Deleting tmporary tmp/ directory..."
  rm -rf ./tmp
fi
