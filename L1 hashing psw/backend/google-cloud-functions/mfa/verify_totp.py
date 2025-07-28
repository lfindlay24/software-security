import os
import json
from flask import Flask, request, jsonify
from google.cloud import firestore
import pyotp

app = Flask(__name__)
db = firestore.Client()

@app.route('/verify_totp', methods=['POST'])
def verify_totp(request):
    """
    HTTP endpoint to verify TOTP code for a user.
    Expects JSON body with 'username' and 'totp_code'.
    """
    request_json = request.get_json(silent=True)
    if not request_json or 'username' not in request_json or 'totp_code' not in request_json:
        return jsonify({"error": "Missing username or totp_code"}), 400

    username = request_json['username']
    totp_code = request_json['totp_code']

    # Check if user exists
    doc_ref = db.collection('users').document(username)
    doc = doc_ref.get()
    if not doc.exists:
        return jsonify({"error": "User not found"}), 404

    user_data = doc.to_dict()
    mfa_secret = user_data.get('mfa_secret')
    mfa_enabled = user_data.get('mfa_enabled', False)
    
    if not mfa_enabled or not mfa_secret:
        return jsonify({"error": "MFA not enabled for this user"}), 400

    # Verify the TOTP code
    totp = pyotp.TOTP(mfa_secret)
    if not totp.verify(totp_code, valid_window=1):
        return jsonify({"error": "Invalid TOTP code"}), 401

    return jsonify({"message": "TOTP verification successful"}), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
