from flask import Flask, render_template, request
import os
import mysql.connector
import socket
from datetime import datetime

app = Flask(__name__)

def get_db_connection():
    try:
        conn = mysql.connector.connect(
            host=os.getenv('DB_HOST'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            database=os.getenv('DB_NAME')
        )
        return conn, None
    except Exception as e:
        return None, str(e)

@app.route('/')
def index():
    server_ip = socket.gethostbyname(socket.gethostname())
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # Database connection test
    conn, error = get_db_connection()
    db_success = error is None
    visit_count = 0
    recent_visits = []
    
    if db_success:
        cursor = conn.cursor(dictionary=True)
        
        # Create table if it doesn't exist
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS page_visits (
                id INT AUTO_INCREMENT PRIMARY KEY,
                visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                visitor_ip VARCHAR(45)
            )
        ''')
        
        # Record this visit
        visitor_ip = request.remote_addr if hasattr(request, 'remote_addr') else '127.0.0.1'
        cursor.execute("INSERT INTO page_visits (visitor_ip) VALUES (%s)", (visitor_ip,))
        
        # Get visit count
        cursor.execute("SELECT COUNT(*) as count FROM page_visits")
        visit_count = cursor.fetchone()['count']
        
        # Get recent visits
        cursor.execute("SELECT * FROM page_visits ORDER BY visit_time DESC LIMIT 5")
        recent_visits = cursor.fetchall()
        
        conn.commit()
        cursor.close()
        conn.close()
    
    return render_template('index.html', 
                          server_ip=server_ip,
                          current_time=current_time,
                          db_success=db_success,
                          error=error,
                          visit_count=visit_count,
                          recent_visits=recent_visits)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)