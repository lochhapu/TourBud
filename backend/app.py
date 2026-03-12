from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
import secrets
import time

app = Flask(__name__)
CORS(app)

DATABASE = 'tourbud.db'


def get_db_connection():
    """Helper function to get a database connection"""
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row  # This enables column access by name
    return conn


def get_user_id_from_token(token):
    """
    Resolves a session token to a user ID.
    
    Returns:
        int -> user_id if token is valid
        None -> if token missing or invalid (TODO: or expired in the future)
    
    This function is the authentication boundary for all protected routes.
    """
    
    # Missing token - checking early to prevent waste & bugs as we update codebase
    if token is None:
        return None

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute(
        "SELECT user_id FROM sessions WHERE token = ?",
        (token,)
    )

    row = cursor.fetchone()

    conn.close()

    # Token invalid (TODO: or expired)
    if row is None:
        return None

    return row["user_id"]


# Home route
@app.route("/api/", methods=["GET"])
def index():
    return "hello, world"

@app.route("/api/register", methods=["POST"])
def register():
    """
    Registers a new user.
    
    Expected JSON:
    {
        "username": str,
        "password": str
    }
    
    Constraints:
    - Username must be unique
    - Passwords are stored in plain text
    - No password confirmation
    """

    # Ensure request is JSON
    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 415

    data = request.get_json()

    # Ensure body exists
    if not data:
        return jsonify({"error": "Body does not exist"}), 400

    # Ensure username and password fields exist
    if "username" not in data or "password" not in data:
        return jsonify({"error": "Missing credentials"}), 400

    username = data["username"]
    password = data["password"]
    
    # Ensure username and password aren't missing
    if not username or not password:
        return jsonify({"error": "Missing credentials"}), 400

    # Ensure correct types
    if not isinstance(data["username"], str):
        return jsonify({"error": "username must be string"}), 400
    if not isinstance(data["password"], str):
        return jsonify({"error": "password must be string"}), 400

    # Ensure username does not have space
    if " " in username:
        return jsonify({"error": "username cannot have space"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute(
            "INSERT INTO users (username, password) VALUES (?, ?)", 
            (username, password)
        )
        conn.commit()
    except sqlite3.IntegrityError:
        conn.close()
        return jsonify({"error": "Registration failed"}), 400

    conn.close()
    return jsonify({"message": "User registered"}), 201

if __name__ == "__main__":
    app.run(debug=True)