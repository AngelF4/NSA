NASA ML Server — README
=========================

This repository exposes a Flask-based server (main file `nasa.py`) that trains a RandomForest classifier on a Kepler dataset and provides endpoints for predictions, dataset management, model info, and image generation for exoplanets.

Quick overview
--------------
- Server file: `nasa.py` (Flask app)
- Image helper: `imageGen.py` (provides `generate_image()` which saves images into `./exoplanets/`)
- Uploaded CSVs saved under `uploaded_csvs/` by default
- Generated planet images saved under `exoplanets/` by default

Requirements & setup
--------------------
1. Create and activate a virtual environment (recommended):

```bash
python3 -m venv venv
# Linux / macOS
source venv/bin/activate
# Windows PowerShell
venv\Scripts\Activate.ps1
```

2. Upgrade pip and install dependencies:

```bash
python -m pip install --upgrade pip setuptools wheel
python -m pip install -r requirements.txt
# or install single packages as needed, e.g.:
# python -m pip install flask pandas scikit-learn pillow requests python-dotenv
```

3. Environment variables (optional):
- `GEMINI_API_KEY` — if you want to enable GenAI endpoints (Gemini). Install google-genai and set key.
- `HF_TOKEN` or `HF_HUGGINGFACE_TOKEN` — HuggingFace token for `imageGen.generate_image()`.

Note: avoid installing packages globally on system Python on Linux (use venv or `--user`).
If you need to bind to port 80, either run with sudo preserving venv (see "Running") or use a systemd unit with `CAP_NET_BIND_SERVICE`.

Running the server
------------------
Development (non-root port):

```bash
# Edit nasa.py if you want to use a non-privileged port (e.g. 5000), or run as:
python nasa.py
# By default the script binds to 0.0.0.0:80 (requires elevated privileges)
```

If you must run on port 80 from an activated venv, preserve venv PATH and env when invoking sudo:

```bash
# from an activated venv
sudo env "PATH=$VIRTUAL_ENV/bin:$PATH" GEMINI_API_KEY="$GEMINI_API_KEY" python3 nasa.py
```

(Recommended for production): use a proper WSGI server (gunicorn) behind nginx, or create a `systemd` unit and grant `CAP_NET_BIND_SERVICE` to the process.

Important file locations and config
-----------------------------------
- Default CSV path used by training: `cfg['path']` → defaults to `<cwd>/kepler.csv`.
- Upload directory (server-saved CSVs): `uploaded_csvs/` (create automatically).
- Generated images directory: `exoplanets/` (created automatically by `generate_image`).
- Flask `MAX_CONTENT_LENGTH` is set to 100 MB to allow larger uploads; adjust reverse proxy limits separately.

Endpoints
---------
All endpoints are relative to the server base (e.g., `http://localhost` or your host/port).

1) GET /health
- Returns: {"status": "ok", "model_trained": true|false}
- Quick health check.

2) GET /model_info
- Returns the `model_info` object (accuracy, confusion_matrix, classification_report, n_features, n_samples, config).

3) GET /model_precision
- Returns structured precision metrics derived from `classification_report`:
  - per_class: { label: {precision, recall, f1-score, support} }
  - aggregates: other rows (e.g., macro avg, weighted avg) if present
  - accuracy: top-level accuracy

4) POST /config/hyperparams
- Body (JSON): {"numest": 200, "mxdepth": 10, "randstate": 101}
- Updates hyperparameters and retrains the model (synchronous).
- Returns: {"updated": {...}, "train": true/false, "model_info": {...}}

5) POST /config/path
- Body (JSON): {"path": "C:/data/kepler.csv"}
- Sets `cfg['path']` to a CSV file and retrains the model.

6) POST /upload_csv
- Two modes supported:
  a) multipart/form-data with a `file` field (legacy): form fields: file (required), path (optional), retrain (optional true/false)
  b) application/json mode: {"csv": "...csv content...", "filename": "kepler.csv", "retrain": true}
- The JSON `csv` field also accepts a list-of-dicts (converted to CSV) or a raw CSV string.
- Saves file into `uploaded_csvs/` by default and updates `cfg['path']`.

7) POST /upload_raw
- Accepts raw binary POST bodies (streamed) and saves them to `uploaded_csvs/`.
- Provide filename via header `X-Filename: kepler.csv` or query `?filename=kepler.csv` and optional `?retrain=1`.
- Use this for very large uploads to avoid JSON/multipart size issues.

8) GET /csvs
- Lists saved CSV filenames in the upload directory.
- Returns: {"csvs": ["kepler.csv", ...]}

9) POST /csvs/select
- Body (JSON): {"filename": "kepler.csv", "retrain": true}
- Sets `cfg['path']` to the chosen uploaded CSV (from upload_dir) and optionally retrains.

10) POST /csvs/select/<filename>
- Convenience: select an uploaded CSV by name in the URL. Query or JSON body may contain `retrain`.

11) GET /GeneralData
- Returns reduced per-planet view (GeneralData) for every processed row.
- Fields returned: kepid, kepler_name, kepoi_name, name, koi_steff, koi_disposition, koi_duration, koi_srad, koi_slogg, koi_model_snr, koi_depth, koi_period

12) GET /planet/kepoi/<kepoi_name>
- Case-insensitive lookup by `kepoi_name`.
- Returns: list of GeneralData entries for matching rows.

13) GET /predict/<kepid>
- Returns model prediction & probabilities for the given `kepid` (uses currently loaded dataset and trained model).
- Response: {"results": [ {kepid, kepler_name, kepoi_name, name, features..., "prediction": "...", "probabilities": {...} } ]}

14) POST /GeneratePlanetImage
- Body (JSON): provide either {"kepid": 123456} or {"kepoi_name": "K00001.01"}. Optional `prompt_extra` string to append creativity/style hints.
- The endpoint builds a descriptive prompt from the planet's GeneralData fields (star temperature, radius, transit depth, period, log g, disposition) and requests a photorealistic full-disc planet image with a deep black background.
- Calls `imageGen.generate_image(prompt, exoplanet_name=<kepoi_name>)` which saves the file to `exoplanets/<sanitized_kepoi_name>.png` (timestamp appended if file exists).
- Returns: {"path": "/full/path/to/exoplanets/K00001.01.png"} or error.

15) GET /ExoplanetImage/<kepoi_name>
- Serves the generated image file from `exoplanets/` for the given kepoi name.
- Example: GET /ExoplanetImage/K00001.01 returns the PNG image (or 404 JSON if not found).

16) GET /Gemini/ExplainGeneral
- Uses GenAI (Gemini) to explain the overall model_info in Spanish. Returns a large text explanation in Spanish divided into three sections (Overview, Key Details, Conclusion).
- Requires: google-genai SDK installed and valid `GEMINI_API_KEY` environment variable. If unavailable the endpoint returns a descriptive error.

17) GET /Gemini/ExplainSpecific/<kepoi_name>
- Uses GenAI to explain a single planet's GeneralData entry in Spanish (three sections). Optionally includes model prediction if the model is trained.
- Same SDK & API key requirements as above.

Notes, limitations, and tips
---------------------------
- model training in `train_model()` runs synchronously and blocks the request that triggers it. For large datasets or production use, move training to a background worker or job queue and provide a status endpoint.
- GenAI endpoints are guarded: they return a clear error if `google-genai` is not installed or `GEMINI_API_KEY` is not set.
- Image generation requires a valid HuggingFace inference token (set `HF_TOKEN` or pass token to `generate_image()` in code). The image generation uses an external inference endpoint — check rate limits and costs.
- For large file uploads behind a reverse proxy (nginx, etc.) ensure the proxy's max body size is increased to match `MAX_CONTENT_LENGTH` (100 MB by default).
- The Flask dev server is used here for convenience. For production use a WSGI server (gunicorn/uvicorn) and let nginx serve static files (`exoplanets/`) directly.

Examples
--------
- Generate an image for kepoi_name K00001.01 (using curl):

```bash
curl -X POST -H "Content-Type: application/json" -d '{"kepoi_name":"K00001.01"}' http://localhost/GeneratePlanetImage
```

- Fetch the generated image:

```bash
curl http://localhost/ExoplanetImage/K00001.01 --output koi-K00001.01.png
```

- Upload a CSV (JSON mode):

```bash
curl -X POST -H "Content-Type: application/json" -d @mycsv.json http://localhost/upload_csv
# where mycsv.json contains: {"csv":"<csv text here>", "filename":"kepler_new.csv","retrain":true}
```

- Get model precision:

```bash
curl http://localhost/model_precision
```

Support & next steps
--------------------
- Want the GeneratePlanetImage endpoint asynchronous (queued) so it returns immediately and the image is generated in background? I can add a simple background thread or integrate with Redis/RQ.
- Want authentication on endpoints? I can add a token-based header check (simple API key) or integrate OAuth/JWT.

If you'd like, I can also:
- Add example Postman requests collection
- Add a small systemd unit file for production deployment
- Add a background worker for image generation and training

---
README generated on: 2025-10-05
