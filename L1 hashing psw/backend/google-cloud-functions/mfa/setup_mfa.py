import os
import json
import secrets
import base64
from flask import Flask, request, jsonify
from google.cloud import firestore
import pyotp

app = Flask(__name__)
db = firestore.Client()

def generate_secret():
    """Generate a random base32 secret for TOTP"""
    return pyotp.random_base32()

def generate_qr_code_uri(username, secret):
    """Generate the QR code URI for authenticator apps"""
    totp = pyotp.TOTP(secret)
    return totp.provisioning_uri(
        name=username,
        issuer_name="PasswordVault"
    )

@app.route('/setup_mfa', methods=['POST'])
def setup_mfa(request):
    """
    HTTP endpoint to generate MFA setup data for a user.
    Expects JSON body with 'username'.
    """
    request_json = request.get_json(silent=True)
    if not request_json or 'username' not in request_json:
        return jsonify({"error": "Missing username"}), 400

    username = request_json['username']

    # Check if user exists
    doc_ref = db.collection('users').document(username)
    doc = doc_ref.get()
    if not doc.exists:
        return jsonify({"error": "User not found"}), 404

    # Generate secret key
    secret = generate_secret()
    
    # Generate QR code URI
    qr_uri = generate_qr_code_uri(username, secret)
    
    # Store the temporary secret (will be confirmed later)
    doc_ref.update({
        'mfa_secret_temp': secret,
        'mfa_enabled': False
    })

    return jsonify({
        "secret": secret,
        "qr_code_uri": qr_uri
    }), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
