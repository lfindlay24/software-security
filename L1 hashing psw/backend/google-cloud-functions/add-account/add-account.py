import os
from flask import Flask, request, jsonify
from google.cloud import firestore
import hashlib
import secrets
from Crypto.Cipher import AES

# Initialize Flask app
app = Flask(__name__)

# Initialize Firestore client
db = firestore.Client()

@app.route('/add-account', methods=['POST'])
def add_account(request):
    """
    HTTP endpoint to register an account associated with a user.
    Expects JSON body with 'username', 'password', 'accountName', 'masterPassword' and 'userId'.
    """
    request_json = request.get_json(silent=True)
    if not request_json or 'username' not in request_json or 'password' not in request_json or 'accountName' not in request_json or 'userId' not in request_json or 'masterPassword' not in request_json:
        return jsonify({"error": "Missing required fields"}), 400

    username = request_json['username']
    password = request_json['password']
    account_name = request_json['accountName']
    user_id = request_json['userId']
    master_password = request_json['masterPassword']

    cipher = AES.new(master_password.encode('utf-8'), AES.MODE_EAX)

    password_hash = hashlib.sha256(password.encode('utf-8')).hexdigest()

    ciphertext, tag = cipher.encrypt_and_digest(password_hash)

    # Add user to Firestore
    doc_ref = db.collection('accounts').document(account_name)
    doc_ref.set({
        'username': username,
        'password': ciphertext,
        'userId': user_id
    })

    return jsonify({"message": f"Account {account_name} registered successfully."}), 200


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)