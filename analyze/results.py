#!/usr/bin/env python3

import os
import sys
import re
import csv
import glob
import pdb
from collections import defaultdict

"""

PERIOD -> LONG/SHORT -> [TRADES]

"""

results = defaultdict(lambda: defaultdict(list))
results_by_alg = defaultdict(lambda: defaultdict(list))


def print_forex_content():
    print('Trades:')
    for period in results:
        for trade_type in results[period]:
            print('  {} / {} <= {}'.format(period, trade_type, len(results[period][trade_type])))

def print_forex_content_by_alg(alg_filter=None):
    if alg_filter:
        print('Trades on alg {}'.format(alg_filter))
        print_forex_content_by_malg(alg_filter, debug=True)
    else:
        print('Trades by alg:')
        for malg in results_by_alg:
            print_forex_content_by_malg(malg)

def print_forex_content_by_malg(malg, debug=False):
    # EntryPrice;ExitPrice
    n_trades = 0
    all_trades = []
    profit = 0.0
    ctrades = defaultdict(list)
    for alg in results_by_alg[malg]:
        trades = results_by_alg[malg][alg]
        all_trades.extend(trades)
        n_trades += len(trades)
        alg_sufix = alg.replace(malg, '')
        calg_regex = re.match(r'-([a-z]{2}).*([0-9]{2,4}).*', alg_sufix)
        calg = '-'.join(calg_regex.groups())
        ctrades[calg].extend(trades)
    profit += sum([float(trade['Size']) * 1000 * (float(trade['ExitPrice']) - float(trade['EntryPrice'])) for trade in all_trades if trade['Position'] == 'LONG'])
    profit += sum([float(trade['Size']) * 1000 * (float(trade['EntryPrice']) - float(trade['ExitPrice'])) for trade in all_trades if trade['Position'] == 'SHORT'])
    print('  {} <= {} [{:.4f}]'.format(malg, n_trades, profit))
    for calg in ctrades:
        profit = 0.0
        trades = ctrades[calg]
        profit += sum([float(trade['Size']) * 1000 * (float(trade['ExitPrice']) - float(trade['EntryPrice'])) for trade in trades if trade['Position'] == 'LONG'])
        profit += sum([float(trade['Size']) * 1000 * (float(trade['EntryPrice']) - float(trade['ExitPrice'])) for trade in trades if trade['Position'] == 'SHORT'])
        print('      {} <= {} [{:.4f}]'.format(calg, len(trades), profit))
        if debug:
            for trade in trades:
                if trade['Position'] == 'SHORT':
                    profit = float(trade['Size']) * 1000 * (float(trade['EntryPrice']) - float(trade['ExitPrice']))
                else:
                    profit = float(trade['Size']) * 1000 * (float(trade['ExitPrice']) - float(trade['EntryPrice']))
                print('          {} => {:.4f}'.format(trade['Position'], profit))

def parse_forex_results(forex_dir):
    global results
    global results_by_alg
    trade_types = ["BUY", "SELL"]
    results_files = glob.glob(forex_dir + "*/*_closed.csv")
    for f in results_files:
        period = f.split('_')[2]
        with open(f, newline='') as freader:
            contents = csv.DictReader(freader, delimiter=";")
            for row in contents:
                trade_type = row.get('OutType', '')
                alg = row.get('EntryReason', '')
                malg = '-'.join(alg.split('-')[0:2])
                if trade_type in trade_types:
                    results[period][trade_type].append(row)
                    results_by_alg[malg][alg].append(row)


if __name__ == "__main__":
    if len(sys.argv) >= 2:
        fdir = sys.argv[1]
        parse_forex_results(fdir)
        if len(sys.argv) >= 3:
            print_forex_content_by_alg(sys.argv[2])
        else:
            print_forex_content()
            print_forex_content_by_alg()
    else:
        print('[err] missing forex dir')
        
