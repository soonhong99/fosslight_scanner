# custom_volume_plugin.py
import os
import sys
import json

def create(name, opts):
    return {'Err': ''}

def mount(name, id, opts=None):
    opts = opts or {}
    source_path = opts.get('SourcePath', '')
    if not source_path:
        return {'Err': 'SourcePath not provided'}
    return {'Mountpoint': source_path, 'Err': ''}

def unmount(name, id):
    return {'Err': ''}

if __name__ == '__main__':
    if len(sys.argv) > 1:
        if sys.argv[1] == 'create':
            print(json.dumps(create(sys.argv[2], json.loads(sys.argv[3]))))
        elif sys.argv[1] == 'mount':
            print(json.dumps(mount(sys.argv[2], sys.argv[3])))
        elif sys.argv[1] == 'unmount':
            print(json.dumps(unmount(sys.argv[2], sys.argv[3])))