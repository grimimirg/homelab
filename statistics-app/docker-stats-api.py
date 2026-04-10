#!/usr/bin/env python3
from flask import Flask, jsonify
from flask_cors import CORS
import docker
from datetime import datetime

app = Flask(__name__)
CORS(app)

def get_docker_client():
    try:
        return docker.from_env()
    except Exception as e:
        print(f"Error connecting to Docker: {e}")
        return None

def format_uptime(created_at):
    try:
        created = datetime.fromisoformat(created_at.replace('Z', '+00:00'))
        now = datetime.now(created.tzinfo)
        delta = now - created
        
        days = delta.days
        hours, remainder = divmod(delta.seconds, 3600)
        minutes, _ = divmod(remainder, 60)
        
        if days > 0:
            return f"{days}d {hours}h"
        elif hours > 0:
            return f"{hours}h {minutes}m"
        else:
            return f"{minutes}m"
    except:
        return "N/A"

@app.route('/api/docker/stats', methods=['GET'])
def get_stats():
    client = get_docker_client()
    
    if not client:
        return jsonify({
            'error': 'Cannot connect to Docker daemon',
            'running': 0,
            'stopped': 0,
            'images': 0,
            'networks': 0,
            'containers': []
        }), 500
    
    try:
        containers = client.containers.list(all=True)
        images = client.images.list()
        networks = client.networks.list()
        
        running_count = sum(1 for c in containers if c.status == 'running')
        stopped_count = len(containers) - running_count
        
        container_list = []
        for container in containers:
            if container.status == 'running':
                container_list.append({
                    'name': container.name,
                    'image': container.image.tags[0] if container.image.tags else container.image.short_id,
                    'state': container.status,
                    'uptime': format_uptime(container.attrs['Created'])
                })
        
        return jsonify({
            'running': running_count,
            'stopped': stopped_count,
            'images': len(images),
            'networks': len(networks),
            'containers': container_list
        })
    
    except Exception as e:
        return jsonify({
            'error': str(e),
            'running': 0,
            'stopped': 0,
            'images': 0,
            'networks': 0,
            'containers': []
        }), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
