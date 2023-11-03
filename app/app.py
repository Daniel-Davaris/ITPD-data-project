import matplotlib
matplotlib.use('Agg')  # Use a non-GUI backend
should_stop = False

from flask import Flask, render_template, request, redirect, send_from_directory, jsonify
import matplotlib.pyplot as plt
import REC_reg_scraping
import os
import subprocess
from subprocess import Popen
from flask_cors import CORS
import pandas as pd
app = Flask(__name__)
CORS(app)
scraper_progress = 0

@app.route('/')
def home():
    with open("example.py", "r") as f:
        content = f.read()
    return render_template('index.html', content=content)


@app.route('/Object_studio')
def Object_studio():
    # with open("example.py", "r") as f:
    #     content = f.read()
    # return render_template('index.html', content=content)
    return render_template('object_studio.html')

@app.route('/ML_studio')
def ML_studio():
    # with open("example.py", "r") as f:
    #     content = f.read()
    # return render_template('index.html', content=content)
    return render_template('ML_studio.html')

@app.route('/Data_studio')
def Data_studio():
    # with open("example.py", "r") as f:
    #     content = f.read()
    # return render_template('index.html', content=content)
    return render_template('data_studio.html')

@app.route('/save', methods=['POST'])
def save():
    new_content = request.form['content']
    new_content = '\n'.join(line.strip() for line in new_content.split('\n')).strip()

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



@app.route('/run_python_code', methods=['POST'])
def run_python_code():
    global process
    open('progress.txt', 'w').close()
    try:
        payload = request.json
        num_threads = payload.get('numThreads', 50)
       
        process = subprocess.Popen(["python", "REC_reg_scraping.py", str(num_threads)])
        return jsonify({"status": "success"})
    except Exception as e:
        print(f"An error occurred: {e}")
        return jsonify({"status": "fail"})


@app.route('/stop_python_code', methods=['POST'])
def stop_python_code():
   
    global process

    if process:
        process.terminate()
    return jsonify({"status": "stopping"})

@app.route('/progress')
def progress():
    if os.stat("progress.txt").st_size != 0:
        with open('progress.txt', 'r') as f:
            scraper_progress = float(f.read())
        return jsonify({"progress": scraper_progress})
    elif process.poll() is not None:  # If the process has ended
        process.terminate()
        return jsonify({"progress": -1})
    else:
        return jsonify({"progress": 0})

@app.route('/list_pkl_files')
def list_pkl_files():
    pkl_files = [f for f in os.listdir('.') if f.endswith('.pkl')]
    return jsonify(pkl_files)


@app.route('/list_pkl_files/folder1')
def list_pkl_files_folder1():
    pkl_files = [f for f in os.listdir('folder1') if f.endswith('.pkl')]
    return jsonify(pkl_files)

@app.route('/list_pkl_files/folder2')
def list_pkl_files_folder2():
    pkl_files = [f for f in os.listdir('folder2') if f.endswith('.pkl')]
    return jsonify(pkl_files)

@app.route('/list_pkl_files/folder3')
def list_pkl_files_folder3():
    pkl_files = [f for f in os.listdir('folder3') if f.endswith('.pkl')]
    return jsonify(pkl_files)

@app.route('/read_or_create_py', methods=['POST'])
def read_or_create_py():
    filename = request.json['filename']


    if filename in os.listdir('folder1'):
        folder = 'folder1'
    elif filename in os.listdir('folder2'):
        folder = 'folder2'
    elif filename in os.listdir('folder3'):
        folder = 'folder3'
    else:
        folder = ''


    base = os.path.splitext(filename)[0]
    py_filename = f'{base}.py'
    py_filepath = os.path.join(folder, py_filename)

    if not os.path.exists(py_filepath):
        open(py_filepath, 'w').close()  # Create the .py file if it doesn't exist
    
    with open(py_filepath, 'r') as file:
        code_content = file.read()
    
    return jsonify({'codeContent': code_content})

@app.route('/save_and_run_code', methods=['POST'])
def save_and_run_code():
    filename = request.json['filename']


    if filename in os.listdir('folder1'):
        folder = 'folder1'
    elif filename in os.listdir('folder2'):
        folder = 'folder2'
    elif filename in os.listdir('folder3'):
        folder = 'folder3'
    else:
        folder = ''


    code_content = request.json['codeContent']
    base = os.path.splitext(filename)[0]
    py_filename = f'{base}.py'
    py_filepath = os.path.join(folder, py_filename)
    pkl_filepath = os.path.join(folder, filename)

    # Save the updated code content to the .py file
    with open(py_filepath, 'w') as file:
        file.write(code_content)

    # Execute the Python code
    namespace = {'source': pd.read_pickle(pkl_filepath)}
    exec(code_content, namespace)
    result_df = namespace.get('result')

    # Check if result is a dataframe and save it to a .pkl file
    if isinstance(result_df, pd.DataFrame):
        result_df.to_pickle(pkl_filepath)
        return jsonify({'status': 'success'})
    else:
        return jsonify({'status': 'fail', 'message': 'No result dataframe found'})

    
if __name__ == '__main__':
    app.run(debug=True)


