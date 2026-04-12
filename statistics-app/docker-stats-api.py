#!/usr/bin/env python3
import docker
import logging
import psutil
import traceback
from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_socketio import SocketIO, emit
from threading import Thread
import time

app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)


def get_docker_client():
    try:
        # Use explicit unix socket path with three slashes as per documentation
        client = docker.DockerClient(base_url='unix:///var/run/docker.sock')
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
            logger.info(f"Processing container: {container.name}")
            container_list.append({
                'id': container.id,
                'name': container.name,
                'image': container.image.tags[0] if container.image.tags else container.image.short_id,
                'state': container.status,
                'uptime': format_uptime(container.attrs['Created']) if container.status == 'running' else 'Stopped'
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


@app.route('/api/docker/container/<container_id>/start', methods=['POST'])
def start_container(container_id):
    logger.info(f"Received request to start container: {container_id}")
    client = get_docker_client()

    if not client:
        return jsonify({'error': 'Cannot connect to Docker daemon'}), 500

    try:
        container = client.containers.get(container_id)
        container.start()
        logger.info(f"Container {container_id} started successfully")
        return jsonify({'success': True, 'message': f'Container {container.name} started'}), 200
    except docker.errors.NotFound:
        logger.error(f"Container {container_id} not found")
        return jsonify({'error': 'Container not found'}), 404
    except Exception as e:
        logger.error(f"Error starting container: {str(e)}")
        logger.error(traceback.format_exc())
        return jsonify({'error': str(e)}), 500


@app.route('/api/docker/container/<container_id>/stop', methods=['POST'])
def stop_container(container_id):
    logger.info(f"Received request to stop container: {container_id}")
    client = get_docker_client()

    if not client:
        return jsonify({'error': 'Cannot connect to Docker daemon'}), 500

    try:
        container = client.containers.get(container_id)
        container.stop()
        logger.info(f"Container {container_id} stopped successfully")
        return jsonify({'success': True, 'message': f'Container {container.name} stopped'}), 200
    except docker.errors.NotFound:
        logger.error(f"Container {container_id} not found")
        return jsonify({'error': 'Container not found'}), 404
    except Exception as e:
        logger.error(f"Error stopping container: {str(e)}")
        logger.error(traceback.format_exc())
        return jsonify({'error': str(e)}), 500


@app.route('/api/docker/container/<container_id>/restart', methods=['POST'])
def restart_container(container_id):
    logger.info(f"Received request to restart container: {container_id}")
    client = get_docker_client()

    if not client:
        return jsonify({'error': 'Cannot connect to Docker daemon'}), 500

    try:
        container = client.containers.get(container_id)
        container.restart()
        logger.info(f"Container {container_id} restarted successfully")
        return jsonify({'success': True, 'message': f'Container {container.name} restarted'}), 200
    except docker.errors.NotFound:
        logger.error(f"Container {container_id} not found")
        return jsonify({'error': 'Container not found'}), 404
    except Exception as e:
        logger.error(f"Error restarting container: {str(e)}")
        logger.error(traceback.format_exc())
        return jsonify({'error': str(e)}), 500


def _collect_server_performances():
    memory = psutil.virtual_memory()
    swap = psutil.swap_memory()
    net_io = psutil.net_io_counters()

    return {
        'cpuPercent': psutil.cpu_percent(),
        'memoryPercent': memory.percent,
        'memory': {
            'total': round(memory.total / (1024 ** 3), 2),
            'available': round(memory.available / (1024 ** 3), 2),
            'used': round(memory.used / (1024 ** 3), 2),
            'percent': memory.percent
        },
        'swap': {
            'total': round(swap.total / (1024 ** 3), 2),
            'used': round(swap.used / (1024 ** 3), 2),
            'percent': swap.percent
        },
        'diskPercent': psutil.disk_usage('/').percent,
        'network': {
            'bytesSent': net_io.bytes_sent,
            'bytesRecv': net_io.bytes_recv,
            'packetsSent': net_io.packets_sent,
            'packetsRecv': net_io.packets_recv,
            'errorsIn': net_io.errin,
            'errorsOut': net_io.errout
        },
        'uptime': format_uptime(datetime.fromtimestamp(psutil.boot_time()).isoformat())
    }


@app.route('/api/server/performances', methods=['GET'])
def performances():
    return jsonify(_collect_server_performances())


@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'}), 200


def get_server_performances():
    return _collect_server_performances()

def background_performance_emitter():
    while True:
        try:
            data = get_server_performances()
            socketio.emit('server_performance', data, namespace='/performance')
            time.sleep(2)
        except Exception as e:
            logger.error(f"Error emitting performance data: {e}")
            time.sleep(2)

@socketio.on('connect', namespace='/performance')
def handle_connect():
    logger.info('Client connected to performance stream')
    emit('server_performance', get_server_performances())

@socketio.on('disconnect', namespace='/performance')
def handle_disconnect():
    logger.info('Client disconnected from performance stream')

if __name__ == '__main__':
    background_thread = Thread(target=background_performance_emitter, daemon=True)
    background_thread.start()
    socketio.run(app, host='0.0.0.0', port=5000, allow_unsafe_werkzeug=True)
