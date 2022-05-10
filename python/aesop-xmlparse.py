import argparse
from codecs import open
from json import dumps,JSONEncoder
from os import chdir,walk
from os.path import isdir,join
from sys import exit,stderr
from xml.etree.ElementTree import parse

# Define namespaces.
ns = {
    'adsml-ma' : 'http://www.adsml.org/adsmlmaterials/2.5',
    'adsml-sd' : 'http://www.adsml.org/adsmlstructureddescriptions/1.0',
    'adsml-cv' : 'http://www.adsml.org/controlledvocabularies/3.0',
    'adsml'    : 'http://www.adsml.org/typelibrary/2.0',
    'booking'  : 'http://www.adsml.org/adsmlbookings/2.5'
}

# Known labeled properties.
labels = ['Package', "Title", "Zone"]

# Custom JSON encoder.
class OrderLineEncoder(JSONEncoder):
    def default(self, o):
        return o.__dict__

# Things i'd like to know.
class OrderLine:

    def __init__(self, orderSerial, orderId, adId, adTitle, insertionDate, insertionStatus, titleCode, editionCode, packageCode):
        self.orderSerial = orderSerial
        self.orderId = orderId
        self.adId = adId
        self.adTitle = adTitle
        self.insertionDate = insertionDate
        self.insertionStatus = insertionStatus
        self.titleCode = titleCode
        self.editionCode = editionCode
        self.packageCode = packageCode

    def getTsvHeader(self):
        return '{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}'.format('ORDERSERIAL', 'ORDERID', 'ADID', 'ADTITLE', 'INSERTIONDATE', 'INSERTIONSTATUS', 'TITLECODE', 'EDITIONCODE', 'PACKAGECODE')

    def toTsv(self):
        return '{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}'.format(self.orderSerial, self.orderId, self.adId, self.adTitle, self.insertionDate, self.insertionStatus, self.titleCode, self.editionCode, self.packageCode)

    def toJson(self):
        return dumps({
            'orderSerial': self.orderSerial,
            'orderId': self.orderId,
            'adId': self.adId,
            'adTitle': self.adTitle,
            'insertionDate': self.insertionDate,
            'insertionStatus': self.insertionStatus,
            'titleCode': self.titleCode,
            'editionCode': self.editionCode,
            'packageCode': self.packageCode
        })

def eprint(*args, **kwargs):
    print(*args, file=stderr, **kwargs)

def getOrderLines(files, encoding):
    # Create set for order lines.
    orderLines = []
    eprint('Using {} encoding to read files...'.format(encoding.upper()))
    eprint('Processing {} XML document(s). Please be patient...'.format(len(files)))

    # Reset values, python does not do 'block' scope.
    orderId = 'NONE'
    orderSerial = 'NONE'

    # The entire xml element tree.
    for file in files:

        target = open(file, mode='r', encoding=encoding)

        root = parse(target).getroot()

        # The order part of the tree. Should always be singular.
        order = root.find('./booking:AdOrder', ns)

        # The order serial number.
        orderSerial = order.attrib['{http://www.adsml.org/typelibrary/2.0}messageID']

        # The order identifier (our correlation id).
        orderId = order.find('booking:BookingIdentifier', ns).text

        # An order can contain multiple placements.
        placements = order.findall('booking:Placement.NewspaperMagazine', ns)

        # Reset values, python does not do 'block' scope.
        adId = 'NONE'
        adTitle = 'NONE'

        for placement in placements:
            adId = placement.find('booking:PlacementIdentifier', ns).text
            adTitle = placement.find('adsml:DescriptionLine', ns).text

            # A placement can contain multiple insertions.
            insertions = placement.findall('booking:InsertionPeriod', ns)
            for insertion in insertions:

                # The insertion date.
                elements = insertion.find('booking:PreDefinedPeriod', ns)

                # Reset values, python does not do 'block' scope.
                insertionDate = 'NONE'

                for element in elements:
                    if element.tag == '{http://www.adsml.org/typelibrary/2.0}CodeList':
                        label = element.text

                    if element.tag == '{http://www.adsml.org/typelibrary/2.0}CodeValue':
                        value = element.text

                if label == 'Insertiondate':
                    insertionDate = value

                # The insertion status.
                elements = insertion.find('adsml:Status', ns)

                # Reset values, python does not do 'block' scope.
                insertionStatus = 'NONE'

                for element in elements:
                    if element.tag == '{http://www.adsml.org/typelibrary/2.0}CodeValue':
                        insertionStatus = element.text

                # The insertion properties (title, zone and package codes).
                labeledProperties = insertion.findall('adsml:Properties/adsml:LabeledProperty', ns)

                # Reset values, python does not do 'block' scope.
                titleCode = 'NONE'
                editionCode = 'NONE'
                packageCode = 'NONE'

                for labeledProperty in labeledProperties:
                    for element in labeledProperty:
                        if element.tag == '{http://www.adsml.org/typelibrary/2.0}Label':
                            label = element.text

                        if element.tag == '{http://www.adsml.org/typelibrary/2.0}Value':
                            value = element.text

                    if label in labels:
                        if label == 'Title':
                            titleCode = value
                        if label == 'Zone':
                            editionCode = value
                        if label == 'Package':
                            packageCode = value

                # Now we know everything, create an Orderline Object:
                orderLine = OrderLine(orderSerial, orderId, adId, adTitle, insertionDate, insertionStatus, titleCode, editionCode, packageCode)
                orderLines.append(orderLine)

    return orderLines

def toJson(fileList, encoding):
    return dumps(getOrderLines(fileList, encoding), cls=OrderLineEncoder)

def toTsv(fileList, encoding):
    orderLines = getOrderLines(fileList, encoding)

    tsvLines = []

    tsvLines.append(orderLines[0].getTsvHeader())
    for orderLine in orderLines:
        tsvLines.append(orderLine.toTsv())

    return tsvLines

def output(fileList, encoding, format):
    if format == 'json':
        print(toJson(fileList, encoding))
    if format == 'tsv':
        for line in toTsv(fileList, encoding):
            print(line)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("adsml", help="An AdsML document or directory of AdsML documents to parse")
    parser.add_argument("-e", "--encoding", type=str, choices=['cp1252', 'utf8'],
                    help="Specify the encoding of the input files.", default='utf8')
    parser.add_argument("-f", "--format", type=str, choices=['tsv', 'json'],
                    help="Specify the output format. Default is tab-separated.", default='tsv')

    args = parser.parse_args()

    if not args.adsml:
        exit(1)

    if isdir(args.adsml):
        for root, dirs, files in walk(args.adsml):
            chdir(root)
            output(files, args.encoding, args.format)
    else:
        output([args.adsml], args.encoding, args.format)

if __name__ == "__main__":
    main()



