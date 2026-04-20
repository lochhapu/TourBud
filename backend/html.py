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
            
            .version {
                display: inline-block;
                background: #48bb78;
                color: white;
                padding: 5px 15px;
                border-radius: 20px;
                font-size: 0.9em;
                margin-top: 10px;
            }
            
            .status {
                display: inline-block;
                background: #4299e1;
                color: white;
                padding: 5px 15px;
                border-radius: 20px;
                font-size: 0.9em;
                margin-top: 10px;
                margin-left: 10px;
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
                display: flex;
                align-items: center;
                gap: 10px;
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
                background: #edf2f7;
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
                margin-bottom: 20px;
            }
            
            .card {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 20px;
                border-radius: 15px;
                text-align: center;
                transition: transform 0.3s;
            }
            
            .card:hover {
                transform: translateY(-5px);
            }
            
            .card h3 {
                font-size: 2em;
                margin-bottom: 10px;
            }
            
            .category-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
                gap: 15px;
                margin-top: 15px;
            }
            
            .category-card {
                background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                color: white;
                padding: 15px;
                border-radius: 10px;
                text-align: center;
            }
            
            .category-card h4 {
                font-size: 1.2em;
                margin-bottom: 5px;
            }
            
            .category-card p {
                font-size: 0.9em;
                opacity: 0.9;
            }
            
            .note {
                background: #fefcbf;
                border-left: 4px solid #ecc94b;
                padding: 15px;
                margin: 20px 0;
                border-radius: 5px;
            }
            
            .success-note {
                background: #c6f6d5;
                border-left-color: #48bb78;
            }
            
            .stats {
                display: flex;
                justify-content: space-around;
                flex-wrap: wrap;
                gap: 20px;
                margin: 20px 0;
            }
            
            .stat-box {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 20px;
                border-radius: 15px;
                text-align: center;
                flex: 1;
                min-width: 150px;
            }
            
            .stat-number {
                font-size: 2.5em;
                font-weight: bold;
            }
            
            .footer {
                text-align: center;
                color: white;
                padding: 20px;
            }
            
            @media (max-width: 768px) {
                .header h1 { font-size: 2em; }
                .section { padding: 20px; }
                .stats { flex-direction: column; }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🌍 TourBud API</h1>
                <p><strong>Your complete travel companion for planning adventures, managing budgets, tracking expenses, and connecting with fellow explorers!</strong></p>
                <span class="version">Version 3.0.0</span>
                <span class="status">🚀 Operational</span>
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
                    <p>Multi-currency budget goals with alerts</p>
                </div>
                <div class="card">
                    <h3>💸</h3>
                    <h3>Expense Tracking</h3>
                    <p>Complete expense management with categories</p>
                </div>
                <div class="card">
                    <h3>👤</h3>
                    <h3>Profile</h3>
                    <p>Complete user profile management</p>
                </div>
                <div class="card">
                    <h3>📊</h3>
                    <h3>Analytics</h3>
                    <p>Expense summaries and budget insights</p>
                </div>
            </div>
            
            <div class="stats">
                <div class="stat-box">
                    <div class="stat-number">18</div>
                    <div>Total Endpoints</div>
                </div>
                <div class="stat-box">
                    <div class="stat-number">15</div>
                    <div>Authenticated Endpoints</div>
                </div>
                <div class="stat-box">
                    <div class="stat-number">3</div>
                    <div>Public Endpoints</div>
                </div>
                <div class="stat-box">
                    <div class="stat-number">6</div>
                    <div>Expense Categories</div>
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
                    &nbsp;&nbsp;-d '{"trip_name": "Summer Adventure", "start_date": "2024-06-01", "end_date": "2024-06-10", "budget_goal": 1000}'<br><br>
                    
                    # 4. Add an expense<br>
                    curl -X POST http://localhost:5000/trips/1/expenses \<br>
                    &nbsp;&nbsp;-H "Authorization: Bearer YOUR-TOKEN-HERE" \<br>
                    &nbsp;&nbsp;-H "Content-Type: application/json" \<br>
                    &nbsp;&nbsp;-d '{"amount": 45.50, "category": "food", "description": "Lunch at cafe"}'<br><br>
                    
                    # 5. View expense summary<br>
                    curl -X GET http://localhost:5000/trips/1/expenses/summary \<br>
                    &nbsp;&nbsp;-H "Authorization: Bearer YOUR-TOKEN-HERE"<br><br>
                    
                    # 6. Logout<br>
                    curl -X POST http://localhost:5000/logout \<br>
                    &nbsp;&nbsp;-H "Authorization: Bearer YOUR-TOKEN-HERE"
                </div>
            </div>
            
            <div class="section">
                <h2>🔐 Authentication Endpoints</h2>
                
                <div class="endpoint">
                    <span class="method post">POST</span>
                    <span class="path">/register</span>
                    <p>Create a new account with optional profile info (full_name, contact_number, date_of_birth)</p>
                </div>
                
                <div class="endpoint">
                    <span class="method post">POST</span>
                    <span class="path">/login</span>
                    <p>Login and receive a session token (valid for 7 days)</p>
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
                    <p>View your profile information (username, full_name, contact_number, date_of_birth, member_since)</p>
                </div>
                
                <div class="endpoint">
                    <span class="method put">PUT</span>
                    <span class="path">/profile</span>
                    <p>Update your profile (full_name, contact_number, date_of_birth - all optional)</p>
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
                    <p>Create a new trip (trip_name, start_date, end_date required)</p>
                </div>
                
                <div class="endpoint">
                    <span class="method put">PUT</span>
                    <span class="path">/trips/&lt;trip_id&gt;</span>
                    <p>Update an existing trip (all fields optional)</p>
                </div>
                
                <div class="endpoint">
                    <span class="method patch">PATCH</span>
                    <span class="path">/trips/&lt;trip_id&gt;/budget</span>
                    <p>Update only the budget goal for a trip</p>
                </div>
                
                <div class="endpoint">
                    <span class="method delete">DELETE</span>
                    <span class="path">/trips/&lt;trip_id&gt;</span>
                    <p>Delete a trip (cascades to all expenses)</p>
                </div>
            </div>
            
            <div class="section">
                <h2>💰 Expense Tracking Endpoints</h2>
                
                <div class="endpoint">
                    <span class="method get">GET</span>
                    <span class="path">/trips/&lt;trip_id&gt;/expenses</span>
                    <p>Get all expenses for a trip (filter by ?category=, ?start_date=, ?end_date=)</p>
                </div>
                
                <div class="endpoint">
                    <span class="method post">POST</span>
                    <span class="path">/trips/&lt;trip_id&gt;/expenses</span>
                    <p>Add a new expense (amount, category required)</p>
                </div>
                
                <div class="endpoint">
                    <span class="method put">PUT</span>
                    <span class="path">/trips/&lt;trip_id&gt;/expenses/&lt;expense_id&gt;</span>
                    <p>Update an existing expense (all fields optional)</p>
                </div>
                
                <div class="endpoint">
                    <span class="method delete">DELETE</span>
                    <span class="path">/trips/&lt;trip_id&gt;/expenses/&lt;expense_id&gt;</span>
                    <p>Delete an expense</p>
                </div>
                
                <div class="endpoint">
                    <span class="method get">GET</span>
                    <span class="path">/trips/&lt;trip_id&gt;/expenses/summary</span>
                    <p>Get expense summary with budget tracking and category breakdown</p>
                </div>
            </div>
            
            <div class="section">
                <h2>📊 Expense Categories</h2>
                <div class="category-grid">
                    <div class="category-card">
                        <h4>🏨 Accommodation</h4>
                        <p>Hotels, hostels, Airbnb, camping</p>
                    </div>
                    <div class="category-card">
                        <h4>🚗 Transportation</h4>
                        <p>Flights, trains, buses, taxis, rentals</p>
                    </div>
                    <div class="category-card">
                        <h4>🍜 Food</h4>
                        <p>Restaurants, groceries, snacks, drinks</p>
                    </div>
                    <div class="category-card">
                        <h4>🎭 Activities</h4>
                        <p>Tours, museums, attractions, entertainment</p>
                    </div>
                    <div class="category-card">
                        <h4>🛍️ Shopping</h4>
                        <p>Souvenirs, gifts, shopping</p>
                    </div>
                    <div class="category-card">
                        <h4>📦 Other</h4>
                        <p>Miscellaneous expenses</p>
                    </div>
                </div>
            </div>
            
            <div class="note success-note">
                <strong>🎯 Budget Tracking Features:</strong>
                <ul style="margin-top: 10px; margin-left: 20px;">
                    <li>✅ Automatic budget vs. spent calculation</li>
                    <li>✅ Real-time budget status: <span style="color:#48bb78;">Good</span> (&lt;90%), <span style="color:#ed8936;">Warning</span> (90-100%), <span style="color:#f56565;">Over Budget</span> (&gt;100%)</li>
                    <li>✅ Daily average spending based on trip duration</li>
                    <li>✅ Category breakdown with percentages</li>
                    <li>✅ Multi-currency support (USD, EUR, GBP, etc.)</li>
                </ul>
            </div>
            
            <div class="note">
                <strong>📝 Important Notes:</strong>
                <ul style="margin-top: 10px; margin-left: 20px;">
                    <li>🔐 Passwords are stored in plaintext (demo only - not for production!)</li>
                    <li>⏰ Sessions expire after 7 days</li>
                    <li>🧹 Expired sessions are automatically cleaned up</li>
                    <li>💱 Budget currency uses 3-letter ISO codes (USD, EUR, GBP, etc.)</li>
                    <li>📅 All dates must be in YYYY-MM-DD format</li>
                    <li>💰 Expenses automatically update trip budget tracking</li>
                    <li>🔑 Include your token in requests: <code>Authorization: Bearer &lt;your-token-here&gt;</code></li>
                    <li>🗑️ Deleting a trip automatically deletes all associated expenses</li>
                </ul>
            </div>
            
            <div class="note" style="background: #e6fffa; border-left-color: #38b2ac;">
                <strong>🚀 Features Coming Soon:</strong>
                <ul style="margin-top: 10px; margin-left: 20px;">
                    <li>📝 Itinerary planning with daily activities</li>
                    <li>💸 Expense splitting between travel buddies</li>
                    <li>👥 Travel buddy matching and connections</li>
                    <li>📸 Photo uploads for trips and expenses</li>
                    <li>⭐ Place reviews and recommendations</li>
                    <li>📊 Advanced analytics and spending insights</li>
                    <li>🌐 Real-time currency conversion</li>
                </ul>
            </div>
            
            <div class="footer">
                <p>🌟 Happy travels with TourBud! 🌟</p>
                <p><small>Check the source code or README for complete documentation</small></p>
                <p><small>Made with ❤️ for travelers around the world</small></p>
            </div>
        </div>
    </body>
    </html>
    """