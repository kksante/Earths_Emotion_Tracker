#-------------------------------------------------------------------------------
# Author: Karthik Vegi
# Email: karthikvegi@outlook.com
# Python Version: 3.6
#-------------------------------------------------------------------------------
import math
from datetime import datetime

def send_to_destination(output, destination, delimiter):
    destination.write(delimiter.join(output) + "\n")

def empty_fields(fields):
    if any(map(lambda x: not x.strip(), fields)):
        return True

def malformed_field(field, ideal_length):
    if len(field) < ideal_length:
        return True

def invalid_date(field, format):
    try:
        datetime.strptime(field, format)
    except Exception as e:
        return True

# Nearest-rank method percentile
def get_ordinal_rank(ord_list, percentile):
    idx = int(math.ceil(percentile * 0.01 * len(ord_list)))
    return (idx-1)
