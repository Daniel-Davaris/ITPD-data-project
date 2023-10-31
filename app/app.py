from flask import Flask, render_template, request, redirect, send_from_directory
import matplotlib.pyplot as plt
import os
import uuid

app = Flask(__name__)

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
        exec(new_content)
    except Exception as e:
        print(f"Error executing code: {e}")
    
    return redirect('/')

@app.route('/graph')
def graph():
    img_name = str(uuid.uuid4()) + ".png"
    img_path = os.path.join("static", img_name)

    # Sample graph creation using matplotlib
    plt.figure(figsize=(6, 4))
    plt.plot([1, 2, 3, 4], [1, 4, 2, 3])
    plt.savefig(img_path)

    return send_from_directory("static", img_name)

if __name__ == '__main__':
    app.run(debug=True)
