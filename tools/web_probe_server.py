"""Serve the built T004 probe and a separate-site sandboxed iframe host.

python tools/web_probe_server.py --build apps/game/build/web
No authentication, production data, COOP/COEP, or external requests.
"""
import argparse
import functools
import http.server
import threading


class Host(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        page = b'''<!doctype html><meta charset="utf-8"><title>T004 iframe host</title>
<style>body{margin:0;background:#090d1c}iframe{border:0;width:100vw;height:95vh}</style>
<iframe title="SIGNAL ZERO probe" src="http://127.0.0.1:8191/"
sandbox="allow-scripts allow-same-origin allow-downloads allow-forms allow-pointer-lock"
allow="autoplay; fullscreen"></iframe>'''
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', str(len(page)))
        self.end_headers()
        self.wfile.write(page)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--build', default='apps/game/build/web')
    args = parser.parse_args()
    app = http.server.ThreadingHTTPServer(
        ('127.0.0.1', 8191),
        functools.partial(http.server.SimpleHTTPRequestHandler, directory=args.build),
    )
    host = http.server.ThreadingHTTPServer(('127.0.0.1', 8192), Host)
    threading.Thread(target=app.serve_forever, daemon=True).start()
    print('App http://127.0.0.1:8191 ; iframe host http://localhost:8192', flush=True)
    try:
        host.serve_forever()
    except KeyboardInterrupt:
        app.shutdown()
        host.server_close()
