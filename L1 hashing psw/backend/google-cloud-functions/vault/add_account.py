import os
import json
import base64
from flask import Flask, request, jsonify
from Crypto.Cipher import AES
from Crypto.Hash import SHA1
from Crypto.Random import get_random_bytes
from google.cloud import firestore

app = Flask(__name__)
db = firestore.Client()

def pad(s):
    pad_len = 16 - len(s) % 16
    return s + chr(pad_len) * pad_len

def encrypt_aes(plaintext, key):
    iv = get_random_bytes(16)
    cipher = AES.new(key, AES.MODE_CBC, iv)
    ct_bytes = cipher.encrypt(pad(plaintext).encode('utf-8'))
    return base64.b64encode(iv + ct_bytes).decode('utf-8')

@app.route('/add_account', methods=['POST'])
def add_account(request):
    data = request.get_json(silent=True)
    username = data.get('username')
    master_password = data.get('master_password')
    account_id = data.get('account_id')
    account_username = data.get('account_username')
    account_password = data.get('account_password')
    comment = data.get('comment', '')
    if not all([username, master_password, account_id, account_username, account_password]):
        return jsonify({'error': 'Missing required fields'}), 400
    key = SHA1.new(master_password.encode('utf-8')).digest()[:16]
    encrypted_password = encrypt_aes(account_password, key)
    # Store in Firestore under users/{username}/accounts/{account_id}
    db.collection('users').document(username).collection('accounts').document(account_id).set({
        'account_id': account_id,
        'account_username': account_username,
        'account_password': encrypted_password,
        'comment': comment
    })
    return jsonify({'message': 'Account added successfully'})

if __name__ == '__main__':
    app.run(debug=True)
