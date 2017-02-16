/////////////////////////////////////////////////////////////////////////////
// static_pages.js
//
// Code relating to static pages such as the root home page.
//
//
// TOC: 
//
// onLoadEventRootHomeHelper():
//
//   Code for (turbolinks) on-load event for root/home page 
//   (static_pages#home). Called from main.js#turbolinks:load().
//
// loadBGImgHandler(): Sets the global aspect ratio of the root/home bg image.
//
// resizeBGImgRootHome():
//
//   For homepage, keep the background image centered and properly scaled to
//   fit the entire screen without distortion.
//
// rootHomeSearchClicked(): Jump to selected property page.
//
//
// TODO:
//   * 11/15/16 DDC: In onLoadEventRootHomeHelper()
//       url: "<%= properties_path %>.json", 
//     doesn't work even when naming this file .js.erb.  Thus, figure out
//     how to embed Ruby in this js file... and how to keep to js color
//     coding working when file ends in .erb... !?!
//
//   * 12/3/16 DDC: resizeBGImgRootHome - see todos in header.  
//
/////////////////////////////////////////////////////////////////////////////
'use strict';
/**
 * @module static_pages
 */
 
/////////////////////////////////////////////////////////////////////////////
// Globals
/////////////////////////////////////////////////////////////////////////////
/* global $ */
/* global DEBUG */

// Global variables for home page to keep background image centered.
// Not put in jsdoc as these are low level implementation details.
var g_RootHome_BGImgAspectRatio = 0.0;
var g_RootHome_BrowserWinInnerWidth= 0;
var g_RootHome_BrowserWinInnerHeight = 0;

//
// static_pages#home (root/home page) globals
//

//
// RH: root/home page related
//

/** @constant */
var RH___means_RootHome = null;
/**
 * The default text for the adress combo box on the home page.
 * @constant
 */
var RH__SELECT2_DEFAULT_TEXT = "Enter an Altadena address here...";


/////////////////////////////////////////////////////////////////////////////
// Code
/////////////////////////////////////////////////////////////////////////////

//
//
// root/home page (static_pages#home)
//
//

/////////////////////////////////////////////////////////////////////////////
// #onLoadEventRootHomeHelper
/**
 * @summary Code for (turbolinks) on-load event for root/home page 
 * (static_pages#home).  
 * 
 * @desc Sets up automatic background image scaling, as well
 * as initializing select2 combobox for addresses.
 * 
 * Sets window.resize() and window.scroll() events.
 * 
 * Called from main.js#{@link turbolinks:load}.
 * 
 * @author Derek Carlson
 * @since 12/7/2016
 * 
 */
/* Additional Notes:
 *
 * window.resize() used to keep background image properly scaled.
 *
 * window.load() used to wait until bg image loaded to determine
 *   aspect ratio (still doesn't work on all devices all the time
 *   as of 12/3/16 - Chrome on Samsung S7, Android 6.0.1.)  See
 *   notes below in code.
 *
 * [1] Select2 Notes:
 *
 * Select2 expects to receive AJAX data in the following format:
 *
 * @tmphash = {
 *   "results": [
 *       {
 *           "id": "CA",
 *           "text": "California"
 *       },
 *       {
 *           "id": "CO",
 *           "text": "Colarado"
 *       }
 *  ]
 * };
 *
 * But what we get back from the properties controller looks like...
 *
 * [{"id":10001,"address1":"251 Acacia St"},
 *  {"id":10002,"address1":"259 Acacia St"}, ...
 * ]
 *
 * So "data" is an array of hashes, and we need to turn that into a hash
 * with 1 key "results", and that key needs to point to an array of hashes,
 * except we need to change the "address1" key to the name "text" that
 * Select2 expects.  This transformation is what processResults does.
 *
 */
function onLoadEventRootHomeHelper() {
  if (DEBUG) console.log("Initializing home page vars...");

  // Below: within this load() event, it turns out, at least when
  // run from Cloud9 on Chome, or Heroku on Chrome, this code runs
  // before bgimg gets loaded.  ?!?
  // As per: https://github.com/turbolinks/turbolinks-classic/issues/295
  // turns out the load() event does not always wait for all assets
  // to load, contrary to the documentation I've read.  Worked fine
  // on FireFox and Edge, but not Chrome.  So, the solution was to
  // force the code to run after bgimg was loaded via the following line:
  // --- this section was first stab
  //   document.getElementById("sp-home-bg-img").
  //     addEventListener('load', loadBGImgHandler);
  // However, if image is already cached, the load event never gets called
  // on IE 11.321, so need to also set it up here to cover that case
  //   loadBGImgHandler();
  // --- but intermittently doesn't work on Chrome Win 10
  //     so trying the line below instead
  $(window).load(loadBGImgHandler);
  $(window).resize(resizeBGImgRootHome); 
  // set callback for whenever browser size changes

  $('#sp-home-search-btn').click(rootHomeSearchClicked);
  
  // See [1] in header comments
  $('#sp-home-addr-select2').select2({
    placeholder: RH__SELECT2_DEFAULT_TEXT,
    tags: true, // This & selectOnBlur & createSearchChoice
                // are needed to allow entry of custom addresses
                // that aren't in our database. See:
                // http://stackoverflow.com/questions/25616520/
                //   select2-dropdown-allow-new-values-by-user-when-user-types
    selectOnBlur: true, 
    selectOnClose: true,
    createSearchChoice: function (term, data) {
        if ($(data).filter(function () {
            return this.text.localeCompare(term) === 0;
        }).length === 0) {
            return {
                id: term,
                text: term
            };
        }
    },
    allowClear: true,
    ajax: {
      url: "properties.json",
      // url: "<%= properties_path %>.json", // erb not working it seems
      dataType: 'json',
      delay: 250,
      // Below transforms the JSON properties list into a format
      // that select2 expects.
      processResults: function (data) {
        return { 
          results: data.map(function (x) 
            { return { id: x.id, text: x.address1 } } ) 
        }
      }
    }
  });
}

/////////////////////////////////////////////////////////////////////////////
// #loadBGImgHandler
/**
 * @summary Set root/home background image aspect ratio and resize image
 * according to browser screen size.
 * 
 * @author Derek Carlson
 * @since 12/7/2016
 * 
 */
/* Need to do this here instead of the document.load (turbolinks:load)
 * routine because on Chrome bgimg is not loaded when turbolinks:load
 * is called, thus .width and .height are 0.  Thus, below is fired
 * on the bgimg load() event.  (Further note: This still doesn't
 * work across several chrome browsers, so there's a kludge in
 * resizeBGImgRootHome() - 12/8/16 DDC.)
 */
function loadBGImgHandler() {
  g_RootHome_BGImgAspectRatio = 
    document.getElementById("sp-home-bg-img").width / 
    document.getElementById("sp-home-bg-img").height;
  resizeBGImgRootHome();	
}


/////////////////////////////////////////////////////////////////////////////
// #resizeBGImgRootHome
/**
 * @summary For homepage, keep the background image centered and properly
 * scaled to fit the entire screen without distortion.
 * 
 * @todo Understand and solve race condition and remove kludge. 12/8/16 DDC.
 * 
 * @author Derek Carlson
 * @since 12/7/2016
 * 
 */
/*
 * Global reference: g_RootHome_BGImgAspectRatio needs to be set prior to
 * call (except there's currently a kludge that
 * sets it in this code if it's null, which is happening intermittently
 * due to some race condition in certain situations/browsers. See further
 * notes in code below.)
 *
 * Notes on scaling algorithm:
 *
 * The aspect ratio is width/height.
 *
 * (A) If browser aspect ratio is less than the bg image aspect ratio
 * (that is, the bg image is wide and the browser is tall and skinny)
 * then make the bg image the height of the browser, and then scale
 * and center it horizontally.  
 *
 * (B) Or, if the browser aspect ratio is greater than the bg image's
 * (the browser is really wide and short), then scale the width
 * of the image to fit the browser, and let the height be what it 
 * needs to be.  NOTE: This, however, creates an unwanted vertical
 * scroll bar situation.
 *
*/
function resizeBGImgRootHome() {
  // Use the || stuff for IE8 and earlier
  g_RootHome_BrowserWinInnerWidth= window.innerWidth
    || document.documentElement.clientWidth
    || document.body.clientWidth;

  g_RootHome_BrowserWinInnerHeight = window.innerHeight
    || document.documentElement.clientHeight
    || document.body.clientHeight;

  var fDOMAspectRatio = g_RootHome_BrowserWinInnerWidth / 
    g_RootHome_BrowserWinInnerHeight;
	
  var img = document.getElementById("sp-home-bg-img"); 

  // **** TODO: KLUDGE WARNING ****
  //
  // 11/27/16, from Dick:  ...(except background photo not displayed 
  // until after I pressed "Search Again"). 
  // Chrome on Samsung S7, Android 6.0.1.
  // I suspect somehow the g_RootHome_BGImgAspectRatio is not getting property
  // set... so hardcoding it below to see if that's the situation (12/1/16)
  //
  // 1900 / 945 = 2.01058 for Altadena_littlehouse_1900_wide.jpg
  if ( (g_RootHome_BGImgAspectRatio === null) || 
       (g_RootHome_BGImgAspectRatio === undefined) || 
       (g_RootHome_BGImgAspectRatio < 0.1) ) 
    g_RootHome_BGImgAspectRatio = 2.01058;

  if (DEBUG) {
    console.log("DOM Aspect Ratio: " + fDOMAspectRatio);
    console.log("BG IMG Aspect Ratio: " + g_RootHome_BGImgAspectRatio);
  }
	
  if (fDOMAspectRatio <= g_RootHome_BGImgAspectRatio) {
    if (DEBUG) console.log("Setting BG IMG height to DOM height...");
    img.height = g_RootHome_BrowserWinInnerHeight;
    img.width = g_RootHome_BGImgAspectRatio * img.height;
    $("#sp-home-bg-img").css("left", - 
      (img.clientWidth/2.0 - g_RootHome_BrowserWinInnerWidth/2.0));
  } else { 
    // Else DOM is wide and not tall - so set the bg image to the 
    // DOM width, and then scale the vertical appropriately
    if (DEBUG) console.log("Setting BG IMG width to DOM width...");
    $("#sp-home-bg-img").css("left", 0);
    img.width = g_RootHome_BrowserWinInnerWidth;
    img.height = img.width / g_RootHome_BGImgAspectRatio;
  }

  $('.select2-container--default').width($('#sp-home-addr-container').width());
}	

//
// root/home page (static_pages#home) functions tied to HTML
//

/////////////////////////////////////////////////////////////////////////////
// #rootHomeSearchClicked
/** 
 * @summary Executes when Search button clicked.
 *
 * @author Derek Carlson
 * @since 12/7/2016
 * 
 */
function rootHomeSearchClicked() {
  if ( $("#sp-home-addr-select2").val() !== null )  {
    $(".btn-arrow-anim__text").html("Looking...");
    document.getElementById("sp-home-form").submit();
  } else { 
    return false; 
  }
}

/////////////////////////////////////////////////////////////////////////////
// #onLoadEventTestformHelper
/** 
 * @summary Used for various and sundry tests.
 *
 * @author Derek Carlson
 * @since 12/31/2016
 * 
 */
function onLoadEventTestformHelper() {
	document.getElementById('testform-div-to-change').innerHTML = 
		'I have seen the light, and I am grateful.';
}
