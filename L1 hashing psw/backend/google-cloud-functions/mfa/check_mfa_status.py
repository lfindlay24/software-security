import os
import json
from flask import Flask, request, jsonify
from google.cloud import firestore

# This file was AI Generated

app = Flask(__name__)
db = firestore.Client()

@app.route('/check_mfa_status', methods=['POST'])
def check_mfa_status(request):
    """
    HTTP endpoint to check MFA status for a user.
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

    user_data = doc.to_dict()
    mfa_enabled = user_data.get('mfa_enabled', False)
    
    return jsonify({"mfa_enabled": mfa_enabled}), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
