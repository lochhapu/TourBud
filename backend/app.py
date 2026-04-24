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
import os
from werkzeug.utils import secure_filename
from werkzeug.datastructures import FileStorage


from html import api_info

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


@app.route("/", methods=["GET"])
def index():
    return api_info()

@app.route("/register", methods=["POST"])
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


@app.route("/login", methods=["POST"])
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


@app.route("/logout", methods=["POST"])
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


@app.route("/profile", methods=["GET"])
def get_profile():
    """
    Get the authenticated user's profile information.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Returns:
        - 200: User profile data
        - 401: Unauthorized if token missing/invalid
    """
    # Get token from Authorization header
    auth_header = request.headers.get("Authorization")
    
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    # Extract token
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    
    # Get user_id from token
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Get user profile (exclude password)
    cursor.execute(
        """
        SELECT id, username, full_name, contact_number, date_of_birth, created_at
        FROM users WHERE id = ?
        """,
        (user_id,)
    )
    
    user = cursor.fetchone()
    conn.close()
    
    if user is None:
        return jsonify({"error": "User not found"}), 404
    
    # Format the response
    profile = {
        "id": user["id"],
        "username": user["username"],
        "full_name": user["full_name"],
        "contact_number": user["contact_number"],
        "date_of_birth": user["date_of_birth"],
        "member_since": user["created_at"],
        "member_since_formatted": time.strftime("%B %Y", time.localtime(user["created_at"]))
    }
    
    return jsonify(profile), 200


@app.route("/profile", methods=["PUT"])
def update_profile():
    """
    Update the authenticated user's profile information.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Expected JSON (all fields optional):
    {
        "full_name": "John Doe",
        "contact_number": "+1234567890",
        "date_of_birth": "1990-01-01"
    }
    
    Returns:
        - 200: Updated profile data
        - 400: Invalid data
        - 401: Unauthorized if token missing/invalid
    """
    # Get token from Authorization header
    auth_header = request.headers.get("Authorization")
    
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    # Extract token
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    
    # Get user_id from token
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Ensure request is JSON
    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 415
    
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    # Build update query dynamically based on provided fields
    updates = []
    values = []
    
    # Check each field and validate
    if "full_name" in data:
        if not isinstance(data["full_name"], str):
            return jsonify({"error": "full_name must be string"}), 400
        updates.append("full_name = ?")
        values.append(data["full_name"])
    
    if "contact_number" in data:
        if not isinstance(data["contact_number"], str):
            return jsonify({"error": "contact_number must be string"}), 400
        # Optional: Add phone number validation here
        updates.append("contact_number = ?")
        values.append(data["contact_number"])
    
    if "date_of_birth" in data:
        if not isinstance(data["date_of_birth"], str):
            return jsonify({"error": "date_of_birth must be string"}), 400
        # Validate date format (YYYY-MM-DD)
        try:
            time.strptime(data["date_of_birth"], "%Y-%m-%d")
        except ValueError:
            return jsonify({"error": "date_of_birth must be in YYYY-MM-DD format"}), 400
        updates.append("date_of_birth = ?")
        values.append(data["date_of_birth"])
    
    # If no valid fields to update
    if not updates:
        return jsonify({"error": "No valid fields to update"}), 400
    
    # Add user_id to values and build query
    values.append(user_id)
    query = f"UPDATE users SET {', '.join(updates)} WHERE id = ?"
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute(query, values)
        conn.commit()
        
        # Fetch updated profile
        cursor.execute(
            """
            SELECT id, username, full_name, contact_number, date_of_birth, created_at
            FROM users WHERE id = ?
            """,
            (user_id,)
        )
        
        updated_user = cursor.fetchone()
        conn.close()
        
        profile = {
            "id": updated_user["id"],
            "username": updated_user["username"],
            "full_name": updated_user["full_name"],
            "contact_number": updated_user["contact_number"],
            "date_of_birth": updated_user["date_of_birth"],
            "member_since": updated_user["created_at"],
            "message": "Profile updated successfully"
        }
        
        return jsonify(profile), 200
        
    except sqlite3.Error as e:
        conn.close()
        return jsonify({"error": "Database error occurred"}), 500


@app.route("/profile", methods=["PATCH"])
def patch_profile():
    """
    Alias for PUT /profile - allows partial updates.
    Simply calls the update_profile function.
    """
    return update_profile()

# ============ TRIP MANAGEMENT ENDPOINTS ============

@app.route("/trips", methods=["GET"])
def get_all_trips():
    """
    Get all trips for the authenticated user.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Optional query parameters:
    - upcoming: 'true' - only trips with end_date >= today
    - past: 'true' - only trips with end_date < today
    
    Returns:
        - 200: List of trips
        - 401: Unauthorized
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Get filter parameters
    upcoming = request.args.get('upcoming', 'false').lower() == 'true'
    past = request.args.get('past', 'false').lower() == 'true'
    today = time.strftime("%Y-%m-%d")
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Build query based on filters
    query = "SELECT * FROM trips WHERE user_id = ?"
    params = [user_id]
    
    if upcoming:
        query += " AND end_date >= ?"
        params.append(today)
    elif past:
        query += " AND end_date < ?"
        params.append(today)
    
    query += " ORDER BY start_date ASC"
    
    cursor.execute(query, params)
    trips = cursor.fetchall()
    conn.close()
    
    # Format the response
    trips_list = []
    for trip in trips:
        trips_list.append({
            "id": trip["id"],
            "trip_name": trip["trip_name"],
            "start_date": trip["start_date"],
            "end_date": trip["end_date"],
            "budget_goal": trip["budget_goal"],
            "budget_currency": trip["budget_currency"],
            "created_at": trip["created_at"],
            "updated_at": trip["updated_at"]
        })
    
    return jsonify({
        "trips": trips_list,
        "count": len(trips_list)
    }), 200


@app.route("/trips/<int:trip_id>", methods=["GET"])
def get_trip_details(trip_id):
    """
    Get detailed information for a specific trip.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Returns:
        - 200: Trip details
        - 401: Unauthorized
        - 403: Forbidden (trip belongs to different user)
        - 404: Trip not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        "SELECT * FROM trips WHERE id = ? AND user_id = ?",
        (trip_id, user_id)
    )
    
    trip = cursor.fetchone()
    conn.close()
    
    if trip is None:
        return jsonify({"error": "Trip not found"}), 404
    
    return jsonify({
        "id": trip["id"],
        "trip_name": trip["trip_name"],
        "start_date": trip["start_date"],
        "end_date": trip["end_date"],
        "budget_goal": trip["budget_goal"],
        "budget_currency": trip["budget_currency"],
        "created_at": trip["created_at"],
        "updated_at": trip["updated_at"]
    }), 200


@app.route("/trips", methods=["POST"])
def create_trip():
    """
    Create a new trip.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Expected JSON:
    {
        "trip_name": str,
        "start_date": str (YYYY-MM-DD),
        "end_date": str (YYYY-MM-DD),
        "budget_goal": float (optional),
        "budget_currency": str (optional, default 'USD')
    }
    
    Returns:
        - 201: Trip created successfully
        - 400: Invalid data
        - 401: Unauthorized
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Validate request
    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 415
    
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    # Required fields
    required_fields = ["trip_name", "start_date", "end_date"]
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Missing required field: {field}"}), 400
    
    trip_name = data["trip_name"]
    start_date = data["start_date"]
    end_date = data["end_date"]
    budget_goal = data.get("budget_goal")
    budget_currency = data.get("budget_currency", "USD")
    
    # Validate types
    if not isinstance(trip_name, str) or not trip_name.strip():
        return jsonify({"error": "trip_name must be a non-empty string"}), 400
    
    # Validate date format
    try:
        time.strptime(start_date, "%Y-%m-%d")
        time.strptime(end_date, "%Y-%m-%d")
    except ValueError:
        return jsonify({"error": "Dates must be in YYYY-MM-DD format"}), 400
    
    # Validate date range
    if start_date > end_date:
        return jsonify({"error": "start_date must be before or equal to end_date"}), 400
    
    # Validate budget if provided
    if budget_goal is not None:
        try:
            budget_goal = float(budget_goal)
            if budget_goal < 0:
                return jsonify({"error": "budget_goal must be a positive number"}), 400
        except (ValueError, TypeError):
            return jsonify({"error": "budget_goal must be a number"}), 400
    
    # Validate currency (simple check - 3 letter code)
    if len(budget_currency) != 3:
        return jsonify({"error": "budget_currency must be a 3-letter currency code (e.g., USD, EUR, GBP)"}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute(
            """
            INSERT INTO trips (user_id, trip_name, start_date, end_date, budget_goal, budget_currency)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (user_id, trip_name.strip(), start_date, end_date, budget_goal, budget_currency.upper())
        )
        conn.commit()
        
        # Get the created trip
        trip_id = cursor.lastrowid
        cursor.execute("SELECT * FROM trips WHERE id = ?", (trip_id,))
        new_trip = cursor.fetchone()
        conn.close()
        
        return jsonify({
            "message": "Trip created successfully",
            "trip": {
                "id": new_trip["id"],
                "trip_name": new_trip["trip_name"],
                "start_date": new_trip["start_date"],
                "end_date": new_trip["end_date"],
                "budget_goal": new_trip["budget_goal"],
                "budget_currency": new_trip["budget_currency"]
            }
        }), 201
        
    except sqlite3.Error as e:
        conn.close()
        return jsonify({"error": f"Database error: {str(e)}"}), 500


@app.route("/trips/<int:trip_id>", methods=["PUT"])
def update_trip(trip_id):
    """
    Update an existing trip.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Expected JSON (all fields optional):
    {
        "trip_name": str (optional),
        "start_date": str (optional, YYYY-MM-DD),
        "end_date": str (optional, YYYY-MM-DD),
        "budget_goal": float (optional),
        "budget_currency": str (optional)
    }
    
    Returns:
        - 200: Trip updated successfully
        - 400: Invalid data
        - 401: Unauthorized
        - 403: Forbidden
        - 404: Trip not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Check if trip exists and belongs to user
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        "SELECT * FROM trips WHERE id = ? AND user_id = ?",
        (trip_id, user_id)
    )
    
    existing_trip = cursor.fetchone()
    if not existing_trip:
        conn.close()
        return jsonify({"error": "Trip not found"}), 404
    
    # Validate request
    if not request.is_json:
        conn.close()
        return jsonify({"error": "Request must be JSON"}), 415
    
    data = request.get_json()
    if not data:
        conn.close()
        return jsonify({"error": "No data provided"}), 400
    
    # Build update query dynamically
    updates = []
    values = []
    
    if "trip_name" in data:
        if not isinstance(data["trip_name"], str) or not data["trip_name"].strip():
            conn.close()
            return jsonify({"error": "trip_name must be a non-empty string"}), 400
        updates.append("trip_name = ?")
        values.append(data["trip_name"].strip())
    
    if "start_date" in data:
        try:
            time.strptime(data["start_date"], "%Y-%m-%d")
        except ValueError:
            conn.close()
            return jsonify({"error": "start_date must be in YYYY-MM-DD format"}), 400
        updates.append("start_date = ?")
        values.append(data["start_date"])
    
    if "end_date" in data:
        try:
            time.strptime(data["end_date"], "%Y-%m-%d")
        except ValueError:
            conn.close()
            return jsonify({"error": "end_date must be in YYYY-MM-DD format"}), 400
        updates.append("end_date = ?")
        values.append(data["end_date"])
    
    if "budget_goal" in data:
        if data["budget_goal"] is not None:
            try:
                budget_goal = float(data["budget_goal"])
                if budget_goal < 0:
                    conn.close()
                    return jsonify({"error": "budget_goal must be a positive number"}), 400
            except (ValueError, TypeError):
                conn.close()
                return jsonify({"error": "budget_goal must be a number"}), 400
        else:
            budget_goal = None
        updates.append("budget_goal = ?")
        values.append(budget_goal)
    
    if "budget_currency" in data:
        if len(data["budget_currency"]) != 3:
            conn.close()
            return jsonify({"error": "budget_currency must be a 3-letter currency code"}), 400
        updates.append("budget_currency = ?")
        values.append(data["budget_currency"].upper())
    
    # Validate date consistency if both dates are being updated
    new_start = data.get("start_date", existing_trip["start_date"])
    new_end = data.get("end_date", existing_trip["end_date"])
    if new_start > new_end:
        conn.close()
        return jsonify({"error": "start_date must be before or equal to end_date"}), 400
    
    if not updates:
        conn.close()
        return jsonify({"error": "No valid fields to update"}), 400
    
    # Execute update
    values.append(trip_id)
    query = f"UPDATE trips SET {', '.join(updates)} WHERE id = ?"
    
    try:
        cursor.execute(query, values)
        conn.commit()
        
        # Fetch updated trip
        cursor.execute("SELECT * FROM trips WHERE id = ?", (trip_id,))
        updated_trip = cursor.fetchone()
        conn.close()
        
        return jsonify({
            "message": "Trip updated successfully",
            "trip": {
                "id": updated_trip["id"],
                "trip_name": updated_trip["trip_name"],
                "start_date": updated_trip["start_date"],
                "end_date": updated_trip["end_date"],
                "budget_goal": updated_trip["budget_goal"],
                "budget_currency": updated_trip["budget_currency"]
            }
        }), 200
        
    except sqlite3.Error as e:
        conn.close()
        return jsonify({"error": f"Database error: {str(e)}"}), 500


@app.route("/trips/<int:trip_id>", methods=["DELETE"])
def delete_trip(trip_id):
    """
    Delete a trip.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Returns:
        - 200: Trip deleted successfully
        - 401: Unauthorized
        - 403: Forbidden
        - 404: Trip not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Check if trip exists and belongs to user
    cursor.execute(
        "SELECT id FROM trips WHERE id = ? AND user_id = ?",
        (trip_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Trip not found"}), 404
    
    # Delete the trip
    cursor.execute("DELETE FROM trips WHERE id = ?", (trip_id,))
    conn.commit()
    conn.close()
    
    return jsonify({"message": "Trip deleted successfully"}), 200


@app.route("/trips/<int:trip_id>/budget", methods=["PATCH"])
def update_budget_goal(trip_id):
    """
    Update only the budget goal for a trip (convenience endpoint).
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Expected JSON:
    {
        "budget_goal": float,
        "budget_currency": str (optional)
    }
    
    Returns:
        - 200: Budget updated successfully
        - 400: Invalid data
        - 401: Unauthorized
        - 404: Trip not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 415
    
    data = request.get_json()
    if "budget_goal" not in data:
        return jsonify({"error": "budget_goal is required"}), 400
    
    # Validate budget
    try:
        budget_goal = float(data["budget_goal"])
        if budget_goal < 0:
            return jsonify({"error": "budget_goal must be a positive number"}), 400
    except (ValueError, TypeError):
        return jsonify({"error": "budget_goal must be a number"}), 400
    
    budget_currency = data.get("budget_currency", "USD")
    if len(budget_currency) != 3:
        return jsonify({"error": "budget_currency must be a 3-letter currency code"}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Check ownership
    cursor.execute(
        "SELECT id FROM trips WHERE id = ? AND user_id = ?",
        (trip_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Trip not found"}), 404
    
    # Update budget
    cursor.execute(
        "UPDATE trips SET budget_goal = ?, budget_currency = ? WHERE id = ?",
        (budget_goal, budget_currency.upper(), trip_id)
    )
    conn.commit()
    conn.close()
    
    return jsonify({
        "message": "Budget goal updated successfully",
        "trip_id": trip_id,
        "budget_goal": budget_goal,
        "budget_currency": budget_currency.upper()
    }), 200

# ============ EXPENSE MANAGEMENT ENDPOINTS ============

# Helper function to validate category
def validate_category(category):
    """Validate expense category"""
    valid_categories = ['accommodation', 'transportation', 'food', 'activities', 'shopping', 'other']
    return category.lower() in valid_categories

@app.route("/trips/<int:trip_id>/expenses", methods=["GET"])
def get_trip_expenses(trip_id):
    """
    Get all expenses for a specific trip.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Optional query parameters:
    - category: filter by category
    - start_date: filter expenses from this date (YYYY-MM-DD)
    - end_date: filter expenses up to this date (YYYY-MM-DD)
    
    Returns:
        - 200: List of expenses
        - 401: Unauthorized
        - 403: Forbidden (trip belongs to different user)
        - 404: Trip not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify trip belongs to user
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        "SELECT id FROM trips WHERE id = ? AND user_id = ?",
        (trip_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Trip not found"}), 404
    
    # Build query with filters
    query = "SELECT * FROM expenses WHERE trip_id = ?"
    params = [trip_id]
    
    # Add category filter
    category = request.args.get('category')
    if category:
        if validate_category(category):
            query += " AND category = ?"
            params.append(category.lower())
        else:
            conn.close()
            return jsonify({"error": f"Invalid category. Valid categories: accommodation, transportation, food, activities, shopping, other"}), 400
    
    # Add date range filters
    start_date = request.args.get('start_date')
    if start_date:
        try:
            time.strptime(start_date, "%Y-%m-%d")
            query += " AND expense_date >= ?"
            params.append(start_date)
        except ValueError:
            conn.close()
            return jsonify({"error": "start_date must be in YYYY-MM-DD format"}), 400
    
    end_date = request.args.get('end_date')
    if end_date:
        try:
            time.strptime(end_date, "%Y-%m-%d")
            query += " AND expense_date <= ?"
            params.append(end_date)
        except ValueError:
            conn.close()
            return jsonify({"error": "end_date must be in YYYY-MM-DD format"}), 400
    
    query += " ORDER BY expense_date DESC, created_at DESC"
    
    cursor.execute(query, params)
    expenses = cursor.fetchall()
    
    # Get trip currency for reference
    cursor.execute("SELECT budget_currency FROM trips WHERE id = ?", (trip_id,))
    trip = cursor.fetchone()
    trip_currency = trip["budget_currency"] if trip else "USD"
    
    conn.close()
    
    # Format expenses
    expenses_list = []
    total_spent = 0
    
    for expense in expenses:
        expenses_list.append({
            "id": expense["id"],
            "amount": expense["amount"],
            "category": expense["category"],
            "currency": expense["currency"],
            "description": expense["description"],
            "expense_date": expense["expense_date"],
            "created_at": expense["created_at"],
            "updated_at": expense["updated_at"]
        })
        total_spent += expense["amount"]
    
    # Get budget info
    budget_info = get_trip_budget_info(trip_id, total_spent, trip_currency)
    
    return jsonify({
        "trip_id": trip_id,
        "trip_currency": trip_currency,
        "expenses": expenses_list,
        "count": len(expenses_list),
        "total_spent": total_spent,
        "budget_info": budget_info
    }), 200


@app.route("/trips/<int:trip_id>/expenses", methods=["POST"])
def add_expense(trip_id):
    """
    Add a new expense to a trip.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Expected JSON:
    {
        "amount": float (required),
        "category": str (required: accommodation, transportation, food, activities, shopping, other),
        "currency": str (optional, default trip's currency),
        "description": str (optional),
        "expense_date": str (optional, default today, YYYY-MM-DD)
    }
    
    Returns:
        - 201: Expense created
        - 400: Invalid data
        - 401: Unauthorized
        - 403: Forbidden
        - 404: Trip not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify trip belongs to user
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        "SELECT id, budget_currency FROM trips WHERE id = ? AND user_id = ?",
        (trip_id, user_id)
    )
    
    trip = cursor.fetchone()
    if trip is None:
        conn.close()
        return jsonify({"error": "Trip not found"}), 404
    
    # Validate request
    if not request.is_json:
        conn.close()
        return jsonify({"error": "Request must be JSON"}), 415
    
    data = request.get_json()
    if not data:
        conn.close()
        return jsonify({"error": "No data provided"}), 400
    
    # Required fields
    if "amount" not in data:
        conn.close()
        return jsonify({"error": "amount is required"}), 400
    
    if "category" not in data:
        conn.close()
        return jsonify({"error": "category is required"}), 400
    
    # Validate amount
    try:
        amount = float(data["amount"])
        if amount <= 0:
            conn.close()
            return jsonify({"error": "amount must be greater than 0"}), 400
    except (ValueError, TypeError):
        conn.close()
        return jsonify({"error": "amount must be a number"}), 400
    
    # Validate category
    category = data["category"].lower()
    if not validate_category(category):
        conn.close()
        return jsonify({"error": "Invalid category. Valid categories: accommodation, transportation, food, activities, shopping, other"}), 400
    
    # Validate currency (optional, default to trip's currency)
    currency = data.get("currency", trip["budget_currency"])
    if len(currency) != 3:
        conn.close()
        return jsonify({"error": "currency must be a 3-letter currency code"}), 400
    
    # Validate expense date (optional, default to today)
    expense_date = data.get("expense_date", time.strftime("%Y-%m-%d"))
    try:
        time.strptime(expense_date, "%Y-%m-%d")
    except ValueError:
        conn.close()
        return jsonify({"error": "expense_date must be in YYYY-MM-DD format"}), 400
    
    # Validate description (optional)
    description = data.get("description", "")
    if description and not isinstance(description, str):
        conn.close()
        return jsonify({"error": "description must be a string"}), 400
    
    # Insert expense
    try:
        cursor.execute(
            """
            INSERT INTO expenses (trip_id, amount, category, currency, description, expense_date)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (trip_id, amount, category, currency, description, expense_date)
        )
        conn.commit()
        
        # Get the created expense
        expense_id = cursor.lastrowid
        cursor.execute("SELECT * FROM expenses WHERE id = ?", (expense_id,))
        new_expense = cursor.fetchone()
        
        # Get updated total spent
        cursor.execute("SELECT SUM(amount) as total FROM expenses WHERE trip_id = ?", (trip_id,))
        total_spent = cursor.fetchone()["total"] or 0
        
        conn.close()
        
        return jsonify({
            "message": "Expense added successfully",
            "expense": {
                "id": new_expense["id"],
                "amount": new_expense["amount"],
                "category": new_expense["category"],
                "currency": new_expense["currency"],
                "description": new_expense["description"],
                "expense_date": new_expense["expense_date"]
            },
            "trip_id": trip_id,
            "total_spent": total_spent
        }), 201
        
    except sqlite3.Error as e:
        conn.close()
        return jsonify({"error": f"Database error: {str(e)}"}), 500


@app.route("/trips/<int:trip_id>/expenses/<int:expense_id>", methods=["PUT"])
def update_expense(trip_id, expense_id):
    """
    Update an existing expense.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Expected JSON (all fields optional):
    {
        "amount": float (optional),
        "category": str (optional),
        "currency": str (optional),
        "description": str (optional),
        "expense_date": str (optional, YYYY-MM-DD)
    }
    
    Returns:
        - 200: Expense updated
        - 400: Invalid data
        - 401: Unauthorized
        - 403: Forbidden
        - 404: Expense not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify trip belongs to user and expense exists
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT e.* FROM expenses e
        JOIN trips t ON e.trip_id = t.id
        WHERE e.id = ? AND e.trip_id = ? AND t.user_id = ?
        """,
        (expense_id, trip_id, user_id)
    )
    
    existing_expense = cursor.fetchone()
    if existing_expense is None:
        conn.close()
        return jsonify({"error": "Expense not found"}), 404
    
    # Validate request
    if not request.is_json:
        conn.close()
        return jsonify({"error": "Request must be JSON"}), 415
    
    data = request.get_json()
    if not data:
        conn.close()
        return jsonify({"error": "No data provided"}), 400
    
    # Build update query
    updates = []
    values = []
    
    if "amount" in data:
        try:
            amount = float(data["amount"])
            if amount <= 0:
                conn.close()
                return jsonify({"error": "amount must be greater than 0"}), 400
            updates.append("amount = ?")
            values.append(amount)
        except (ValueError, TypeError):
            conn.close()
            return jsonify({"error": "amount must be a number"}), 400
    
    if "category" in data:
        category = data["category"].lower()
        if not validate_category(category):
            conn.close()
            return jsonify({"error": "Invalid category. Valid categories: accommodation, transportation, food, activities, shopping, other"}), 400
        updates.append("category = ?")
        values.append(category)
    
    if "currency" in data:
        if len(data["currency"]) != 3:
            conn.close()
            return jsonify({"error": "currency must be a 3-letter currency code"}), 400
        updates.append("currency = ?")
        values.append(data["currency"].upper())
    
    if "description" in data:
        updates.append("description = ?")
        values.append(data["description"] if data["description"] else None)
    
    if "expense_date" in data:
        try:
            time.strptime(data["expense_date"], "%Y-%m-%d")
            updates.append("expense_date = ?")
            values.append(data["expense_date"])
        except ValueError:
            conn.close()
            return jsonify({"error": "expense_date must be in YYYY-MM-DD format"}), 400
    
    if not updates:
        conn.close()
        return jsonify({"error": "No valid fields to update"}), 400
    
    # Execute update
    values.append(expense_id)
    query = f"UPDATE expenses SET {', '.join(updates)} WHERE id = ?"
    
    try:
        cursor.execute(query, values)
        conn.commit()
        
        # Get updated expense
        cursor.execute("SELECT * FROM expenses WHERE id = ?", (expense_id,))
        updated_expense = cursor.fetchone()
        
        # Get updated total spent
        cursor.execute("SELECT SUM(amount) as total FROM expenses WHERE trip_id = ?", (trip_id,))
        total_spent = cursor.fetchone()["total"] or 0
        
        conn.close()
        
        return jsonify({
            "message": "Expense updated successfully",
            "expense": {
                "id": updated_expense["id"],
                "amount": updated_expense["amount"],
                "category": updated_expense["category"],
                "currency": updated_expense["currency"],
                "description": updated_expense["description"],
                "expense_date": updated_expense["expense_date"]
            },
            "trip_id": trip_id,
            "total_spent": total_spent
        }), 200
        
    except sqlite3.Error as e:
        conn.close()
        return jsonify({"error": f"Database error: {str(e)}"}), 500


@app.route("/trips/<int:trip_id>/expenses/<int:expense_id>", methods=["DELETE"])
def delete_expense(trip_id, expense_id):
    """
    Delete an expense.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Returns:
        - 200: Expense deleted
        - 401: Unauthorized
        - 403: Forbidden
        - 404: Expense not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify expense belongs to user's trip
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT e.id FROM expenses e
        JOIN trips t ON e.trip_id = t.id
        WHERE e.id = ? AND e.trip_id = ? AND t.user_id = ?
        """,
        (expense_id, trip_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Expense not found"}), 404
    
    # Delete expense
    cursor.execute("DELETE FROM expenses WHERE id = ?", (expense_id,))
    conn.commit()
    
    # Get updated total spent
    cursor.execute("SELECT SUM(amount) as total FROM expenses WHERE trip_id = ?", (trip_id,))
    total_spent = cursor.fetchone()["total"] or 0
    
    conn.close()
    
    return jsonify({
        "message": "Expense deleted successfully",
        "trip_id": trip_id,
        "total_spent": total_spent
    }), 200


@app.route("/trips/<int:trip_id>/expenses/summary", methods=["GET"])
def get_expense_summary(trip_id):
    """
    Get expense summary for a trip (by category).
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Returns:
        - 200: Expense summary by category
        - 401: Unauthorized
        - 403: Forbidden
        - 404: Trip not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify trip belongs to user
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        "SELECT id, budget_goal, budget_currency FROM trips WHERE id = ? AND user_id = ?",
        (trip_id, user_id)
    )
    
    trip = cursor.fetchone()
    if trip is None:
        conn.close()
        return jsonify({"error": "Trip not found"}), 404
    
    # Get expenses by category
    cursor.execute(
        """
        SELECT category, SUM(amount) as total, COUNT(*) as count
        FROM expenses
        WHERE trip_id = ?
        GROUP BY category
        ORDER BY total DESC
        """,
        (trip_id,)
    )
    
    category_summary = cursor.fetchall()
    
    # Get total spent
    cursor.execute("SELECT SUM(amount) as total FROM expenses WHERE trip_id = ?", (trip_id,))
    total_spent = cursor.fetchone()["total"] or 0
    
    # Get daily average if trip has dates
    cursor.execute("SELECT start_date, end_date FROM trips WHERE id = ?", (trip_id,))
    trip_dates = cursor.fetchone()
    
    daily_average = None
    if trip_dates and trip_dates["start_date"] and trip_dates["end_date"]:
        start = time.strptime(trip_dates["start_date"], "%Y-%m-%d")
        end = time.strptime(trip_dates["end_date"], "%Y-%m-%d")
        days = (time.mktime(end) - time.mktime(start)) / (24 * 60 * 60) + 1
        if days > 0:
            daily_average = round(total_spent / days, 2)
    
    conn.close()
    
    # Format summary
    categories = []
    for cat in category_summary:
        categories.append({
            "category": cat["category"],
            "total": cat["total"],
            "count": cat["count"],
            "percentage": round((cat["total"] / total_spent * 100), 2) if total_spent > 0 else 0
        })
    
    return jsonify({
        "trip_id": trip_id,
        "total_spent": total_spent,
        "budget_goal": trip["budget_goal"],
        "budget_currency": trip["budget_currency"],
        "remaining_budget": trip["budget_goal"] - total_spent if trip["budget_goal"] else None,
        "daily_average": daily_average,
        "categories": categories,
        "summary_by_category": {cat["category"]: cat["total"] for cat in categories}
    }), 200


# Helper function for budget info
def get_trip_budget_info(trip_id, total_spent, trip_currency):
    """Helper function to get budget information for a trip"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("SELECT budget_goal FROM trips WHERE id = ?", (trip_id,))
    trip = cursor.fetchone()
    conn.close()
    
    budget_goal = trip["budget_goal"] if trip else None
    
    if budget_goal:
        remaining = budget_goal - total_spent
        percent_used = (total_spent / budget_goal * 100) if budget_goal > 0 else 0
        
        # Determine status
        if percent_used >= 100:
            status = "over_budget"
            message = f"You have exceeded your budget by {abs(remaining):.2f} {trip_currency}"
        elif percent_used >= 90:
            status = "warning"
            message = f"You've used {percent_used:.1f}% of your budget. {remaining:.2f} {trip_currency} remaining"
        else:
            status = "good"
            message = f"On track! {remaining:.2f} {trip_currency} remaining"
        
        return {
            "budget_goal": budget_goal,
            "total_spent": total_spent,
            "remaining": remaining,
            "percent_used": round(percent_used, 2),
            "status": status,
            "message": message
        }
    else:
        return {
            "budget_goal": None,
            "message": "No budget set for this trip"
        }

# ============ LOCATION MANAGEMENT ENDPOINTS ============

@app.route("/trips/<int:trip_id>/locations", methods=["GET"])
def get_trip_locations(trip_id):
    """
    Get all locations for a specific trip.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Returns:
        - 200: List of locations with their todos
        - 401: Unauthorized
        - 403: Forbidden
        - 404: Trip not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify trip belongs to user
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        "SELECT id FROM trips WHERE id = ? AND user_id = ?",
        (trip_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Trip not found"}), 404
    
    # Get all locations for the trip
    cursor.execute(
        """
        SELECT * FROM locations 
        WHERE trip_id = ? 
        ORDER BY arrival_date ASC
        """,
        (trip_id,)
    )
    
    locations = cursor.fetchall()
    
    # Get todos for each location
    locations_list = []
    for location in locations:
        cursor.execute(
            """
            SELECT * FROM todos 
            WHERE location_id = ? 
            ORDER BY due_date ASC, created_at ASC
            """,
            (location["id"],)
        )
        todos = cursor.fetchall()
        
        todos_list = []
        for todo in todos:
            todos_list.append({
                "id": todo["id"],
                "description": todo["description"],
                "is_completed": bool(todo["is_completed"]),
                "category": todo["category"],
                "due_date": todo["due_date"],
                "created_at": todo["created_at"],
                "updated_at": todo["updated_at"]
            })
        
        # Calculate days at location
        arrival = time.strptime(location["arrival_date"], "%Y-%m-%d")
        departure = time.strptime(location["departure_date"], "%Y-%m-%d")
        days_staying = int((time.mktime(departure) - time.mktime(arrival)) / (24 * 60 * 60)) + 1
        
        locations_list.append({
            "id": location["id"],
            "place_name": location["place_name"],
            "arrival_date": location["arrival_date"],
            "departure_date": location["departure_date"],
            "days_staying": days_staying,
            "notes": location["notes"],
            "created_at": location["created_at"],
            "updated_at": location["updated_at"],
            "todos": todos_list,
            "todos_count": len(todos_list),
            "completed_todos": sum(1 for todo in todos_list if todo["is_completed"])
        })
    
    conn.close()
    
    return jsonify({
        "trip_id": trip_id,
        "locations": locations_list,
        "count": len(locations_list)
    }), 200


@app.route("/trips/<int:trip_id>/locations", methods=["POST"])
def add_location(trip_id):
    """
    Add a new location to a trip.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Expected JSON:
    {
        "place_name": str (required),
        "arrival_date": str (required, YYYY-MM-DD),
        "departure_date": str (required, YYYY-MM-DD),
        "notes": str (optional)
    }
    
    Returns:
        - 201: Location created
        - 400: Invalid data
        - 401: Unauthorized
        - 404: Trip not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify trip belongs to user
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        "SELECT id, start_date, end_date FROM trips WHERE id = ? AND user_id = ?",
        (trip_id, user_id)
    )
    
    trip = cursor.fetchone()
    if trip is None:
        conn.close()
        return jsonify({"error": "Trip not found"}), 404
    
    # Validate request
    if not request.is_json:
        conn.close()
        return jsonify({"error": "Request must be JSON"}), 415
    
    data = request.get_json()
    if not data:
        conn.close()
        return jsonify({"error": "No data provided"}), 400
    
    # Required fields
    required_fields = ["place_name", "arrival_date", "departure_date"]
    for field in required_fields:
        if field not in data:
            conn.close()
            return jsonify({"error": f"Missing required field: {field}"}), 400
    
    place_name = data["place_name"]
    arrival_date = data["arrival_date"]
    departure_date = data["departure_date"]
    notes = data.get("notes", "")
    
    # Validate place_name
    if not isinstance(place_name, str) or not place_name.strip():
        conn.close()
        return jsonify({"error": "place_name must be a non-empty string"}), 400
    
    # Validate dates
    try:
        time.strptime(arrival_date, "%Y-%m-%d")
        time.strptime(departure_date, "%Y-%m-%d")
    except ValueError:
        conn.close()
        return jsonify({"error": "Dates must be in YYYY-MM-DD format"}), 400
    
    # Validate date range
    if arrival_date > departure_date:
        conn.close()
        return jsonify({"error": "arrival_date must be before or equal to departure_date"}), 400
    
    # Check if location dates are within trip dates
    if arrival_date < trip["start_date"] or departure_date > trip["end_date"]:
        conn.close()
        return jsonify({"error": "Location dates must be within trip date range"}), 400
    
    # Insert location
    try:
        cursor.execute(
            """
            INSERT INTO locations (trip_id, place_name, arrival_date, departure_date, notes)
            VALUES (?, ?, ?, ?, ?)
            """,
            (trip_id, place_name.strip(), arrival_date, departure_date, notes)
        )
        conn.commit()
        
        # Get the created location
        location_id = cursor.lastrowid
        cursor.execute("SELECT * FROM locations WHERE id = ?", (location_id,))
        new_location = cursor.fetchone()
        conn.close()
        
        return jsonify({
            "message": "Location added successfully",
            "location": {
                "id": new_location["id"],
                "place_name": new_location["place_name"],
                "arrival_date": new_location["arrival_date"],
                "departure_date": new_location["departure_date"],
                "notes": new_location["notes"],
                "created_at": new_location["created_at"]
            }
        }), 201
        
    except sqlite3.Error as e:
        conn.close()
        return jsonify({"error": f"Database error: {str(e)}"}), 500


@app.route("/trips/<int:trip_id>/locations/<int:location_id>", methods=["PUT"])
def update_location(trip_id, location_id):
    """
    Update an existing location.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Expected JSON (all fields optional):
    {
        "place_name": str (optional),
        "arrival_date": str (optional, YYYY-MM-DD),
        "departure_date": str (optional, YYYY-MM-DD),
        "notes": str (optional)
    }
    
    Returns:
        - 200: Location updated
        - 400: Invalid data
        - 401: Unauthorized
        - 404: Location not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify location belongs to user's trip
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT l.*, t.start_date, t.end_date FROM locations l
        JOIN trips t ON l.trip_id = t.id
        WHERE l.id = ? AND l.trip_id = ? AND t.user_id = ?
        """,
        (location_id, trip_id, user_id)
    )
    
    existing_location = cursor.fetchone()
    if existing_location is None:
        conn.close()
        return jsonify({"error": "Location not found"}), 404
    
    # Validate request
    if not request.is_json:
        conn.close()
        return jsonify({"error": "Request must be JSON"}), 415
    
    data = request.get_json()
    if not data:
        conn.close()
        return jsonify({"error": "No data provided"}), 400
    
    # Build update query
    updates = []
    values = []
    
    if "place_name" in data:
        if not isinstance(data["place_name"], str) or not data["place_name"].strip():
            conn.close()
            return jsonify({"error": "place_name must be a non-empty string"}), 400
        updates.append("place_name = ?")
        values.append(data["place_name"].strip())
    
    if "arrival_date" in data:
        try:
            time.strptime(data["arrival_date"], "%Y-%m-%d")
        except ValueError:
            conn.close()
            return jsonify({"error": "arrival_date must be in YYYY-MM-DD format"}), 400
        updates.append("arrival_date = ?")
        values.append(data["arrival_date"])
    
    if "departure_date" in data:
        try:
            time.strptime(data["departure_date"], "%Y-%m-%d")
        except ValueError:
            conn.close()
            return jsonify({"error": "departure_date must be in YYYY-MM-DD format"}), 400
        updates.append("departure_date = ?")
        values.append(data["departure_date"])
    
    if "notes" in data:
        updates.append("notes = ?")
        values.append(data["notes"] if data["notes"] else None)
    
    if not updates:
        conn.close()
        return jsonify({"error": "No valid fields to update"}), 400
    
    # Validate date consistency if both dates are being updated
    new_arrival = data.get("arrival_date", existing_location["arrival_date"])
    new_departure = data.get("departure_date", existing_location["departure_date"])
    
    if new_arrival > new_departure:
        conn.close()
        return jsonify({"error": "arrival_date must be before or equal to departure_date"}), 400
    
    # Check if dates are within trip bounds
    if new_arrival < existing_location["start_date"] or new_departure > existing_location["end_date"]:
        conn.close()
        return jsonify({"error": "Location dates must be within trip date range"}), 400
    
    # Execute update
    values.append(location_id)
    query = f"UPDATE locations SET {', '.join(updates)} WHERE id = ?"
    
    try:
        cursor.execute(query, values)
        conn.commit()
        
        # Get updated location
        cursor.execute("SELECT * FROM locations WHERE id = ?", (location_id,))
        updated_location = cursor.fetchone()
        conn.close()
        
        return jsonify({
            "message": "Location updated successfully",
            "location": {
                "id": updated_location["id"],
                "place_name": updated_location["place_name"],
                "arrival_date": updated_location["arrival_date"],
                "departure_date": updated_location["departure_date"],
                "notes": updated_location["notes"]
            }
        }), 200
        
    except sqlite3.Error as e:
        conn.close()
        return jsonify({"error": f"Database error: {str(e)}"}), 500


@app.route("/trips/<int:trip_id>/locations/<int:location_id>", methods=["DELETE"])
def delete_location(trip_id, location_id):
    """
    Delete a location (cascades to all associated todos).
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Returns:
        - 200: Location deleted
        - 401: Unauthorized
        - 404: Location not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify location belongs to user's trip
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT l.id FROM locations l
        JOIN trips t ON l.trip_id = t.id
        WHERE l.id = ? AND l.trip_id = ? AND t.user_id = ?
        """,
        (location_id, trip_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Location not found"}), 404
    
    # Delete location (todos will cascade)
    cursor.execute("DELETE FROM locations WHERE id = ?", (location_id,))
    conn.commit()
    conn.close()
    
    return jsonify({"message": "Location deleted successfully"}), 200

# ============ TODO MANAGEMENT ENDPOINTS ============

# Helper function to validate todo category
def validate_todo_category(category):
    """Validate todo category"""
    valid_categories = ['sightseeing', 'food', 'transport', 'accommodation', 'packing', 'booking', 'other']
    return category.lower() in valid_categories

@app.route("/locations/<int:location_id>/todos", methods=["GET"])
def get_location_todos(location_id):
    """
    Get all todos for a specific location.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Optional query parameters:
    - completed: 'true' or 'false' to filter by completion status
    - category: filter by category
    
    Returns:
        - 200: List of todos
        - 401: Unauthorized
        - 404: Location not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify location belongs to user's trip
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT l.id FROM locations l
        JOIN trips t ON l.trip_id = t.id
        WHERE l.id = ? AND t.user_id = ?
        """,
        (location_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Location not found"}), 404
    
    # Build query with filters
    query = "SELECT * FROM todos WHERE location_id = ?"
    params = [location_id]
    
    # Filter by completion status
    completed_filter = request.args.get('completed')
    if completed_filter is not None:
        if completed_filter.lower() == 'true':
            query += " AND is_completed = 1"
        elif completed_filter.lower() == 'false':
            query += " AND is_completed = 0"
    
    # Filter by category
    category = request.args.get('category')
    if category:
        if validate_todo_category(category):
            query += " AND category = ?"
            params.append(category.lower())
        else:
            conn.close()
            return jsonify({"error": "Invalid category. Valid categories: sightseeing, food, transport, accommodation, packing, booking, other"}), 400
    
    query += " ORDER BY due_date ASC, created_at ASC"
    
    cursor.execute(query, params)
    todos = cursor.fetchall()
    conn.close()
    
    todos_list = []
    for todo in todos:
        todos_list.append({
            "id": todo["id"],
            "description": todo["description"],
            "is_completed": bool(todo["is_completed"]),
            "category": todo["category"],
            "due_date": todo["due_date"],
            "created_at": todo["created_at"],
            "updated_at": todo["updated_at"]
        })
    
    return jsonify({
        "location_id": location_id,
        "todos": todos_list,
        "count": len(todos_list),
        "completed_count": sum(1 for todo in todos_list if todo["is_completed"])
    }), 200


@app.route("/locations/<int:location_id>/todos", methods=["POST"])
def add_todo(location_id):
    """
    Add a new todo to a location.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Expected JSON:
    {
        "description": str (required),
        "category": str (optional, default 'other'),
        "due_date": str (optional, YYYY-MM-DD)
    }
    
    Returns:
        - 201: Todo created
        - 400: Invalid data
        - 401: Unauthorized
        - 404: Location not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify location belongs to user's trip
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT l.id, l.arrival_date, l.departure_date FROM locations l
        JOIN trips t ON l.trip_id = t.id
        WHERE l.id = ? AND t.user_id = ?
        """,
        (location_id, user_id)
    )
    
    location = cursor.fetchone()
    if location is None:
        conn.close()
        return jsonify({"error": "Location not found"}), 404
    
    # Validate request
    if not request.is_json:
        conn.close()
        return jsonify({"error": "Request must be JSON"}), 415
    
    data = request.get_json()
    if not data:
        conn.close()
        return jsonify({"error": "No data provided"}), 400
    
    # Required fields
    if "description" not in data:
        conn.close()
        return jsonify({"error": "description is required"}), 400
    
    description = data["description"]
    category = data.get("category", "other")
    due_date = data.get("due_date")
    
    # Validate description
    if not isinstance(description, str) or not description.strip():
        conn.close()
        return jsonify({"error": "description must be a non-empty string"}), 400
    
    # Validate category
    if not validate_todo_category(category):
        conn.close()
        return jsonify({"error": "Invalid category. Valid categories: sightseeing, food, transport, accommodation, packing, booking, other"}), 400
    
    # Validate due date if provided
    if due_date:
        try:
            time.strptime(due_date, "%Y-%m-%d")
        except ValueError:
            conn.close()
            return jsonify({"error": "due_date must be in YYYY-MM-DD format"}), 400
        
        # Check if due date is within location date range
        if due_date < location["arrival_date"] or due_date > location["departure_date"]:
            conn.close()
            return jsonify({"error": "due_date must be within location date range"}), 400
    
    # Insert todo
    try:
        cursor.execute(
            """
            INSERT INTO todos (location_id, description, category, due_date)
            VALUES (?, ?, ?, ?)
            """,
            (location_id, description.strip(), category.lower(), due_date)
        )
        conn.commit()
        
        # Get the created todo
        todo_id = cursor.lastrowid
        cursor.execute("SELECT * FROM todos WHERE id = ?", (todo_id,))
        new_todo = cursor.fetchone()
        conn.close()
        
        return jsonify({
            "message": "Todo added successfully",
            "todo": {
                "id": new_todo["id"],
                "description": new_todo["description"],
                "is_completed": bool(new_todo["is_completed"]),
                "category": new_todo["category"],
                "due_date": new_todo["due_date"],
                "created_at": new_todo["created_at"]
            }
        }), 201
        
    except sqlite3.Error as e:
        conn.close()
        return jsonify({"error": f"Database error: {str(e)}"}), 500


@app.route("/todos/<int:todo_id>", methods=["PUT"])
def update_todo(todo_id):
    """
    Update an existing todo.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Expected JSON (all fields optional):
    {
        "description": str (optional),
        "is_completed": bool (optional),
        "category": str (optional),
        "due_date": str (optional, YYYY-MM-DD)
    }
    
    Returns:
        - 200: Todo updated
        - 400: Invalid data
        - 401: Unauthorized
        - 404: Todo not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify todo belongs to user's location and trip
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT t.*, l.arrival_date, l.departure_date FROM todos t
        JOIN locations l ON t.location_id = l.id
        JOIN trips tr ON l.trip_id = tr.id
        WHERE t.id = ? AND tr.user_id = ?
        """,
        (todo_id, user_id)
    )
    
    existing_todo = cursor.fetchone()
    if existing_todo is None:
        conn.close()
        return jsonify({"error": "Todo not found"}), 404
    
    # Validate request
    if not request.is_json:
        conn.close()
        return jsonify({"error": "Request must be JSON"}), 415
    
    data = request.get_json()
    if not data:
        conn.close()
        return jsonify({"error": "No data provided"}), 400
    
    # Build update query
    updates = []
    values = []
    
    if "description" in data:
        if not isinstance(data["description"], str) or not data["description"].strip():
            conn.close()
            return jsonify({"error": "description must be a non-empty string"}), 400
        updates.append("description = ?")
        values.append(data["description"].strip())
    
    if "is_completed" in data:
        if not isinstance(data["is_completed"], bool):
            conn.close()
            return jsonify({"error": "is_completed must be a boolean"}), 400
        updates.append("is_completed = ?")
        values.append(1 if data["is_completed"] else 0)
    
    if "category" in data:
        if not validate_todo_category(data["category"]):
            conn.close()
            return jsonify({"error": "Invalid category. Valid categories: sightseeing, food, transport, accommodation, packing, booking, other"}), 400
        updates.append("category = ?")
        values.append(data["category"].lower())
    
    if "due_date" in data:
        if data["due_date"] is not None:
            try:
                time.strptime(data["due_date"], "%Y-%m-%d")
            except ValueError:
                conn.close()
                return jsonify({"error": "due_date must be in YYYY-MM-DD format"}), 400
            
            # Check if due date is within location date range
            if data["due_date"] < existing_todo["arrival_date"] or data["due_date"] > existing_todo["departure_date"]:
                conn.close()
                return jsonify({"error": "due_date must be within location date range"}), 400
        updates.append("due_date = ?")
        values.append(data["due_date"])
    
    if not updates:
        conn.close()
        return jsonify({"error": "No valid fields to update"}), 400
    
    # Execute update
    values.append(todo_id)
    query = f"UPDATE todos SET {', '.join(updates)} WHERE id = ?"
    
    try:
        cursor.execute(query, values)
        conn.commit()
        
        # Get updated todo
        cursor.execute("SELECT * FROM todos WHERE id = ?", (todo_id,))
        updated_todo = cursor.fetchone()
        conn.close()
        
        return jsonify({
            "message": "Todo updated successfully",
            "todo": {
                "id": updated_todo["id"],
                "description": updated_todo["description"],
                "is_completed": bool(updated_todo["is_completed"]),
                "category": updated_todo["category"],
                "due_date": updated_todo["due_date"]
            }
        }), 200
        
    except sqlite3.Error as e:
        conn.close()
        return jsonify({"error": f"Database error: {str(e)}"}), 500


@app.route("/todos/<int:todo_id>", methods=["DELETE"])
def delete_todo(todo_id):
    """
    Delete a todo.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Returns:
        - 200: Todo deleted
        - 401: Unauthorized
        - 404: Todo not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify todo belongs to user's location and trip
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT t.id FROM todos t
        JOIN locations l ON t.location_id = l.id
        JOIN trips tr ON l.trip_id = tr.id
        WHERE t.id = ? AND tr.user_id = ?
        """,
        (todo_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Todo not found"}), 404
    
    # Delete todo
    cursor.execute("DELETE FROM todos WHERE id = ?", (todo_id,))
    conn.commit()
    conn.close()
    
    return jsonify({"message": "Todo deleted successfully"}), 200


@app.route("/todos/<int:todo_id>/complete", methods=["PATCH"])
def complete_todo(todo_id):
    """
    Mark a todo as completed (convenience endpoint).
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Returns:
        - 200: Todo marked as completed
        - 401: Unauthorized
        - 404: Todo not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify todo belongs to user
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT t.id FROM todos t
        JOIN locations l ON t.location_id = l.id
        JOIN trips tr ON l.trip_id = tr.id
        WHERE t.id = ? AND tr.user_id = ?
        """,
        (todo_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Todo not found"}), 404
    
    # Mark as completed
    cursor.execute(
        "UPDATE todos SET is_completed = 1 WHERE id = ?",
        (todo_id,)
    )
    conn.commit()
    conn.close()
    
    return jsonify({
        "message": "Todo marked as completed",
        "todo_id": todo_id
    }), 200


@app.route("/todos/<int:todo_id>/incomplete", methods=["PATCH"])
def incomplete_todo(todo_id):
    """
    Mark a todo as incomplete (convenience endpoint).
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Returns:
        - 200: Todo marked as incomplete
        - 401: Unauthorized
        - 404: Todo not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify todo belongs to user
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT t.id FROM todos t
        JOIN locations l ON t.location_id = l.id
        JOIN trips tr ON l.trip_id = tr.id
        WHERE t.id = ? AND tr.user_id = ?
        """,
        (todo_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Todo not found"}), 404
    
    # Mark as incomplete
    cursor.execute(
        "UPDATE todos SET is_completed = 0 WHERE id = ?",
        (todo_id,)
    )
    conn.commit()
    conn.close()
    
    return jsonify({
        "message": "Todo marked as incomplete",
        "todo_id": todo_id
    }), 200

# Configuration for file uploads
UPLOAD_FOLDER = 'static/uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'heic'}
MAX_FILE_SIZE = 16 * 1024 * 1024  # 16MB

# Create upload folder if it doesn't exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Helper function to check allowed file extensions
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Helper function to get file size
def get_file_size(file_path):
    return os.path.getsize(file_path) if os.path.exists(file_path) else 0

# ============ GALLERY MANAGEMENT ENDPOINTS ============

@app.route("/locations/<int:location_id>/gallery", methods=["GET"])
def get_location_gallery(location_id):
    """
    Get all images for a specific location.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Returns:
        - 200: List of gallery images
        - 401: Unauthorized
        - 403: Forbidden
        - 404: Location not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify location belongs to user's trip
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT l.id FROM locations l
        JOIN trips t ON l.trip_id = t.id
        WHERE l.id = ? AND t.user_id = ?
        """,
        (location_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Location not found"}), 404
    
    # Get all images for the location
    cursor.execute(
        """
        SELECT * FROM gallery 
        WHERE location_id = ? 
        ORDER BY uploaded_at DESC
        """,
        (location_id,)
    )
    
    images = cursor.fetchall()
    conn.close()
    
    # Build full URLs for images
    base_url = request.host_url.rstrip('/')
    images_list = []
    for image in images:
        images_list.append({
            "id": image["id"],
            "image_url": f"{base_url}/{image['image_path']}",
            "image_path": image["image_path"],
            "caption": image["caption"],
            "file_name": image["file_name"],
            "file_size": image["file_size"],
            "mime_type": image["mime_type"],
            "uploaded_at": image["uploaded_at"],
            "uploaded_at_formatted": time.strftime("%B %d, %Y at %H:%M", time.localtime(image["uploaded_at"]))
        })
    
    return jsonify({
        "location_id": location_id,
        "images": images_list,
        "count": len(images_list)
    }), 200


@app.route("/locations/<int:location_id>/gallery", methods=["POST"])
def upload_image(location_id):
    """
    Upload an image to a location's gallery.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Expected form data:
    - image: file (required)
    - caption: string (optional)
    
    Returns:
        - 201: Image uploaded successfully
        - 400: Invalid file or missing data
        - 401: Unauthorized
        - 404: Location not found
        - 413: File too large
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify location belongs to user's trip
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT l.id FROM locations l
        JOIN trips t ON l.trip_id = t.id
        WHERE l.id = ? AND t.user_id = ?
        """,
        (location_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Location not found"}), 404
    
    # Check if file was uploaded
    if 'image' not in request.files:
        conn.close()
        return jsonify({"error": "No image file provided"}), 400
    
    file = request.files['image']
    
    if file.filename == '':
        conn.close()
        return jsonify({"error": "No image selected"}), 400
    
    # Validate file type
    if not allowed_file(file.filename):
        conn.close()
        return jsonify({"error": f"File type not allowed. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}"}), 400
    
    # Secure the filename and create unique name
    original_filename = secure_filename(file.filename)
    file_ext = original_filename.rsplit('.', 1)[1].lower()
    unique_filename = f"{int(time.time())}_{location_id}_{original_filename}"
    
    # Create location-specific subdirectory
    location_folder = os.path.join(UPLOAD_FOLDER, str(location_id))
    os.makedirs(location_folder, exist_ok=True)
    
    # Save the file
    file_path = os.path.join(location_folder, unique_filename)
    relative_path = os.path.join('static/uploads', str(location_id), unique_filename).replace('\\', '/')
    
    try:
        file.save(file_path)
        
        # Get file size
        file_size = os.path.getsize(file_path)
        
        # Check file size limit
        if file_size > MAX_FILE_SIZE:
            os.remove(file_path)
            conn.close()
            return jsonify({"error": f"File too large. Maximum size: {MAX_FILE_SIZE // (1024*1024)}MB"}), 413
        
        # Get caption from form data
        caption = request.form.get('caption', '')
        
        # Get mime type (simple detection)
        mime_type = f"image/{file_ext}"
        if file_ext == 'jpg':
            mime_type = 'image/jpeg'
        
        # Insert into database
        cursor.execute(
            """
            INSERT INTO gallery (location_id, image_path, caption, file_name, file_size, mime_type)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (location_id, relative_path, caption, original_filename, file_size, mime_type)
        )
        conn.commit()
        
        image_id = cursor.lastrowid
        
        # Get the uploaded image info
        cursor.execute("SELECT * FROM gallery WHERE id = ?", (image_id,))
        new_image = cursor.fetchone()
        conn.close()
        
        base_url = request.host_url.rstrip('/')
        
        return jsonify({
            "message": "Image uploaded successfully",
            "image": {
                "id": new_image["id"],
                "image_url": f"{base_url}/{relative_path}",
                "image_path": relative_path,
                "caption": new_image["caption"],
                "file_name": new_image["file_name"],
                "file_size": new_image["file_size"],
                "mime_type": new_image["mime_type"],
                "uploaded_at": new_image["uploaded_at"]
            }
        }), 201
        
    except Exception as e:
        # Clean up file if database insert fails
        if os.path.exists(file_path):
            os.remove(file_path)
        conn.close()
        return jsonify({"error": f"Failed to upload image: {str(e)}"}), 500


@app.route("/gallery/<int:image_id>", methods=["PUT"])
def update_image_caption(image_id):
    """
    Update the caption/description of a gallery image.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Expected JSON:
    {
        "caption": str (required)
    }
    
    Returns:
        - 200: Caption updated successfully
        - 400: Missing caption
        - 401: Unauthorized
        - 404: Image not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify image belongs to user's location and trip
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT g.id FROM gallery g
        JOIN locations l ON g.location_id = l.id
        JOIN trips t ON l.trip_id = t.id
        WHERE g.id = ? AND t.user_id = ?
        """,
        (image_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Image not found"}), 404
    
    # Validate request
    if not request.is_json:
        conn.close()
        return jsonify({"error": "Request must be JSON"}), 415
    
    data = request.get_json()
    if not data or "caption" not in data:
        conn.close()
        return jsonify({"error": "caption is required"}), 400
    
    caption = data["caption"]
    
    # Update caption
    try:
        cursor.execute(
            "UPDATE gallery SET caption = ? WHERE id = ?",
            (caption, image_id)
        )
        conn.commit()
        conn.close()
        
        return jsonify({
            "message": "Caption updated successfully",
            "image_id": image_id,
            "caption": caption
        }), 200
        
    except sqlite3.Error as e:
        conn.close()
        return jsonify({"error": f"Database error: {str(e)}"}), 500


@app.route("/gallery/<int:image_id>", methods=["DELETE"])
def delete_image(image_id):
    """
    Delete an image from the gallery (removes file from disk too).
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Returns:
        - 200: Image deleted successfully
        - 401: Unauthorized
        - 404: Image not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify image belongs to user's location and trip
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT g.id, g.image_path FROM gallery g
        JOIN locations l ON g.location_id = l.id
        JOIN trips t ON l.trip_id = t.id
        WHERE g.id = ? AND t.user_id = ?
        """,
        (image_id, user_id)
    )
    
    image = cursor.fetchone()
    if image is None:
        conn.close()
        return jsonify({"error": "Image not found"}), 404
    
    # Delete the file from disk
    file_path = image["image_path"]
    if os.path.exists(file_path):
        try:
            os.remove(file_path)
        except Exception as e:
            # Log error but continue with database deletion
            print(f"Warning: Could not delete file {file_path}: {e}")
    
    # Delete from database
    cursor.execute("DELETE FROM gallery WHERE id = ?", (image_id,))
    conn.commit()
    conn.close()
    
    return jsonify({
        "message": "Image deleted successfully",
        "image_id": image_id
    }), 200


# Optional: Bulk upload endpoint
@app.route("/locations/<int:location_id>/gallery/bulk", methods=["POST"])
def bulk_upload_images(location_id):
    """
    Upload multiple images to a location's gallery at once.
    
    Expected Authorization header:
    Authorization: Bearer <token>
    
    Expected form data:
    - images: files (multiple, required)
    - captions: string (optional, comma-separated for multiple images)
    
    Returns:
        - 201: Images uploaded successfully
        - 400: Invalid files
        - 401: Unauthorized
        - 404: Location not found
    """
    # Authenticate user
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return jsonify({"error": "Unauthorized"}), 401
    
    token = auth_header.replace("Bearer ", "", 1) if auth_header.startswith("Bearer ") else auth_header
    user_id = get_user_id_from_token(token)
    
    if user_id is None:
        return jsonify({"error": "Invalid or expired token"}), 401
    
    # Verify location belongs to user's trip
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute(
        """
        SELECT l.id FROM locations l
        JOIN trips t ON l.trip_id = t.id
        WHERE l.id = ? AND t.user_id = ?
        """,
        (location_id, user_id)
    )
    
    if cursor.fetchone() is None:
        conn.close()
        return jsonify({"error": "Location not found"}), 404
    
    # Check if files were uploaded
    if 'images' not in request.files:
        conn.close()
        return jsonify({"error": "No image files provided"}), 400
    
    files = request.files.getlist('images')
    
    if len(files) == 0 or files[0].filename == '':
        conn.close()
        return jsonify({"error": "No images selected"}), 400
    
    # Get captions if provided (comma-separated)
    captions_input = request.form.get('captions', '')
    captions = [c.strip() for c in captions_input.split(',')] if captions_input else []
    
    uploaded_images = []
    errors = []
    
    for idx, file in enumerate(files):
        if file.filename == '':
            continue
            
        # Validate file type
        if not allowed_file(file.filename):
            errors.append(f"File {file.filename}: Type not allowed")
            continue
        
        # Process each file
        original_filename = secure_filename(file.filename)
        file_ext = original_filename.rsplit('.', 1)[1].lower()
        unique_filename = f"{int(time.time())}_{location_id}_{idx}_{original_filename}"
        
        # Create location-specific subdirectory
        location_folder = os.path.join(UPLOAD_FOLDER, str(location_id))
        os.makedirs(location_folder, exist_ok=True)
        
        # Save the file
        file_path = os.path.join(location_folder, unique_filename)
        relative_path = os.path.join('static/uploads', str(location_id), unique_filename).replace('\\', '/')
        
        try:
            file.save(file_path)
            
            # Get file size
            file_size = os.path.getsize(file_path)
            
            # Check file size limit
            if file_size > MAX_FILE_SIZE:
                os.remove(file_path)
                errors.append(f"File {file.filename}: Too large (>16MB)")
                continue
            
            # Get caption for this image (if provided)
            caption = captions[idx] if idx < len(captions) else ''
            
            # Get mime type
            mime_type = f"image/{file_ext}"
            if file_ext == 'jpg':
                mime_type = 'image/jpeg'
            
            # Insert into database
            cursor.execute(
                """
                INSERT INTO gallery (location_id, image_path, caption, file_name, file_size, mime_type)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (location_id, relative_path, caption, original_filename, file_size, mime_type)
            )
            conn.commit()
            
            image_id = cursor.lastrowid
            
            # Get the uploaded image info
            cursor.execute("SELECT * FROM gallery WHERE id = ?", (image_id,))
            new_image = cursor.fetchone()
            
            base_url = request.host_url.rstrip('/')
            
            uploaded_images.append({
                "id": new_image["id"],
                "image_url": f"{base_url}/{relative_path}",
                "caption": new_image["caption"],
                "file_name": new_image["file_name"]
            })
            
        except Exception as e:
            # Clean up file if error occurs
            if os.path.exists(file_path):
                os.remove(file_path)
            errors.append(f"File {file.filename}: {str(e)}")
    
    conn.close()
    
    return jsonify({
        "message": f"Successfully uploaded {len(uploaded_images)} image(s)",
        "uploaded_images": uploaded_images,
        "errors": errors if errors else None,
        "total_uploaded": len(uploaded_images),
        "total_errors": len(errors)
    }), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)