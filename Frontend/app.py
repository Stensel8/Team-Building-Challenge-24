import random
import logging
from flask import Flask, escape, render_template, url_for, jsonify
import requests
from os import getenv, mkdir, path
from matplotlib.figure import Figure
import matplotlib.dates as mdates
from threading import Thread, Lock
from queue import Queue
import time

# Setup logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Get the backend servers from environment variables and split them into a list
BACKENDS = getenv('SAXCOIN_BACKENDS', 'http://192.168.30.120:5000,http://192.168.30.125:5000,http://192.168.30.130:5000').split(',')
logger.debug(f'Backends={BACKENDS}')
CACHE_DIR = 'static/cache'
cache_building = False
total_charts = 0
charts_rendered = 0
current_coin = ""
cache_lock = Lock()
queue = Queue()

class Trading:
    tradings = {}

    def __init__(self, coin, date, rate, low, high, volume):
        self.coin = coin
        self.date = date
        self.rate = rate
        self.low = low
        self.high = high
        self.volume = volume

    @staticmethod
    def get_tradings(symbol):
        tradings = Trading.tradings.get(symbol, None)
        if tradings is None:
            tradings = []
            logger.debug(f"Fetching trading data for {symbol}")
            try:
                backend = random.choice(BACKENDS)  # Choose a random backend
                tradings_data = requests.get(backend + '/trading/' + escape(symbol))
                tradings_data.raise_for_status()  # Check if the request was successful
                for trading_data in tradings_data.json():
                    trading = Trading(
                        symbol,
                        trading_data['date'],
                        float(trading_data['close']),
                        float(trading_data['low']),
                        float(trading_data['high']),
                        float(trading_data['volume'])
                    )
                    tradings.append(trading)
                Trading.tradings[symbol] = tradings
            except requests.RequestException as e:
                logger.error(f"Error fetching trading data for {symbol}: {e}")
        return tradings

    @staticmethod
    def get_graph(symbol: str) -> str:
        """Create a trading graph of the given coin `symbol` and return the filename if it doesn't exist already."""
        plot_name = f'{symbol}-tradings.webp'
        file_name = f'{CACHE_DIR}/{plot_name}'
        if not path.exists(CACHE_DIR):
            mkdir(CACHE_DIR)

        with cache_lock:
            if not path.exists(file_name):
                global current_coin, charts_rendered
                current_coin = symbol
                logger.debug(f"Creating graph for {symbol}")
                try:
                    figure = Figure(figsize=(10, 6))
                    plot = figure.add_subplot()
                    tradings = Trading.get_tradings(symbol)
                    if not tradings:
                        raise ValueError("No trading data available")

                    x = [mdates.datestr2num(trading.date) for trading in tradings]
                    y_rate = [trading.rate for trading in tradings]
                    y_low = [trading.low for trading in tradings]
                    y_high = [trading.high for trading in tradings]

                    plot.plot(x, y_rate, 'blue', label='Koers')
                    plot.plot(x, y_low, 'red', label='Laag')
                    plot.plot(x, y_high, 'green', label='Hoog')

                    plot.grid(True)
                    plot.set_xlabel('Tijd (jaren)')
                    plot.set_ylabel('Prijs (Euro)')
                    plot.set_title(f'Prijzen van {symbol}')
                    plot.legend(['Koers', 'Laag', 'Hoog'])
                    plot.xaxis.set_major_formatter(mdates.DateFormatter('%Y'))
                    plot.xaxis.set_major_locator(mdates.YearLocator())

                    figure.autofmt_xdate()
                    figure.savefig(file_name, format='webp')
                    charts_rendered += 1
                    logger.debug(f"Rendered {symbol}: |{file_name}|{CACHE_DIR}|{plot_name}|")
                    logger.debug(f"Progress: {charts_rendered}/{total_charts} ({(charts_rendered/total_charts)*100:.2f}%)")
                except Exception as e:
                    logger.error(f"Error creating graph for {symbol}: {e}")
        return f'/static/cache/{plot_name}'

class Coin:
    coins = None

    def __init__(self, symbol, name):
        self.symbol = symbol
        self.name = name
        self.url = url_for('get_coin', symbol=symbol)
        self.logo = url_for('static', filename=f'{self.symbol}.png') \
            if path.exists(f'static/{self.symbol}.png') \
            else url_for('static', filename='coin.png')

    def __str__(self):
        return f'{self.symbol} {self.name} {self.url} {self.logo}'

    @staticmethod
    def get_coins():
        if Coin.coins is None:
            logger.debug('Loading coins')
            Coin.coins = {}
            try:
                backend = random.choice(BACKENDS)  # Choose a random backend
                coins_data = requests.get(backend + '/coins')
                coins_data.raise_for_status()  # Check if the request was successful
                for coin_data in coins_data.json():
                    coin = Coin(
                        coin_data['symbol'],
                        coin_data['name']
                    )
                    Coin.coins[coin.symbol] = coin
            except requests.RequestException as e:
                logger.error(f"Error loading coins: {e}")
        return Coin.coins

def create_cache():
    global total_charts, cache_building, current_coin, charts_rendered
    with cache_lock:
        if cache_building:
            logger.debug("Cache building is already in progress.")
            return
        cache_building = True

    try:
        with app.app_context():
            coins = Coin.get_coins()
            total_charts = len(coins)
            charts_rendered = 0  # Reset the rendered count
            logger.debug(f"Total coins to render: {total_charts}")
            coin_symbols = list(coins.keys())

            for symbol in coin_symbols:
                queue.put(symbol)

            while not queue.empty():
                symbol = queue.get()
                Trading.get_graph(symbol)
                queue.task_done()
    finally:
        with cache_lock:
            cache_building = False
            current_coin = ""
        logger.debug("Rendering completed.")

@app.route('/', methods=['GET'])
def home():
    coins = list(Coin.get_coins().values())
    coins.sort(key=lambda coin: coin.name)  # Sort coins by name
    with cache_lock:
        if not cache_building:
            Thread(target=create_cache).start()
    return render_template('index.html', coins=coins)

@app.route('/coin/<symbol>', methods=['GET'])
def get_coin(symbol):
    coin = Coin.get_coins()[symbol]
    plot = Trading.get_graph(symbol)
    return render_template('coin.html', coin=coin.name, symbol=coin.symbol, logo=coin.logo, tradings=plot)

@app.route('/cache_status', methods=['GET'])
def cache_status():
    return jsonify({
        'cache_building': cache_building,
        'total_charts': total_charts,
        'charts_rendered': charts_rendered,
        'current_coin': current_coin
    })

if __name__ == "__main__":
    logger.debug("Starting frontend")
    app.run(port=8080, debug=True)
