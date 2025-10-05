"""NASA ML server

This file was converted from a Colab script into a Flask-based server that
trains a RandomForest classifier on the Kepler dataset and exposes endpoints to:
- get prediction for a specific `kepid`
- return all planets information (processed)
- update hyperparameters (numest, mxdepth, randstate)
- update CSV path

Run: python nasa.py  (server binds 0.0.0.0:80)
"""

from flask import Flask, request, jsonify, send_from_directory
from werkzeug.utils import secure_filename
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report
import joblib
import threading
import json
import os
from dotenv import load_dotenv
from typing import Optional

# Load environment variables from .env (if present) early
load_dotenv()

from imageGen import generate_image


# --- optional Google GenAI client ---
genai_client = None
try:
    from google import genai
    api_key = os.getenv('GEMINI_API_KEY')
    if api_key:
        # Prefer explicit API key provided via environment
        genai_client = genai.Client(api_key=api_key)
    else:
        # Do not attempt to instantiate the client without an explicit key here.
        # Some versions of the SDK may attempt auth flows that can raise during import.
        genai_client = None
except Exception as e:
    # Log the import/initialization error to help debugging on servers like EC2
    print("GenAI client import/init failed:", repr(e))
    genai_client = None

app = Flask(__name__)
# Allow larger uploads (e.g. 100 MB). This increases the maximum request body size Flask/Werkzeug will accept.
# If you run behind a reverse proxy (nginx, IIS, etc.) you must also increase its limit there.
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 100 MB

# Default configuration
config_lock = threading.Lock()
cfg = {
    "path": os.path.join(os.getcwd(), "kepler.csv"),
    "numest": 100,
    "mxdepth": 100,
    "randstate": 42,
    # Directory where uploaded CSVs (via API) are stored
    "upload_dir": os.path.join(os.getcwd(), "uploaded_csvs"),
}

# Globals for data and model
model = None
scaler = None
df_processed = None
X_columns = None
model_info = {}

# Ensure upload directory exists
os.makedirs(cfg['upload_dir'], exist_ok=True)

# Columns to drop (same as original script)
COLUMNS_TO_DROP = [
    'kepid', 'kepoi_name', 'kepler_name', 'koi_disposition', 'koi_pdisposition',
    'koi_score', 'koi_comment', 'koi_vet_stat', 'koi_vet_date', 'koi_disp_prov',
    'koi_fittype', 'koi_parm_prov', 'koi_limbdark_mod', 'koi_trans_mod',
    'koi_datalink_dvr', 'koi_datalink_dvs', 'koi_tce_delivname', 'koi_sparprov'
]


def load_csv(path):
    """Load CSV and apply initial filtering used for binary classification."""
    df = pd.read_csv(path)
    # Keep only CONFIRMED and FALSE POSITIVE rows for binary classification
    df = df[df['koi_disposition'].isin(['CONFIRMED', 'FALSE POSITIVE'])]
    return df


def preprocess(df):
    """Return X (numeric features) and y (target) and the processed df."""
    y = df['koi_disposition']
    X = df.drop(columns=COLUMNS_TO_DROP, errors='ignore').select_dtypes(include=np.number)
    X = X.copy()
    # Fill missing values with column mean
    X.fillna(X.mean(), inplace=True)
    return X, y, df


def train_model():
    """Train the RandomForest model with current configuration.

    Updates globals: model, scaler, X_columns, df_processed, model_info
    """
    global model, scaler, X_columns, df_processed, model_info
    with config_lock:
        path = cfg['path']
        numest = int(cfg['numest'])
        mxdepth = None if cfg['mxdepth'] in [None, 0] else int(cfg['mxdepth'])
        randstate = int(cfg['randstate'])

    if not os.path.exists(path):
        model_info = {"error": f"CSV file not found at path: {path}"}
        return False

    try:
        df = load_csv(path)
        X, y, df_proc = preprocess(df)

        # Train/test split
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=randstate, stratify=y
        )

        # Scale
        scl = StandardScaler()
        X_train_scaled = scl.fit_transform(X_train)
        X_test_scaled = scl.transform(X_test)

        clf = RandomForestClassifier(n_estimators=numest, max_depth=mxdepth, random_state=randstate, n_jobs=-1)
        clf.fit(X_train_scaled, y_train)

        # Evaluate
        y_pred = clf.predict(X_test_scaled)
        acc = accuracy_score(y_test, y_pred)
        conf = confusion_matrix(y_test, y_pred).tolist()
        class_rep = classification_report(y_test, y_pred, output_dict=True)

        # Update globals
        model = clf
        scaler = scl
        X_columns = X.columns
        df_processed = df_proc
        model_info = {
            "accuracy": acc,
            "confusion_matrix": conf,
            "classification_report": class_rep,
            "n_features": len(X_columns),
            "n_samples": len(df_proc),
            "config": cfg.copy()
        }
        return True
    except Exception as e:
        model_info = {"error": str(e)}
        return False


def predict_by_kepid(kepid):
    """Return prediction and probabilities for a kepid. If multiple rows exist, returns all."""
    if model is None or scaler is None or df_processed is None:
        return {"error": "Model not trained"}

    obs = df_processed[df_processed['kepid'] == kepid]
    if obs.empty:
        return {"error": f"No observation found with kepid: {kepid}"}

    features = obs[X_columns]
    feat_scaled = scaler.transform(features)
    preds = model.predict(feat_scaled)
    probs = model.predict_proba(feat_scaled)
    classes = model.classes_

    results = []
    for i in range(len(preds)):
        prob_map = {str(classes[j]): float(probs[i][j]) for j in range(len(classes))}
        results.append({
            "kepid": int(obs.iloc[i]['kepid']) if pd.notnull(obs.iloc[i]['kepid']) else None,
            "kepler_name": str(obs.iloc[i]['kepler_name']) if pd.notnull(obs.iloc[i]['kepler_name']) else None,
            "kepoi_name": str(obs.iloc[i]['kepoi_name']) if pd.notnull(obs.iloc[i]['kepoi_name']) else None,
            "name": str(obs.iloc[i]['kepler_name']) if pd.notnull(obs.iloc[i]['kepler_name']) and obs.iloc[i]['kepler_name'] not in (None, '') else str(obs.iloc[i]['kepoi_name']) if pd.notnull(obs.iloc[i]['kepoi_name']) else None,
            "koi_steff": float(obs.iloc[i]['koi_steff']) if pd.notnull(obs.iloc[i]['koi_steff']) else None,
            "koi_disposition": str(obs.iloc[i]['koi_disposition']) if pd.notnull(obs.iloc[i]['koi_disposition']) else None,
            "koi_duration": float(obs.iloc[i]['koi_duration']) if pd.notnull(obs.iloc[i]['koi_duration']) else None,
            "koi_srad": float(obs.iloc[i]['koi_srad']) if pd.notnull(obs.iloc[i]['koi_srad']) else None,
            "koi_slogg": float(obs.iloc[i]['koi_slogg']) if pd.notnull(obs.iloc[i]['koi_slogg']) else None,
            "koi_model_snr": float(obs.iloc[i]['koi_model_snr']) if pd.notnull(obs.iloc[i]['koi_model_snr']) else None,
            "koi_depth": float(obs.iloc[i]['koi_depth']) if pd.notnull(obs.iloc[i]['koi_depth']) else None,
            "koi_period": float(obs.iloc[i]['koi_period']) if pd.notnull(obs.iloc[i]['koi_period']) else None,
            "prediction": str(preds[i]),
            "probabilities": prob_map
        })
    return {"results": results}


def row_to_general_entry(row):
    """Convert a DataFrame row (Series) to the GeneralData JSON-friendly dict."""
    def safe_str(col):
        if col in row and pd.notnull(row[col]):
            return str(row[col])
        return None

    def safe_num(col):
        if col in row and pd.notnull(row[col]):
            v = row[col]
            if isinstance(v, (np.integer,)):
                return int(v)
            try:
                return float(v)
            except Exception:
                return None
        return None

    def safe_id(col):
        if col in row and pd.notnull(row[col]):
            try:
                v = row[col]
                if isinstance(v, (np.integer,)):
                    return int(v)
                fv = float(v)
                if fv.is_integer():
                    return int(fv)
                return int(fv)
            except Exception:
                return None
        return None

    kepler_name = safe_str('kepler_name')
    kepoi_name = safe_str('kepoi_name')
    name = kepler_name if kepler_name not in (None, '') else kepoi_name

    return {
        'kepid': safe_id('kepid'),
        'kepler_name': kepler_name,
        'kepoi_name': kepoi_name,
        'name': name,
        'koi_steff': safe_num('koi_steff'),
        'koi_disposition': safe_str('koi_disposition'),
        'koi_duration': safe_num('koi_duration'),
        'koi_srad': safe_num('koi_srad'),
        'koi_slogg': safe_num('koi_slogg'),
        'koi_model_snr': safe_num('koi_model_snr'),
        'koi_depth': safe_num('koi_depth'),
        'koi_period': safe_num('koi_period')
    }


def call_genai_and_get_text(prompt: str):
    """Call the GenAI API and return the response text. Returns (text, error).

    If genai_client is not available, returns (None, error_message).
    """
    if genai_client is None:
        return None, "GenAI client not available. Set GEMINI_API_KEY and install google-genai SDK."

    try:
        response = genai_client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt
        )
        # response.text contains the generated text
        return getattr(response, 'text', None), None
    except Exception as e:
        return None, str(e)


def build_general_prompt(model_info: dict):
    """Create a Spanish prompt asking Gemini to explain the overall model results."""
    acc = model_info.get('accuracy') if isinstance(model_info, dict) else None
    n_features = model_info.get('n_features') if isinstance(model_info, dict) else None
    n_samples = model_info.get('n_samples') if isinstance(model_info, dict) else None
    gist = json.dumps(model_info, default=str, indent=2)

    prompt = f"""
                Eres un comunicador científico experto. Explica de forma corta pero sencilla los resultados de un modelo de clasificación entrenado con datos de Kepler.

                Datos resumidos del modelo:
                - Accuracy: {acc}
                - Número de características: {n_features}
                - Número de muestras: {n_samples}

                También incluye este resumen técnico (no muy largo): {gist}

                Por favor, responde en español y entrega una explicación corta pero simple dividida en estas tres secciones claramente marcadas:
                1) Overview
                2) Key Details
                3) Conclusion

                Cada sección debe desarrollarse en profundidad sin usar jerga técnica innecesaria. Solo devuelve esas tres secciones y nada más.
                No te despegues de estos datos, no inventes nada.
            """
    return prompt


def build_specific_prompt(entry: dict, prediction: Optional[dict] = None):
    """Create a Spanish prompt for a single planet using its GeneralData entry and optional prediction info."""
    entry_json = json.dumps(entry, default=str, indent=2, ensure_ascii=False)
    pred_json = json.dumps(prediction, default=str, indent=2, ensure_ascii=False) if prediction else "Sin predicción disponible"

    prompt = f"""
                Eres un comunicador científico experto. Explica de forma larga pero sencilla la información sobre este candidato a exoplaneta y, si existe, la predicción del modelo.

                Datos del objeto:
                {entry_json}

                Predicción del modelo:
                {pred_json}

                Por favor, responde en español y entrega una explicación larga pero simple dividida en estas tres secciones claramente marcadas:
                1) Overview
                2) Key Details
                3) Conclusion

                Cada sección debe desarrollarse en profundidad sin usar jerga técnica innecesaria. Solo devuelve esas tres secciones y nada más.
                No te despegues de estos datos, no inventes nada.
            """
    return prompt


@app.route('/predict/<int:kepid>', methods=['GET'])
def api_predict(kepid):
    """Predict endpoint: returns prediction for a kepid."""
    res = predict_by_kepid(kepid)
    return jsonify(res)


@app.route('/planets', methods=['GET'])
def api_planets():
    """Return all processed planets (as JSON records)."""
    if df_processed is None:
        return jsonify({"error": "Data not loaded / model not trained"}), 400
    # Convert to records; ensure serializable types
    records = df_processed.to_dict(orient='records')
    return jsonify(records)


@app.route('/config/hyperparams', methods=['POST'])
def api_set_hyperparams():
    """Update numest, mxdepth, randstate and retrain the model.

    JSON body example: {"numest":200, "mxdepth":10, "randstate":101}
    """
    body = request.get_json(force=True)
    updated = {}
    with config_lock:
        for k in ('numest', 'mxdepth', 'randstate'):
            if k in body:
                cfg[k] = body[k]
                updated[k] = body[k]

    ok = train_model()
    if not ok:
        return jsonify({"updated": updated, "train": False, "model_info": model_info}), 500
    return jsonify({"updated": updated, "train": True, "model_info": model_info})


@app.route('/config/path', methods=['POST'])
def api_set_path():
    """Update CSV path and retrain.

    JSON body example: {"path": "C:/data/kepler.csv"}
    """
    body = request.get_json(force=True)
    if 'path' not in body:
        return jsonify({"error": "Missing 'path' in body"}), 400

    with config_lock:
        cfg['path'] = body['path']

    ok = train_model()
    if not ok:
        return jsonify({"path": cfg['path'], "train": False, "model_info": model_info}), 500
    return jsonify({"path": cfg['path'], "train": True, "model_info": model_info})


@app.route('/upload_csv', methods=['POST'])
def api_upload_csv():
    """Receive a CSV file via multipart/form-data and save it.

    Form fields:
    - file: the uploaded file (required)
    - path: optional destination path (string). If omitted, uses configured path.
    - retrain: optional ('1'/'true') to trigger retraining after save.
    """
    # Support two modes:
    # 1) multipart/form-data with a file field named 'file' (legacy)
    # 2) application/json with {"csv": "...csv content...", "filename": "kepler.csv", "retrain": true}

    retrain_flag = False
    dest_path = None

    # JSON mode
    if request.is_json:
        body = request.get_json()
        if 'csv' not in body:
            return jsonify({"error": "Missing 'csv' field in JSON body"}), 400
        csv_content = body['csv']
        filename = body.get('filename') or f"kepler_{int(threading.get_ident())}.csv"
        filename = secure_filename(filename)
        retrain_flag = bool(body.get('retrain', False))

        # Normalize csv_content to a CSV string if it's not already a string
        try:
            if isinstance(csv_content, (list, dict)):
                # If it's a list of dicts (ConvertFrom-Csv in PowerShell), convert to CSV via pandas
                try:
                    df_tmp = pd.DataFrame(csv_content)
                    csv_text = df_tmp.to_csv(index=False)
                except Exception:
                    # Fallback: join list items or dump dict
                    if isinstance(csv_content, list):
                        csv_text = '\n'.join(str(x) for x in csv_content)
                    else:
                        csv_text = json.dumps(csv_content)
            else:
                # Ensure we have a string
                csv_text = str(csv_content)
        except Exception as e:
            return jsonify({"error": f"Failed to normalize csv content: {e}"}), 400

        # Save under upload_dir
        dest_path = os.path.join(cfg['upload_dir'], filename)
        try:
            with open(dest_path, 'w', encoding='utf-8') as f:
                f.write(csv_text)
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    else:
        # multipart/form-data mode
        if 'file' not in request.files:
            return jsonify({"error": "No file part in the request (field name must be 'file')"}), 400

        file = request.files['file']
        if file.filename == '':
            return jsonify({"error": "No selected file"}), 400

        form_path = request.form.get('path')
        retrain_flag = str(request.form.get('retrain', '')).lower() in ('1', 'true', 'yes')

        with config_lock:
            dest = form_path or cfg.get('path')

        try:
            if os.path.isdir(dest) or dest.endswith(os.path.sep):
                filename = secure_filename(file.filename)
                os.makedirs(dest, exist_ok=True)
                dest_path = os.path.join(dest, filename)
            else:
                dest_dir = os.path.dirname(dest) or os.getcwd()
                os.makedirs(dest_dir, exist_ok=True)
                dest_path = dest

            file.save(dest_path)
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    # Update configured path to the newly saved file (chosen CSV)
    with config_lock:
        cfg['path'] = dest_path

    response = {"saved": dest_path}
    if retrain_flag:
        ok = train_model()
        response['retrain'] = ok
        response['model_info'] = model_info

    return jsonify(response)


@app.route('/upload_raw', methods=['POST'])
def api_upload_raw():
    """Accept a raw binary POST body (streamed) and save it as a CSV file.

    Clients should send the filename in header `X-Filename` or as query param `?filename=`.
    Optionally include `?retrain=1` to retrain after saving.

    Example (curl):
      curl.exe -X POST --data-binary @C:\path\to\kepler.csv -H "X-Filename: kepler.csv" "http://localhost/upload_raw?retrain=1"
    """
    filename = request.headers.get('X-Filename') or request.args.get('filename')
    if not filename:
        return jsonify({"error": "Missing filename. Provide X-Filename header or ?filename query parameter."}), 400

    filename = secure_filename(filename)
    dest_path = os.path.join(cfg['upload_dir'], filename)

    try:
        # Stream write to avoid loading whole body into memory
        with open(dest_path, 'wb') as f:
            chunk_size = 64 * 1024
            while True:
                chunk = request.stream.read(chunk_size)
                if not chunk:
                    break
                # request.stream.read returns bytes in binary POST
                if isinstance(chunk, str):
                    # convert to bytes
                    chunk = chunk.encode('utf-8')
                f.write(chunk)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

    # Update configured path
    with config_lock:
        cfg['path'] = dest_path

    response = {"saved": dest_path}
    retrain_q = request.args.get('retrain')
    retrain_flag = str(retrain_q).lower() in ('1', 'true', 'yes') if retrain_q is not None else False
    if retrain_flag:
        ok = train_model()
        response['retrain'] = ok
        response['model_info'] = model_info

    return jsonify(response)


@app.route('/model_info', methods=['GET'])
def api_model_info():
    return jsonify(model_info)


@app.route('/model_precision', methods=['GET'])
def api_model_precision():
    """Return precision metrics for the trained model.

    Returns per-class precision and aggregate metrics (macro/weighted) when available.
    """
    if not model_info:
        return jsonify({"error": "Model info not available. Train or upload dataset first."}), 400

    cr = model_info.get('classification_report')
    if not isinstance(cr, dict):
        return jsonify({"error": "Classification report not available in model_info."}), 400

    per_class = {}
    aggregates = {}
    # classification_report typically contains entries per class and 'macro avg', 'weighted avg', 'accuracy'
    for k, v in cr.items():
        # skip accuracy which is a float sometimes
        try:
            if isinstance(v, dict) and 'precision' in v:
                per_class[k] = {
                    'precision': float(v.get('precision')) if v.get('precision') is not None else None,
                    'recall': float(v.get('recall')) if v.get('recall') is not None else None,
                    'f1-score': float(v.get('f1-score')) if v.get('f1-score') is not None else None,
                    'support': int(v.get('support')) if v.get('support') is not None else None
                }
            else:
                # non-class aggregates (e.g., accuracy float)
                aggregates[k] = v
        except Exception:
            # best-effort conversion fallback
            per_class[k] = v

    # Try to pull accuracy if present at top-level of model_info
    accuracy = model_info.get('accuracy')

    response = {
        'per_class': per_class,
        'aggregates': aggregates,
        'accuracy': float(accuracy) if accuracy is not None else model_info.get('accuracy')
    }
    return jsonify(response)


@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "model_trained": model is not None})


@app.route('/GeneralData', methods=['GET'])
def api_general_data():
    """Return a reduced view of the planets data as described by the spec.

    Fields returned per planet:
      - kepler_name (string or null)
      - kepoi_name (string)
      - name (kepler_name if present else kepoi_name)
      - koi_steff (float or int or null)
      - koi_disposition (string)
      - koi_duration (float or null)
      - koi_srad (float or null)
      - koi_slogg (float or null)
      - koi_model_snr (float or null)
      - koi_depth (float or null)
      - koi_period (float or null)
    """
    if df_processed is None:
        return jsonify({"error": "Data not loaded / model not trained"}), 400

    # Use helper to convert each row to the GeneralData shape
    out = [row_to_general_entry(row) for _, row in df_processed.iterrows()]
    return jsonify(out)


@app.route('/planet/kepoi/<path:kepoi_name>', methods=['GET'])
def api_planet_by_kepoi(kepoi_name):
    """Look up planet(s) by kepoi_name (case-insensitive).

    Returns a list of matching full records from the processed dataframe.
    """
    if df_processed is None:
        return jsonify({"error": "Data not loaded / model not trained"}), 400

    key = str(kepoi_name).strip().upper()
    # Compare case-insensitively, safely converting to str
    try:
        mask = df_processed['kepoi_name'].astype(str).str.strip().str.upper() == key
        matches = df_processed[mask]
    except Exception:
        # Fallback to exact match
        matches = df_processed[df_processed['kepoi_name'] == kepoi_name]

    if matches.empty:
        return jsonify({"error": f"No planet found with kepoi_name: {kepoi_name}"}), 404

    out = [row_to_general_entry(row) for _, row in matches.iterrows()]
    return jsonify(out)


@app.route('/csvs', methods=['GET'])
def api_list_csvs():
    """List CSV files saved in the server upload directory."""
    upload_dir = cfg.get('upload_dir')
    try:
        files = [f for f in os.listdir(upload_dir) if os.path.isfile(os.path.join(upload_dir, f)) and f.lower().endswith('.csv')]
        return jsonify({"csvs": files})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/csvs/select', methods=['POST'])
def api_select_csv():
    """Select a CSV filename (from upload_dir) as the current dataset and retrain.

    JSON body: {"filename": "kepler.csv", "retrain": true}
    """
    body = request.get_json(force=True)
    if 'filename' not in body:
        return jsonify({"error": "Missing 'filename' in body"}), 400
    filename = secure_filename(body['filename'])
    upload_dir = cfg.get('upload_dir')
    src = os.path.join(upload_dir, filename)
    if not os.path.exists(src):
        return jsonify({"error": f"File not found: {filename}"}), 404

    with config_lock:
        cfg['path'] = src

    retrain_flag = bool(body.get('retrain', False))
    response = {"selected": src}
    if retrain_flag:
        ok = train_model()
        response['retrain'] = ok
        response['model_info'] = model_info

    return jsonify(response)


@app.route('/csvs/select/<path:filename>', methods=['POST'])
def api_select_csv_by_name(filename):
    """Convenience endpoint: select an uploaded CSV by name (from upload_dir) as current and optionally retrain.

    Query param: retrain=1 or retrain=true to trigger retrain. Also accepts JSON body {"retrain": true}.
    """
    upload_dir = cfg.get('upload_dir')
    safe_name = secure_filename(filename)
    src = os.path.join(upload_dir, safe_name)
    if not os.path.exists(src):
        return jsonify({"error": f"File not found: {filename}"}), 404

    with config_lock:
        cfg['path'] = src

    # determine retrain flag: prefer query param, else JSON body
    retrain_flag = False
    q = request.args.get('retrain')
    if q is not None:
        retrain_flag = str(q).lower() in ('1', 'true', 'yes')
    else:
        if request.is_json:
            retrain_flag = bool(request.get_json().get('retrain', False))

    response = {"selected": src}
    if retrain_flag:
        ok = train_model()
        response['retrain'] = ok
        response['model_info'] = model_info

    return jsonify(response)


@app.route('/Gemini/ExplainGeneral', methods=['GET'])
def api_gemini_explain_general():
    """Ask Gemini to explain the overall model_info in Spanish with three sections."""
    if not model_info:
        return jsonify({"error": "Model info not available. Train or upload dataset first."}), 400

    prompt = build_general_prompt(model_info)
    text, err = call_genai_and_get_text(prompt)
    if err:
        print("GenAI Api Key:", os.getenv('GEMINI_API_KEY'))
        return jsonify({"error": err}), 500
    return jsonify({"explanation": text})


@app.route('/Gemini/ExplainSpecific/<path:kepoi_name>', methods=['GET'])
def api_gemini_explain_specific(kepoi_name):
    """Ask Gemini to explain a specific planet (by kepoi_name) in Spanish with three sections."""
    if df_processed is None:
        return jsonify({"error": "Data not loaded / model not trained"}), 400

    key = str(kepoi_name).strip().upper()
    try:
        mask = df_processed['kepoi_name'].astype(str).str.strip().str.upper() == key
        matches = df_processed[mask]
    except Exception:
        matches = df_processed[df_processed['kepoi_name'] == kepoi_name]

    if matches.empty:
        return jsonify({"error": f"No planet found with kepoi_name: {kepoi_name}"}), 404

    # Use the first match for the specific explanation
    first = matches.iloc[0]
    entry = row_to_general_entry(first)

    # Optionally include model prediction if available: try to predict using model
    prediction = None
    if model is not None and scaler is not None and X_columns is not None:
        try:
            features = first[X_columns]
            feat_scaled = scaler.transform([features])[0].reshape(1, -1)
            pred = model.predict(feat_scaled)[0]
            probs = model.predict_proba(feat_scaled)[0]
            classes = model.classes_
            prob_map = {str(classes[j]): float(probs[j]) for j in range(len(classes))}
            prediction = {"prediction": str(pred), "probabilities": prob_map}
        except Exception:
            prediction = None

    prompt = build_specific_prompt(entry, prediction)
    text, err = call_genai_and_get_text(prompt)
    if err:
        print("GenAI Api Key:", os.getenv('GEMINI_API_KEY'))
        return jsonify({"error": err}), 500
    return jsonify({"explanation": text})


@app.route('/GeneratePlanetImage', methods=['POST'])
def api_generate_planet_image():
    """Generate an image for a specific planet using model-derived data.

    JSON body should include either:
      - {"kepid": 123456}
    or
      - {"kepoi_name": "K00001.01"}

    Optional: {"prompt_extra": "..."} to append creative instructions.
    """
    if df_processed is None:
        return jsonify({"error": "Data not loaded / model not trained"}), 400

    body = request.get_json(force=True)
    kepid = body.get('kepid')
    kepoi_name = body.get('kepoi_name')

    # Find the planet row
    matches = None
    if kepid is not None:
        try:
            kepid = int(kepid)
        except Exception:
            return jsonify({"error": "Invalid kepid"}), 400
        matches = df_processed[df_processed['kepid'] == kepid]
    elif kepoi_name:
        key = str(kepoi_name).strip().upper()
        try:
            mask = df_processed['kepoi_name'].astype(str).str.strip().str.upper() == key
            matches = df_processed[mask]
        except Exception:
            matches = df_processed[df_processed['kepoi_name'] == kepoi_name]
    else:
        return jsonify({"error": "Provide 'kepid' or 'kepoi_name' in body"}), 400

    if matches is None or matches.empty:
        return jsonify({"error": "No matching planet found"}), 404

    row = matches.iloc[0]
    entry = row_to_general_entry(row)

    # Build a descriptive prompt from available fields
    parts = []
    parts.append("Photorealistic full-disc rendering of an exoplanet, centered in frame, whole planet visible (not a surface close-up).")
    parts.append("Background: deep black space, subtle distant stars, no text or UI elements.")
    parts.append("Lighting: cinematic, realistic star lighting with soft atmospheric scattering on the limb.")
    parts.append("Style: high detail, high resolution, realistic planetary textures, natural color palette, no signatures or watermarks.")

    # Include known properties in the visual description
    if entry.get('koi_srad') is not None:
        parts.append(f"Apparent host star radius (relative units): approximately {entry['koi_srad']}; adjust star brightness accordingly.")
    if entry.get('koi_steff') is not None:
        parts.append(f"Host star effective temperature: {entry['koi_steff']} K; choose star color and lighting consistent with this temperature.")
    if entry.get('koi_depth') is not None:
        parts.append(f"Transit depth indicator: {entry['koi_depth']} (use to suggest the planet's relative size vs star).")
    if entry.get('koi_period') is not None:
        parts.append(f"Orbital period: {entry['koi_period']} days (can suggest proximity to host and atmospheric appearance).")
    if entry.get('koi_slogg') is not None:
        parts.append(f"Surface gravity proxy (log g): {entry['koi_slogg']}; influence cloud cover and atmospheric thickness accordingly.")

    # Add disposition if useful
    if entry.get('koi_disposition'):
        parts.append(f"Disposition: {entry['koi_disposition']}. Render as a plausible planet consistent with this label.")

    # Allow user-provided creative tail
    extra = body.get('prompt_extra')
    if extra:
        parts.append(str(extra))

    # Encourage full-planet framing and black background explicitly
    parts.append("Focus on the whole spherical planet centered in the image; black background; do not include spacecraft, people, or UI; produce a single PNG image.")

    prompt = ' '.join(parts)

    # Name to save
    save_name = None
    if entry.get('kepoi_name'):
        save_name = entry['kepoi_name']
    elif entry.get('name'):
        save_name = entry['name']
    else:
        save_name = f"planet_{int(time.time())}"

    # Call the image generator
    gen_res = generate_image(prompt, exoplanet_name=save_name)
    if not gen_res.get('ok'):
        return jsonify({"error": gen_res.get('error'), "details": gen_res.get('details', None)}), 500

    return jsonify({"path": gen_res.get('path')})


@app.route('/ExoplanetImage/<path:kepoi_name>', methods=['GET'])
def api_get_exoplanet_image(kepoi_name):
    """Serve the generated image for a given kepoi_name from the ./exoplanets folder.

    Example: GET /ExoplanetImage/K00001.01
    """
    exo_dir = os.path.join(os.getcwd(), 'exoplanets')
    if not os.path.isdir(exo_dir):
        return jsonify({"error": "No exoplanets directory found"}), 404

    safe = secure_filename(kepoi_name)
    # Try common extensions, prefer .png
    candidates = [f"{safe}.png", f"{safe}.jpg", f"{safe}.jpeg", safe]
    for fname in candidates:
        fpath = os.path.join(exo_dir, fname)
        if os.path.exists(fpath) and os.path.isfile(fpath):
            # send_from_directory will set correct headers
            return send_from_directory(exo_dir, fname)

    # Also attempt case-insensitive or prefix match as a fallback
    for entry in os.listdir(exo_dir):
        if entry.lower().startswith(safe.lower()):
            return send_from_directory(exo_dir, entry)

    return jsonify({"error": f"Image not found for {kepoi_name}"}), 404


if __name__ == '__main__':
    # Train model at startup (best effort)
    trained = train_model()
    if trained:
        print("Model trained on startup.")
    else:
        print("Model training failed on startup:", model_info)

    if genai_client:
        print("GenAI client initialized.")
    else:
        print("GenAI client not available. Set GEMINI_API_KEY and install google-genai SDK to enable.")

    # Bind to 0.0.0.0:80 as requested
    # Note: on many systems binding to port 80 requires elevated privileges.
    app.run(host='0.0.0.0', port=80)