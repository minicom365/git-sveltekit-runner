// [EN] Tiny pull-and-reload webhook receiver for a SvelteKit app. No Flask/Python: plain Node.js stdlib.
//      Verifies X-Gitea-Signature (HMAC-SHA256) when WEBHOOK_SECRET is set, then runs pull_and_reload.sh detached.
// [KO] SvelteKit 앱용 초경량 webhook 수신기. Flask/Python 없이 Node.js 표준 라이브러리만 사용.
//      WEBHOOK_SECRET이 있으면 X-Gitea-Signature(HMAC-SHA256)를 검증한 뒤 pull_and_reload.sh를 백그라운드로 실행.
'use strict';

const http = require('http');
const crypto = require('crypto');
const { spawn } = require('child_process');

const PORT = parseInt(process.env.PORT || '4000', 10);
const SECRET = process.env.WEBHOOK_SECRET || '';
const SCRIPT = '/app/pull_and_reload.sh';

function verifySignature(rawBody, headerValue) {
    if (!SECRET) return true; // 시크릿 미설정 시 기존 동작 유지(경고 로그)
    if (!headerValue) return false;
    const expected = 'sha256=' + crypto.createHmac('sha256', SECRET).update(rawBody).digest('hex');
    const a = Buffer.from(expected, 'utf8');
    const b = Buffer.from(String(headerValue).trim(), 'utf8');
    return a.length === b.length && crypto.timingSafeEqual(a, b);
}

const server = http.createServer((req, res) => {
    if (req.method === 'GET' && (req.url === '/health' || req.url === '/')) {
        res.writeHead(200, { 'content-type': 'text/plain; charset=utf-8' });
        res.end('ok');
        return;
    }
    if (req.method === 'POST' && req.url === '/webhook') {
        const chunks = [];
        req.on('data', (c) => chunks.push(c));
        req.on('end', () => {
            const raw = Buffer.concat(chunks);
            const sig = req.headers['x-gitea-signature'] || req.headers['x-hub-signature-256'] || '';
            if (!verifySignature(raw, sig)) {
                console.warn('[webhook] rejected: invalid signature');
                res.writeHead(401, { 'content-type': 'text/plain; charset=utf-8' });
                res.end('invalid signature');
                return;
            }
            console.log('[webhook] accepted: starting pull_and_reload');
            const child = spawn(SCRIPT, [], { stdio: 'inherit', detached: true });
            child.unref();
            res.writeHead(200, { 'content-type': 'text/plain; charset=utf-8' });
            res.end('pulled and reloaded');
        });
        return;
    }
    res.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' });
    res.end('not found');
});

server.listen(PORT, '0.0.0.0', () => {
    console.log('[webhook] listening on ' + PORT + (SECRET ? ' (signed)' : ' (unsigned, set WEBHOOK_SECRET to enforce)'));
});
