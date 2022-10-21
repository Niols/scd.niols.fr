import sys
import time

from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.support.wait import WebDriverWait

source = sys.argv[1]
target = sys.argv[2]
width  = sys.argv[3]

## Get a driver for a headless Firefox.
options = FirefoxOptions()
options.headless = True
driver = webdriver.Firefox(options=options)

## Get the requested page.
driver.get(source)

## Maximize the window, set its size and give time for the page to stabilise.
driver.maximize_window()
driver.set_window_size(width, 8000)
time.sleep(1)

## Save a screenshot and leave.
driver.find_element_by_tag_name('body').screenshot(target)
driver.quit()
