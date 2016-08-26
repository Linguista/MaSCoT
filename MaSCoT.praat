#!/usr/bin/praat
#praat script

# NOTICE: This file uses UTF-8!

debug = 0

script_name$ = "MaSCoT"
version$ = "2.5"
author$ = "Scott Sadowsky"

# MaSCoT.praat
##############################################################################
# SCRIPT:	MAssive Speech COrpora Tool (MaSCoT)
# AUTHOR:	Scott Sadowsky - http://sadowsky.cl - ssadowsky REMOVETHISBIT gmail com
# DATE:		9 September 2013
# VERSION:	2.5
# DESCRIPTION: Opens a LongSound + TextGrid pair and saves all intervals 
#			on the selected tier THAT MATCH THE REGEX THE USER PROVIDES
#			to individual WAV files.
#			Trying to add ability to extract TGs, too.
# USAGE NOTES:	-- The source sound must be a LongSound object.
#		    	-- Both the TextGrid and the LongSound must have identical names
#			  		and must be selected before running the script.
# THANKS:	GetTierName procedure adapted from a script by Mietta Lennes.
#			Some other parts of this script are also based on a script by
#			Mietta Lennes.
#
# MaSCoT Changelog
#
# 24
# Added option to exclude intervals on a user-selected tier that contain text that matches any regular expression.
# Added option to put sequential interval number before interval labels in some situations.
#
# 22
# Moved to two-digit versioning system.
# Added ability to normalize extracted audio. Normalization is done to the peak value.
#
# 219
# Added ability to apply fade-in and fade-out to extracted audio.
# Made adding a left and right margin to the extracted audio optional.
#
# 216
# Added more info to the log file that MaSCoT produces.
#
# 213
# Changed default field contents for Regex, since the bracketed expression [áéíóú] works irregularly (!!!).
#
# 210
# Added ability to save TextGrids along with sound files.
##############################################################################


# Define certain variables.
useRestrict = 0
useSoundExtractionTier = 0
#number_of_characters_in_filename_prefix = 15
date$ = date$()
first_number = 1

form MAssive Speech COrpus Tool (MaSCoT) v. 2.5
	
	#comment ***** Requires a TextGrid and a LongSound be selected *****

	sentence Search_tier misc
	#sentence Useful_symbols i̯ u̯ d̪ ʤ d͡ʒ ʝ ɲ ɾ ʃ t̪ t͡ɾ ʧ t͡ʃ ʂ ˈ | ‖
	sentence Regular_expression_to_use .+
	comment REGEX EXAMPLES: ^line$  <word> · [a-z]  [ieaou]  [^0-9]  (a|b|c)  \d  \D  \l  \L ·  ?  .  .*  .+  {2,5}

	sentence Restrict_search_to_this_tier_(optional) 
	sentence And_to_this_section_of_the_tier_(optional) 
	sentence Extract_sound_from_this_tier_(optional) 
	sentence Use_labels_from_this_tier_(optional) 
	sentence Additional_labels_from_this_tier_(optional) 
	sentence Exclude_intervals_from_this_tier_(optional) misc
	sentence If_above_intervals_match_following_regex_(optional) XXX|xxx|REVIEW|Review|review|WRONG|Wrong|wrong|REPEAT|Repeat|repeat|UNKNOWN|Unknown|unknown|SPANISH|Spanish|spanish|.*\?.*

	boolean Extract_WAV_files yes
	boolean Also_extract_TextGrids yes
   
	boolean Add_margin_to_extracted_interval yes
	comment Time margin to add to beginning and end of each extracted interval:
	positive Margin_(seconds) 0.005
	 
	 boolean Normalize_intensity yes
	 boolean Apply_fade_in_and_fade_out_to_extracted_audio yes
	 positive Fade_length_(seconds) 0.005
	
	comment What folder do you want to save the WAV files in? (Use the full path, ending with "/")
	text Folder E:/AV_Corpus/!!_Recordings/!!_Processing/praat-output/
	
	positive Number_of_characters_in_filename_prefix 20
	positive Maximum_length_of_each_field_in_WAV_filenames 25
	
	boolean Put_sequential_number_before_interval_labels_(optional) yes
	 
	comment What are the first and last intervals you want to extract?
	
	integer First_interval 1
	integer Last_interval_(0=to_end) 0

endform


# Give form variables shorter, English names.
restrictionTierName$ = restrict_search_to_this_tier$
restrictionText$ = and_to_this_section_of_the_tier$
searchTierName$ = search_tier$
extractionTierName$ = extract_sound_from_this_tier$
labelTierName$ = use_labels_from_this_tier$
addLabelTierName$ = additional_labels_from_this_tier$
maxLength = maximum_length_of_each_field_in_WAV_filenames
exclusionTier$ = exclude_intervals_from_this_tier$
exclusionRegex$ = if_above_intervals_match_following_regex$

# Perform necessary processing of certain form fields.
	# If no search tier is provided, die.
	if searchTierName$ = ""
		exit ERROR!'newline$''newline$'You must input the name of the tier you want to search in. 'newline$''newline$'Close this window by clicking on <OK>, close the script window with <CANCEL>, and try again... 'newline$''newline$'
	endif

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


soundName$ = selected$ ("TextGrid", 1)
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
	exit ERROR!'newline$''newline$'There aren't 'first_interval' intervals in the tier labeled ``'searchTierName$'´´.'newline$''newline$'
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
prefix$ = left$("'soundName$'", number_of_characters_in_filename_prefix)

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

		
	# NEW IN 24: Check exclusion tier for regex to be excluded (if desired) +++++
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
if extract_WAV_files = 1
	pause You are about to export 'files' WAV files. Continue?
endif

# Define path and name of log file
textfilename$ = "'folder$'" + "'soundName$'" + "_" + "'first_number'" + "-to-" + "'files'" + ".txt"

# Check if the log file exists. If so, give the user the option to overwrite it.
if fileReadable (textfilename$)
	pause The log file, 'soundName$'_'first_number'-to-'files'.txt, already exists. Do you want to overwrite it?
	filedelete 'textfilename$'
endif

# NEW IN 216: Print metadata to log file
dog$ =	"======================================================================'newline$'
		...'script_name$' ver. 'version$' by 'author$''newline$''newline$'
		...Search date:'tab$''date$'.'newline$'
		...Directory:'tab$''folder$''newline$''newline$'
		...Search expression:'tab$''tab$''tab$''regular_expression_to_use$''newline$'
		...Tier searched:'tab$''tab$''tab$''tab$''search_tier$''newline$'
		...Sound extraction tier:'tab$''tab$''extractionTierName$''newline$'
		...Restriction tier:'tab$''tab$''tab$''restrict_search_to_this_tier$''newline$'
		...Restriction tier section:'tab$''and_to_this_section_of_the_tier$''newline$'
		...Tier used for labels:'tab$''tab$''use_labels_from_this_tier$''newline$'
		...Additional label tier:'tab$''tab$''addLabelTierName$''newline$'
		...======================================================================'newline$''newline$'"
fileappend "'textfilename$'" 'dog$'

# NEW IN 216: Print header row to log file
# For reasons I can't figure out, the normal (and possibly more efficient) way of doing 
# this --if X then dog$=Y else dog$=Z-- doesn't work. I have to do dog$=Y, if X then dog$=Z.
dog$ = "INTERVAL_NUM'tab$'FILE_PREFIX'tab$'SEARCH_INT_LABEL'tab$'LABEL_INT_NAME'tab$'RESTRICTION_TXT'tab$'EXTRACTION_TIER_LABEL'newline$'"

if ( useAddLabel = 1 )
	dog$ = "INTERVAL_NUM'tab$'FILE_PREFIX'tab$'SEARCH_INT_LABEL'tab$'ADD_INT_LABEL'tab$'LABEL_INT_NAME'tab$'RESTRICTION_TXT'tab$'EXTRACTION_TIER_LABEL'newline$'"
endif

fileappend "'textfilename$'" 'dog$'

# Loop through all intervals in the selected tier of the TextGrid
for searchInterval from first_interval to last_interval
	check = 1
	select TextGrid 'soundName$'
	searchIntervalLabel$ = ""
	searchIntervalLabel$ = Get label of interval... searchTierNum searchInterval
	
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
	
	# NEW IN 24: Check exclusion tier for regex to be excluded (if desired) +++++
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
	
	# +++++
	
	
	# Get the number of the interval on the extraction tier that corresponds to the current
	# search interval.				 extractionTierName$ extractionTierNum
	extractionInterval = Get interval at time... extractionTierNum searchSelectionStart
	extractionIntervalLabel$ = ""
	extractionIntervalLabel$ = Get label of interval... extractionTierNum extractionInterval

	# Extract the text from the label interval on the label tier
	
		# Get the number of the interval on the label tier that corresponds to the current search interval
		labelInterval = Get interval at time... labelTierNum searchSelectionStart
		
		# On the label tier, get the interval label that corresponds to the current search interval.
		labelIntervalName$ = ""
		labelIntervalName$ = Get label of interval... labelTierNum labelInterval
		



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
		   

		# NEW IN 217: MAKE EXTRACTING WAVS OPTIONAL
		if extract_WAV_files = 1
		
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
			
			# The name of the sound file then consists of these elements:
			if ( useRestrict = 1 && useSoundExtractionTier = 1)
				intervalfile$ = "'folder$'" +
				... "'prefix$'-" +
				... "['intnumber']__" + 
				... "{'combinedIntervalLabel$'}__" +
				... "utterance='labelIntervalName$'__" +
				... "restriction='restrictionText$'__" + 
				... "extracted-from='extractionTierLabel$'"

			elsif ( useRestrict = 1 && useSoundExtractionTier = 0)
				intervalfile$ = "'folder$'" +
				... "'prefix$'-" +
				... "['intnumber']__" + 
				... "{'combinedIntervalLabel$'}__" +
				... "utterance='labelIntervalName$'__" +
				... "restriction='restrictionText$'"

			elsif ( useRestrict = 0 && useSoundExtractionTier = 1)
				intervalfile$ = "'folder$'" +
				... "'prefix$'-" +
				... "['intnumber']__" + 
				... "{'combinedIntervalLabel$'}__" +
				... "utterance='labelIntervalName$'__" +
				... "extracted-from='extractionTierLabel$'"

			else
				# Place interval number first if user selected this option: put_sequential_number_before_interval_labels
				if put_sequential_number_before_interval_labels
					intervalfile$ = "'folder$'" +
					... "'prefix$'-" +
					... "['intnumber']--" +
					... "{'combinedIntervalLabel$'}"
				else
					intervalfile$ = "'folder$'" +
					... "'prefix$'-" +
					... "{'combinedIntervalLabel$'}__" +
					... "_['intnumber']"
				endif
			endif
			
			intervalfileWithExt$ = intervalfile$ + ".wav"


			Write to WAV file... 'intervalfileWithExt$'
			Remove
		
	# NEW IN 217: MAKE WRITING WAVS OPTIONAL
	endif
	
		# Take the label of the saved sound interval and add it to the text file:
		select TextGrid 'soundName$'
		  
		  # #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		  # !!!!! EXPERIMENTAL !!!!! WARNING  !!! Extract TextGrid along with sound file
			
		if also_extract_TextGrids
			Extract part... intervalstart intervalend no
			intervalfileWithExt$ = intervalfile$ + ".TextGrid"
			Write to text file... 'intervalfileWithExt$'
			Remove
		endif
		  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

		  
		# Write information about the extracted sound to log file
		dog$ = "'intnumber''tab$''prefix$''tab$''searchIntervalLabel$''tab$''labelIntervalName$''tab$''restrictionText$''tab$''extractionTierLabel$''newline$'"
		if (useAddLabel = 1)
			dog$ = "'intnumber''tab$''prefix$''tab$''searchIntervalLabel$''tab$''addLabelIntervalName$''tab$''labelIntervalName$''tab$''restrictionText$''tab$''extractionTierLabel$''newline$'"
		endif
		
		fileappend "'textfilename$'" 'dog$'

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


