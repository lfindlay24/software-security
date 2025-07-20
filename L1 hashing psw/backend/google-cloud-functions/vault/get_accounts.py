import os
import json
import base64
from flask import Flask, request, jsonify
from Crypto.Cipher import AES
from Crypto.Hash import SHA1
from google.cloud import firestore

app = Flask(__name__)
db = firestore.Client()

def pad(s):
    pad_len = 16 - len(s) % 16
    return s + chr(pad_len) * pad_len

def unpad(s):
    pad_len = ord(s[-1])
    return s[:-pad_len]

def decrypt_aes(ciphertext_b64, key):
    data = base64.b64decode(ciphertext_b64)
    iv = data[:16]
    ct = data[16:]
    cipher = AES.new(key, AES.MODE_CBC, iv)
    pt = cipher.decrypt(ct).decode('utf-8')
    return unpad(pt)

@app.route('/get_accounts', methods=['POST'])
def get_accounts(request):
    data = request.get_json(silent=True)
    username = data.get('username')
    master_password = data.get('master_password')
    if not username or not master_password:
        return jsonify({'error': 'Missing username or master_password'}), 400
    key = SHA1.new(master_password.encode('utf-8')).digest()[:16]
    accounts_ref = db.collection('users').document(username).collection('accounts')
    docs = accounts_ref.stream()
    result = []
    for doc in docs:
        acc = doc.to_dict()
        try:
            decrypted_pw = decrypt_aes(acc['account_password'], key)
        except Exception:
            decrypted_pw = 'DECRYPTION_FAILED'
        result.append({
            'account_id': acc.get('account_id', ''),
            'account_username': acc.get('account_username', ''),
            'account_password': decrypted_pw,
            'comment': acc.get('comment', '')
        })
    return jsonify({'accounts': result})

if __name__ == '__main__':
    app.run(debug=True)
