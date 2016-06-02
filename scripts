# Scripts
Below I'll list scripts that are useful to have on hand

#### FLAC to MP3
OSX and iTunes doesn't support FLAC so let's convert them to MP3.
First off install `ffmpeg`
````
brew install ffmpeg
````
Then run in selected folder with .flac files:
````
for f in *.flac; do ffmpeg -i "$f" -aq 1 "${f%flac}mp3"; done
````
