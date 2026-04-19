def api_info():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>🌍 TourBud API - Your Travel Companion</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: #333;
                line-height: 1.6;
            }
            
            .container {
                max-width: 1200px;
                margin: 0 auto;
                padding: 20px;
            }
            
            .header {
                background: white;
                border-radius: 20px;
                padding: 40px;
                margin-bottom: 30px;
                text-align: center;
                box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            }
            
            h1 {
                font-size: 3em;
                color: #667eea;
                margin-bottom: 10px;
            }
            
            .badge {
                display: inline-block;
                background: #48bb78;
                color: white;
                padding: 5px 15px;
                border-radius: 20px;
                font-size: 0.9em;
                margin-top: 10px;
            }
            
            .section {
                background: white;
                border-radius: 15px;
                padding: 30px;
                margin-bottom: 30px;
                box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            }
            
            .section h2 {
                color: #667eea;
                margin-bottom: 20px;
                padding-bottom: 10px;
                border-bottom: 3px solid #e2e8f0;
            }
            
            .endpoint {
                background: #f7fafc;
                border-left: 4px solid #667eea;
                padding: 15px;
                margin: 15px 0;
                border-radius: 0 8px 8px 0;
                transition: transform 0.2s;
            }
            
            .endpoint:hover {
                transform: translateX(5px);
            }
            
            .method {
                display: inline-block;
                padding: 4px 12px;
                border-radius: 5px;
                font-weight: bold;
                font-size: 0.85em;
                margin-right: 10px;
            }
            
            .get { background: #48bb78; color: white; }
            .post { background: #4299e1; color: white; }
            .put { background: #ed8936; color: white; }
            .patch { background: #9f7aea; color: white; }
            .delete { background: #f56565; color: white; }
            
            .path {
                font-family: 'Courier New', monospace;
                font-weight: bold;
                color: #2d3748;
            }
            
            .code {
                background: #2d3748;
                color: #68d391;
                padding: 15px;
                border-radius: 8px;
                overflow-x: auto;
                font-family: 'Courier New', monospace;
                font-size: 0.9em;
                margin: 10px 0;
            }
            
            .grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 20px;
                margin-top: 20px;
            }
            
            .card {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 20px;
                border-radius: 15px;
                text-align: center;
            }
            
            .card h3 {
                font-size: 2em;
                margin-bottom: 10px;
            }
            
            .note {
                background: #fefcbf;
                border-left: 4px solid #ecc94b;
                padding: 15px;
                margin: 20px 0;
                border-radius: 5px;
            }
            
            .footer {
                text-align: center;
                color: white;
                padding: 20px;
            }
            
            @media (max-width: 768px) {
                .header h1 { font-size: 2em; }
                .section { padding: 20px; }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🌍 TourBud API</h1>
                <p><strong>Your travel companion for planning adventures, managing budgets, and connecting with fellow explorers!</strong></p>
                <span class="badge">Version 2.0.0</span>
                <span class="badge" style="background: #4299e1; margin-left: 10px;">Operational</span>
            </div>
            
            <div class="grid">
                <div class="card">
                    <h3>🔐</h3>
                    <h3>Authentication</h3>
                    <p>Secure token-based auth with 7-day sessions</p>
                </div>
                <div class="card">
                    <h3>✈️</h3>
                    <h3>Trip Management</h3>
                    <p>Full CRUD operations for your adventures</p>
                </div>
                <div class="card">
                    <h3>💰</h3>
                    <h3>Budget Tracking</h3>
                    <p>Multi-currency budget goals</p>
                </div>
                <div class="card">
                    <h3>👤</h3>
                    <h3>Profile</h3>
                    <p>Complete user profile management</p>
                </div>
            </div>
            
            <div class="section">
                <h2>🚀 Quick Start (Copy-Paste Ready)</h2>
                <div class="code">
                    # 1. Create an account<br>
                    curl -X POST http://localhost:5000/register \<br>
                    &nbsp;&nbsp;-H "Content-Type: application/json" \<br>
                    &nbsp;&nbsp;-d '{"username": "traveler123", "password": "securepass"}'<br><br>
                    
                    # 2. Login to get your token<br>
                    curl -X POST http://localhost:5000/login \<br>
                    &nbsp;&nbsp;-H "Content-Type: application/json" \<br>
                    &nbsp;&nbsp;-d '{"username": "traveler123", "password": "securepass"}'<br><br>
                    
                    # 3. Create your first trip<br>
                    curl -X POST http://localhost:5000/trips \<br>
                    &nbsp;&nbsp;-H "Authorization: Bearer YOUR-TOKEN-HERE" \<br>
                    &nbsp;&nbsp;-H "Content-Type: application/json" \<br>
                    &nbsp;&nbsp;-d '{"trip_name": "Summer Adventure", "start_date": "2024-06-01", "end_date": "2024-06-10", "budget_goal": 1000}'
                </div>
            </div>
            
            <div class="section">
                <h2>🔐 Authentication Endpoints</h2>
                
                <div class="endpoint">
                    <span class="method post">POST</span>
                    <span class="path">/register</span>
                    <p>Create a new account with optional profile info</p>
                </div>
                
                <div class="endpoint">
                    <span class="method post">POST</span>
                    <span class="path">/login</span>
                    <p>Login and receive a session token</p>
                </div>
                
                <div class="endpoint">
                    <span class="method post">POST</span>
                    <span class="path">/logout</span>
                    <p>Invalidate your session token</p>
                </div>
            </div>
            
            <div class="section">
                <h2>👤 Profile Endpoints</h2>
                
                <div class="endpoint">
                    <span class="method get">GET</span>
                    <span class="path">/profile</span>
                    <p>View your profile information</p>
                </div>
                
                <div class="endpoint">
                    <span class="method put">PUT</span>
                    <span class="path">/profile</span>
                    <p>Update your profile (full_name, contact_number, date_of_birth)</p>
                </div>
            </div>
            
            <div class="section">
                <h2>✈️ Trip Management Endpoints</h2>
                
                <div class="endpoint">
                    <span class="method get">GET</span>
                    <span class="path">/trips</span>
                    <p>Get all your trips (use ?upcoming=true or ?past=true to filter)</p>
                </div>
                
                <div class="endpoint">
                    <span class="method get">GET</span>
                    <span class="path">/trips/&lt;trip_id&gt;</span>
                    <p>Get details of a specific trip</p>
                </div>
                
                <div class="endpoint">
                    <span class="method post">POST</span>
                    <span class="path">/trips</span>
                    <p>Create a new trip</p>
                </div>
                
                <div class="endpoint">
                    <span class="method put">PUT</span>
                    <span class="path">/trips/&lt;trip_id&gt;</span>
                    <p>Update an existing trip</p>
                </div>
                
                <div class="endpoint">
                    <span class="method patch">PATCH</span>
                    <span class="path">/trips/&lt;trip_id&gt;/budget</span>
                    <p>Update only the budget goal for a trip</p>
                </div>
                
                <div class="endpoint">
                    <span class="method delete">DELETE</span>
                    <span class="path">/trips/&lt;trip_id&gt;</span>
                    <p>Delete a trip</p>
                </div>
            </div>
            
            <div class="note">
                <strong>📝 Important Notes:</strong>
                <ul style="margin-top: 10px; margin-left: 20px;">
                    <li>🔐 Passwords are stored in plaintext (demo only - not for production!)</li>
                    <li>⏰ Sessions expire after 7 days</li>
                    <li>🧹 Expired sessions are automatically cleaned up</li>
                    <li>💱 Budget currency uses 3-letter ISO codes (USD, EUR, GBP, etc.)</li>
                    <li>📅 All dates must be in YYYY-MM-DD format</li>
                    <li>🔑 Include your token in requests: <code>Authorization: Bearer &lt;your-token-here&gt;</code></li>
                </ul>
            </div>
            
            <div class="note" style="background: #e6fffa; border-left-color: #38b2ac;">
                <strong>🎯 Features Coming Soon:</strong>
                <ul style="margin-top: 10px; margin-left: 20px;">
                    <li>📝 Itinerary planning with daily activities</li>
                    <li>💸 Expense tracking and splitting</li>
                    <li>👥 Travel buddy matching</li>
                    <li>📸 Photo uploads for trips</li>
                    <li>⭐ Place reviews and recommendations</li>
                </ul>
            </div>
            
            <div class="footer">
                <p>🌟 Happy travels with TourBud! 🌟</p>
                <p><small>Check the source code or README for complete documentation</small></p>
            </div>
        </div>
    </body>
    </html>
    """