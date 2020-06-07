import os
import re
from csv import DictReader
from glob import glob
from os.path import abspath
from os.path import join

cwd = abspath(".")
target_dir = abspath(join("..", "_links", "email"))
list_of_csvs = glob(abspath(join(".", "contacts")) + os.sep + "*.csv")
filename_regex = re.compile("(\.|,|\)|\(|')")


for csv in list_of_csvs:
    csv_file = open(csv, newline='')
    csv_reader = DictReader(csv_file)
    for row in csv_reader:
        # name,position,city,state,police_department_name,email
        filename = target_dir + os.sep + "email_" + row['position'] + "_of_" + row['city'] + "_" + row['police_department_name']
        filename = filename_regex.sub('', filename).replace(' ', '-').lower() + ".md"
        newfile = open(filename, mode='w')
        file_template = open(join(cwd, "contact_person_generic_template.md"))
        for line in file_template:
            if "[NAME]" in line:
                line = line.replace("[NAME]", row['name'])
            if "[POSITION]" in line:
                line = line.replace("[POSITION]", row['position'])
            if "[CITY]" in line:
                line = line.replace("[CITY]", row['city'])
            if "[STATE]" in line:
                line = line.replace("[STATE]", row['state'])
            if "[POLICE-DEPT]" in line:
                line = line.replace("[POLICE-DEPT]", row['police_department_name'])
            if "[EMAIL]" in line:
                line = line.replace("[EMAIL]", row['email'])
            if "[CITY-LARGE]" in line:
                line = line.replace("[CITY-LARGE]", row['city'].upper())
            if "[STATE-LARGE]" in line:
                line = line.replace("[STATE-LARGE]", row['state'].upper())
            # Finally, write the line
            newfile.write(line)
            newfile.flush()
        newfile.close()
        file_template.close()
    csv_file.close()
