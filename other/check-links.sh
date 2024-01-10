#!/bin/bash

# contents of this script should match the one at https://github.com/lisa-analyzer/lisa/blob/master/.github/workflows/docs-links-checker.yml

function check_link () {
  # we remove any in-page anchor
  fileroot=`dirname $1`
  polished=$(echo $2 | cut -d'#' -f 1)
  if [ -z "$polished" ]; then
	# in-page link
	return 0
  elif [[ $polished == https://* ]]; then
	curl -o /dev/null -Ifs "$polished"
	if [[ $? -ne 0 ]]; then
	  echo "- broken web link: $polished"
	  return 1
	fi
  elif [[ "$polished" == "{{ site.baseurl }}/"* ]]; then
	# we remove the website-root specifier
	replaced=${polished/"{{ site.baseurl }}/"/"$3/"}
	# path is absolute at this point, we can check it directly
	if [ ! -f "$replaced" -a ! -d "$replaced" ]; then
	  echo "- broken file ref: $replaced (was $polished)"
	  return 1
	fi
  else
	if [[ "$polished" == "/"* ]]; then
      echo "- link won't work since it's absolute: $polished"
	  return 1
	elif [ ! -f "$fileroot/$polished" -a ! -d "$fileroot/$polished" ]; then
	  echo "- broken file ref: $polished (rooted at $fileroot)"
	  return 1
	fi
  fi
  return 0
}
markdowns=$(find $1 -type f -regex "[^_]*\.md")
code=0
IFS=$'\n'
root=`dirname $0`
for file in ${markdowns[@]}; do
  echo Checking $file
  hreflinks=$(grep -oP '(?<=href=").*?(?=")' $file)
  varlinks=$(grep -oP '(?<=\]:).*?(?=$)' $file)
  inlinelinks=$(grep -oP '(?<=\]\().*?(?=\))' $file)
  for link in ${hreflinks}; do
	check_link $file $link $root
	let "code=code+$?"
  done
  for link in ${varlinks}; do
	check_link $file $link $root
	let "code=code+$?"
  done
  for link in ${inlinelinks}; do
	check_link $file $link $root
	let "code=code+$?"
  done
done
exit $code