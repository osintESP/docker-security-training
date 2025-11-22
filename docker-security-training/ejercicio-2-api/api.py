from flask import Flask
import socket # Importamos socket
app = Flask(__name__)

@app.route('/')
def hello():
    hostname = socket.gethostname() # Obtenemos el nombre del contenedor
    return f'<h1>Hola Seguro, desde {hostname}!</h1>' # Devolvemos el nombre

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)