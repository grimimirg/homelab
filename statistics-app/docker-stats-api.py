#!/usr/bin/env python3
from flask import Flask, jsonify
from flask_cors import CORS
import docker
from datetime import datetime
import logging
import traceback
import requests_unixsocket

# Register the unix socket adapter
requests_unixsocket.monkeypatch()

app = Flask(__name__)
CORS(app)

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def get_docker_client():
    try:
        # from_env() will use DOCKER_HOST env var or default to unix socket
        client = docker.from_env()
        # Test the connection
        client.ping()
        logger.info("Successfully connected to Docker daemon")
        return client
    except Exception as e:
        logger.error(f"Error connecting to Docker: {e}")
        logger.error(traceback.format_exc())
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
    logger.info("Received request for /api/docker/stats")
    client = get_docker_client()
    
    if not client:
        logger.error("Cannot connect to Docker daemon")
        return jsonify({
            'error': 'Cannot connect to Docker daemon',
            'running': 0,
            'stopped': 0,
            'images': 0,
            'networks': 0,
            'containers': []
        }), 500
    
    try:
        logger.info("Fetching containers...")
        containers = client.containers.list(all=True)
        logger.info(f"Found {len(containers)} containers")
        
        logger.info("Fetching images...")
        images = client.images.list()
        logger.info(f"Found {len(images)} images")
        
        logger.info("Fetching networks...")
        networks = client.networks.list()
        logger.info(f"Found {len(networks)} networks")
        
        running_count = sum(1 for c in containers if c.status == 'running')
        stopped_count = len(containers) - running_count
        
        container_list = []
        for container in containers:
            if container.status == 'running':
                logger.info(f"Processing container: {container.name}")
                container_list.append({
                    'name': container.name,
                    'image': container.image.tags[0] if container.image.tags else container.image.short_id,
                    'state': container.status,
                    'uptime': format_uptime(container.attrs['Created'])
                })
        
        response = {
            'running': running_count,
            'stopped': stopped_count,
            'images': len(images),
            'networks': len(networks),
            'containers': container_list
        }
        logger.info(f"Returning response: {response}")
        return jsonify(response)
    
    except Exception as e:
        logger.error(f"Error in get_stats: {str(e)}")
        logger.error(traceback.format_exc())
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
