import argparse

# HOW TO USE #
# python3 ~/PycharmProjects/Python/antiSENSE.py -rna GAGAACCGACACCTGCAGTTT
###### arguments ######
parser = argparse.ArgumentParser()
parser.add_argument('-rna','--rna', metavar='Str', dest='RNA', help='rna',type=str)
args = parser.parse_args()
###### arguments ######

def convertnt(x):
    if x == 'A':
        return 'T'
    elif x == 'T':
        return 'A'
    elif x == 'C':
        return 'G'
    else:
        return 'C'

def antiSENSE(rna):
    RNA = rna[::-1]
    c = []
    for i in RNA:
        c.append(convertnt(i))
    c = ''.join(c)
    print(c)
    F = 'CCGG'+rna+'CTCGAG'+c+'TTTTTG'
    R = c+'GAGCTC'+rna+'AAAAACTTAA'
    print('Forward is {}'.format(F))
    print('Reversed is {}'.format(R))

antiSENSE(rna=args.RNA)
