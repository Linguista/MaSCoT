#!/usr/bin/praat
#praat script

# NOTICE: This file uses UTF-8!

debug = 0

script_name$ = "MaSCoT"
version$ = "4.1-SotAL-EXPERIMENTAL"
author$ = "Scott Sadowsky"

# MaSCoT.praat
##############################################################################
# SCRIPT:		MAssive Speech COrpora Tool (MaSCoT)
# AUTHOR:		Scott Sadowsky - http://sadowsky.cl - ssadowsky REMOVETHISBIT gmail com
# DATE:		23 May 2015
# VERSION:	4.1-SotAL-EXPERIMENTAL
#			- Special version for Sounds of the Andean Languages project
#			- This version reads in index numbers from a file and looks them
#			  up based on the gloss in the interval. (See changelog for details).
#			- Now with 100% more SQL!
# DESCRIPTION:	Opens a LongSound + TextGrid pair and saves all intervals 
#			  on the selected tier THAT MATCH THE REGEX THE USER PROVIDES
#			  to individual WAV files.
# USAGE NOTES:	- The source sound must be a LongSound object.
#			- Both the TextGrid and the LongSound must have identical names
#			  and must be selected before running the script.
# THANKS:		GetTierName procedure adapted from a script by Mietta Lennes.
#			Some other parts of this script are also based on a script by
#			  Mietta Lennes.
# LICENSE:   	This software is licensed under the GNU GPL v3.
##############################################################################

# ¡¡¡ WARNING !!!
# In version 3.7 an error became manifest (though it may have existed before): 
#   When extracting SQL and LOG files *without* extracting audio, most variables aren't read!
#   WORKAROUND: Always extract audio!
#
# ----- MaSCoT Changelog -----
#
# 4,1-SotAL-EXPERIMENTAL
# - Add option to only extract entries with a phonetic transcription.
#
# 4,0-SotAL-EXPERIMENTAL
# - Deals with duplicate identical entries (as determined by existence of WAV file which would
#   be overwritten) by not extracting new WAV, not writing entry to log, and not adding SQL statement.
#
# 3,8-SotAL-EXPERIMENTAL
# - Added some features for compatibility with the Sound Comparisons Website database.
#	- IxMorphologicalInstance will now be used for something other than what Sounds of Mapudungun
#	  has been using it for. Until now it encoded the value of altmorph in the textgrids. From
#	  now on it will be set to 0 in all cases except nosotros_dos (where it'll be 3) and 
#	  nosotros_pl (where it'll be 4). This is because the database doesn't really have a unique
#	  key, but rather a combination of IxElicitation and IxMorphologicalInstance.
#	  To implement this, there is now an ad hoc if-then routine.
#	- The value that was previously stored in IxMorphologicalInstance will now be stored in 
#	  CommonRootMorphemeStructDifferent.
#	- A new database field, DifferentMorphemeStructureNote, will be added for the explanations of the cases 
#	  where CommonRootMorphemeStructDifferent is one. Notes should be similar to "Missing final -ün morpheme".
#	  The values for this field will come from the Praat "notes" tier. Note, though, that the phonetic 
#	  transcriptions 1-12 do NOT use the tier this way, and in fact have no notes on this matter (Paul
#	  only recently explained this criterion).
#
# 3,7-SotAL-EXPERIMENTAL
# - Stopped writing the value of sotalLabelNotes$ (which are my misc notes about any old thing)
#   to the UsageNote field, which is for info on register and style.
#
# 3,6-SotAL-EXPERIMENTAL
# - Added SQL output.
#
# 3,5-SotAL-EXPERIMENTAL
# - Wonderful things were done here! But sometimes, what happens in Praat stays in Praat.
#
# 3,4-SotAL-EXPERIMENTAL
# - Handles non-existent table entry errors with grace and dignity.
#
# 3,3-SotAL-EXPERIMENTAL
# - This version is for salvaging old Sound Comparison Website audio files that 
#	have had words tagged only with the gloss, but whose extracted WAV files must
#	have the gloss PLUS the index number. This info is read from an external file.
#
# 3,1-SotAL
# - Changed script so it can recognize more than one of the following labels in a given segment
#   in tier 5 (Status): "altmorph", "altlex", "altpron".
# - Script now puts extracted files into automatically named sub-folders.
#
# 2,9-SotAL
# - Changed format of output file names to make it compatible with Paul's SotAL database
# - Changed the contents of the TSV output file to make it compatible with Paul's SotAL database
#
# 2,8-SotAL
# - Changed names of variables and form content to match new text grid conventions. 
#   "Spanish" > "Gloss"; "Mapudungun" > "Orthographic".
#
# 2,7-SotAL
# - Added "altlex" and "altpron" label processing.
#
# 2,6-SotAL
# - Removed "review" and its allographs from words which prevent a segment from being extracted.
# - Removed "altlex" from words which prevent a segment from being extracted.
# - Added feature to label words with "altlex" tag as such.
#
# 2,4-SotAL
# - Hard coded output formats for filenames and text log.
#
# 2,4
# - Added option to exclude intervals on a user-selected tier that contain text that matches any regular expression.
# - Added option to put sequential interval number before interval labels in some situations.
#
# 2,2
# - Moved to two-digit versioning system.
# - Added ability to normalize extracted audio. Normalization is done to the peak value.
#
# 2,1,9
# - Added ability to apply fade-in and fade-out to extracted audio.
# - Made adding a left and right margin to the extracted audio optional.
#
# 2,1,6
# - Added more info to the log file that MaSCoT produces.
#
# 2,1,3
# - Changed default field contents for Regex, since the bracketed expression [áéíóú] works irregularly (!!!).
#
# 2,1,0
# - Added ability to save TextGrids along with sound files.
##############################################################################


# Define certain variables.
useRestrict = 0
useSoundExtractionTier = 0
#number_of_characters_in_filename_prefix = 15
date$ = date$()
first_number = 1

form MAssive Speech COrpus Tool (MaSCoT) v. 4.1-SotAL
	
	comment ***** Requires a TextGrid and a LongSound be selected *****
	
	#comment Exclude intervals whose status field contains the following:
    #sentence Regular_expression XXX|Xxx|xxx|WRONG|Wrong|wrong|REPEAT|Repeat|repeat|UNKNOWN|Unknown|unknown|SPANISH|Spanish|spanish|EXCLUDED|Excluded|excluded|.*\?.*

	sentence User Scott Sadowsky
	
	# TEMPORARILY DISABLED DUE TO BUG:
	#boolean Extract_audio yes
	
	boolean Extract_only_intervals_with_phonetic_transcription yes
	boolean Output_sql yes
	boolean Also_extract_TextGrids no
	boolean Export_notes no
   
	boolean Add_margin_to_extracted_interval yes
	comment Time margin to add to beginning and end of each extracted interval:
	positive Margin_(seconds) 0.005
	 
	boolean Normalize_intensity yes
	boolean Apply_fade_in_and_fade_out_to_extracted_audio yes
	positive Fade_length_(seconds) 0.010
	 
	comment Path and filename of tab-separated table with glosses and index numbers? (Leave blank if none.)
	text glossIndexTableFile 
	#text glossIndexTableFile C:/sotal/gloss-index-table.txt
	
	comment What folder do you want to save the WAV files in? (Use the full path, ending with "/")
	#text Folder E:/AV_Corpus/!!_Recordings/!!_Processing/praat-output/
	#text Folder C:/sotal/extracted-files/
	text Folder E:/AV_Corpus/!!_Recordings/!!_Processing/praat-output/
     
	#positive Number_of_characters_in_filename_prefix 100
	#positive Maximum_length_of_each_field_in_WAV_filenames 100

	#boolean Put_sequential_number_before_interval_labels_(optional) yes
 
	#comment What are the first and last intervals you want to extract?
	#integer First_interval 1
	#integer Last_interval_(0=to_end) 0

endform

# HARD CODED TO DEAL WITH BUG
extract_audio = 1

# Latest hard coded variables
regular_expression$ = "XXX|Xxx|xxx|WRONG|Wrong|wrong|REPEAT|Repeat|repeat|UNKNOWN|Unknown|unknown|SPANISH|Spanish|spanish|EXCLUDED|Excluded|excluded|.*\?.*"
number_of_characters_in_filename_prefix = 100
maximum_length_of_each_field_in_WAV_filenames = 100

# Hard code values of most variables for SotAL version of script.
searchTierName$ = "Gloss"
regular_expression_to_use$ = ".+"
restrictionTierName$ = ""
restrictionText$ = ""
extractionTierName$ = ""
labelTierName$ = ""
addLabelTierName$ = "Orthographic"
exclusionTier$ = "Status"
first_interval = 1
last_interval = 0
extract_audio_files = extract_audio

maxLength = maximum_length_of_each_field_in_WAV_filenames

exclusionRegex$ = regular_expression$

# Hard coded variables for SQL output. 
# For Mapudungun, ALL of these should be hard coded, as they aren't used and contain
# only default values. For other languages, these variables may be dynamic (read from
# text grids or manually entered by transcribers).
studyIx$ = "2"
familyIx$ = "8"
spellingAltvOne$ = ""
spellingAltvTwo$ = ""
notCognateWithMainWordInThisFamily$ = "0"
commonRootMorphemeStructDifferent$ = "0"
differentMeaningToUsualForCognate$ = "0"
actualMeaningInThisLanguage$ = ""
otherLexemeInLanguageForMeaning$ = ""
rootIsLoanWordFromKnownDonor$ = "0"
rootSharedInAnotherFamily$ = "0"
isoCodeKnownDonor$ = ""
differentMorphemeStructureNote$ = ""
oddPhonology$ = "0"
oddPhonologyNote$ = ""
soundProblem$ = "0"


# Perform necessary processing of certain form fields.

	# Set variable for use in WAV filename
	extractionTierLabel$ = extractionTierName$
	
	# If no extraction tier is provided, use the search tier for this.
	if extractionTierName$ = ""
		extractionTierName$ = searchTierName$
	endif
	
	# If no tier is provided for the source of labels, use the sound tier for them.
	if labelTierName$ = ""
		labelTierName$ = searchTierName$
	endif
	
	if ( restrictionTierName$ <> "" ) and ( restrictionText$ <> "" )
		useRestrict = 1
	else
		useRestrict = 0
	endif
	
	if ( exclusionTier$ <> "" ) and ( exclusionRegex$ <> "" )
		useExclusion = 1
	else
		useExclusion = 0
	endif
	
	if addLabelTierName$ <> ""
		useAddLabel = 1
	else
		useAddLabel = 0
	endif

	if ( extractionTierName$ <> "" ) and ( extractionTierName$ <> searchTierName$ )
		useSoundExtractionTier = 1
	else
		useSoundExtractionTier = 0
	endif


# Get name of TextGrid object
soundName$ = selected$ ("TextGrid", 1)

# Read the gloss-index table file, if it exists
if glossIndexTableFile$ <> ""
	Read Table from tab-separated file... 'glossIndexTableFile$'
	glossIndexTableObj$ = selected$ ("Table", 1)
endif

# Select TextGrid object
select TextGrid 'soundName$'

# Get the numbers of the tiers whose names were given.
call GetTierNum 'searchTierName$' searchTierNum
call GetTierNum 'labelTierName$' labelTierNum

if useAddLabel = 1
	call GetTierNum 'addLabelTierName$' addLabelTierNum
endif

call GetTierNum 'extractionTierName$' extractionTierNum

if ( useRestrict = 1 )
	call GetTierNum 'restrictionTierName$' restrictionTierNum
endif

if ( useExclusion = 1 )
	call GetTierNum 'exclusionTier$' exclusionTierNum
endif

# Check the interval values and correct them if necessary.
numberOfIntervals = Get number of intervals... searchTierNum

if first_interval > numberOfIntervals
	exit ERROR!'newline$''newline$'There aren´t 'first_interval' intervals in the tier labeled ``'searchTierName$'´´.'newline$''newline$'
endif

if last_interval > numberOfIntervals
	last_interval = numberOfIntervals
endif

if last_interval = 0
	last_interval = numberOfIntervals
endif

# Set default values for certain variables.
files = 0
intervalstart = 0
intervalend = 0
searchInterval = 1
intnumber = first_number - 1
soundIntervalName$ = ""
labelIntervalName$ = ""
addLabelIntervalName$ = ""
intervalfile$ = ""
endoffile = Get finishing time

# +++++
# Extract information from file name (Sound name) into variables that will be used
# to create output file names and the output TSV file.
speaker$ = replace_regex$("'soundName$'", "^.+_-_", "", 1)
langFullIndexNum$ = replace_regex$("'soundName$'", "--.*$", "", 1)
langName$ = replace_regex$("'soundName$'", "^.+--", "", 1)
langName$ = replace_regex$("'langName$'", "_-_.+$", "", 1)

prefix$ = langName$

# Count number of files (i.e. matching intervals) that will be produced.
for searchInterval from first_interval to last_interval
	searchIntervalLabel$ = Get label of interval... searchTierNum searchInterval
	check = 1

	# Take the necessary steps to make sure that the restriction tier and text
	# the user provides are taken into account
	
		# Get the position of current search interval in the search tier, to find 
		# corresponding intervals on the other tiers
		searchSelectionStart = Get start point... searchTierNum searchInterval
		searchSelectionEnd = Get end point...  searchTierNum searchInterval
		
		# Get the number of the interval on the restriction tier that corresponds to the 
		# current search interval, if the user wants to restrict the search to a given tier.
		if ( useRestrict = 1 )
			restrictionInterval = Get interval at time... restrictionTierNum searchSelectionStart
			restrictionIntervalLabel$ = Get label of interval... restrictionTierNum restrictionInterval
				
			# If the search expression matches current interval AND the restriction experssion also matches
			# then set check=0 (i.e. include this interval)
			if index_regex (searchIntervalLabel$, regular_expression_to_use$) 
				... and restrictionIntervalLabel$ = restrictionText$
				check = 0
			endif
			# If no restriction tier is selected, then just check to see if the search expression 
			# matches the current interval
			elsif ( useRestrict = 0 )
				if index_regex (searchIntervalLabel$, regular_expression_to_use$) 
					check = 0
				endif
			# If a weird value comes up, quit script
			else exit INVALID useRestrict value!
		
		endif

		
	# NEW IN 24: Check exclusion tier for regex to be excluded (if desired) 
	# NOTE: check=0 seems to mean "continue and process stuff".
	if ( useExclusion = 1 )

		# Get the number of the interval on the exclusion tier that corresponds
		# to the current search interval
		exclusionInterval = Get interval at time... exclusionTierNum searchSelectionStart
		exclusionIntervalLabel$ = Get label of interval... exclusionTierNum exclusionInterval
		
		# Check to see if the exclusion interval label matches the exclusion regex. If so, 
		# the variable exclusionTest will equal something non-zero.
		exclusionTest = index_regex (exclusionIntervalLabel$, exclusionRegex$)
		
		if ( exclusionTest <> 0 )
			check = 1
		endif
	endif

	# If current segment meets all conditions for being counted, increase file count
	if check = 0
	   files = files + 1
	endif
	
endfor

searchInterval = 1

# Check to see if there are 0 matches. If so, die.
if files = 0
	select TextGrid 'soundName$'
	plus LongSound 'soundName$'
	exit SORRY!'newline$''newline$'No interval matches your search expression. 
	...'newline$''newline$'Close this window by clicking  <OK>, close the script window by clicking 
	...<CANCEL>, and try again... 'newline$''newline$'	
endif

# Ask user for confirmation to proceed.
if extract_audio_files = 1
	pause You are about to export 'files' audio files (per format chosen). Continue?
endif

# Create directory whose name is the langauge variety (+speaker) name
createDirectory ("'folder$''langName$'")

# Change directory name to directory + new folder name, effectively cd-ing into the new directory
folder$ = folder$ + langName$ + "/"

# Define path and name of log file
textfilename$ = "'folder$'" + "'soundName$'" + "_" + "'first_number'" + "-to-" + "'files'" + ".txt"

# Define path and name of SQL file
if output_sql = 1
	sqlfilename$ = "'folder$'" + "Transcriptions_Mapudungun_" + "'langName$'" + ".sql"
endif

# Check if the log file exists. If so, give the user the option to overwrite it.
if fileReadable (textfilename$)
	pause The log file, 'soundName$'_'first_number'-to-'files'.txt, already exists. Do you want to overwrite it?
	filedelete 'textfilename$'
endif

# Check if the SQL file exists. If so, give the user the option to overwrite it.
if fileReadable (sqlfilename$)
	pause The SQL file, 'soundName$'_'first_number'-to-'files'.sql, already exists. Do you want to overwrite it?
	filedelete 'sqlfilename$'
endif


# NEW IN 24-SotAL: Print metadata to log file
dog$ =	"======================================================================'newline$'
		...'script_name$' ver. 'version$' by 'author$' - http://sadowsky.cl/'newline$'
		...User:'tab$''tab$''tab$''tab$''user$''newline$'
		...Search date:'tab$''tab$''date$'.'newline$'
		...Output directory:'tab$''folder$''newline$'
		...Search expression:'tab$'[AUTOMATIC]'newline$'
          ...'tab$''tab$''tab$''tab$''tab$'[Settings hard-coded for Sounds of the Andean Languages Project]'newline$'
		...======================================================================'newline$''newline$'"
fileappend "'textfilename$'" 'dog$'

# NEW IN 24-SotAL
# Complete header is now mandatory and automatic
if export_notes = 1
	dog$ = "LanguageFullIndexNumber'tab$'LanguageName'tab$'WordIndexNumber'tab$'IxMorphologicalInstance'tab$'PhoneticTranscription'tab$'WordNameInRefLangGLOSS'tab$'WordNameInRefLangORTHO'tab$'IxLex'tab$'IxPron'tab$'Status'tab$'Count'tab$'Notes'tab$'SpeakerName'tab$'CommonRootMorphemeStructDifferent'tab$'DifferentMorphemeStructureNote'newline$'"
else
	dog$ = "LanguageFullIndexNumber'tab$'LanguageName'tab$'WordIndexNumber'tab$'IxMorphologicalInstance'tab$'PhoneticTranscription'tab$'WordNameInRefLangGLOSS'tab$'WordNameInRefLangORTHO'tab$'IxLex'tab$'IxPron'tab$'CommonRootMorphemeStructDifferent'tab$'DifferentMorphemeStructureNote'newline$'"
endif
	
fileappend "'textfilename$'" 'dog$'

##################################################################################
# Loop through all intervals in the selected tier of the TextGrid
##################################################################################
for searchInterval from first_interval to last_interval
	check = 1
	select TextGrid 'soundName$'
	searchIntervalLabel$ = ""
	searchIntervalLabel$ = Get label of interval... searchTierNum searchInterval
     
     # Get the interval labels for all tiers of interest, regardless of what user 
	# indicates, except the index number, which is processed below as of v3,3-SotAL-EXPERIMENTAL.
	sotalLabelGloss$ = Get label of interval... 2 searchInterval
     sotalLabelOrthographic$ = Get label of interval... 3 searchInterval
     sotalLabelPhonetic$ = Get label of interval... 4 searchInterval
     sotalLabelStatus$ = Get label of interval... 5 searchInterval
     sotalLabelNotes$ = Get label of interval... 6 searchInterval
	
	# Get the position of current search interval in the search tier, to find 
	# corresponding intervals on the other tiers
	searchSelectionStart = Get start point... searchTierNum searchInterval
	searchSelectionEnd = Get end point...  searchTierNum searchInterval
	
	# Get the number of the interval on the restriction tier that corresponds to the 
	# current search interval, if the user wants to restrict search to a certain tier section.
	if ( useRestrict = 1 )
		restrictionInterval = Get interval at time... restrictionTierNum searchSelectionStart
		restrictionIntervalLabel$ = Get label of interval... restrictionTierNum restrictionInterval
		
		# If search expression matches current search interval AND restriction expression matches 
		# the current restriction interval, then set check=0 to signal that this interval is to be
		# extracted.
		if index_regex (searchIntervalLabel$, regular_expression_to_use$) 
			... and restrictionIntervalLabel$ = restrictionText$
			check = 0
		endif
	endif
     
	# If no restriction tier or text are set, only check to see if the search expression matches 
	# current search interval in order to set check=0, thereby signalling that this interval is to be
	# extracted.
	if ( useRestrict = 0 )
		if index_regex (searchIntervalLabel$, regular_expression_to_use$) 
			check = 0
		endif
	endif
	
	# NEW IN 24: Check exclusion tier for regex to be excluded (if desired) 
	# NOTE: check=0 seems to mean "continue and process stuff".
	if ( useExclusion = 1 )

		# Get the number of the interval on the exclusion tier that corresponds
		# to the current search interval
		exclusionInterval = Get interval at time... exclusionTierNum searchSelectionStart
		exclusionIntervalLabel$ = Get label of interval... exclusionTierNum exclusionInterval
		
		# Check to see if the exclusion interval label matches the exclusion regex. If so, 
		# the variable exclusionTest will equal something non-zero.
		exclusionTest = index_regex (exclusionIntervalLabel$, exclusionRegex$)
		
		if ( exclusionTest <> 0 )
			check = 1
		endif
	endif
	
	# NEW IN 4,1
	# If user chooses to only extract intervals with a phonetic transcription, check the interval
	# and don't extract it if it's empty
	if ( extract_only_intervals_with_phonetic_transcription = 1 ) and ( sotalLabelPhonetic$ = "" )
		check = 1
	endif
	
	# Get the number of the interval on the extraction tier that corresponds to the current
	# search interval.	   extractionTierName$ extractionTierNum
	extractionInterval = Get interval at time... extractionTierNum searchSelectionStart
	extractionIntervalLabel$ = ""
	extractionIntervalLabel$ = Get label of interval... extractionTierNum extractionInterval
	
	# Extract the text from the label interval on the label tier
	
		# Get the number of the interval on the label tier that corresponds to the current search interval
		labelInterval = Get interval at time... labelTierNum searchSelectionStart
		
		# On the label tier, get the interval label that corresponds to the current search interval.
		labelIntervalName$ = ""
		labelIntervalName$ = Get label of interval... labelTierNum labelInterval
		

	# # DEBUG NEW IN 4,0
	# if labelIntervalName$ = ""
		# printline labelInterval = 'labelInterval'
		# printline labelIntervalName$ = _'labelIntervalName$'_
	# endif 


		# Get the number of the interval on the ADDITIONAL label tier that corresponds to the current search interval
		if ( useAddLabel = 1 )
			addLabelInterval = Get interval at time... addLabelTierNum searchSelectionStart
			
			# On the ADDITIONAL label tier, get the interval label that corresponds to the current search interval.
			addLabelIntervalName$ = ""
			addLabelIntervalName$ = Get label of interval... addLabelTierNum addLabelInterval
		endif
 
          
	# Perform the actual sound extraction.
	if check = 0
	  intnumber = intnumber + 1
	  
		# Extract interval PLUS MARGIN
		if add_margin_to_extracted_interval = 1
				  
			  # Add margins to start and end times for extraction.
			  intervalstart = Get starting point... extractionTierNum extractionInterval
				   
				   if intervalstart > margin
						intervalstart = intervalstart - margin
						else
							 intervalstart = 0
				   endif
		 
			  intervalend = Get end point... extractionTierNum extractionInterval
				   if intervalend < endoffile - margin
						intervalend = intervalend + margin
						else
							 intervalend = endoffile
				   endif
		endif
			  
		# Extract interval WITHOUT MARGIN		   
		if add_margin_to_extracted_interval = 0
				  
			  # Add margins to start and end times for extraction.
			  intervalstart = Get starting point... extractionTierNum extractionInterval
			  intervalend = Get end point... extractionTierNum extractionInterval

		endif
		   
		# NEW IN 3,3-SotAL-EXPERIMENTAL
		# Get index number.
		#
		# If the "Path and filename of tab-separated table with glosses and index 
		# numbers?" form field is empty, get the index number from the text grid. 
		# If not, look it up in the user-provided table.		
		if glossIndexTableFile$ = ""
			sotalLabelIndex$ = Get label of interval... 1 searchInterval
		else
			select Table 'glossIndexTableObj$'
			# NEW IN 3,34! Search for a match first (0 = no match). If none is found, assign default
			# text to index label. Otherwise, extract index number from the table file.
			isMatch = Search column: "gloss", sotalLabelGloss$
			if isMatch = 0
				sotalLabelIndex$ = "MISSING-VALUE-IN-INTERVAL-" + "'searchInterval'"
			else			
				Extract rows where column (text): "gloss", "is equal to", sotalLabelGloss$
				foundIndexNumber$ = Get value: 1, "index"
				sotalLabelIndex$ = foundIndexNumber$
				Remove
				## DEBUG
				#printline sotalLabelGloss$ = 'sotalLabelGloss$'
				#printline foundIndexNumber = 'foundIndexNumber'
				#printline foundIndexNumber$ = 'foundIndexNumber$'
				#printline sotalLabelIndex = 'sotalLabelIndex'
				#printline sotalLabelIndex$ = 'sotalLabelIndex$'
				#printline ======== 'newline$'
			endif
		endif
		
		# # New in 4,0 -- DEBUG -- Find empty intervals
		# if sotalLabelIndex$ = ""
			# printline " "
			# printline "Problem!"
			# printline sotalLabelIndex$ = 'sotalLabelIndex$'
			# printline 
		# endif
		
		# NEW IN 3,6: REMOVE LEADING ZEROS FROM sotalLabelIndex$
		sotalLabelIndex$ = replace_regex$("'sotalLabelIndex$'", "^0+", "", 0)
		
		# NEW IN 217: MAKE EXTRACTING WAVS OPTIONAL
		if extract_audio_files = 1
		
			# Extract the sound from the interval. THE KEY VALUES ARE intervalstart AND intervalend *****************
			select LongSound 'soundName$'
			Extract part... intervalstart intervalend no
			   
                  # Perform fade-in and fade-out, if desired
                  if apply_fade_in_and_fade_out_to_extracted_audio
                         
                         Fade in... All 0 fade_length n
                         
                         clipEndTime = Get end time
                         neg_fade_length = fade_length * -1
                         Fade out... All clipEndTime neg_fade_length n
                  endif
                  
                  # Normalize intensity to peak, if desired.
                  if normalize_intensity
                         Scale peak... 0.99
                  endif
			
			stringLength = length (prefix$)
			if stringLength > maxLength
				prefix$ = left$ (prefix$, maxLength)
			endif
			
			stringLength = length (restrictionText$)
			if stringLength > maxLength
				restrictionText$ = left$ (restrictionText$, maxLength)
			endif
			
			stringLength = length (extractionTierName$)
			if stringLength > maxLength
				extractionTierName$ = left$ (extractionTierName$, maxLength)
			endif

			stringLength = length (labelIntervalName$)
			if stringLength > maxLength
				labelIntervalName$ = left$ (labelIntervalName$, maxLength)
			endif


			# Append ADDITIONAL label to search interval label, if user specifies an additional label.
			combinedIntervalLabel$ = searchIntervalLabel$
			if (useAddLabel = 1)
				# combinedIntervalLabel$ = searchIntervalLabel$ + "__" + addLabelIntervalName$
					combinedIntervalLabel$ = addLabelIntervalName$ + "}_{" + searchIntervalLabel$
			endif
			
			
			###################################################################################
			# NEW IN 3,8
			# If the current word is labelled as an altmorph of any type, then 
			# commonRootMorphemeStructDifferent$ is set to 1 and the value of the Notes 
			# field is is read and set in differentMorphemeStructureNote$.
			
			# Set default values
			commonRootMorphemeStructDifferent$ = "0"
			differentMorphemeStructureNote$ = ""
			
			#if ( sotalLabelStatus$ = "altmorph")
			if index_regex (sotalLabelStatus$, "altmorph")
				commonRootMorphemeStructDifferent$ = "1"
				differentMorphemeStructureNote$ = sotalLabelNotes$
			endif
			
			if index_regex (sotalLabelStatus$, "altmorph2")
				commonRootMorphemeStructDifferent$ = "1"
				differentMorphemeStructureNote$ = sotalLabelNotes$
			endif
			
			if index_regex (sotalLabelStatus$, "altmorph3")
				commonRootMorphemeStructDifferent$ = "1"
				differentMorphemeStructureNote$ = sotalLabelNotes$
			endif
			
			if index_regex (sotalLabelStatus$, "altmorph4")
				commonRootMorphemeStructDifferent$ = "1"
				differentMorphemeStructureNote$ = sotalLabelNotes$
			endif
			
			if index_regex (sotalLabelStatus$, "altmorph5")
				commonRootMorphemeStructDifferent$ = "1"
				differentMorphemeStructureNote$ = sotalLabelNotes$
			endif
			
			###################################################################################
			# NEW IN 3,8
			# Set IxMorphologicalInstance to 0 in all except two cases:
			#   - If the word is nosotros_dos, set to 3
			#   - If the word is nosotros_pl, set to 4

			ixMorphologicalInstance$ = "0"
			
			if ( sotalLabelGloss$ = "nosotros_dos" )
				ixMorphologicalInstance$ = "3"
			endif
			
			if ( sotalLabelGloss$ = "nosotros_pl" )
				ixMorphologicalInstance$ = "4"
			endif
			
			###################################################################################
			# CHANGED IN 3,6 SQL DELUXE VERSION: The default value of altlex$ was changed from 1 to 0,
			# in accordance with Paul's instructions that it should NEVER be 1.
			
			# Process items that are alternative lexemes
				# Set default value
				altLex$ = "0"
				
				# LABEL: "altlex"
				#if ( sotalLabelStatus$ = "altlex")
				if index_regex (sotalLabelStatus$, "altlex")
					altLex$ = "_lex2"
				endif
			
				# LABEL: "altlex2"
				if index_regex (sotalLabelStatus$, "altlex2")
					altLex$ = "_lex3"
				endif
				
				# LABEL: "altlex3"
				if index_regex (sotalLabelStatus$, "altlex3")
					altLex$ = "_lex4"
				endif
				
				# LABEL: "altlex4"
				if index_regex (sotalLabelStatus$, "altlex4")
					altLex$ = "_lex5"
				endif
			
			# CHANGED IN 3,6 SQL DELUXE VERSION: The default value of altPron$ was changed from 1 to 0,
			# in accordance with Paul's instructions that it should NEVER be 1.
			# Process items that are alternative pronunciations
			
			# Set default value
			altPron$ = "0"
			
			#if ( sotalLabelStatus$ = "altpron")
			if index_regex (sotalLabelStatus$, "altpron")
				altPron$ = "_pron2"
			endif
			
				# LABEL: "altpron2"
				if index_regex (sotalLabelStatus$, "altpron2")
					altPron$ = "_pron3"
				endif
			
				# LABEL: "altpron3"
				if index_regex (sotalLabelStatus$, "altpron3")
					altPron$ = "_pron4"
				endif
				
				# LABEL: "altpron4"
				if index_regex (sotalLabelStatus$, "altpron4")
					altPron$ = "_pron5"
				endif
				
				# LABEL: "altpron5"
				if index_regex (sotalLabelStatus$, "altpron5")
					altPron$ = "_pron6"
				endif
			
			
			# Change spaces to underscores in sotalLabelGloss$
			sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGloss$'", " ", "_", 0)
			
			# # Remove non-ASCII characters in sotalLabelGloss$
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "á", "a", 0)
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "é", "e", 0)
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "í", "i", 0)
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "ó", "o", 0)
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "ú", "u", 0)
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "ü", "u", 0)
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "ñ", "nh", 0)
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "Á", "A", 0)
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "É", "E", 0)
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "Í", "I", 0)
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "Ó", "O", 0)
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "Ú", "U", 0)
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "Ü", "U", 0)
			# sotalLabelGlossUnderscores$ = replace_regex$("'sotalLabelGlossUnderscores$'", "Ñ", "NH", 0)
			
			# CHANGED IN 3,6: The IF statement used to be: "if ( altLex$ = "1" )". That was when 1 was the
			# default value. Now that the default is 0, I've changed the corresponding value in the IF statement below.
			if ( altLex$ = "0" )
				altLexFN$ = ""
			else
				altLexFN$ = altLex$
			endif
			
			# CHANGED IN 3,6: The IF statement used to be: "if ( altPron$ = "1" )". That was when 1 was the
			# default value. Now that the default is 0, I've changed the corresponding value in the IF statement below.
			if ( altPron$ = "0" )
				altPronFN$ = ""
			else
				altPronFN$ = altPron$
			endif
			
			# CREATE FILE NAME STRING
			intervalfile$ = "'folder$'" +
			... "'prefix$'_" +
			... "'sotalLabelIndex$'_" +
			... "'sotalLabelGlossUnderscores$'" +
			... "'altLexFN$'" +
			... "'altPronFN$'"

			# Create string with full filename (base + extension) and export WAV
			intervalfileWithExt$ = intervalfile$ + ".wav"
				
			# Determine whether this word has already been extracted. If so, set relevant variable.
			currentWordIsDuplicate = 0
			
			if fileReadable ( intervalfileWithExt$ )
				currentWordIsDuplicate = 1
			endif
			
			# Write the WAV file IF AND ONLY IF it's NOT a duplicate (NEW IN 4,0)
			if currentWordIsDuplicate = 0
				Write to WAV file... 'intervalfileWithExt$'
			endif
			
			Remove
	endif
	
		# Take the label of the saved sound interval and add it to the text file:
		select TextGrid 'soundName$'
		  
		# Extract TextGrid along with sound file (NEW IN 4,0)
		if currentWordIsDuplicate = 0
			if also_extract_TextGrids
				Extract part... intervalstart intervalend no
				intervalfileWithExt$ = intervalfile$ + ".TextGrid"
				Write to text file... 'intervalfileWithExt$'
				Remove
			endif
		endif
		  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

		# Remove underscores from AltPron$ and AltLex$ and altMorph$
		altPron$ = replace_regex$("'altPron$'", "_pron", "", 0)
		altLex$ = replace_regex$("'altLex$'", "_lex", "", 0)
		altMorph$ = replace_regex$("'altMorph$'", "_", "", 0)
		
		# Write information about the extracted sound to log file
		# Only do this if word is NOT dupe (New in 4,0)
		if currentWordIsDuplicate = 0
			if export_notes = 1
				dog$ = "'langFullIndexNum$''tab$''langName$''tab$''sotalLabelIndex$''tab$''ixMorphologicalInstance$''tab$''sotalLabelPhonetic$''tab$''sotalLabelGloss$''tab$''sotalLabelOrthographic$''tab$''altLex$''tab$''altPron$''tab$''sotalLabelStatus$''tab$''intnumber''tab$''sotalLabelNotes$''tab$''speaker$''tab$''commonRootMorphemeStructDifferent$''tab$''differentMorphemeStructureNote$''newline$'"
			else
				dog$ = "'langFullIndexNum$''tab$''langName$''tab$''sotalLabelIndex$''tab$''ixMorphologicalInstance$''tab$''sotalLabelPhonetic$''tab$''sotalLabelGloss$''tab$''sotalLabelOrthographic$''tab$''altLex$''tab$''altPron$''tab$''commonRootMorphemeStructDifferent$''tab$''differentMorphemeStructureNote$''newline$'"
			endif
					
			fileappend "'textfilename$'" 'dog$'
		endif
		
		# Write information to SQL file +++++
		# Only do this if word is NOT dupe (New in 4,0)
		if currentWordIsDuplicate = 0
			if output_sql = 1

				# DEAL WITH NASTY CHARACTERS!
				
				# Convert apostrophes to closing smart quotes in the ORTHOGRAPHIC transcription field
				sotalLabelOrthographic$ = replace_regex$("'sotalLabelOrthographic$'", "'", "’", 0)
				
				# Convert apostrophes to closing smart quotes in the GLOSS field
				sotalLabelGloss$ = replace_regex$("'sotalLabelGloss$'", "'", "’", 0)
				
				# Convert apostrophes to closing smart quotes in the NOTES field
				sotalLabelNotes$ = replace_regex$("'sotalLabelNotes$'", "'", "’", 0)

				
				# Prepare the string that will contain the entire SQL statement!
				sql_statement$ = "INSERT INTO Transcriptions_Mapudungun (StudyIx,FamilyIx,IxElicitation,IxMorphologicalInstance,AlternativePhoneticRealisationIx,AlternativeLexemIx,LanguageIx,Phonetic,SpellingAltv1,SpellingAltv2,NotCognateWithMainWordInThisFamily,CommonRootMorphemeStructDifferent,DifferentMeaningToUsualForCognate,ActualMeaningInThisLanguage,OtherLexemeInLanguageForMeaning,RootIsLoanWordFromKnownDonor,RootSharedInAnotherFamily,IsoCodeKnownDonor,DifferentMorphemeStructureNote,OddPhonology,OddPhonologyNote,UsageNote,SoundProblem) VALUES ("
				...	+ studyIx$
				... + ","
				... + familyIx$
				... + ","
				... + sotalLabelIndex$
				... + ","
				...	+ ixMorphologicalInstance$
				... + ","
				...	+ altPron$
				... + ","
				...	+ altLex$
				... + ","
				... + langFullIndexNum$
				... + ",'"
				...	+ sotalLabelPhonetic$
				... + "','"
				...	+ spellingAltvOne$
				... + "','"
				...	+ spellingAltvTwo$
				... + "',"
				...	+ notCognateWithMainWordInThisFamily$
				... + ","
				...	+ commonRootMorphemeStructDifferent$
				... + ","
				...	+ differentMeaningToUsualForCognate$
				... + ",'"
				...	+ actualMeaningInThisLanguage$
				... + "','"
				...	+ otherLexemeInLanguageForMeaning$
				... + "',"
				...	+ rootIsLoanWordFromKnownDonor$
				... + ","
				...	+ rootSharedInAnotherFamily$
				... + ",'"
				...	+ isoCodeKnownDonor$
				... + "','"
				...	+ differentMorphemeStructureNote$
				... + "',"
				...	+ oddPhonology$
				... + ",'"
				...	+ oddPhonologyNote$
				... + "','"
				...	+ ""
				... + "',"
				...	+ soundProblem$
				... + ") ON DUPLICATE KEY UPDATE "
				... + "StudyIx="
				...	+ studyIx$
				... + ","
				...	+ "FamilyIx="
				...	+ familyIx$
				... + ","
				...	+ "IxElicitation="
				...	+ sotalLabelIndex$
				... + ","
				...	+ "IxMorphologicalInstance="
				...	+ ixMorphologicalInstance$
				... + ","
				...	+ "AlternativePhoneticRealisationIx="
				...	+ altPron$
				... + ","
				...	+ "AlternativeLexemIx="
				...	+ altLex$
				... + ","
				...	+ "LanguageIx="
				...	+ langFullIndexNum$
				...	+ ";"
				
				appendFileLine: sqlfilename$, sql_statement$
			endif
		endif
	endif
endfor

########DEBUG
	if debug = 1
		printline ========== NEW DEBUG ==========
		printline useRestrict = 'useRestrict'
		printline useSoundExtractionTier = 'useSoundExtractionTier'
		printline 
		printline regex = 'regular_expression_to_use$'
		printline restrictionTierName$ = 'restrictionTierName$'
		printline restrictionText$ = 'restrictionText$'
		printline extractionTierName$ = 'extractionTierName$'
		printline labelTierName$ = 'labelTierName$'
		printline labelIntervalName$ = 'labelIntervalName$'
		printline intnumber = 'intnumber'
		printline searchIntervalLabel$ = 'searchIntervalLabel$'
		printline -------------------------------
		printline 
		printline 
	endif

	if glossIndexTableFile$ <> ""
		select Table 'glossIndexTableObj$'
		Remove
	endif

select TextGrid 'soundName$'
plus LongSound 'soundName$'

##############################################################################
# PROCEDURE:	GetTierNum .name$ .variable$
# DESCRIPTION:	Finds the number of a tier that has a given label.
# GLOBAL VARIABLES NEEDED:
#	<soundName$> is the name of the sound and TextGrid file being used.
# THANKS: Adapted from a script by Mietta Lennes.
##############################################################################
procedure GetTierNum .name$ .variable$
	
	select TextGrid 'soundName$'
	.numberOfTiers = Get number of tiers
	
	# Cycle through the tiers in the TextGrid and check tier names until the 
	# desired one is found or all tiers have been tried unsuccessfully.
	.itier = 1
	repeat
		.currentTier$ = Get tier name... .itier
		.itier = .itier + 1
	until .currentTier$ = .name$ or .itier > .numberOfTiers

	# If no tier has the name being searched for, set the variable passed back 
	# to the main part of the script (whose name is contained in .variable$) to 0. 
	if .currentTier$ <> .name$
		'.variable$' = 0
	
	# If the tier being searched for WAS found, set the variable passed as the
	# procedure's second parameter (held in .variable$) to the tier number.
	else
		'.variable$' = .itier - 1
	endif

	# If the tier being searched for was not found, die and throw an error message.
	if '.variable$' = 0
		exit There is no tier called '.name$' in the file 'soundName$'!
	endif

endproc


