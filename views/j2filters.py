#!/usr/bin/env python3



# _shtp_fancy_at_date () {
#     ## Attempt to read the date as 1. only year, 2. without day and 3. full. If
#     ## none of these succeed, fail miserably. We output the date in British
#     ## English, eg. 31 August 2022.
#     date --date="$1"-01-01 +'in %Y' 2>/dev/null \
#         || date --date="$1"-01 +'in %B %Y' 2>/dev/null \
#         || date --date="$1" +'on %-d %B %Y' 2>/dev/null \
#         || die 'Could not interpret `%s` as date or partial date' "$1"
# }

# shtp_fancy_formatted_date () {
#     if exists date-format; then
#         _date_format=$(raw date-format)
#     else
#         _date_format='%at-date%'
#     fi

#     if exists date; then
#         _date=$(raw date)
#         _year=${_date%%-*}
#         _at_date=$(_shtp_fancy_at_date "$_date")
#         printf '%s' "$_date_format" | \
#             sed -e "s|%year%|$_year|g" \
#                 -e "s|%at-date%|$_at_date|g"
#     else
#         printf '%s' "$_date_format"
#     fi
# }



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
