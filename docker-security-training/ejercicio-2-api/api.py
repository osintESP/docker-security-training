from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return '<h1>Hola Seguro, desde Python!</h1>'

if __name__ == '__main__':
    # Flask por defecto escucha en 0.0.0.0:5000
    app.run(host='0.0.0.0', port=5000)