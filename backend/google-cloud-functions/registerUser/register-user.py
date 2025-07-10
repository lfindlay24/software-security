import os
from flask import Flask, request, jsonify
from google.cloud import firestore
import hashlib
import secrets

# Initialize Flask app
app = Flask(__name__)

# Initialize Firestore client
db = firestore.Client()

@app.route('/register', methods=['POST'])
def register_user(request):
    """
    HTTP endpoint to register a user.
    Expects JSON body with 'username' and 'password'.
    """
    request_json = request.get_json(silent=True)
    if not request_json or 'username' not in request_json or 'password' not in request_json:
        return jsonify({"error": "Missing username or password"}), 400

    username = request_json['username']
    password = request_json['password']

    salt = secrets.token_hex(32)  # Generate a secure 32 byte salt

    password_hash = hashlib.sha256((salt + password).encode()).hexdigest()

    # Add user to Firestore
    doc_ref = db.collection('users').document(username)
    doc_ref.set({
        'username': username,
        'password': password_hash,
        'salt': salt
    })

    return jsonify({"message": f"User {username} registered successfully."}), 200

# def get_salt(password):

#     for i in range(password.len()):

#     return hashlib.sha256(("salted" + password).encode()).hexdigest()


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)