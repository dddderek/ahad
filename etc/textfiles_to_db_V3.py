#############################################################################
#
# AHAD note and sources text file parser, logger, cleaner, and inserter
# into a MySQL database.
#
# Derek Carlson, Aug 2016
#
# I am able to run this script and have the text from the note and sources
# text files inserted into two database columns in a given MySQL database.
#
# For a given property,
# one column will contain the text of a note file, if it exists, and a
# sources file, if it exists, and that text will be stripped of whitespace
# at the start and end and also stripped of non-ASCII characters.
#
# A second column will contain the same text, but copied verbatim from the
# text files, with whitespace and non-ASCII chars intact.
#
# This process will be fully logged, so that any questions that may arise
# in the future about the transfer of data from the textfiles to the
# database can be tracked and understood.
#
# A summary file will be created that can be easily examined in Excel.
# It will contain the details for every property for which one or both
# text files were parsed.
#
# A test suite, along with test data, will be runnable at any time in
# the future, in order to verify the operation of this script even when
# the main set of textfiles have been archived.
#
# Functions:
#
#   insert_many_records
#   read_db_config
#   load_propids
#   valid_propid
#   remove_non_ascii
#
#   test_run_all
#   test_file
#       test_files
#       test_dir_struct
#
#   parse_file
#   logit
#   parse_all_files_into_dict
#   parse_one_dir_into_dict
#
# TODOs:
#
#   * finish testing routine
#       - multiple files
#       - note/sources dir struct
#       - DONE: write out results to a text file
#
#  DONE BELOW
#
#   * DONE -- add funky chars tracking
#       - DONE -- list of which files have them
#       - DONE -- a list of all funky chars
#       - DONE -- a dict keyed on funky char, with an array of files that have it
#
#   * DONE -- print out all blank files and funky files at end of log file
#
#   * DONE -- add a copy of the content with funky replaced with [0x ] so
#     can visually inspect... and output this to the log file...
#     then make sure 2 instances of each funky char in note 10049
#
#   * DONE -- content_raw -- add a copy of content unstripped
#
#   * DONE  keep sorted array of propids parsed, so summary file is in order
#
#   * DONE: test SQL insertion of funky chars (in & out of db & verify)
#
#   * DONE add routine to go through dict and create
#       - DONE  summary file (use sorted propids)
#       - DONE calls to actual SQL insert routine
#
#############################################################################

#from __future__ import print_function
import mysql.connector
from mysql.connector import MySQLConnection, Error
from configparser import ConfigParser
from os import listdir
from os.path import isfile, join
import pprint
from sys import exit
import sys
import time
import codecs

#
# CONST
#

#
# 11953_debug into local database
#
if False:
    g_instructions = [
        { 'logdir' : './AHAD_Txt_Files/testing_files/11953_debug/log/',
          'arParseDirs': ['./AHAD_Txt_Files/testing_files/11953_debug/'],
          'updatequery':  "INSERT INTO main(idmain, propid, nsclean, nsraw) VALUES(%s,%s,%s,%s)",
          'dbconfig': 'config-Win10.ini',
        } ]

#
# 10049_debug into local database
#
if False:
    g_instructions = [
        { 'logdir' : './AHAD_Txt_Files/testing_files/10049_debug/log/',
          'arParseDirs': ['./AHAD_Txt_Files/testing_files/10049_debug/'],
          'updatequery':  "INSERT INTO main(idmain, propid, nsclean, nsraw) VALUES(%s,%s,%s,%s)",
          'dbconfig': 'config-Win10.ini',
        } ]

#
# test_struct1 into local database
#
if False:
    g_instructions = [
        { 'logdir' : './AHAD_Txt_Files/testing_files/test_struct1/log/',
          'arParseDirs': ['./AHAD_Txt_Files/testing_files/test_struct1/note/',
                          './AHAD_Txt_Files/testing_files/test_struct1/sources/'],
          'updatequery':  "INSERT INTO main(idmain, propid, nsclean, nsraw) VALUES(%s,%s,%s,%s)",
          'dbconfig': 'config-Win10.ini',
        } ]

#
# test_struct1 into AHAD REMOTE database
#
if False:
    g_instructions = [
        { 'logdir' : './AHAD_Txt_Files/testing_files/test_struct1/log/',
          'arParseDirs': ['./AHAD_Txt_Files/testing_files/test_struct1/note/',
                          './AHAD_Txt_Files/testing_files/test_struct1/sources/'],
          'updatequery':  "INSERT INTO TESTnotesource(id, propid, nscleaned, nsraw) VALUES(%s,%s,%s,%s)",
          'dbconfig': 'config-AHAD.ini',
        } ]

#
# full live run to LOCAL database
#
if False:
    g_instructions = [
        { 'logdir' : './AHAD_Txt_Files/live_runs/',
          'arParseDirs': ['./AHAD_Txt_Files/note/LIVE/',
                          './AHAD_Txt_Files/sources/LIVE/'],
          'updatequery': "INSERT INTO main(idmain, propid, nsclean, nsraw) VALUES(%s,%s,%s,%s)",
          'dbconfig': 'config-Win10.ini',
          } ]

#
# full live run to REMOTE AHAD database
#
if True:
    g_instructions = [
        { 'logdir' : './AHAD_Txt_Files/live_runs/',
          'arParseDirs': ['./AHAD_Txt_Files/note/LIVE/',
                          './AHAD_Txt_Files/sources/LIVE/'],
          'updatequery': "INSERT INTO TESTnotesource(id, propid, nscleaned, nsraw) VALUES(%s,%s,%s,%s)",
          'dbconfig': 'config-AHAD.ini',
          } ]

#
# 10025 debug
#
if False:
    g_instructions = [
        { 'logdir' : './AHAD_Txt_Files/testing_files/10025_debug/',
          'arParseDirs': ['./AHAD_Txt_Files/testing_files/10025_debug/']
        } ]


g_preNoteStr = "<b>Notes<\\b><br>\n"
g_noteSourcesSepStr = "<br>\n"
g_preSourcesStr = "<b>Sources<\\b><br>\n"

LOG_TO_SCREEN = True

MAXFILES_TO_PROCESS = 5  # set to 0 to process all available files

TEXTFILE_DIR = g_instructions[0]['logdir']

LOG_LEVEL = 5
# 1 : Log just results
# 9 : Include low level details of individual file parsing
# 10: Log all, including dicts



#
# GLOBALS
#
g_logfile = open(TEXTFILE_DIR + "AHAD-note-and-sources-parse-log_" + \
				 time.strftime("%Y-%m-%d_%H-%M-%S") +".txt", 'w')

g_summaryfile = open(TEXTFILE_DIR + "AHAD-note-and-sources-parse-summary_" + \
                     time.strftime("%Y-%m-%d_%H-%M-%S") +".txt", 'w')

g_testresultsfile = open(TEXTFILE_DIR + "AHAD-test-results_" + \
                     time.strftime("%Y-%m-%d_%H-%M-%S") +".txt", 'w')

g_lstPropIDs = [] # list of all prop ids from existing "property" table

# Stats trackers
g_numFiles = {'note': 0, 'sources': 0}

g_numBlankCleanedFiles = {'note': 0, 'sources': 0}
g_blankCleanedFilesList = [] # arrays -- ['note'] or ['sources']

g_numBlankRawFiles = {'note': 0, 'sources': 0}
g_blankRawFilesList = [] # arrays -- ['note'] or ['sources']

g_numFileswFunkyChars = {'note': 0, 'sources': 0}
g_funkyCharsFilesList = [] # arrays -- ['note'] or ['sources']
g_strAllFunkyCharsFound = ""

g_dictFunkyCodesToFiles = {} # key is, e.g. [0xc2], value is a file list with commas


def runupdate(query):

    try:
        db_config = read_db_config(g_instructions[0]['dbconfig'])
        conn = MySQLConnection(**db_config)

        cursor = conn.cursor()
        cursor.execute(query)
        conn.commit()

    except Error as error:
        print(error)

    finally:
        cursor.close()
        conn.close()


def runquery(query):

    try:
        db_config = read_db_config(g_instructions[0]['dbconfig'])
        conn = MySQLConnection(**db_config)

        cursor = conn.cursor()
        cursor.execute(query)
        rows = cursor.fetchall()

    except Error as error:
        print(error)

    finally:
        cursor.close()
        conn.close()
        return rows


def insert_many_records(query, recs):

    #print "RECS:"
    #strinspect(recs[0][3], True)
    try:
        db_config = read_db_config(g_instructions[0]['dbconfig'])
        conn = MySQLConnection(**db_config)
 
        cursor = conn.cursor()
        cursor.executemany(query, recs)
 
        conn.commit()
    except Error as e:
        print('Error:', e)
 
    finally:
        cursor.close()
        conn.close()


def read_db_config(filename='config.ini', section='mysql'):
    """ Read database configuration file and return a dictionary object
    :param filename: name of the configuration file
    :param section: section of database configuration
    :return: a dictionary of database parameters
    """
    # create parser and read ini configuration file
    parser = ConfigParser()
    parser.read(filename)
 
    # get section, default to mysql
    db = {}
    if parser.has_section(section):
        items = parser.items(section)
        for item in items:
            db[item[0]] = item[1]
    else:
        raise Exception('{0} not found in the {1} file'.format(section, filename))
 
    return db


def load_propids():
    """ load propids into global array"""
    with open("./AHAD_Txt_Files/propids_2016_08_08.txt", 'r') as propidsfile:
        for line in propidsfile:
            g_lstPropIDs.append(line.strip())

    
def valid_propid(propid):
  return (propid in g_lstPropIDs)


def fileinspect(pnf, bBinary=False):
    with open(pnf, "r") as infile:
        data = infile.read()

    strinspect(data, bBinary)


def strinspect(s, bBinary=False):
    chars_per_line = 16
    i = 0
    lstrs = []
    lcodes = []
    ts = ""
    tcs = ""
    for c in s:
        if ord(c) > 128:
            ts = ts + "?"
        elif c == "\n":
            ts = ts + c.replace("\n", "\\n")
        elif c == "\r":
            ts = ts + c.replace("\r", "\\r")
        else:
            ts = ts + c

        if bBinary:
            tcs = tcs + "%6s" % ("[" + str(hex(ord(c))) + "]")
        else:
            tcs = tcs + "%6s" % ("[" + str(ord(c)) + "]")

        if i == (chars_per_line - 1):
            lstrs.append(ts)
            lcodes.append(tcs)
            ts = ""
            tcs = ""
            i = 0
            continue
        i += 1

    # append whatever was left in the buffer before we hit max char count
    lstrs.append(ts)
    lcodes.append(tcs)

    for ss in lstrs:
        chold = ""
        for c in ss:
            if c == "\\":
                chold = "\\"
            elif c == "n" or c == "r":
                if chold == "\\":
                    chold = ""
                    sys.stdout.write("   {:3}".format("\\" + c))
                else:
                    sys.stdout.write("   {:3}".format(c))
            else:
                if chold == "\\": # prev \ char not printed yet, nor cleared
                    sys.stdout.write("   {:3}".format("\\"))
                    chold = ""
                sys.stdout.write("   {:3}".format(c))


        print("")
        print(lcodes.pop(0))


def remove_non_ascii(text, fname):
    #return ''.join([i if ord(i) < 128 else "[" + str(hex(ord(i))) + "]" for i in text])
    #return ''.join([i if ord(i) < 128 else "" for i in text])
    global g_strAllFunkyCharsFound

    out_clean = ''
    out_w_codes = ''
    codes = {}
    str_codes = ''

    # track dict of codes and # times, then
    # at the end, [0xc0]: fname-2


    for c in text:
        if ord(c) < 128:
            out_clean = out_clean + c
            out_w_codes = out_w_codes + c
        else:
            scode = "[" + str(hex(ord(c))) + "]"

            # Only add code if not already in list
            if not scode in g_strAllFunkyCharsFound:
                g_strAllFunkyCharsFound = g_strAllFunkyCharsFound + scode

            out_w_codes = out_w_codes + scode
            if not (scode in codes):
                if len(str_codes) > 0:
                    str_codes = str_codes + scode
                else:
                    str_codes = scode
                codes[scode] = 1
            else:
                codes[scode] = codes[scode] + 1

    for code in codes:
        if not code in g_dictFunkyCodesToFiles:
            g_dictFunkyCodesToFiles[code] = fname + "-" + str(codes[code])
        else:
            g_dictFunkyCodesToFiles[code] = g_dictFunkyCodesToFiles[code] + \
                                             ", " + fname + "-" + str(codes[code])

    return { "clean": out_clean,
             "w_codes": out_w_codes,
             "map_codes_and_count": codes,
             "str_codes": str_codes}


#-----------------------------------------------------------------------------
#
# Run all tests:
#
#   1. Define and then run all single file tests
#   2. Run multi-file tests
#   3. Run full dir (with note and sources subdirs) test
#
# TODO:
#   - Log results to a test-results.txt logfile
#   - Add multi-file tests
#   - Add full dir tests
#
#-----------------------------------------------------------------------------
def test_run_all():

    testDir = "./AHAD_Txt_Files/testing_files/"

    g_testresultsfile.write("Script with test_run_all() that is generating this file: " + sys.argv[0] + "\n")
    g_testresultsfile.write("Test started at: " + time.strftime("%Y-%m-%d_%H-%M-%S") + "\n")
    g_testresultsfile.write("Test directory: " + testDir + "\n")

    ansDict = {}
    arTests = []

    #
    # Define all single file tests
    #

    if True:  # just for purpose of PyCharm section wrapping
        ##### 1.	Text file with valid propid (either note or source)
        content = "Dwelling & garage, 40x42; owner Knapp, Caltech professor\nSECOND LINE"
        arTests.append(
        ["ok file", "16440_note_01.txt",
          { 'error': False, 'blank_cleaned': False, 'type': 'note', 'content': content }
        ]
        )

        ##### 2.	Text file with propid that doesn't exist in altaheri "property" table
        arTests.append(
        [ "invalid propid from textfile name", "16440432_note_01_invalid_propid.txt",
          { 'error': True, 'blank_cleaned': False, 'type': '', 'content': '' }
        ]
        )

        ##### 3.	Text file not labeled [\d+]_[note|source]_
        arTests.append(
        ["invalid note or source tag from textfile name", "16440_unknown_01.txt",
          { 'error': True, 'blank_cleaned': False, 'type': '', 'content': '' }
        ]
        )

        ##### 4.	Property with just a note text file and no source text file
        # Covered in test 1 above

        ##### 5.	Property with just a source text file and no note text file
        content = "Builder & Contractor (journal) 8/7/31, p. 79\nBuilder & Contractor (journal) 8/28/31, p. 66"
        arTests.append(
        ["ok file", "13715_sources_01.txt",
          { 'error': False, 'blank_cleaned': False, 'type': 'sources', 'content': content }
        ]
        )

        ##### 6.	Property witha text file that contains that weird character between "an  arched"
        content = "SHPO Description: This single story L-shaped residence has a low hip roof of tile with an offset front gable. The porch is located in the inner portion of the L and has an arched opening with a portion containing a low stucco wall and wood supports. There is a wrought iron railing across the arched opening. A tapered stucco chimney is located on the east side. Windows are multi-paned casement or fixed with wood moldings. Under a portion of the eaves, rafters are exposed. The house is covered with stucco.\n\nSHPO Significance: This house was built in 1927 for Henry E. and Sandie P. Bender. Mr. Bender was a carpenter and may have built this house.\nThe house is a good example of the Spanish Colonial Revival style but is not distinctive enough to qualify for the National Register either individually or as part of a district."
        arTests.append(
        ["weird circle character (as seen in Word) between 'an ' and 'arched'", "10049_note_01.txt",
          { 'error': False, 'blank_cleaned': False, 'type': 'note', 'content': content }
        ]
        )


        ##### 9.	Text file with no text, just a newline
        content = ""
        arTests.append(
        ["blank file to ignore: Text file with no text, just a newline", "16440_note_just_1_newline.txt",
          { 'error': False, 'blank_cleaned': True, 'type': 'note', 'content': content }
        ]
        )

        ##### 9b.	Text file with no text, no newline, nothing.  Empty file.
        content = ""
        arTests.append(
        ["blank file to ignore: Text file with no text, no newline, nothing.  Empty file.", "16440_note_empty_file.txt",
          { 'error': False, 'blank_cleaned': True, 'type': 'note', 'content': content }
        ]
        )

        ##### 9c.	Text file with no text, no newline, nothing.  Empty file.
        content = ""
        arTests.append(
        ["blank file to ignore: Text file with no text, no newline, nothing.  Empty file.", "10008_note_01.txt",
          { 'error': False, 'blank_cleaned': True, 'type': 'note', 'content': content }
        ]
        )


        ##### 10.	Text file with no text, just multiple newlines
        content = ""
        arTests.append(
        ["blank file to ignore: Text file with no text, just multiple newlines", "16440_note_blank_multiple_newlines.txt",
          { 'error': False, 'blank_cleaned': True, 'type': 'note', 'content': content }
        ]
        )

        ##### 11.	Text file with no text, just whitespace and no newlines
        content = ""
        arTests.append(
        ["blank file to ignore: Text file with no text, just whitespace and no newlines", "16440_note_whitespace_no_newlines.txt",
          { 'error': False, 'blank_cleaned': True, 'type': 'note', 'content': content }
        ]
        )

        ##### 12.	Text file with text with no newline at end
        content = "9 rms., frame & stucco, tile roof, ornamental iron, garage"
        arTests.append(
        ["ok file: Text file with text with no newline at end", "11565_note_01.txt",
          { 'error': False, 'blank_cleaned': False, 'type': 'note', 'content': content }
        ]
        )

        ##### 13.	Text file with text with one newline at end
        content = "Orig. survey notes: 1 of 7 dwellings; blt. together w/198, 214, 234, 258 & 266 W. Altadena\n\nSHPO Description: This 1 1/2 story residence has a high pitched side facing gable roof with three front overlapping gable roofs. Most of the gable ends are clipped. The entrance has a high pitched gable over it and the porch is open with a low stucco wall. There are French doors on the east side of the facade. All openings have wood frames and moldings. Siding is stucco. On the west side is a tall exterior stucco chimney.\nSHPO Significance: This house was built in 1924 for Arthur L. Todd. No listing was found for Mr. Todd in the City Directory.\nThe house is not architecturally distinctive enough to qualify for listing on the National Register."
        arTests.append(
        ["ok file: Text file with text with one newline at end", "10562_note_01.txt",
          { 'error': False, 'blank_cleaned': False, 'type': 'note', 'content': content }
        ]
        )

        ##### 14.	Text file with text with multiple newlines at end
        content = "Orig. survey notes: 1930: add to dwelling & garage; 1935: add to frame dwelling, 24x16, shingle roof\n\nSHPO Description: This large two-story residence has a medium gable roof. Attached to the west side is an addition on the second story with a carport underneath. The second story has been covered with wood shingles. The rest of the house is covered with stucco. Some windows have wood frames and others are sliding aluminum frame. It is difficult to tell what is original to the house since it appears to have been quite altered. A second house is located in front of the main house. This small house has a high pitched gable roof with a more recent hip roofed cupola added. Siding is stucco and windows are wood frame with multi-panes. The small front porch is attached with a gable roof. The arch that characterizes Mission Revival can be found in the door entrance, the front window and the driveway.\nSHPO Significance: This house was built in 1923 for William Lowman, a salesman. It is not certain which house was built first. Neither house is architecturally distinctive enough to qualify for the National Register."
        arTests.append(
        ["ok file: Text file with text with multiple newlines at end", "10063_note_01.txt",
          { 'error': False, 'blank_cleaned': False, 'type': 'note', 'content': content }
        ]
        )

        ##### 15.	Text file with text with multiple newlines at end that contain weird circle character
        content = "Original prop. built by Prof. Lowe as residence for son; donated by W.A. Scripps & named for Mrs. Scripps;\n1914: annex, Swiss-style, 2-story, 32x50, enclosed bridge to main structure, donated along w/8-acre tract of land by W.A. Scripps; 1914: small hospital donated by Mrs. A.F. Gartz, named 'Gloria Cottage' for her daughter;\n1920: plans prepared for 2-story structure; 1922: 2-story lounge, dining room, kitchen & sleeping quarters;\n1926: 2-story addition, hollow tile, L-shaped, 115 x 100, stucco; 1926: contract for E wing & helpers' quarters of existing bldg.;\n1932: infirmary bldg., 1-story, pt. basement, 16 rms., masonry, asbestos shingle roof; 1932: add to infirmary, 37x106;\n1941: alterations to dormitory moved to site; 1943: new comp. roof; 1956: addl. wing; 1963: new hospital & community bldg., including visitor's lounge & auditorium/chapel."
        arTests.append(
        ["ok file: Text file with text with multiple newlines at end that contain weird circle character", "11953_note_01.txt",
          { 'error': False, 'blank_cleaned': False, 'type': 'note', 'content': content }
        ]
        )

        ##### 16.	Text file with multiple paragraphs
        # Already covered in #13, 14, 15

        ##### 8.	Empty text file
        arTests.append(
        [ "blank file", "16440_note_01_blank_file.txt",
          { 'error': False, 'blank_cleaned': True, 'type': 'note', 'content': '' }
        ]
        )


    #
    # Now run all single-file tests
    #
    bPassedTests = True
    
    for test_entry in arTests:
        s = "Running Test: " + test_entry[1] + " -- " + test_entry[0]
        g_testresultsfile.write(s + "\n")
        print(s)

        testOutDict = test_file(testDir, test_entry[1], test_entry[2])

        bPassedTests = testOutDict['passed'] and bPassedTests

        pprint.pprint(testOutDict['details'])

        for s in testOutDict['details']:
            g_testresultsfile.write(s + "\n")

        if testOutDict['passed']:
            s = "***PASSED***"
            g_testresultsfile.write(s + "\n")
            print(s)
        else:
            s = "            ------------ FAILED -------------- "
            g_testresultsfile.write(s + "\n")
            print(s)

    s = "\n\nSingle file tests all done!  Passed: " + str(bPassedTests) + "\n\n"
    g_testresultsfile.write(s + "\n")
    print(s)

    g_testresultsfile.write("Test completed at: " + time.strftime("%Y-%m-%d_%H-%M-%S") + "\n")
    g_testresultsfile.close()


    #
    # TODO: Multi-file tests or dir tests
    #
    
    ##### 7.	Property with both note and source text files
    #
    # 13715|BP #4923: garage, 16x16, $150; BP #5131: dwelling, 24x32, $1,200|Builder & Contractor (journal) 8/7/31, p. 79\nBuilder & Contractor (journal) 8/28/31, p. 66
    
    # Parse file, get outDict['content'], store as note
    # Pass in outDict['content'] (with note already in it), parse file, add source to it
    # May need to add in an arg for a fullDict or something that parse_file adds to with each parse
    # Or can do that after file is parsed.
    #
    # fullDict = {}
    #
    # outDict = parse_file
    #
    # Below needs to be its own routine to add a content to an existing dict, making sure
    #   that the "note" or "source" is not already filled in 
    
    #
    # merge_in_result(outDict, fullDict)
    #	See if fullDict has propid yet.  Log yes or no.
    #   If not, add it with note|source and content
    #   If so, check that note|source not already filled in
    #	  If not, add it in
    #     If so, return error condition
    #

    # ansDict = { '13715' : {'note': 'BP #4923: garage, 16x16, $150; BP #5131: dwelling, 24x32, $1,200', 'sources': 'Builder & Contractor (journal) 8/7/31, p. 79\nBuilder & Contractor (journal) 8/28/31, p. 66'} };
    
    # ansDict should match fullDict
    # or could do:
    #

    # arStrAns = ['13715|BP #4923: garage, 16x16, $150; BP #5131: dwelling, 24x32, $1,200|Builder & Contractor (journal) 8/7/31, p. 79\nBuilder & Contractor (journal) 8/28/31, p. 66'];

    # then run dict_to_flat_string(fullDict) to get a string to compare and skips the struct comparison
    
    # testOutDict = test_files(testDir, ["13715_note_01.txt","13715_sources_01.txt"], ansDict)

    # Just run one file, and get text output as per dump to Excel
    # Run two files (note & source) in succession, and get the total
    #	text output for both... e.g. 16440|note stuff|source stuff

  
#-----------------------------------------------------------------------------
#
# Test one file:
#   - parse file
#   - compare output of parse to the expected result
#       - error status, blank or not, type, and content
#
#   - Returns test results dict {
#       passed: true or false
#       details: array of expected result, received result
#       parseResultsDict: parse result dict (error, blank, type, content)
#     }
#
#-----------------------------------------------------------------------------
def test_file(path, tfile, ansDict):
  
  testResultsDict = {}
  
  parseResultsDict = parse_file(path, tfile)
  
  if (  (parseResultsDict['error'] == ansDict['error']) and
	(parseResultsDict['blank_cleaned'] == ansDict['blank_cleaned']) and
	(parseResultsDict['type'] == ansDict['type']) and
	(parseResultsDict['content_cleaned'] == ansDict['content']) ):
    testResultsDict['passed'] = True
  else:
    testResultsDict['passed'] = False

  arDetails = [ "   Expected Error Status: " + str(ansDict['error']), 
		"   Got Error Status     : " + str(parseResultsDict['error']),
		"   Error Desc           : " + str(parseResultsDict['error_desc']),
		"   Expected Blank Status: " + str(ansDict['blank_cleaned']),
		"   Got Blank Status     : " + str(parseResultsDict['blank_cleaned']),
		"   Expected File Type   : [" + str(ansDict['type']) + "]",
		"   Got File type        : [" + str(parseResultsDict['type']) + "]",
		"   Expected Content     : [" + str(ansDict['content']) + "]",
		"   Received Content     : [" + str(parseResultsDict['content_cleaned']) + "]" ]
  
  testResultsDict['details'] = arDetails
  testResultsDict['parseResultsDict'] = parseResultsDict

  return testResultsDict

 
#-----------------------------------------------------------------------------
#
# Parse a note or source file
#
# Error out if:
#
#	a) file doesn't exist or 
#	b) invalid proprid
#       c) not specified in filename as 'note' or 'source'
#
# Otherwise valid file:
#
# If valid, then either:
#
#	a) blank file or
#	b) nonblank file
#
# Returns: {
#       propid
#       error: T/F
#       error_desc
#            "File does not exist."
#            "Property ID does not exist in the 'property' table."
#            "Type is not 'note' or 'source'"
#       blank: T/F
#       content
#       type
# }
#
#-----------------------------------------------------------------------------
def parse_file(path, tfile):
  
    outDict = { 'propid': '', 'error': False, 'error_desc': '',
                'blank_cleaned': False, 'blank_raw': False, 
                'type': '', 
                'content_cleaned': '', 'content_raw': '', 'content_w_codes': '',
                'map_codes_and_count': {}, 'str_codes': '' }

    pnf = path + tfile
  
    if not isfile(pnf):
        outDict['error'] = True
        outDict['error_desc'] = "File [" + pnf + "] does not exist."
        return outDict
    
    propid = tfile.split("_")[0]
    typens = tfile.split("_")[1]

    if not valid_propid(propid):
        outDict['error'] = True
        outDict['error_desc'] = "Property ID [" + propid +\
            "] does not exist in the 'property' table."
        return outDict

    outDict['propid'] = propid

    if (typens != "note" and typens != "sources"):
        outDict['error'] = True
        outDict['error_desc'] = "Type [" + typens +\
            "] is not 'note' or 'source' (second part of filename is the type, after the first underscore)."
        return outDict
  
    with open (pnf) as sourcefile:
        content = sourcefile.read()
    
    outDict['content_raw'] = content
    #print("CONTENT READ IN FROM FILE into VAR:")
    #strinspect(content, True)

    if len(content) == 0:
        outDict['blank_raw'] = True
    
        
    # Get rid of weird unicode characters
    # This had to go before the .strip(), because 11953 had 4 \n's at the
    # and of the file, and then [0xc2][0xa0] at the very end, so the \n's
    # got left when this was after the .strip() below.

    d_clean_results = remove_non_ascii(content, tfile)
    content = d_clean_results["clean"]

    # Strip whitespace from start and end of file
    content = content.strip()

    # Turn \r\n to \n (e.g. 13715_sources_01.txt)
    content = content.replace ("\r\n", "\n")


    outDict['error'] = False
    outDict['type'] = typens
  
    if len(content) == 0:
        outDict['blank_cleaned'] = True
    else:
        outDict['blank_cleaned'] = False
        outDict['content_cleaned'] = content
        outDict['content_w_codes'] = d_clean_results["w_codes"]
        outDict['map_codes_and_count'] = d_clean_results["map_codes_and_count"]
        outDict['str_codes'] = d_clean_results["str_codes"]

    return outDict


def logit(s, printalso):
  g_logfile.write(time.strftime("%Y-%m-%d_%H-%M-%S") + "\t| " + s + "\n")
  if printalso:
    print s


#-----------------------------------------------------------------------------
# V2: Routine that actually parses all text files note and sources,
#     logs all info to a log file,
#     writes out a summary file
#     returns a dict that another routine will use to run SQL
#-----------------------------------------------------------------------------
def parse_all_files_into_dict():

    # g_numFiles['note'] = 0
    # g_numFiles['sources'] = 0
    #
    # g_numBlankCleanedFiles['note'] = 0
    # g_numBlankCleanedFiles['sources'] = 0

    logit("Script creating this file: " + sys.argv[0], LOG_TO_SCREEN)
    logit("Starting processing of note and sources text files...", LOG_TO_SCREEN)

    dictNoteSource = {}

    for parsedir in g_instructions[0]['arParseDirs']:
        logit("", LOG_TO_SCREEN)
        logit("", LOG_TO_SCREEN)
        logit("Parsing directory: " + parsedir, LOG_TO_SCREEN)
        dictNoteSource = parse_one_dir_into_dict(parsedir, dictNoteSource)

    # Run a test dir for the _01 a _02 files and the exception it throws
    s = "********************************************************"
    logit(s, LOG_TO_SCREEN)


    s = "Num note files processed|" + str(g_numFiles['note'])
    logit(s, LOG_TO_SCREEN)

    s = "Num sources files processed|" + str(g_numFiles['sources'])
    logit(s, LOG_TO_SCREEN)
    s = ""
    logit(s, LOG_TO_SCREEN)
    logit(s, LOG_TO_SCREEN)

    s = "Num raw BLANK note files processed|" + str(g_numBlankRawFiles['note'])
    logit(s, LOG_TO_SCREEN)

    s = "Num raw BLANK sources files processed|" + str(g_numBlankRawFiles['sources'])
    logit(s, LOG_TO_SCREEN)

    s = "Num cleaned BLANK note files processed|" + str(g_numBlankCleanedFiles['note'])
    logit(s, LOG_TO_SCREEN)

    s = "Num cleaned BLANK sources files processed|" + str(g_numBlankCleanedFiles['sources'])
    logit(s, LOG_TO_SCREEN)
    s = ""
    logit(s, LOG_TO_SCREEN)
    s = "Cleaned Blank Files List"
    logit(s, LOG_TO_SCREEN)
    for bf in g_blankCleanedFilesList:
        logit("BF|" + bf, LOG_TO_SCREEN)

    s = ""
    logit(s, LOG_TO_SCREEN)
    logit(s, LOG_TO_SCREEN)

    s = "Num note files with FUNKY chars|" + str(g_numFileswFunkyChars['note'])
    logit(s, LOG_TO_SCREEN)
    s = "Num sources files with FUNKY chars|" + str(g_numFileswFunkyChars['sources'])
    logit(s, LOG_TO_SCREEN)
    s = ""
    logit(s, LOG_TO_SCREEN)
    s = "Files With Funky Chars List"
    logit(s, LOG_TO_SCREEN)
    for ff in g_funkyCharsFilesList:
        logit("FF|" + ff, LOG_TO_SCREEN)


    s = ""
    logit(s, LOG_TO_SCREEN)
    s = "List of FUNKY codes with files that contain those codes"
    logit(s, LOG_TO_SCREEN)
    for k in g_dictFunkyCodesToFiles:
        s = k + "|" + g_dictFunkyCodesToFiles[k]
        logit(s, LOG_TO_SCREEN)

    s = "--------"
    logit(s, LOG_TO_SCREEN)

    if LOG_LEVEL > 9:
        s = "Final resulting dict|" + pprint.pformat(dictNoteSource)
        logit(s, LOG_TO_SCREEN)

    logit("Completed processing of note and sources text files...", LOG_TO_SCREEN)
    g_logfile.close()

    return dictNoteSource


#-----------------------------------------------------------------------------
#
# Parses all files in a single dir, adding all the parsed info to
# dictNoteSource.
#
# Inputs:
#   d: dir that contains files to parse (does not do subdirs)
#   dictNoteSource: the dict to add any new parse results to
#
# Returns:
#   dictNoteSource: With the newly parsed data inserted and/or added
#
# TODO:
#   Make sure each if/else path has a test
#
#-----------------------------------------------------------------------------
def parse_one_dir_into_dict(d, dictNoteSource):

    files = [f for f in listdir(d) if isfile(join(d, f))]

    iFileCount = 0

    for lfile in files:

        s = "-------------------------------------------------------------"
        logit(s, LOG_TO_SCREEN)

        s = "Parsing file| " + lfile
        logit(s, LOG_TO_SCREEN)

        dictOut = parse_file(d, lfile)  # PARSE THE FILE HERE

        if LOG_LEVEL > 8:
            s = "PropID| " + dictOut['propid']
            logit(s, LOG_TO_SCREEN)

        ftype = dictOut['type']

        if LOG_LEVEL > 8:
            s = "Type  | " + dictOut['type']
            logit(s, LOG_TO_SCREEN)

        g_numFiles[ftype] = g_numFiles[ftype] + 1

        #
        # Funky chars tracking
        #
        if len(dictOut['str_codes']) > 0:
            g_numFileswFunkyChars[ftype] = g_numFileswFunkyChars[ftype] + 1
            g_funkyCharsFilesList.append(lfile)
            # Where maintain unique list of all funky chars, as well as
            # which chars (key) are associated with what files (values)
            s = "Funky chars | " + dictOut['str_codes']
            logit(s, LOG_TO_SCREEN)

        if LOG_LEVEL > 8:
            s = "In dictNoteSource  | " + str(dictOut['propid'] in dictNoteSource)
            logit(s, LOG_TO_SCREEN)

        if LOG_LEVEL > 9:
            s = "Result from parse_file | " + pprint.pformat(dictOut)
            logit(s, LOG_TO_SCREEN)

        # Add all files parsed at this point, whether blank or not... let
        # summary generation routine throw out blanks if it needs to

        if (dictOut['blank_cleaned'] == True):
            g_numBlankCleanedFiles[ftype] = g_numBlankCleanedFiles[ftype] + 1
            g_blankCleanedFilesList.append(lfile)
            s = "Note: cleaned content was blank."
            logit(s, LOG_TO_SCREEN)

        # Maybe add raw cleaned logging here
        if (dictOut['blank_raw'] == True):
            g_numBlankRawFiles[ftype] = g_numBlankRawFiles[ftype] + 1
            g_blankRawFilesList.append(lfile)
            s = "Note: raw content was blank."
            logit(s, LOG_TO_SCREEN)

        if dictOut['propid'] in dictNoteSource:
            # propid is in dict already
            if dictOut['type'] in dictNoteSource[dictOut['propid']]:
                # Error out if we find _01 and _02, etc. files
                s = 'Found 2 files for same property and same type ' +\
                    '(note or sources)... e.g. 10006_note_01.txt and ' +\
                    '10006_note_02.txt.  This is not supported.  The ' +\
                    'second file that caused this error is:' + d + lfile
                logit(s, LOG_TO_SCREEN)
                raise Exception(s)
            else: # 'note' or 'sources' key not in existing dict at propid
                #  propid key exists, and non-blank content,
                #  so we can add the new member to it directly
                dictNoteSource[dictOut['propid']][dictOut['type']] = dictOut
                s = "CONTENT ADD PROPID EXISTS: propid already exists, but of different type, so adding " + \
                    dictOut['type'] + ": " + dictOut['propid'] + "|" +  dictOut['content_cleaned']
                logit(s, LOG_TO_SCREEN)
                if len(dictOut['str_codes']) > 0:
                    s = "        CONTENT With funky codes explicit |" + dictOut['content_w_codes']
                    logit(s, LOG_TO_SCREEN)
        else:
            # propid key doesn't exist, so we add it first here
            dictNoteSource[dictOut['propid']] = { dictOut['type']: dictOut }
            s = "CONTENT ADD NEW: propid key is new, so adding: " + dictOut['propid'] + "|" + dictOut['content_cleaned']
            logit(s, LOG_TO_SCREEN)
            if len(dictOut['str_codes']) > 0:
                s = "        CONTENT With funky codes explicit |" + dictOut['content_w_codes']
                logit(s, LOG_TO_SCREEN)

        iFileCount = iFileCount + 1
        if MAXFILES_TO_PROCESS > 0:
            if iFileCount == MAXFILES_TO_PROCESS:
                break

    if LOG_LEVEL > 9:
        s = "Updated dictNoteSource | " + pprint.pformat(dictNoteSource)
        logit(s, LOG_TO_SCREEN)

    return dictNoteSource


#----------------------------------------------------------------------------
# CSV Column Layout
#   Time start
#   Num propids populated
#   Num note files processed
#   Num sources files processed
#   Funky chars list
#
# propid,
#   note_exists T/F, note_raw_blank T/F, note_cleaned_blank T/F,
#   note_funky_chars T/F, note_funky_chars_list, note_content_w_codes,
#   note_content_cleaned  (raw not to text summary file, but held in data
#   struct for direct passing to SQL insert statement)
#
#   Same columns for sources
#
# Ultimately, the SQL will merge the note and sources text into one column
#   cleaned and into another column raw (an no columns with codes explicit)
#
#   No insert if propid has only a note or sources field, and raw is blank
#   No insert if propid has both blank raw note and sources
#
# dictNoteSource { propid: {note: dictOut, sources: dictOut } }
#
#----------------------------------------------------------------------------
def process_full_note_sources_dict(dictNoteSource):
    sep = "|"

    g_summaryfile.write("Script generating this file: " + sys.argv[0] + "\n")
    g_summaryfile.write("Parse started at ||" + time.strftime("%Y-%m-%d_%H-%M-%S") + "\n")

    s = "propid,note_content_cleaned," + \
        "note_raw_blank,note_cleaned_blank," + \
        "note_funky_chars,note_funky_chars_list,note_content_w_codes," + \
        "sources_content_cleaned,sources_raw_blank,sources_cleaned_blank," + \
        "sources_funky_chars,sources_funky_chars_list,sources_content_w_codes," + \
        "cleaned_for_db\n"
    s = s.replace(",", sep)
    g_summaryfile.write(s)

    iCount = 1
    lrecs = []

    for propid in sorted(dictNoteSource):
        s = str(propid) + sep
        sCombinedClean = ""
        sCombinedCleanForDB = ""
        sCombinedRawForDB = ""

        # Write out all the other fields
        if 'note' in dictNoteSource[propid] and (not dictNoteSource[propid]['note']['blank_raw']):
            s = s + dictNoteSource[propid]['note']['content_cleaned'].replace("\n", "\\n") + sep
            #s = s + str('note' in dictNoteSource[propid]) + sep # note_exists
            s = s + str(dictNoteSource[propid]['note']['blank_raw']) + sep # note_raw_blank
            s = s + str(dictNoteSource[propid]['note']['blank_cleaned']) + sep # note_cleaned_blank
            s = s + str(len(dictNoteSource[propid]['note']['str_codes']) > 0) + sep # note_funky_chars
            s = s + dictNoteSource[propid]['note']['str_codes'] + sep # note_funky_chars_list
            s = s + dictNoteSource[propid]['note']['content_w_codes'].replace("\n", "\\n") + sep # note_content_w_codes
#            s = s + dictNoteSource[propid]['note']['content_raw'].replace("\n", "\\n") + sep # note_content_w_codes

            sCombinedClean = g_preNoteStr.replace("\n", "\\n") + \
                             dictNoteSource[propid]['note']['content_cleaned'].replace("\n", "\\n")

            sCombinedCleanForDB = g_preNoteStr + \
                             dictNoteSource[propid]['note']['content_cleaned']
            sCombinedRawForDB = g_preNoteStr + \
                           dictNoteSource[propid]['note']['content_raw']

        else:
            s = s + "||||||"

        if 'sources' in dictNoteSource[propid] and (not dictNoteSource[propid]['sources']['blank_raw']):
            s = s + dictNoteSource[propid]['sources']['content_cleaned'].replace("\n", "\\n") + sep
            #s = s + str('sources' in dictNoteSource[propid]) + sep # note_exists
            s = s + str(dictNoteSource[propid]['sources']['blank_raw']) + sep # note_raw_blank
            s = s + str(dictNoteSource[propid]['sources']['blank_cleaned']) + sep # note_cleaned_blank
            s = s + str(len(dictNoteSource[propid]['sources']['str_codes']) > 0) + sep # note_funky_chars
            s = s + dictNoteSource[propid]['sources']['str_codes'] + sep # note_funky_chars_list
            s = s + dictNoteSource[propid]['sources']['content_w_codes'].replace("\n", "\\n") + sep  # note_content_w_codes
#            s = s + dictNoteSource[propid]['sources']['content_raw'].replace("\n", "\\n") + sep  # note_content_w_codes

            sCombinedClean = sCombinedClean + \
                             (g_noteSourcesSepStr.replace("\n", "\\n") if (len(sCombinedClean) > 0) else "") + \
                g_preSourcesStr.replace("\n", "\\n") + \
                dictNoteSource[propid]['sources']['content_cleaned'].replace("\n", "\\n")

            sCombinedCleanForDB = sCombinedCleanForDB + \
                             (g_noteSourcesSepStr if (len(sCombinedCleanForDB) > 0) else "") + \
                g_preSourcesStr + dictNoteSource[propid]['sources']['content_cleaned']

            sCombinedRawForDB = sCombinedRawForDB + \
                             (g_noteSourcesSepStr if (len(sCombinedRawForDB) > 0) else "") + \
                g_preSourcesStr + dictNoteSource[propid]['sources']['content_raw']

        else:
            s = s + "||||||"

        lrecs.append((str(iCount), propid, sCombinedCleanForDB, sCombinedRawForDB))

        # insert_many_records(g_instructions[0]['updatequery'], recs)  # keep here if insert one at a time

        s = s + sCombinedClean + sep
        #s = s + sCombinedRaw
        s = s + "\n"
        g_summaryfile.write(s)

        iCount = iCount + 1

    insert_many_records(g_instructions[0]['updatequery'], lrecs)

    g_summaryfile.write("\n\n")
    g_summaryfile.write("Total Prop IDs to be updated ||" + str(len(dictNoteSource)) + "\n")
    g_summaryfile.write("# note files parsed ||" + str(g_numFiles['note']) + "\n")
    g_summaryfile.write("# sources files parsed ||" + str(g_numFiles['sources']) + "\n")
    g_summaryfile.write("Non-printing chars found ||" + g_strAllFunkyCharsFound + "\n")

    g_summaryfile.write("\n")
    g_summaryfile.write("# note files with blank raw data ||" + \
                        str(g_numBlankRawFiles['note']) + "\n")
    g_summaryfile.write("# note files with blank cleaned data ||" + \
                        str(g_numBlankCleanedFiles['note']) + "\n")
    g_summaryfile.write("# note files with non-printing chars ||" + \
                        str(g_numFileswFunkyChars['note']) + "\n")

    g_summaryfile.write("\n")
    g_summaryfile.write("# sources files with blank raw data ||" + \
                        str(g_numBlankRawFiles['sources']) + "\n")
    g_summaryfile.write("# sources files with blank cleaned data ||" + \
                        str(g_numBlankCleanedFiles['sources']) + "\n")
    g_summaryfile.write("# sources files with non-printing chars ||" + \
                        str(g_numFileswFunkyChars['sources']) + "\n")

    g_summaryfile.write("\n\n")
    g_summaryfile.write("Parse completed at ||" + time.strftime("%Y-%m-%d_%H-%M-%S") + "\n")
    g_summaryfile.close()

#
#
# Main
#
#
if __name__ == '__main__':

    if True:
        load_propids()
        dictNoteSource = parse_all_files_into_dict()
        process_full_note_sources_dict(dictNoteSource)


    if False:
        print("Inspect copy/paste directly from MySQL Workbench")
        fileinspect(r"C:\Users\derek\CCC\Clients\AHAD\NS_Shared\python\textfiles_to_db\AHAD_Txt_Files\testing_files\non-ASCII_chars\10049_copy_unquoted_paste_from_MySQL_Workbench_manually.txt", True)

    if False:
        fileinspect(r"C:\Users\derek\CCC\Clients\AHAD\NS_Shared\python\textfiles_to_db\AHAD_Txt_Files\testing_files\test_struct1\note\10049_note_01.txt", True)


    if False:
        rows = runquery("SELECT nsraw FROM main WHERE propid='10049'")
        sout = rows[0][0]

        #with codecs.open(r"C:\Users\derek\CCC\Clients\AHAD\NS_Shared\python\textfiles_to_db\AHAD_Txt_Files\testing_files\non-ASCII_chars\10049rawFromDB.txt", "w",encoding="UTF-8") as outfile:
        #    outfile.write(sout)

        #print "Inspect 10049 raw:"
        #strinspect(sout, True)

        print "Inspect 10049 raw skipping first 17 chars:"
        strinspect(sout[17:], True)


    if False:
        s = "A\nB"
        print "Inspect S:"
        strinspect(s)
        runupdate("UPDATE main SET nsclean='" + s + "' WHERE propid=10000")
        rows = runquery("SELECT nsclean FROM main WHERE propid='10000'")
        sout = rows[0][0]
        print "Inspect SOut:"
        strinspect(sout)

    if False:
        strinspect("A\rB")
        print "\n"
        strinspect("The")
        print "\n"
        strinspect("One\nTwo\nThree")
        print "\n"
        strinspect("The quick brown fox jumped over the big brown bear.  Yeah!")
        print "\n"

    if False:
        runupdate("UPDATE TESTnotesource SET nscleaned='newvalue' WHERE id=1")

    if False:
        rows = runquery("SELECT nsclean, nsraw FROM main WHERE propid='10049'")
        print "nsclean: " + rows[0][0]

        # Works.. inspected in word and UTF-8 unicode chars intact
        with codecs.open("C:\\Users\\derek\\tmp\\10049funkyouttest.txt", 'w',encoding='utf-8') as fout:
            fout.write(rows[0][1])

    if False:
        load_propids()
        test_run_all()
    
    if False: # This was my first take, was over-engineered
      note_and_source_dict = parse_textfiles_deprecated()
      print "\n\nRESULT: "
      pprint.pprint(note_and_source_dict)
