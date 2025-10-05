import os
import requests
import io
from PIL import Image
import json
import time
from typing import Optional, Dict, Any

# --- Configuration ---
# Default HF inference API (change if you host your own endpoint)
API_URL = "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0"

# By default read the token from environment variable 'HF_TOKEN' or 'HF_HUGGINGFACE_TOKEN'
# It's safer to set this in your shell or systemd unit than hard-coding it.
DEFAULT_HF_TOKEN = os.getenv('HF_TOKEN') or os.getenv('HF_HUGGINGFACE_TOKEN')


def _detect_content_type_and_return(response: requests.Response):
    content_type = response.headers.get('content-type', '')
    if 'text/plain' in content_type:
        return {"error": "Plain text error from API", "details": response.text}
    if 'application/json' in content_type:
        try:
            return response.json()
        except Exception:
            return {"error": "Invalid JSON from API", "details": response.text}
    if 'image' in content_type or response.status_code == 200:
        return response.content
    return {"error": f"Unexpected content type: {content_type}", "details": response.text}


def _sanitize_name(name: str) -> str:
    # Keep safe characters for filenames: alnum, dash, underscore, dot
    import re
    s = str(name).strip()
    # replace spaces with underscore
    s = s.replace(' ', '_')
    # remove any path separators or suspicious chars
    s = re.sub(r'[^A-Za-z0-9._-]', '', s)
    # avoid empty
    return s or 'image'


def generate_image(prompt: str,
                   api_url: str = API_URL,
                   hf_token: Optional[str] = None,
                   output_path: Optional[str] = None,
                   exoplanet_name: Optional[str] = None,
                   wait_for_model: bool = True,
                   return_bytes: bool = False,
                   timeout: int = 120) -> Dict[str, Any]:
    """Generate an image using the HF Inference API.

    Args:
      prompt: Text prompt to send to the model.
      api_url: Full URL to the inference model endpoint.
      hf_token: HuggingFace token to use (falls back to env DEFAULT_HF_TOKEN).
      output_path: If provided, save the image to this path. If not provided, a name will be generated.
      wait_for_model: If True, pass option to wait for model to load.
      return_bytes: If True, include raw bytes in the returned dict under 'content'.
      timeout: HTTP request timeout in seconds.

    Returns:
      dict with keys: 'ok' (bool), and on success either 'path' or 'content'. On error 'error' key is set.
    """
    hf_token = hf_token or DEFAULT_HF_TOKEN
    if not hf_token:
        return {"ok": False, "error": "No HuggingFace token provided. Set HF_TOKEN env var or pass hf_token."}

    headers = {"Authorization": f"Bearer {hf_token}"}
    payload = {"inputs": prompt, "options": {"wait_for_model": bool(wait_for_model)}}

    try:
        resp = requests.post(api_url, headers=headers, json=payload, timeout=timeout)
    except Exception as e:
        return {"ok": False, "error": f"Request failed: {e}"}

    if resp.status_code >= 400:
        # Try to extract error details
        detail = None
        try:
            detail = resp.json()
        except Exception:
            detail = resp.text
        return {"ok": False, "error": f"Model call failed (status {resp.status_code})", "details": detail}

    result = _detect_content_type_and_return(resp)

    if isinstance(result, dict) and result.get('error'):
        return {"ok": False, **result}

    # If we got bytes (image) save or return them
    if isinstance(result, (bytes, bytearray)):
        content = bytes(result)

        # If an exoplanet_name is provided, save to ./exoplanets/<sanitized_name>.png
        if exoplanet_name:
            safe = _sanitize_name(exoplanet_name)
            out_dir = os.path.join(os.getcwd(), 'exoplanets')
            os.makedirs(out_dir, exist_ok=True)
            output_path = os.path.join(out_dir, f"{safe}.png")

        if output_path is None:
            ts = int(time.time())
            output_path = f"generated_image_{ts}.png"

        # Try to write image via PIL to validate and ensure format
        try:
            image = Image.open(io.BytesIO(content))
            # Ensure parent dir exists
            parent = os.path.dirname(output_path)
            if parent:
                os.makedirs(parent, exist_ok=True)
            image.save(output_path)
        except Exception:
            # If PIL fails, still try raw write
            try:
                with open(output_path, 'wb') as f:
                    f.write(content)
            except Exception as e:
                return {"ok": False, "error": f"Failed to save image: {e}"}

        # If file exists, append timestamp to avoid overwriting
        if os.path.exists(output_path):
            base, ext = os.path.splitext(output_path)
            output_path = f"{base}_{int(time.time())}{ext}"

        ret = {"ok": True, "path": output_path}
        if return_bytes:
            ret['content'] = content
        return ret

    # If response was JSON (e.g., model returned an error or metadata)
    try:
        return {"ok": False, "error": "Unexpected JSON response", "details": result}
    except Exception:
        return {"ok": False, "error": "Unknown response from model"}


if __name__ == '__main__':
    # Simple CLI for quick testing
    import argparse

    parser = argparse.ArgumentParser(description='Generate an image via HuggingFace Inference API')
    parser.add_argument('prompt', nargs='+', help='Prompt text (wrap in quotes)')
    parser.add_argument('--out', '-o', help='Output file path (png)')
    parser.add_argument('--token', '-t', help='HuggingFace token (optional; uses HF_TOKEN env var if omitted)')
    parser.add_argument('--url', help='Model API url (optional)')
    args = parser.parse_args()

    prompt_text = ' '.join(args.prompt)
    print(f"🎨 Generating image for prompt: {prompt_text}")
    res = generate_image(prompt_text, api_url=args.url or API_URL, hf_token=args.token, output_path=args.out)
    if res.get('ok'):
        print(f"✅ Image saved to: {res.get('path')}")
    else:
        print(f"❌ Generation failed: {res.get('error')}")
        if 'details' in res:
            print('Details:', res['details'])