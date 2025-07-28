import os
from flask import Flask, request, jsonify
from google.cloud import firestore
import hashlib

# Initialize Flask app
app = Flask(__name__)

# Initialize Firestore client
db = firestore.Client()

@app.route('/login', methods=['GET'])
def login_user(request):
    """
    HTTP endpoint to login a user.
    Expects JSON body with 'username' and 'password'.
    """
    request_json = request.get_json(silent=True)
    if not request_json or 'username' not in request_json or 'password' not in request_json:
        return jsonify({"error": "Missing username or password"}), 400

    username = request_json['username']
    password = request_json['password']

    # Check user in Firestore
    doc_ref = db.collection('users').document(username)
    doc = doc_ref.get()
    if not doc.exists:
        return jsonify({"error": "User not found"}), 404
    
    # Retrieve salt and hash the password
    salt = doc.to_dict().get('salt')
    if not salt:
        return jsonify({"error": "User data is corrupted"}), 500

    password_hash = hashlib.sha256((salt + password).encode()).hexdigest()

    if doc.to_dict().get('password') != password_hash:
        return jsonify({"error": "Invalid password"}), 401

    # Check if MFA is enabled
    mfa_enabled = doc.to_dict().get('mfa_enabled', False)
    
    return jsonify({
        "message": f"User {username} logged in successfully.",
        "mfa_enabled": mfa_enabled
    }), 200

# def get_salt(password):

#     for i in range(password.len()):

#     return hashlib.sha256(("salted" + password).encode()).hexdigest()


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)