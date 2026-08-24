import logging
import random
from flask import Flask, send_from_directory
from os import getenv

# Setup logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def sanitize_for_log(message: str) -> str:
    """Strip CR/LF so user input can never forge extra log lines."""
    return message.replace('\r', '').replace('\n', ' ')

# Only enable the Werkzeug debugger when explicitly asked for: it exposes an
# interactive console that allows arbitrary code execution.
DEBUG = getenv('FLASK_DEBUG', '0').lower() in ('1', 'true', 'yes')

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
    logger.debug(sanitize_for_log(f'Serving file: {path}'))
    return send_from_directory(app.static_folder, path)

if __name__ == "__main__":
    logger.debug("Starting landing page server")
    app.run(port=8079, debug=DEBUG)
