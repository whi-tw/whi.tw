#!/usr/bin/env python
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
import os
  
# This is the only code you need to edit in your existing scripts.
# The command_executor tells the test to run on Sauce, while the desired_capabilities
# parameter tells us which browsers and OS to spin up.
desired_cap = {
    'platform': "Mac OS X 10.9",
    'browserName': "chrome",
    'version': "31",
}
driver = webdriver.Remote(
   command_executor='http://127.0.0.1:4444/wd/hub',
   desired_capabilities=desired_cap)
  
# This is your test logic. You can add multiple tests here.
driver.get("https://whi.tw/ell")
if not "Tom Whitwell" in driver.title:
    raise Exception("Unable to load homepage")

for root, dirs, files in os.walk("content"):
    for file in files:
        url = "https://whi.tw/ell/{}/{}".format(root, file.replace(".md","")).replace("/content","")
        print driver.get(url)
  
# This is where you tell Sauce Labs to stop running tests on your behalf.
# It's important so that you aren't billed after your test finishes.
driver.quit()
