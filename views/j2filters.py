#!/usr/bin/env python3

def error(message):
    raise Exception(message)

def dateYear(date):
    return date.split("-")[0]

def fancyDate(date, dateFmt="%at-date%"):
    months = ["", "January", "February", "March", "April", "May", "June",
              "July", "August", "September", "October", "November", "December"]
    components = date.split("-")
    year = components[0]
    if len(components) == 1:
        atDate = "in {}".format(year)
    else:
        month = months[int(components[1])]
        if len(components) == 2:
            atDate = "in {} {}".format(month, year)
        else:
            day = int(components[2])
            atDate = "on {} {} {}".format(day, month, year)
    return dateFmt.replace("%year%", year).replace("%at-date%", atDate)
