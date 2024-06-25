from flask import jsonify
from datetime import datetime
import glob
from functools import lru_cache

class CryptoCoin:
    _TRADE_FIELDS = ["date", "open", "high", "low", "close", "volume", "total"]
    _all_coins = None

    @staticmethod
    def get_all_coins():
        if not CryptoCoin._all_coins:
            CryptoCoin._all_coins = {}
            CryptoCoin.read_csv_data()
        return CryptoCoin._all_coins

    def __init__(self, symbol: str, name: str):
        self._symbol = symbol
        self._name = name
        self._day_trading = {}  # dictionary on trade day

    def __str__(self):
        return f"{self._symbol}({self._name}, {len(self._day_trading)} days)"

    @staticmethod
    def _read_line(file):
        return file.readline().strip('\n').split(',')

    @staticmethod
    def _read_csv(coin_file_name: str):
        print(f"READING: {coin_file_name}")
        with open(coin_file_name) as file:
            fields = CryptoCoin._read_line(file)
            coin = CryptoCoin(fields[1], fields[2])  # first line contains coin symbol and name
            CryptoCoin._all_coins[coin._symbol] = coin
            header = CryptoCoin._read_line(file)  # second line contains the header (field names)
            for line in file:
                fields = line.strip('\n').split(',')
                if fields == ['']:
                    break
                day_trade = {}
                for i in range(len(fields)):
                    # only add usable fields
                    if header[i] in CryptoCoin._TRADE_FIELDS:
                        # Convert date field to date and the rest to float
                        day_trade[header[i]] = datetime.strptime(fields[i], '%Y-%m-%d %H:%M:%S') if header[i] == CryptoCoin._TRADE_FIELDS[0] else float(fields[i])
                coin._day_trading[day_trade[CryptoCoin._TRADE_FIELDS[0]]] = day_trade

    @staticmethod
    def read_csv_data():
        for name in glob.glob('csv/*.csv'):
            CryptoCoin._read_csv(name)

    @staticmethod
    @lru_cache(maxsize=32)
    def get_coin_json(code):
        """Returns as a JSON the name of the specific coin."""
        try:
            coin = CryptoCoin.get_all_coins()[code]
            return {'name': coin._name}
        except KeyError:
            return {'Unknown coin': code}

    @staticmethod
    @lru_cache(maxsize=32)
    def get_coin_trading_json(code):
        try:
            coin = CryptoCoin.get_all_coins()[code]
            trading = [dt for dt in coin._day_trading.values()]
            return trading
        except KeyError:
            return {'Unknown coin': code}

    @staticmethod
    def get_coins_json():
        """Returns a JSON list of data of all the coins. Each entry contains a symbol and a name."""
        print("get_coins_json()")
        coins = []
        for coin in CryptoCoin.get_all_coins().values():
            record = {}
            record['symbol'] = coin._symbol
            record['name'] = coin._name
            coins.append(record)
        return jsonify(coins)

if __name__ == "__main__":
    for coin in CryptoCoin.get_all_coins().values():
        print(f"{coin}: trading = {len(coin._day_trading)}")
        count = 0
        for trading in coin._day_trading.values():
            print(trading)
            count += 1
            if count == 10:
                print('...')
                break
