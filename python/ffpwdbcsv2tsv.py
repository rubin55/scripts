#! /usr/bin/env python3

import csv
import ipaddress
import re


def is_ipv4(string):
    try:
        ipaddress.IPv4Network(string)
        return True
    except ValueError:
        return False


def extract_identifier(url):
    removed_scheme = url.replace('ftp://', '').replace('http://', '').replace('https://', '')
    remove_port = re.sub(':[0-9]*', '', removed_scheme)
    removed_www = remove_port.replace('www.', '')
    if is_ipv4(removed_www):
        return removed_www
    else:
        return '.'.join(reversed(removed_www.split('.')))


def handle_empty(string):
    if not string:
        return 'unknown'
    else:
        return string


with open('firefox.csv') as file:
    data = csv.reader(file)
    for row in data:
        identifier = extract_identifier(row[0])
        username = handle_empty(row[1])
        password = row[2]
        print(f"{identifier}\t{username}\t{password}")
