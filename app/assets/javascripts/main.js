/////////////////////////////////////////////////////////////////////////////
// main.js
//
// Handles all non-page specific code, and non-cross-module utility code.
// e.g. this is the entry point for the turbolinks:load event that is
// called when each new page is loaded.
//
// Also contains global definitions that are used across multiple modules.
//
//
// TOC:
// 
// document.ready(): Event, not used at the moment (12/3/16 DDC).
//
// window.load(): Event, for loading Google Map load script.
//
// turbolinks.load()
//
//   Event, fired on fresh page loads as well as intra-site links, delegates
//   to code specific to each different page load.
//
/////////////////////////////////////////////////////////////////////////////
'use strict';
/**
 * @module main
 */
 
/////////////////////////////////////////////////////////////////////////////
// Globals
/////////////////////////////////////////////////////////////////////////////
/* global $ */

// From static_pages.js
/* global onLoadEventRootHomeHelper */
/* global onLoadEventTestformHelper */

// From properties.js
/* global onLoadEventPropertyShowHelper */
/* global onLoadEventPropertyNotFoundHelper */

/**
 * Global debug variable for logging across all modules.
 * @constant
 * @global
 */
var DEBUG = true;  // "const" doesn't work in IE 8, 9, 10


/////////////////////////////////////////////////////////////////////////////
// Code
/////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////
// #document.ready
/** 
 * @function document.ready
 * 
 * @desc 'ready' is fired first time site is first loaded, 
 * even with turbolinks.
 * 
 * @author Derek Carlson
 * @since 12/7/2016
 * 
 */
$(document).on('ready', function (e) {
  if (DEBUG) console.log("Event: ready() at: " + e.timeStamp);
});


/////////////////////////////////////////////////////////////////////////////
// #window.load
/**
 * @function window.load
 * 
 * @desc Used to load Google Map init script.
 * 
 * @todo Uncomment the call, or remove this function entirely. DDC 12/8/16
 * 
 * @author Derek Carlson
 * @since 12/7/2016
 * 
 */
$(window).on('load', function (e) {
//	loadGoogleMapScript();
});


/////////////////////////////////////////////////////////////////////////////
// #turbolinks:load
/** 
 * @function turbolinks:load
 * 
 * @desc Delegate page load code to various functions depending on which
 * page (or type of page) is being loaded.
 * 
 * @author Derek Carlson
 * @since 12/7/2016
 * 
 */
/*
 * Suspect below needs to be turbolinks:load, for when we are at
 * a non-home page, and we click back to the homepage and need the
 * bg image re-initialized.
 *
 * With Turbolinks, the page header is always the same and the
 * body is the only thing that gets swapped out when in-site
 * links are clicked.
 *
 * Thus, we only want certain code to run on certain pages,
 * but each page load is going to come through this event,
 * so we need to delegate to page-specific code here.
 *
 * I'm sure there's a cleaner, more proper way to deal with 
 * this, but haven't found it yet. Or, could just disable
 * Turbolinks.  But will give it a shot until the code
 * to deal with it gets too unruly.
 */
$(document).on('turbolinks:load', function (e) {

  if (DEBUG) {
    console.log("Got to turbolinks:load at " + e.timeStamp);
    console.log("URL: " + window.location.href);
  }
  
  var page = "";

  if (window.location.href.match(/.+\/$/)) {
    page = "root";
  } else {
    page = window.location.href.match(/.+\/(.+)/)[1];
  }
  
  if (DEBUG) console.log("Turbolinks page: " + page);
  
  // Turn off property address fade in/out based on scrolling
  // for when we're on non-property view pages. Not sure
  // if the event persists across turbolinks page loads,
  // but playing it safe here.
  $(window).off('scroll');
  
  // Delegate to code that runs specific to each page loaded
  if (page == "root") {
    // Home page with search box -- root 'static_pages#home'
    onLoadEventRootHomeHelper();
  } else if (page == "testform") {
  	onLoadEventTestformHelper();
  } else if (window.location.href.match(/properties\/\d+/)) {
    // property#show page -- e.g. /properties/12413
    onLoadEventPropertyShowHelper(); // properties.js
  } else if (window.location.href.match(/search.*/)) {
    // property#[not found] -- e.g. /search?id=1000+E+Mount+...
    onLoadEventPropertyNotFoundHelper(); // properties.js
  } 
});

