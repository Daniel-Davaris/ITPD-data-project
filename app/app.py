import matplotlib
matplotlib.use('Agg')  # Use a non-GUI backend


from flask import Flask, render_template, request, redirect, send_from_directory
import matplotlib.pyplot as plt
import os

from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    with open("example.py", "r") as f:
        content = f.read()
    return render_template('index.html', content=content)

@app.route('/save', methods=['POST'])
def save():
    new_content = request.form['content']
    with open("example.py", "w") as f:
        f.write(new_content)

    # Execute the Python code and generate a graph
    try:
        namespace = {}
        exec(new_content, namespace)
        if 'plt' in namespace:
            namespace['plt'].savefig('static/latest_graph.png')
    except Exception as e:
        print(f"Error executing code: {e}")

    return {'status': 'success'}

@app.route('/graph')
def graph():
    return send_from_directory("static", "latest_graph.png")

if __name__ == '__main__':
    app.run(debug=True)
