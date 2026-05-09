import urllib.request, urllib.error, json

BASE = 'http://localhost:8000/api/v1'

def post(path, data):
    body = json.dumps(data).encode()
    req = urllib.request.Request(
        f'{BASE}{path}', data=body,
        headers={'Content-Type': 'application/json'},
        method='POST'
    )
    try:
        r = urllib.request.urlopen(req)
        return json.loads(r.read()), r.status
    except urllib.error.HTTPError as e:
        return json.loads(e.read()), e.code

def get_auth(path, token):
    req = urllib.request.Request(
        f'{BASE}{path}',
        headers={'Authorization': f'Bearer {token}'},
        method='GET'
    )
    try:
        r = urllib.request.urlopen(req)
        return json.loads(r.read()), r.status
    except urllib.error.HTTPError as e:
        return json.loads(e.read()), e.code

# ── 1. Register ───────────────────────────────────────────────────
print('=== REGISTER ===')
resp, code = post('/auth/register', {
    'full_name': 'Test Owner',
    'email': 'testowner@clp.com',
    'password': 'Test@1234',
    'role': 'business_owner'
})
print(f'Status: {code}')
print(json.dumps(resp, indent=2)[:500])

# ── 2. Login ──────────────────────────────────────────────────────
print('\n=== LOGIN ===')
resp2, code2 = post('/auth/login', {
    'email': 'testowner@clp.com',
    'password': 'Test@1234'
})
print(f'Status: {code2}')
token = resp2.get('access_token', '')
if token:
    print('access_token: ' + token[:50] + '...')
    print('user_id: ' + str(resp2.get('user_id')))
    print('role:    ' + str(resp2.get('role')))
else:
    print(json.dumps(resp2, indent=2)[:500])

# ── 3. Dashboard (authenticated) ─────────────────────────────────
if token:
    print('\n=== DASHBOARD (no business yet — expect empty/404) ===')
    resp3, code3 = get_auth('/dashboard?business_id=00000000-0000-0000-0000-000000000000', token)
    print(f'Status: {code3}')
    print(json.dumps(resp3, indent=2)[:300])
