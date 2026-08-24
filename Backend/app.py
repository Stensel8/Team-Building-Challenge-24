from flask import Flask, jsonify, request
from crypto_coins import CryptoCoin
from os import getenv

# Only enable the Werkzeug debugger when explicitly asked for: it exposes an
# interactive console that allows arbitrary code execution.
DEBUG = getenv('FLASK_DEBUG', '0').lower() in ('1', 'true', 'yes')

# Create a Flask app
app = Flask(__name__)

@app.route('/', methods=['GET', 'POST'])
def version():
    if request.method == 'POST':
        return jsonify({'version': '$ax¢oin Backend version 0.2'})
    return "<h1>$ax¢oin Backend</h1><p>version 0.2</p>"

@app.route('/coins', methods=['GET'])
def get_coins():
    return CryptoCoin.get_coins_json()

@app.route('/coin/<code>', methods=['GET'])
def get_coin_info(code):
    return jsonify(CryptoCoin.get_coin_json(code))

@app.route('/trading/<code>', methods=['GET'])
def get_coin_trading(code):
    return jsonify(CryptoCoin.get_coin_trading_json(code))

if __name__ == "__main__":
    print("Starting backend")
    app.run(port=5000, debug=DEBUG)
