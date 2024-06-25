import logging
import random
from flask import Flask, send_from_directory
from os import getenv

# Setup logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__, static_folder='landingpage', static_url_path='')

# Get the backend servers from environment variables and split them into a list
BACKENDS = getenv('SAXCOIN_BACKENDS', 'http://192.168.30.120:5000,http://192.168.30.125:5000,http://192.168.30.130:5000').split(',')
logger.debug(f'Backends={BACKENDS}')

def get_backend_url():
    """Return a random backend URL from the list of BACKENDS."""
    return random.choice(BACKENDS)

@app.route('/')
def serve_index():
    logger.debug('Serving index.html')
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/<path:path>')
def serve_file_in_dir(path):
    logger.debug(f'Serving file: {path}')
    return send_from_directory(app.static_folder, path)

if __name__ == "__main__":
    logger.debug("Starting landing page server")
    app.run(port=8079, debug=True)
