# Altadena Heritage Architectural Database Rails Website

[Note to recruiters / potential employers perusing this code: I develop this
project in a private repo on BitBucket, so I just copied the latest version
over to GitHub so that my code could be publicly viewed in the most conventional
place.  I'd be glad to share the BitBucket repo upon request.  I also store
copious Dev Notes in Evernote and am glad to share that notebook upon
request as well.  Long live Dev Notes!  Well worth the energy!]

[*Altadena Heritage*](http://altadenaheritage.org/)

Old website: [Altadena Heritage Property Database](http://altadenaheritagepdb.org/)

New website: [The New Altadena Heritage Property Database](http://ahad.altadenaheritagepdb.org/)

This Rails website is being developed by 
[Derek Carlson](http://www.consciouscomputerconsulting.com/) and Dick Rubin.

* System dependencies:
  *   To run the test suite on cloud9, `xvfb`, `geckodriver`, and `firefox` must all
      be installed for the feature tests to run.  See below for full instructions 
      on how to set that up.

* To run test suite on cloud9: `xvfb-run bundle exec rspec spec --format doc`

* To run test suite on local ubuntu dev machine: `bundle exec rspec spec --format doc`

## How To: Setup for development on cloud9 (c9.io)

To develop in the cloud9 IDE, you need to install several components in order to be able to run the automated Selenium-based feature tests.

Selenium is already installed via the Gemfile, but the following components need to be manually installed and set up:

- Firefox: The good 'ol web browser
- geckodriver, the Selenium web driver mediator for Firefox: a standalone binary that mediates between Selenium and Firefox
- xvfb: The X windows Virtual Frame Buffer display server that allows Firefox to run on a system lacking an X Windows display

### Here's why these things are needed:

**xvfb:** In order to do fully automated integration/feature tests of the site's pages that contain JavaScript (like the home page that incorporates the select2 combobox), RSpec uses Capybara which uses Selenium to drive Firefox through the tests.

However, Firefox won't run on cloud9 because the cloud9 virtual Ubuntu machine does not have an X Windows display for Firefox to appear on.  So Firefox won't start up.  To get around this, we use a utility called xvfb which creates a virtual display (really an in-memory frame buffer), and makes Firefox think that it's a real display.  So Firefox starts just fine, displaying itself on this virtual frame buffer and being none the wiser.  

(The only downside to this for us developers is that we can't see anything that's happening when Firefox is running, which is why we found it necessray to maintain a regular local Ubuntu development server so we can see what Firefox is being driven to do when we're trying to figure things out or diagnose errors or inconsistencies with integration tests.  But that's an aside -- lets continue getting this running on cloud9!)

**Selenium web driver for Firefox:** A mediating stand-alone executable known as "geckodriver" is necessary for Selenium 3 (we're using 3.0.5 as of 1/21/17) to drive Firefox 50 (50.1.0 as of 1/21/17).  With older versions of Selenium and Firefox this wasn't necessary.

### Here's how to set them up:

**Firefox**:
```
sudo apt-get update
sudo apt-get install firefox
```

**Selenium Web Driver for Firefox (geckodriver):**

Download the latest geckodriver from: 

<https://github.com/mozilla/geckodriver/releases>

For example, I just downloaded: `geckodriver-v0.13.0-linux64.tar.gz` since cloud9 is a 64-bit Ubuntu Linux system.

Once that's downloaded to your local computer, upload it to cloud9:

* In the file explorer on the left-hand side of the cloud9 IDE, click on the top-most folder (the root folder for all of your workspace projects) to select it.  Whatever folder is selected determines where uploaded files are uploaded to.  The top-most folder in the GUI is the `~/workspace folder` in the shell, and that's where we're going to upload to.

* Go to the `File` menu, and select `Upload Local Files...` and then drag the `geckodriver-v0.13.0-linux64.tar.gz` file that you downloaded to your local system onto the "Drag & Drop" area of the upload dialog box to upload it to `~/workspace`.

Now, to install it:

```
cd ~/workspace
mkdir /home/ubuntu/bin
tar xzvf geckodriver-v0.13.0-linux64.tar.gz
mv geckodriver /home/ubuntu/bin
rm geckodriver-v0.13.0-linux64.tar.gz
```

and to make sure it's working, type `geckodriver --version` and you should see it print out some info starting with something like `geckodriver 0.11.1`.  This assumes `/home/ubuntu/bin` is in your path, which it should be by default.  You can check that with `echo $PATH`, and look for `/home/ubuntu/bin` (should be the second one).

**xvfb**:

```
sudo apt-get update
sudo apt-get install xvfb
sudo apt-get install x11-xkb-utils
```
To make sure it's working, you should get a help listing by typing `xvfb-run --help`

Note: I followed instructions found at <http://tutorials.jumpstartlab.com/topics/capybara/capybara_with_selenium_and_webkit.html> to learn how to install xvfb.

## How to run the test suite

To run all the RSpec tests, do this:
```
cd [the root rails AHAD website project directory]
xvfb-run bundle exec rspec spec --format doc
```
It could take 2-3 minutes to run, so be patient, as it takes a while to run the Firefox driven integration tests.

It will print out a bunch of colorful rspec tests (hopefully all green), and end with something similar to:
```
Finished in 53.93 seconds (files took 22.92 seconds to load)
60 examples, 0 failures
```
**If it does that, it works!  Congratulations!**

If you want to *only* run the integration tests that run Firefox, in order to most directly see if you set things up correctly, you can do this:

`xvfb-run bundle exec rspec spec/features --format doc`

**There you have it!  That's how to get the test suite running on a fresh cloud9 dev environment!**

PS. If you ever forget the `xvfb-run` at the front of that command, and if you're like me, you probably will several times, you'll get a really cryptic error message saying something about:

```
Failure/Error: visit "/" Net::ReadTimeout: 
                             Net::ReadTimeout
``` 

Just keep that in mind for when it happens, and always remember `xvfb-run` when working on cloud9.

PPS. If you're working on a local Ubuntu dev system instead of cloud9, all of the above applies except you don't need `xvfb`.