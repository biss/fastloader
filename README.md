=== Description ===
This file downloader downloads a file by breaking it into multiple parts and spawning separate process to download each part.

=== Prerequisites ===
# cURL            	(Comes pre-installed with Ubuntu.)

=== Installation ===
just clone the repo

=== Usage ===
Example demonstrating how to run the program:
./fastloader -p --input-url=<inputurl> --output-filename=<outputfilename> --splits=#numsplit --proxy=<proxyurl> --approx-maxsize=#maxsize

= short-option =
* -p: to be specified if the file is to be downloaded in parts paralelly
= long option =
* <inputurl>:       URL of the file to be downloaded
* <outputfilename>: output filename
* <numsplits>:      number of parts the file should be downloaded in
* <proxyurl>:       proxy url
* <maxsize>:        approximate maximum size of the file
