"""
    Welcome to the backend file! Careful touching this!
    Just use the setup instructions, and try to run it.
    Make sure to get Python3 on your device.
"""

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


@app.route("/api/", methods=["GET"])
def index():
    """
    API root endpoint - returns a friendly introduction to TourBud API
    """
    api_info = {
        "message": "👋 Welcome to TourBud API!",
        "description": "Your travel companion for connecting with fellow explorers.",
        "version": "1.0.0",
        "status": "operational",
        "endpoints": {
            "GET /": {
                "description": "You're here! This friendly introduction",
                "auth_required": False
            },
            "POST /register": {
                "description": "Create a new account",
                "auth_required": False,
                "expected_body": {
                    "username": "string",
                    "password": "string"
                },
                "example_response": {
                    "message": "User registered"
                }
            },
            "POST /login": {
                "description": "Login and get a session token",
                "auth_required": False,
                "expected_body": {
                    "username": "string",
                    "password": "string"
                },
                "example_response": {
                    "token": "a1b2c3d4e5f6...",
                    "expires_at": 1700000000,
                    "message": "Login successful"
                }
            },
            "POST /logout": {
                "description": "Logout and invalidate your session token",
                "auth_required": True,
                "auth_method": "Bearer token in Authorization header",
                "example_headers": {
                    "Authorization": "Bearer <your-token-here>"
                },
                "example_response": {
                    "message": "Logged out successfully"
                }
            }
        },
        "quick_start": {
            "1_create_account": "curl -X POST http://localhost:5000/register -H 'Content-Type: application/json' -d '{\"username\": \"traveler123\", \"password\": \"securepass\"}'",
            "2_login": "curl -X POST http://localhost:5000/login -H 'Content-Type: application/json' -d '{\"username\": \"traveler123\", \"password\": \"securepass\"}'",
            "3_logout": "curl -X POST http://localhost:5000/logout -H 'Authorization: Bearer YOUR-TOKEN-HERE'"
        },
        "notes": [
            "🔐 Passwords are stored in plaintext (demo only!)",
            "⏰ Sessions expire after 7 days",
            "🧹 Expired sessions are automatically cleaned up",
            "🚀 More endpoints coming soon!"
        ],
        "docs": "Check the source code or README for more details",
        "support": "Happy travels! 🌍✈️"
    }
    
    return jsonify(api_info)


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


@app.route("/api/login", methods=["POST"])
def login():
    """
    Logs in a user and creates a session.
    
    Expected JSON:
    {
        "username": str,
        "password": str
    }
    
    Returns:
        - 200: {"token": "session_token"} on success
        - 400: {"error": "Missing credentials"} if fields missing
        - 401: {"error": "Invalid credentials"} if username/password incorrect
        - 415: {"error": "Request must be JSON"} if wrong content type
    
    The returned token should be sent in subsequent requests via:
    Authorization: Bearer <token>
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
    
    # Ensure username and password aren't empty
    if not username or not password:
        return jsonify({"error": "Missing credentials"}), 400

    # Ensure correct types
    if not isinstance(data["username"], str):
        return jsonify({"error": "username must be string"}), 400
    if not isinstance(data["password"], str):
        return jsonify({"error": "password must be string"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    # Find user with matching username and password
    cursor.execute(
        "SELECT id FROM users WHERE username = ? AND password = ?",
        (username, password)
    )
    
    user = cursor.fetchone()

    # Invalid credentials
    if user is None:
        conn.close()
        return jsonify({"error": "Invalid credentials"}), 401

    # Generate a secure random token
    token = secrets.token_hex(32)  # 64-character hex token
    
    # Set expiration to 7 days from now (in seconds since epoch)
    expires_at = int(time.time()) + (7 * 24 * 60 * 60)  # 7 days

    try:
        # Insert session token (trigger will auto-clean expired sessions)
        cursor.execute(
            "INSERT INTO sessions (token, user_id, expires_at) VALUES (?, ?, ?)",
            (token, user["id"], expires_at)
        )
        conn.commit()
    except sqlite3.Error:
        conn.close()
        return jsonify({"error": "Could not create session"}), 500

    conn.close()
    
    # Return the token to the client
    return jsonify({
        "token": token,
        "expires_at": expires_at,
        "message": "Login successful"
    }), 200


@app.route("/api/logout", methods=["POST"])
def logout():
    """
    Logs out a user by deleting their session token.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Returns:
        - 200: {"message": "Logged out successfully"} on success
        - 401: {"error": "Unauthorized"} if token missing
        - 500: {"error": "Logout failed"} if server error
    """
    
    # Get token from Authorization header (Bearer format)
    auth_header = request.headers.get("Authorization")
    
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    # Extract token from "Bearer <token>" format
    if auth_header.startswith("Bearer "):
        token = auth_header.split(" ")[1]
    else:
        token = auth_header  # Fallback for bare token
    
    if not token:
        return jsonify({"error": "Unauthorized"}), 401

    conn = get_db_connection()
    cursor = conn.cursor()

    # Check if token exists before deleting (optional)
    cursor.execute(
        "SELECT token FROM sessions WHERE token = ?",
        (token,)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Invalid token"}), 401

    # Delete the session
    cursor.execute(
        "DELETE FROM sessions WHERE token = ?",
        (token,)
    )

    conn.commit()
    
    # Check if any row was actually deleted
    if cursor.rowcount == 0:
        conn.close()
        return jsonify({"error": "Logout failed"}), 500

    conn.close()

    return jsonify({"message": "Logged out successfully"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)